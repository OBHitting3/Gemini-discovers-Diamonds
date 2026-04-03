--[[
    CoinService.server.lua
    Authoritative coin ledger for Mullet Game.

    Responsibilities:
      - Award, deduct, and query coin balances
      - Enforce anti-exploit caps (max grant per event, rate limit)
      - Apply active coin boost multipliers
      - Fire EconomyUpdate event so clients stay in sync
      - Integrate with MulletService for per-kill and per-wave rewards
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MulletConfig = require(ReplicatedStorage:WaitForChild("MulletConfig"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)

local function getOrCreateEvent(name: string): RemoteEvent
    local existing = Remotes:FindFirstChild(name)
    if existing and existing:IsA("RemoteEvent") then return existing end
    local ev = Instance.new("RemoteEvent")
    ev.Name   = name
    ev.Parent = Remotes
    return ev
end

local evEconomyUpdate = getOrCreateEvent("UpdateCoins")
local evNotify        = getOrCreateEvent("NotifyPlayer")
local evCollectCoin   = getOrCreateEvent("CollectCoin")  -- client fires when walking over coin pickup

---------------------------------------------------------------------------
-- STATE
-- balances[userId]      = number (current coins)
-- coinBoosts[userId]    = number (multiplier, e.g. 2.0)
-- txLog[userId]         = { {time, amount}, ... }  (rate-limit rolling window)
---------------------------------------------------------------------------
local balances:  { [number]: number } = {}
local coinBoosts: { [number]: number } = {}
local txLog:     { [number]: { table } } = {}

---------------------------------------------------------------------------
-- INTERNAL HELPERS
---------------------------------------------------------------------------

local function syncClient(player: Player)
    evEconomyUpdate:FireClient(player, balances[player.UserId] or 0)
end

local function isRateLimited(userId: number): boolean
    local now  = os.clock()
    local log  = txLog[userId]
    if not log then return false end

    -- Purge entries older than 60 seconds
    local fresh = {}
    for _, entry in ipairs(log) do
        if now - entry.time < 60 then
            table.insert(fresh, entry)
        end
    end
    txLog[userId] = fresh

    return #fresh >= MulletConfig.Economy.MaxTransactionsPerMinute
end

local function recordTx(userId: number, amount: number)
    txLog[userId] = txLog[userId] or {}
    table.insert(txLog[userId], { time = os.clock(), amount = amount })
end

---------------------------------------------------------------------------
-- PUBLIC API
---------------------------------------------------------------------------

local CoinService = {}

--- Return the current balance for a player.
function CoinService:getBalance(player: Player): number
    return balances[player.UserId] or 0
end

--- Set a coin boost multiplier for the player (e.g. from a purchased boost).
function CoinService:setBoost(player: Player, mult: number)
    coinBoosts[player.UserId] = math.max(1.0, mult)
end

--- Clear any active boost.
function CoinService:clearBoost(player: Player)
    coinBoosts[player.UserId] = 1.0
end

--- Award coins to a player (server-authoritative).
--- reason: string label for logging (e.g. "kill", "wave", "boss")
--- Returns the actual amount awarded after multipliers.
function CoinService:awardCoins(player: Player, amount: number, reason: string?): number
    local userId = player.UserId
    if not balances[userId] then return 0 end

    -- Anti-exploit: cap per-grant
    local cappedAmount = math.min(
        math.abs(math.floor(amount)),
        MulletConfig.Economy.MaxCoinGrantPerEvent
    )

    -- Anti-exploit: rate limit
    if isRateLimited(userId) then
        warn("[CoinService] Rate limit hit for " .. player.Name)
        return 0
    end

    -- Apply boost
    local boost  = coinBoosts[userId] or 1.0
    local final  = math.floor(cappedAmount * boost)

    balances[userId] = math.min(
        (balances[userId] or 0) + final,
        MulletConfig.Economy.MaxCoinsPerSession
    )

    recordTx(userId, final)
    syncClient(player)

    if reason then
        print(("[CoinService] +%d coins (%s) → %s (total: %d)"):format(
            final, reason, player.Name, balances[userId]))
    end

    return final
end

--- Deduct coins. Returns true on success, false if insufficient funds.
function CoinService:deductCoins(player: Player, amount: number, reason: string?): boolean
    local userId = player.UserId
    if not balances[userId] then return false end

    amount = math.abs(math.floor(amount))
    if balances[userId] < amount then
        evNotify:FireClient(player, "Not enough coins! Need " .. amount)
        return false
    end

    balances[userId] -= amount
    recordTx(userId, -amount)
    syncClient(player)

    if reason then
        print(("[CoinService] -%d coins (%s) → %s (total: %d)"):format(
            amount, reason, player.Name, balances[userId]))
    end

    return true
end

--- Check if a player can afford an amount.
function CoinService:canAfford(player: Player, amount: number): boolean
    return (balances[player.UserId] or 0) >= amount
end

---------------------------------------------------------------------------
-- REMOTE HANDLER — client walks over a coin pickup
---------------------------------------------------------------------------
evCollectCoin.OnServerEvent:Connect(function(player: Player, pickupId: string)
    -- Validate: the pickup must still exist in the workspace
    local pickups = workspace:FindFirstChild("CoinPickups")
    if not pickups then return end

    local pickup = pickups:FindFirstChild(pickupId)
    if not pickup then return end  -- already collected by someone else

    local value = pickup:GetAttribute("Value") or 5
    pickup:Destroy()

    CoinService:awardCoins(player, value, "pickup")
end)

---------------------------------------------------------------------------
-- PLAYER LIFECYCLE
---------------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player: Player)
    balances[player.UserId]  = MulletConfig.Economy.StartingCoins
    coinBoosts[player.UserId] = 1.0
    txLog[player.UserId]     = {}

    -- Send initial balance once character is ready
    player.CharacterAdded:Connect(function()
        task.wait(1)
        syncClient(player)
    end)
end)

Players.PlayerRemoving:Connect(function(player: Player)
    balances[player.UserId]  = nil
    coinBoosts[player.UserId] = nil
    txLog[player.UserId]     = nil
end)

print("[CoinService] Initialized")

return CoinService
