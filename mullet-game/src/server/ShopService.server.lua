--[[
    ShopService.server.lua
    In-game coin shop for weapons, abilities, cosmetics, boosts, and eggs.

    Responsibilities:
      - Validate and process PurchaseShopItem requests from clients
      - Check affordability via CoinService
      - Grant items to player's data via MulletService
      - Apply time-limited boosts via CoinService / EggService
      - Expose GetShopInventory remote function for the client UI
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopConfig   = require(ReplicatedStorage:WaitForChild("ShopConfig"))
local MulletConfig = require(ReplicatedStorage:WaitForChild("MulletConfig"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)

local function getOrCreateEvent(name: string): RemoteEvent
    local existing = Remotes:FindFirstChild(name)
    if existing and existing:IsA("RemoteEvent") then return existing end
    local ev = Instance.new("RemoteEvent")
    ev.Name = name ; ev.Parent = Remotes
    return ev
end

local function getOrCreateFunction(name: string): RemoteFunction
    local existing = Remotes:FindFirstChild(name)
    if existing and existing:IsA("RemoteFunction") then return existing end
    local fn = Instance.new("RemoteFunction")
    fn.Name = name ; fn.Parent = Remotes
    return fn
end

local evNotify       = getOrCreateEvent("NotifyPlayer")
local evPurchaseRes  = getOrCreateEvent("ShopPurchaseResult")
local evPurchaseReq  = getOrCreateEvent("PurchaseShopItem")
local fnGetInventory = getOrCreateFunction("GetShopInventory")

---------------------------------------------------------------------------
-- SERVICE REFERENCES (injected after all services start)
---------------------------------------------------------------------------
local _coinService   = nil
local _mulletService = nil
local _eggService    = nil

local ShopService = {}

--- Inject dependencies from the main server init script.
function ShopService:init(coinService, mulletService, eggService)
    _coinService   = coinService
    _mulletService = mulletService
    _eggService    = eggService
    print("[ShopService] Dependencies injected")
end

---------------------------------------------------------------------------
-- INTERNAL: apply purchased item to player
---------------------------------------------------------------------------

local function grantWeapon(player: Player, item: table): boolean
    local data = _mulletService and _mulletService:getData(player)
    if not data then return false end

    -- Prevent duplicate purchase
    for _, id in ipairs(data.ownedWeapons) do
        if id == item.id then
            evNotify:FireClient(player, "You already own " .. item.name .. "!")
            return false
        end
    end

    table.insert(data.ownedWeapons, item.id)
    return true
end

local function grantAbility(player: Player, item: table): boolean
    local data = _mulletService and _mulletService:getData(player)
    if not data then return false end

    for _, id in ipairs(data.ownedAbilities) do
        if id == item.id then
            evNotify:FireClient(player, "You already own " .. item.name .. "!")
            return false
        end
    end

    table.insert(data.ownedAbilities, item.id)
    return true
end

local function grantCosmetic(player: Player, item: table): boolean
    local data = _mulletService and _mulletService:getData(player)
    if not data then return false end

    for _, id in ipairs(data.ownedCosmetics) do
        if id == item.id then
            evNotify:FireClient(player, "You already own " .. item.name .. "!")
            return false
        end
    end

    table.insert(data.ownedCosmetics, item.id)
    return true
end

local function grantBoost(player: Player, item: table): boolean
    if not _coinService then return false end

    -- Apply effect based on boost type
    if item.coinMult and _coinService then
        _coinService:setBoost(player, item.coinMult)
        -- Auto-expire
        task.delay(item.duration, function()
            if Players:GetPlayerByUserId(player.UserId) then
                _coinService:clearBoost(player)
                evNotify:FireClient(player, item.name .. " has expired.")
            end
        end)

    elseif item.luckMult and _eggService then
        _eggService:setLuckBoost(player, item.luckMult)
        task.delay(item.duration, function()
            if Players:GetPlayerByUserId(player.UserId) then
                _eggService:setLuckBoost(player, 1.0)
                evNotify:FireClient(player, item.name .. " has expired.")
            end
        end)

    elseif item.speedBonus then
        local char = player.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed += item.speedBonus
                task.delay(item.duration, function()
                    if Players:GetPlayerByUserId(player.UserId) then
                        local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                        if h then
                            h.WalkSpeed = math.max(16, h.WalkSpeed - item.speedBonus)
                        end
                        evNotify:FireClient(player, item.name .. " has expired.")
                    end
                end)
            end
        end
    end

    return true
end

local function grantEgg(player: Player, item: table): boolean
    if not _eggService then return false end
    _eggService:giveEgg(player, item.eggId, 1)
    return true
end

---------------------------------------------------------------------------
-- PURCHASE HANDLER
---------------------------------------------------------------------------

local CATEGORY_HANDLERS = {
    Weapons    = grantWeapon,
    Abilities  = grantAbility,
    Cosmetics  = grantCosmetic,
    Boosts     = grantBoost,
    Eggs       = grantEgg,
}

local function processPurchase(player: Player, itemId: string): boolean
    if not _coinService then
        warn("[ShopService] CoinService not injected")
        return false
    end

    local item = ShopConfig.getItem(itemId)
    if not item then
        evNotify:FireClient(player, "Unknown item!")
        return false
    end

    local price = item.price or 0
    if price > 0 then
        if not _coinService:deductCoins(player, price, "shop:" .. itemId) then
            return false
        end
    end

    -- Determine category
    local granted = false
    for category, handler in pairs(CATEGORY_HANDLERS) do
        local list = ShopConfig[category]
        if list then
            for _, entry in ipairs(list) do
                if entry.id == itemId then
                    granted = handler(player, entry)
                    break
                end
            end
        end
        if granted then break end
    end

    if not granted and price > 0 then
        -- Refund if grant failed
        _coinService:awardCoins(player, price, "refund:" .. itemId)
        return false
    end

    evPurchaseRes:FireClient(player, { success = true, itemId = itemId })
    evNotify:FireClient(player, "Purchased: " .. (item.name or itemId))
    print("[ShopService] " .. player.Name .. " purchased " .. itemId)
    return true
end

---------------------------------------------------------------------------
-- REMOTE HANDLERS
---------------------------------------------------------------------------

evPurchaseReq.OnServerEvent:Connect(function(player: Player, itemId: string)
    if type(itemId) ~= "string" then return end
    processPurchase(player, itemId)
end)

fnGetInventory.OnServerInvoke = function(_player: Player): table
    -- Return all shop items grouped by category for the client UI
    local result = {}
    for _, category in ipairs(ShopConfig.Categories) do
        result[category] = ShopConfig[category] or {}
    end
    return result
end

print("[ShopService] Initialized")

return ShopService
