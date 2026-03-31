--[[
    RobuxShopService.server.lua
    Handles real-money (Robux) purchases via Roblox developer products
    and game passes.

    Responsibilities:
      - Process MarketplaceService.ProcessReceipt for developer products
      - Grant purchased rewards (coins, eggs, cosmetics, game passes)
      - Handle game pass ownership checks and associated perks
      - Prevent duplicate grants via receipt ID logging in DataStore
      - Fire client notifications on successful purchase
]]

local Players              = game:GetService("Players")
local MarketplaceService   = game:GetService("MarketplaceService")
local ReplicatedStorage    = game:GetService("ReplicatedStorage")
local DataStoreService     = game:GetService("DataStoreService")

local MulletConfig = require(ReplicatedStorage:WaitForChild("MulletConfig"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)

local function getOrCreateEvent(name: string): RemoteEvent
    local existing = Remotes:FindFirstChild(name)
    if existing and existing:IsA("RemoteEvent") then return existing end
    local ev = Instance.new("RemoteEvent")
    ev.Name = name ; ev.Parent = Remotes
    return ev
end

local evNotify       = getOrCreateEvent("NotifyPlayer")
local evRobuxPurchase = getOrCreateEvent("PurchaseRobuxItem")  -- client fires to open Roblox prompt

---------------------------------------------------------------------------
-- DEVELOPER PRODUCT CATALOG
-- productId → { reward function or config }
-- Set actual IDs in MulletConfig.Economy.DevProducts before publishing.
---------------------------------------------------------------------------

-- NOTE: Replace 0-value product IDs with real Roblox developer product IDs
-- after the game is published. The catalog is keyed by product ID.
local PRODUCT_CATALOG: { [number]: table } = {
    -- Coin packs
    -- [REAL_ID] = { type = "coins", amount = 500 }
}

-- Egg purchases (by product ID)
-- [REAL_ID] = { type = "egg", eggId = "cosmic" }

-- Cosmetic unlock
-- [REAL_ID] = { type = "cosmetic", itemId = "cosmetic_trail_fire" }

---------------------------------------------------------------------------
-- GAME PASS PERKS
-- passId → perk application function, called on PlayerAdded / ownership check
---------------------------------------------------------------------------
-- NOTE: Replace 0-value pass IDs with real Roblox game pass IDs after publish.
local PASS_PERKS: { [number]: (player: Player) -> () } = {
    -- [REAL_VIP_PASS_ID] = function(player)
    --     local data = mulletService:getData(player)
    --     if data then data.isVIP = true end
    -- end,
}

---------------------------------------------------------------------------
-- RECEIPT DATA STORE (prevents duplicate grants)
---------------------------------------------------------------------------
local ReceiptStore = DataStoreService:GetDataStore("MulletGame_Receipts_v1")

local function hasProcessedReceipt(receiptId: string): boolean
    local ok, result = pcall(function()
        return ReceiptStore:GetAsync("receipt_" .. receiptId)
    end)
    return ok and result == true
end

local function markReceiptProcessed(receiptId: string)
    local ok, err = pcall(function()
        ReceiptStore:SetAsync("receipt_" .. receiptId, true)
    end)
    if not ok then
        warn("[RobuxShopService] Failed to mark receipt " .. receiptId .. ": " .. tostring(err))
    end
end

---------------------------------------------------------------------------
-- INJECTED SERVICE REFERENCES
---------------------------------------------------------------------------
local _coinService   = nil
local _eggService    = nil
local _mulletService = nil

local RobuxShopService = {}

function RobuxShopService:init(coinService, eggService, mulletService)
    _coinService   = coinService
    _eggService    = eggService
    _mulletService = mulletService
    print("[RobuxShopService] Dependencies injected")
end

---------------------------------------------------------------------------
-- GRANT HELPERS
---------------------------------------------------------------------------

local function grantReward(player: Player, reward: table): boolean
    if reward.type == "coins" then
        if not _coinService then return false end
        _coinService:awardCoins(player, reward.amount, "robux_purchase")
        evNotify:FireClient(player, "Received " .. reward.amount .. " coins!")
        return true

    elseif reward.type == "egg" then
        if not _eggService then return false end
        _eggService:giveEgg(player, reward.eggId, reward.count or 1)
        return true

    elseif reward.type == "cosmetic" then
        local data = _mulletService and _mulletService:getData(player)
        if not data then return false end
        table.insert(data.ownedCosmetics, reward.itemId)
        evNotify:FireClient(player, "Cosmetic unlocked!")
        return true

    elseif reward.type == "gamepass_perk" then
        -- Applied separately via checkGamePasses
        return true
    end

    warn("[RobuxShopService] Unknown reward type: " .. tostring(reward.type))
    return false
end

---------------------------------------------------------------------------
-- PROCESS RECEIPT (Roblox callback)
---------------------------------------------------------------------------

MarketplaceService.ProcessReceipt = function(receiptInfo: table): Enum.ProductPurchaseDecision
    local receiptId  = tostring(receiptInfo.PurchaseId)
    local productId  = receiptInfo.ProductId
    local userId     = receiptInfo.PlayerId

    -- Duplicate guard
    if hasProcessedReceipt(receiptId) then
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end

    local player = Players:GetPlayerByUserId(userId)
    if not player then
        -- Player left during purchase — retry next session is safe because
        -- we haven't marked the receipt yet.
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    local reward = PRODUCT_CATALOG[productId]
    if not reward then
        warn("[RobuxShopService] No reward configured for product " .. tostring(productId))
        -- Still grant to avoid Roblox penalising us; log for manual resolution
        markReceiptProcessed(receiptId)
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end

    local success = grantReward(player, reward)
    if success then
        markReceiptProcessed(receiptId)
        print("[RobuxShopService] Processed receipt " .. receiptId ..
              " for " .. player.Name .. " (product " .. productId .. ")")
        return Enum.ProductPurchaseDecision.PurchaseGranted
    else
        return Enum.ProductPurchaseDecision.NotProcessedYet
    end
end

---------------------------------------------------------------------------
-- GAME PASS CHECKS
---------------------------------------------------------------------------

--- Apply all owned game pass perks for a player.
function RobuxShopService:checkGamePasses(player: Player)
    for passId, applyPerk in pairs(PASS_PERKS) do
        local ok, owns = pcall(function()
            return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
        end)
        if ok and owns then
            applyPerk(player)
            print("[RobuxShopService] Applied pass perk for passId " .. passId ..
                  " to " .. player.Name)
        end
    end
end

---------------------------------------------------------------------------
-- REMOTE HANDLER — client requests a Roblox purchase prompt
---------------------------------------------------------------------------

evRobuxPurchase.OnServerEvent:Connect(function(player: Player, productId: number)
    if type(productId) ~= "number" then return end
    -- Fire the Roblox purchase dialog on the client via the server
    MarketplaceService:PromptProductPurchase(player, productId)
end)

---------------------------------------------------------------------------
-- PLAYER LIFECYCLE
---------------------------------------------------------------------------

Players.PlayerAdded:Connect(function(player: Player)
    task.spawn(function()
        -- Wait for MulletService data to load
        task.wait(2)
        RobuxShopService:checkGamePasses(player)
    end)
end)

print("[RobuxShopService] Initialized")

return RobuxShopService
