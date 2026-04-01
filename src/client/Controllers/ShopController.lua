--[[
    ShopController.lua
    Client-side shop interactions: claim prompts, management panel,
    browsing, purchasing, market overview.
]]

local Players           = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig    = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteManager = require(ReplicatedStorage:WaitForChild("RemoteManager"))

local ShopController = {}
ShopController._uiController = nil
ShopController._shopUpdates = {}

---------------------------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------------------------

function ShopController:init(uiController)
    self._uiController = uiController

    -- Listen for shop updates
    local shopEvent = RemoteManager:getEvent("ShopUpdate")
    if shopEvent then
        shopEvent.OnClientEvent:Connect(function(data)
            self:_onShopUpdate(data)
        end)
    end

    -- Set up proximity prompts on storefronts
    task.spawn(function()
        task.wait(5)  -- Wait for El Paseo to build
        self:_setupStorefrontPrompts()
    end)

    print("[ShopController] Initialized")
end

---------------------------------------------------------------------------
-- PROXIMITY PROMPTS
---------------------------------------------------------------------------

function ShopController:_setupStorefrontPrompts()
    local elPaseo = workspace:FindFirstChild("ElPaseo")
    if not elPaseo then return end

    for _, sf in ipairs(elPaseo:GetChildren()) do
        if sf:IsA("Model") and sf:GetAttribute("SlotId") then
            local signBoard = sf:FindFirstChild("SignBoard")
            if signBoard then
                local prompt = signBoard:FindFirstChild("ClaimShopPrompt")
                if prompt then
                    prompt.Triggered:Connect(function(player)
                        if player == Players.LocalPlayer then
                            local slotId = sf:GetAttribute("SlotId")
                            self:_onShopClaimTriggered(slotId)
                        end
                    end)
                end
            end
        end
    end
end

function ShopController:_onShopClaimTriggered(slotId: number)
    RemoteManager:fireServer("ClaimShop", slotId)
end

---------------------------------------------------------------------------
-- SHOP UPDATES
---------------------------------------------------------------------------

function ShopController:_onShopUpdate(data: table)
    if data.action == "claimed" then
        self._uiController:showNotification(
            data.ownerName .. " claimed El Paseo storefront #" .. data.shopId .. "!")
    elseif data.action == "purchase" then
        self._uiController:showNotification(
            data.buyerName .. " bought " .. data.itemId .. " from shop #" .. data.shopId)
    end
end

---------------------------------------------------------------------------
-- SHOP ACTIONS
---------------------------------------------------------------------------

function ShopController:claimShop(slotId: number)
    RemoteManager:fireServer("ClaimShop", slotId)
end

function ShopController:stockItem(itemId: string, quantity: number?, price: number?)
    RemoteManager:fireServer("UpdateShopInventory", "stock", itemId, quantity or 1, price)
end

function ShopController:removeItem(itemId: string)
    RemoteManager:fireServer("UpdateShopInventory", "remove", itemId)
end

function ShopController:setShopName(name: string)
    RemoteManager:fireServer("UpdateShopInventory", "setName", name)
end

function ShopController:purchaseFromShop(shopId: number, itemId: string)
    RemoteManager:fireServer("SellItem", shopId, itemId)
end

---------------------------------------------------------------------------
-- DATA REQUESTS
---------------------------------------------------------------------------

function ShopController:getShopData(shopId: number): table?
    return RemoteManager:invokeServer("GetShopData", shopId)
end

function ShopController:getMarketListings(): table?
    return RemoteManager:invokeServer("GetShopData", nil)
end

return ShopController
