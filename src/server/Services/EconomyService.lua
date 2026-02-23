--[[
    EconomyService.lua
    Server-authoritative economy management for Palm Springs Paradise.
    Manages SunCoins, Prestige, Level, leaderstats, transactions,
    and anti-exploit validation.

    ALL currency mutations happen here — never on the client.
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnalyticsService  = game:GetService("AnalyticsService")

local GameConfig     = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteManager  = require(ReplicatedStorage:WaitForChild("RemoteManager"))
local Utilities      = require(ReplicatedStorage:WaitForChild("Utilities"))

local EconomyService = {}

-- Internal state
EconomyService._playerData = {}       -- userId → profile data ref
EconomyService._rateLimits = {}       -- userId → { count, lastReset }
EconomyService._persistenceService = nil

---------------------------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------------------------

--- Initialize the economy service.
--- @param persistenceService table — reference to PersistenceService for saving
function EconomyService:init(persistenceService)
    self._persistenceService = persistenceService

    -- Listen for economy-related remote events
    local purchaseEvent = RemoteManager:getEvent("PurchaseItem")
    if purchaseEvent then
        purchaseEvent.OnServerEvent:Connect(function(player, itemId)
            self:_handlePurchase(player, itemId)
        end)
    end

    print("[EconomyService] Initialized")
end

---------------------------------------------------------------------------
-- LEADERSTATS
---------------------------------------------------------------------------

--- Create leaderstats folder for a player with initial values.
function EconomyService:createLeaderstats(player: Player, data: table)
    -- Store reference
    self._playerData[player.UserId] = data

    -- Create leaderstats folder
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local coins = Instance.new("IntValue")
    coins.Name = "SunCoins"
    coins.Value = data.sunCoins or GameConfig.Economy.StartingCoins
    coins.Parent = leaderstats

    local prestige = Instance.new("IntValue")
    prestige.Name = "Prestige"
    prestige.Value = data.prestige or GameConfig.Economy.StartingPrestige
    prestige.Parent = leaderstats

    local level = Instance.new("IntValue")
    level.Name = "Level"
    level.Value = data.level or 1
    level.Parent = leaderstats

    -- Initialize rate limit tracking
    self._rateLimits[player.UserId] = { count = 0, lastReset = os.time() }

    print("[EconomyService] Leaderstats created for " .. player.Name ..
          " (Coins=" .. coins.Value .. ", Prestige=" .. prestige.Value .. ")")
end

--- Remove player data on leave.
function EconomyService:removePlayer(player: Player)
    self._playerData[player.UserId] = nil
    self._rateLimits[player.UserId] = nil
end

---------------------------------------------------------------------------
-- ANTI-EXPLOIT: Rate Limiting
---------------------------------------------------------------------------

function EconomyService:_checkRateLimit(player: Player): boolean
    local userId = player.UserId
    local rl = self._rateLimits[userId]
    if not rl then return false end

    local now = os.time()
    -- Reset counter every 60 seconds
    if now - rl.lastReset >= 60 then
        rl.count = 0
        rl.lastReset = now
    end

    rl.count += 1
    if rl.count > GameConfig.Economy.MaxTransactionsPerMinute then
        warn("[EconomyService] Rate limit exceeded for " .. player.Name)
        return false
    end

    return true
end

---------------------------------------------------------------------------
-- COIN OPERATIONS
---------------------------------------------------------------------------

--- Add SunCoins to a player. Server-only, validated.
--- @param player Player
--- @param amount number — must be positive
--- @param reason string — logging tag
--- @return boolean — success
function EconomyService:addCoins(player: Player, amount: number, reason: string): boolean
    -- Validation
    if type(amount) ~= "number" or amount <= 0 or amount ~= math.floor(amount) then
        warn("[EconomyService] Invalid addCoins amount: " .. tostring(amount))
        return false
    end

    if amount > GameConfig.Economy.MaxCoinGrant then
        warn("[EconomyService] Coin grant exceeds maximum: " .. amount)
        return false
    end

    local data = self._playerData[player.UserId]
    if not data then return false end

    data.sunCoins += amount
    data.stats.totalCoinsEarned += amount
    self:_syncLeaderstats(player)
    self:_markDirty(player)

    -- Notify client
    RemoteManager:fireClient("EconomyUpdate", player, {
        sunCoins = data.sunCoins,
        prestige = data.prestige,
        reason = reason,
        delta = amount,
    })

    return true
end

--- Remove SunCoins from a player. Checks balance first.
--- @return boolean — success (false if insufficient funds)
function EconomyService:removeCoins(player: Player, amount: number, reason: string): boolean
    if type(amount) ~= "number" or amount <= 0 or amount ~= math.floor(amount) then
        warn("[EconomyService] Invalid removeCoins amount: " .. tostring(amount))
        return false
    end

    local data = self._playerData[player.UserId]
    if not data then return false end

    if data.sunCoins < amount then
        return false  -- insufficient funds
    end

    data.sunCoins -= amount
    self:_syncLeaderstats(player)
    self:_markDirty(player)

    RemoteManager:fireClient("EconomyUpdate", player, {
        sunCoins = data.sunCoins,
        prestige = data.prestige,
        reason = reason,
        delta = -amount,
    })

    return true
end

--- Add Prestige points.
function EconomyService:addPrestige(player: Player, amount: number): boolean
    if type(amount) ~= "number" or amount <= 0 then return false end

    local data = self._playerData[player.UserId]
    if not data then return false end

    data.prestige += math.floor(amount)
    data.stats.totalPrestigeEarned += math.floor(amount)

    -- Level up check (every 100 prestige = 1 level)
    local newLevel = math.floor(data.prestige / 100) + 1
    if newLevel > data.level then
        data.level = newLevel
        RemoteManager:fireClient("NotifyPlayer", player,
            "Level Up! You are now Level " .. newLevel .. "!")

        pcall(function()
            AnalyticsService:LogProgressionEvent(player, Enum.AnalyticsProgressionType.Complete, "LevelUp", {
                ["level"] = data.level,
            })
        end)
    end

    self:_syncLeaderstats(player)
    self:_markDirty(player)

    RemoteManager:fireClient("EconomyUpdate", player, {
        sunCoins = data.sunCoins,
        prestige = data.prestige,
        level = data.level,
    })

    pcall(function()
        AnalyticsService:LogProgressionEvent(player, Enum.AnalyticsProgressionType.Complete, "PrestigeUp", {
            ["prestige_total"] = data.prestige,
        })
    end)

    return true
end

--- Get current SunCoins balance.
function EconomyService:getBalance(player: Player): number
    local data = self._playerData[player.UserId]
    return data and data.sunCoins or 0
end

--- Check if player can afford a cost.
function EconomyService:canAfford(player: Player, cost: number): boolean
    return self:getBalance(player) >= cost
end

---------------------------------------------------------------------------
-- PLAYER-TO-PLAYER TRANSACTIONS
---------------------------------------------------------------------------

--- Process a transaction between two players (e.g., shop purchase).
--- @param buyer Player
--- @param seller Player
--- @param amount number — price in SunCoins
--- @param itemId string — item being traded
--- @return boolean
function EconomyService:processTransaction(buyer: Player, seller: Player, amount: number, itemId: string): boolean
    if not self:_checkRateLimit(buyer) then
        RemoteManager:fireClient("NotifyPlayer", buyer, "Too many transactions! Please wait.")
        return false
    end

    if type(amount) ~= "number" or amount <= 0 or amount ~= math.floor(amount) then
        return false
    end

    -- Calculate tax
    local tax = math.floor(amount * GameConfig.Economy.ShopTaxRate)
    local sellerReceives = amount - tax

    -- Check buyer can afford
    if not self:canAfford(buyer, amount) then
        RemoteManager:fireClient("NotifyPlayer", buyer, "Insufficient SunCoins!")
        return false
    end

    -- Execute atomically
    local buyerData = self._playerData[buyer.UserId]
    local sellerData = self._playerData[seller.UserId]
    if not buyerData or not sellerData then return false end

    buyerData.sunCoins -= amount
    sellerData.sunCoins += sellerReceives

    buyerData.stats.itemsBought += 1
    sellerData.stats.itemsSold += 1

    self:_syncLeaderstats(buyer)
    self:_syncLeaderstats(seller)
    self:_markDirty(buyer)
    self:_markDirty(seller)

    -- Notify both players
    RemoteManager:fireClient("EconomyUpdate", buyer, {
        sunCoins = buyerData.sunCoins,
        reason = "Purchased " .. itemId,
        delta = -amount,
    })

    RemoteManager:fireClient("EconomyUpdate", seller, {
        sunCoins = sellerData.sunCoins,
        reason = "Sold " .. itemId .. " (tax: " .. tax .. ")",
        delta = sellerReceives,
    })

    return true
end

---------------------------------------------------------------------------
-- INVENTORY MANAGEMENT
---------------------------------------------------------------------------

--- Give an item to a player's inventory.
function EconomyService:giveItem(player: Player, itemId: string, quantity: number?)
    local data = self._playerData[player.UserId]
    if not data then return end

    quantity = quantity or 1
    data.inventory[itemId] = (data.inventory[itemId] or 0) + quantity
    self:_markDirty(player)
end

--- Remove an item from a player's inventory.
function EconomyService:removeItem(player: Player, itemId: string, quantity: number?): boolean
    local data = self._playerData[player.UserId]
    if not data then return false end

    quantity = quantity or 1
    local current = data.inventory[itemId] or 0
    if current < quantity then return false end

    data.inventory[itemId] = current - quantity
    if data.inventory[itemId] <= 0 then
        data.inventory[itemId] = nil
    end
    self:_markDirty(player)
    return true
end

--- Check if player has an item.
function EconomyService:hasItem(player: Player, itemId: string, quantity: number?): boolean
    local data = self._playerData[player.UserId]
    if not data then return false end
    return (data.inventory[itemId] or 0) >= (quantity or 1)
end

---------------------------------------------------------------------------
-- INTERNAL HELPERS
---------------------------------------------------------------------------

--- Sync leaderstats IntValues from internal data.
function EconomyService:_syncLeaderstats(player: Player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end

    local data = self._playerData[player.UserId]
    if not data then return end

    local coins = leaderstats:FindFirstChild("SunCoins")
    if coins then coins.Value = data.sunCoins end

    local prestige = leaderstats:FindFirstChild("Prestige")
    if prestige then prestige.Value = data.prestige end

    local level = leaderstats:FindFirstChild("Level")
    if level then level.Value = data.level end
end

--- Mark player data as dirty for next auto-save.
function EconomyService:_markDirty(player: Player)
    if self._persistenceService then
        self._persistenceService:markDirty(player)
    end
end

--- Handle PurchaseItem remote event (buy from NPC shop / catalog).
function EconomyService:_handlePurchase(player: Player, itemId: string)
    if not self:_checkRateLimit(player) then
        RemoteManager:fireClient("NotifyPlayer", player, "Too many purchases! Slow down.")
        return
    end

    -- Look up item in catalog
    local ItemCatalog = require(ReplicatedStorage:WaitForChild("ItemCatalog"))
    local item = ItemCatalog.getAnyItem(itemId)
    if not item then
        warn("[EconomyService] Unknown item: " .. tostring(itemId))
        return
    end

    local price = item.price or item.basePrice or item.seedPrice or 0
    if not self:removeCoins(player, price, "Purchase: " .. itemId) then
        RemoteManager:fireClient("NotifyPlayer", player,
            "Not enough SunCoins! Need " .. price)
        return
    end

    self:giveItem(player, itemId)
    RemoteManager:fireClient("NotifyPlayer", player,
        "Purchased " .. (item.name or itemId) .. "!")
end

--- Get player data reference (for other services).
function EconomyService:getPlayerData(player: Player): table?
    return self._playerData[player.UserId]
end

return EconomyService
