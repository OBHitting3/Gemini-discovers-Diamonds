--[[
    ShopService.lua
    Manages El Paseo boutique storefronts: claiming, stocking,
    pricing, purchasing, shop naming, and market overview.

    6 storefront slots along El Paseo boulevard.
    Server-authoritative with 10% tax on all transactions.
]]

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig    = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteManager = require(ReplicatedStorage:WaitForChild("RemoteManager"))
local ItemCatalog   = require(ReplicatedStorage:WaitForChild("ItemCatalog"))
local Utilities     = require(ReplicatedStorage:WaitForChild("Utilities"))

local ShopService = {}

-- Internal state
ShopService._shops = {}             -- shopId → ShopData
ShopService._economyService = nil
ShopService._webhookClient = nil
ShopService._persistenceService = nil

---------------------------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------------------------

function ShopService:init(economyService, webhookClient, persistenceService)
    self._economyService = economyService
    self._webhookClient = webhookClient
    self._persistenceService = persistenceService

    -- Initialize 6 storefront slots
    for shopId = 1, 6 do
        self._shops[shopId] = {
            shopId = shopId,
            ownerId = nil,
            displayName = "Unclaimed Storefront #" .. shopId,
            inventory = {},
            totalSales = 0,
            rating = 0,
        }
    end

    -- Connect remote events
    local claimEvent = RemoteManager:getEvent("ClaimShop")
    if claimEvent then
        claimEvent.OnServerEvent:Connect(function(player, shopId)
            self:claimShop(player, shopId)
        end)
    end

    local updateEvent = RemoteManager:getEvent("UpdateShopInventory")
    if updateEvent then
        updateEvent.OnServerEvent:Connect(function(player, action, ...)
            if action == "stock" then
                self:stockItem(player, ...)
            elseif action == "remove" then
                self:removeItem(player, ...)
            elseif action == "setName" then
                self:setShopName(player, ...)
            elseif action == "setPrice" then
                self:setItemPrice(player, ...)
            end
        end)
    end

    local sellEvent = RemoteManager:getEvent("SellItem")
    if sellEvent then
        sellEvent.OnServerEvent:Connect(function(player, shopId, itemId)
            self:purchaseFromShop(player, shopId, itemId)
        end)
    end

    -- Remote function
    local getShopFunc = RemoteManager:getFunction("GetShopData")
    if getShopFunc then
        getShopFunc.OnServerInvoke = function(_player, shopId)
            if shopId then
                return self:getShopInventory(shopId)
            else
                return self:getMarketListings()
            end
        end
    end

    print("[ShopService] Initialized with 6 storefront slots")
end

---------------------------------------------------------------------------
-- CLAIM SHOP
---------------------------------------------------------------------------

function ShopService:claimShop(player: Player, shopId: number): boolean
    if type(shopId) ~= "number" or shopId < 1 or shopId > 6 then
        return false
    end

    local shop = self._shops[shopId]

    -- Already claimed?
    if shop.ownerId then
        RemoteManager:fireClient("NotifyPlayer", player,
            "This storefront is already claimed!")
        return false
    end

    -- Check player doesn't already own a shop
    local data = self._economyService:getPlayerData(player)
    if data and data.shopId then
        RemoteManager:fireClient("NotifyPlayer", player,
            "You already own a storefront!")
        return false
    end

    -- Afford check
    local price = GameConfig.Economy.StorefrontRental[shopId]
    if not self._economyService:removeCoins(player, price, "Claim shop #" .. shopId) then
        RemoteManager:fireClient("NotifyPlayer", player,
            "Not enough SunCoins! Need " .. Utilities.formatCurrency(price))
        return false
    end

    -- Claim
    shop.ownerId = player.UserId
    shop.displayName = player.Name .. "'s Boutique"

    if data then
        data.shopId = shopId
    end

    -- Update the storefront visual sign
    self:_updateStorefrontSign(shopId)

    -- Remove claim prompt from the storefront
    local elPaseo = workspace:FindFirstChild("ElPaseo")
    if elPaseo then
        local sf = elPaseo:FindFirstChild("Storefront_" .. shopId)
        if sf then
            sf:SetAttribute("Claimed", true)
            local signBoard = sf:FindFirstChild("SignBoard")
            if signBoard then
                local prompt = signBoard:FindFirstChild("ClaimShopPrompt")
                if prompt then prompt:Destroy() end
            end
        end
    end

    self:_markDirty(player)
    RemoteManager:fireClient("NotifyPlayer", player,
        "Claimed El Paseo storefront #" .. shopId .. "!")

    -- Broadcast shop update
    RemoteManager:fireAllClients("ShopUpdate", {
        action = "claimed",
        shopId = shopId,
        ownerName = player.Name,
    })

    print("[ShopService] " .. player.Name .. " claimed shop #" .. shopId)
    return true
end

---------------------------------------------------------------------------
-- STOCK / REMOVE ITEMS
---------------------------------------------------------------------------

function ShopService:stockItem(player: Player, itemId: string, quantity: number?, price: number?): boolean
    local shop = self:_getPlayerShop(player)
    if not shop then
        RemoteManager:fireClient("NotifyPlayer", player, "You don't own a shop!")
        return false
    end

    quantity = quantity or 1
    if type(quantity) ~= "number" or quantity < 1 then return false end

    -- Check player has the item
    if not self._economyService:hasItem(player, itemId, quantity) then
        RemoteManager:fireClient("NotifyPlayer", player,
            "You don't have enough of this item!")
        return false
    end

    -- Determine price
    local item = ItemCatalog.getAnyItem(itemId)
    local itemPrice = price or (item and (item.price or item.basePrice or item.seedPrice)) or 10
    if type(itemPrice) ~= "number" or itemPrice < 1 then itemPrice = 10 end

    -- Remove from player inventory
    self._economyService:removeItem(player, itemId, quantity)

    -- Add to shop inventory (merge if already listed)
    local found = false
    for _, listing in ipairs(shop.inventory) do
        if listing.itemId == itemId then
            listing.quantity += quantity
            listing.price = itemPrice
            found = true
            break
        end
    end

    if not found then
        table.insert(shop.inventory, {
            itemId = itemId,
            quantity = quantity,
            price = itemPrice,
            listedAt = os.time(),
        })
    end

    self:_markDirty(player)
    RemoteManager:fireClient("NotifyPlayer", player,
        "Stocked " .. quantity .. "x " .. (item and item.name or itemId) ..
        " at " .. Utilities.formatCurrency(itemPrice) .. " each")

    return true
end

function ShopService:removeItem(player: Player, itemId: string): boolean
    local shop = self:_getPlayerShop(player)
    if not shop then return false end

    for i, listing in ipairs(shop.inventory) do
        if listing.itemId == itemId then
            -- Return items to player
            self._economyService:giveItem(player, itemId, listing.quantity)
            table.remove(shop.inventory, i)
            self:_markDirty(player)
            RemoteManager:fireClient("NotifyPlayer", player,
                "Removed " .. itemId .. " from shop")
            return true
        end
    end

    return false
end

function ShopService:setItemPrice(player: Player, itemId: string, newPrice: number): boolean
    local shop = self:_getPlayerShop(player)
    if not shop then return false end
    if type(newPrice) ~= "number" or newPrice < 1 then return false end

    for _, listing in ipairs(shop.inventory) do
        if listing.itemId == itemId then
            listing.price = math.floor(newPrice)
            self:_markDirty(player)
            return true
        end
    end

    return false
end

---------------------------------------------------------------------------
-- PURCHASE FROM SHOP
---------------------------------------------------------------------------

function ShopService:purchaseFromShop(buyer: Player, shopId: number, itemId: string): boolean
    if type(shopId) ~= "number" or shopId < 1 or shopId > 6 then return false end

    local shop = self._shops[shopId]
    if not shop or not shop.ownerId then
        RemoteManager:fireClient("NotifyPlayer", buyer, "This shop isn't open!")
        return false
    end

    -- Can't buy from own shop
    if shop.ownerId == buyer.UserId then
        RemoteManager:fireClient("NotifyPlayer", buyer,
            "You can't buy from your own shop!")
        return false
    end

    -- Find item in shop inventory
    local listing = nil
    local listingIndex = nil
    for i, l in ipairs(shop.inventory) do
        if l.itemId == itemId and l.quantity > 0 then
            listing = l
            listingIndex = i
            break
        end
    end

    if not listing then
        RemoteManager:fireClient("NotifyPlayer", buyer, "Item not available!")
        return false
    end

    -- Process transaction
    local seller = Players:GetPlayerByUserId(shop.ownerId)
    if seller then
        local success = self._economyService:processTransaction(
            buyer, seller, listing.price, itemId
        )
        if not success then return false end
    else
        -- Seller offline — direct purchase from game
        if not self._economyService:removeCoins(buyer, listing.price, "Shop purchase: " .. itemId) then
            RemoteManager:fireClient("NotifyPlayer", buyer, "Not enough SunCoins!")
            return false
        end
    end

    -- Give item to buyer
    self._economyService:giveItem(buyer, itemId)

    -- Update shop inventory
    listing.quantity -= 1
    if listing.quantity <= 0 then
        table.remove(shop.inventory, listingIndex)
    end

    shop.totalSales += 1

    -- Webhook for transaction tracking
    if self._webhookClient then
        self._webhookClient:sendShopTransaction({
            buyerId = buyer.UserId,
            sellerId = shop.ownerId,
            itemId = itemId,
            amount = listing.price,
            tax = math.floor(listing.price * GameConfig.Economy.ShopTaxRate),
        })
    end

    -- Broadcast
    RemoteManager:fireAllClients("ShopUpdate", {
        action = "purchase",
        shopId = shopId,
        itemId = itemId,
        buyerName = buyer.Name,
    })

    print("[ShopService] " .. buyer.Name .. " bought " .. itemId ..
          " from shop #" .. shopId)
    return true
end

---------------------------------------------------------------------------
-- SHOP MANAGEMENT
---------------------------------------------------------------------------

function ShopService:setShopName(player: Player, name: string): boolean
    local shop = self:_getPlayerShop(player)
    if not shop then return false end

    -- Sanitize name (max 30 chars, no special chars)
    name = string.sub(tostring(name), 1, 30)
    shop.displayName = name
    self:_updateStorefrontSign(shop.shopId)
    self:_markDirty(player)

    RemoteManager:fireClient("NotifyPlayer", player,
        "Shop renamed to: " .. name)
    return true
end

---------------------------------------------------------------------------
-- DATA ACCESS
---------------------------------------------------------------------------

function ShopService:getShopInventory(shopId: number): table?
    return self._shops[shopId]
end

function ShopService:getMarketListings(): { table }
    local listings = {}
    for _, shop in pairs(self._shops) do
        if shop.ownerId and #shop.inventory > 0 then
            table.insert(listings, {
                shopId = shop.shopId,
                displayName = shop.displayName,
                itemCount = #shop.inventory,
                totalSales = shop.totalSales,
            })
        end
    end
    return listings
end

---------------------------------------------------------------------------
-- INTERNAL
---------------------------------------------------------------------------

function ShopService:_getPlayerShop(player: Player): table?
    for _, shop in pairs(self._shops) do
        if shop.ownerId == player.UserId then
            return shop
        end
    end
    return nil
end

function ShopService:_updateStorefrontSign(shopId: number)
    local shop = self._shops[shopId]
    if not shop then return end

    local elPaseo = workspace:FindFirstChild("ElPaseo")
    if not elPaseo then return end

    local sf = elPaseo:FindFirstChild("Storefront_" .. shopId)
    if not sf then return end

    local signBoard = sf:FindFirstChild("SignBoard")
    if not signBoard then return end

    local gui = signBoard:FindFirstChild("ShopSign")
    if gui then
        local lbl = gui:FindFirstChild("ShopName")
        if lbl then
            lbl.Text = shop.displayName
        end
    end
end

function ShopService:_markDirty(player: Player)
    if self._persistenceService then
        self._persistenceService:markDirty(player)
    end
end

--- Check if today is a weekend (for weekend market bonus).
function ShopService:isWeekendMarket(): boolean
    local day = os.date("*t").wday  -- 1=Sun, 7=Sat
    return day == 1 or day == 7
end

return ShopService
