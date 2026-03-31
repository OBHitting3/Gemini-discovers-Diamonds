--[[
    MulletService.server.lua
    Authoritative server for mullet progression.

    Responsibilities:
      - Track each player's mullet level and kill count
      - Apply mullet-level stat bonuses (speed, damage multiplier)
      - Broadcast level-up events to the owning client
      - Persist mullet data via DataStoreService
      - Expose remote function GetPlayerData for clients
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService  = game:GetService("DataStoreService")
local RunService        = game:GetService("RunService")

local MulletConfig = require(ReplicatedStorage:WaitForChild("MulletConfig"))

-- Remote setup (created once; clients wait on these)
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
    Remotes = Instance.new("Folder")
    Remotes.Name = "Remotes"
    Remotes.Parent = ReplicatedStorage
end

local function getOrCreateEvent(name: string): RemoteEvent
    local existing = Remotes:FindFirstChild(name)
    if existing and existing:IsA("RemoteEvent") then return existing end
    local ev = Instance.new("RemoteEvent")
    ev.Name = name
    ev.Parent = Remotes
    return ev
end

local function getOrCreateFunction(name: string): RemoteFunction
    local existing = Remotes:FindFirstChild(name)
    if existing and existing:IsA("RemoteFunction") then return existing end
    local fn = Instance.new("RemoteFunction")
    fn.Name = name
    fn.Parent = Remotes
    return fn
end

-- Events used by this service
local evUpdateMullet = getOrCreateEvent("UpdateMulletLevel")
local evNotify       = getOrCreateEvent("NotifyPlayer")
local fnGetData      = getOrCreateFunction("GetPlayerData")

---------------------------------------------------------------------------
-- DataStore
---------------------------------------------------------------------------
local MulletStore = DataStoreService:GetDataStore("MulletGame_v1")

---------------------------------------------------------------------------
-- In-memory player state
---------------------------------------------------------------------------
-- playerData[userId] = { kills, mulletLevel, coinMultiplier, owned... }
local playerData: { [number]: table } = {}

local DEFAULT_DATA = {
    kills            = 0,
    mulletLevel      = 0,
    coinsTotal       = 0,
    ownedWeapons     = { "weapon_scissors" },
    ownedAbilities   = {},
    ownedCosmetics   = {},
    activeWeapon     = "weapon_scissors",
    activeAbility    = nil,
    activePets       = {},
    unlockedZones    = { "zone_barbershop" },
    currentZone      = "zone_barbershop",
    equippedTrail    = nil,
    equippedTag      = nil,
}

---------------------------------------------------------------------------
-- INTERNAL HELPERS
---------------------------------------------------------------------------

local function deepCopy(t: table): table
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = type(v) == "table" and deepCopy(v) or v
    end
    return copy
end

local function getMulletLevel(kills: number): number
    local milestones = MulletConfig.Mullet.GrowthMilestones
    local level = 0
    for i, threshold in ipairs(milestones) do
        if kills >= threshold then
            level = i
        else
            break
        end
    end
    return math.min(level, MulletConfig.Mullet.MaxLevel)
end

local function applyStatBonuses(player: Player, data: table)
    local char = player.Character
    if not char then return end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local speedBonus = MulletConfig.Mullet.SpeedBonus[data.mulletLevel] or 0
    humanoid.WalkSpeed = MulletConfig.Mullet.BaseWalkSpeed + speedBonus
end

---------------------------------------------------------------------------
-- LOAD / SAVE
---------------------------------------------------------------------------

local function loadData(player: Player): table
    local userId = player.UserId
    local key    = "player_" .. userId
    local ok, result = pcall(function()
        return MulletStore:GetAsync(key)
    end)

    local data
    if ok and type(result) == "table" then
        data = result
        -- Back-fill any missing keys from DEFAULT_DATA
        for k, v in pairs(DEFAULT_DATA) do
            if data[k] == nil then
                data[k] = type(v) == "table" and deepCopy(v) or v
            end
        end
    else
        data = deepCopy(DEFAULT_DATA)
        if not ok then
            warn("[MulletService] DataStore load failed for " .. player.Name .. ": " .. tostring(result))
        end
    end

    playerData[userId] = data
    return data
end

local function saveData(player: Player)
    local userId = player.UserId
    local data   = playerData[userId]
    if not data then return end

    local key = "player_" .. userId
    local ok, err = pcall(function()
        MulletStore:SetAsync(key, data)
    end)
    if not ok then
        warn("[MulletService] DataStore save failed for " .. player.Name .. ": " .. tostring(err))
    end
end

---------------------------------------------------------------------------
-- PUBLIC API
---------------------------------------------------------------------------

local MulletService = {}

--- Return the data table for the given player (server-only).
function MulletService:getData(player: Player): table?
    return playerData[player.UserId]
end

--- Register a kill for the player and update mullet level if crossed a milestone.
function MulletService:registerKill(player: Player, coinService)
    local data = playerData[player.UserId]
    if not data then return end

    data.kills += 1

    local newLevel = getMulletLevel(data.kills)
    if newLevel > data.mulletLevel then
        data.mulletLevel = newLevel
        local styleName = MulletConfig.Mullet.StyleUnlocks[newLevel] or "???"
        applyStatBonuses(player, data)

        evUpdateMullet:FireClient(player, {
            level    = newLevel,
            styleName = styleName,
            kills    = data.kills,
        })
        evNotify:FireClient(player, "Mullet evolved! Now: " .. styleName)
        print("[MulletService] " .. player.Name .. " reached mullet level " .. newLevel)
    end

    -- Coin reward per kill (routed through CoinService if available)
    if coinService then
        local baseCoin = MulletConfig.Economy.CoinPerKill
        local mult = MulletConfig.Economy.CoinMultipliers[data.mulletLevel] or 1.0
        coinService:awardCoins(player, math.floor(baseCoin * mult), "kill")
    end
end

--- Get the damage multiplier for a player based on mullet level.
function MulletService:getDamageMultiplier(player: Player): number
    local data = playerData[player.UserId]
    if not data then return 1.0 end
    return MulletConfig.Mullet.DamageMultiplier[data.mulletLevel] or 1.0
end

---------------------------------------------------------------------------
-- REMOTE HANDLERS
---------------------------------------------------------------------------

fnGetData.OnServerInvoke = function(player: Player): table?
    local data = playerData[player.UserId]
    if not data then return nil end
    -- Return a safe copy (no mutation by client)
    return deepCopy(data)
end

---------------------------------------------------------------------------
-- PLAYER LIFECYCLE
---------------------------------------------------------------------------

Players.PlayerAdded:Connect(function(player: Player)
    local data = loadData(player)

    -- Apply bonuses once character loads
    player.CharacterAdded:Connect(function()
        task.wait(0.5)  -- wait for humanoid to initialise
        applyStatBonuses(player, data)
        evUpdateMullet:FireClient(player, {
            level     = data.mulletLevel,
            styleName = MulletConfig.Mullet.StyleUnlocks[data.mulletLevel] or "Baby Mullet",
            kills     = data.kills,
        })
    end)

    print("[MulletService] Loaded data for " .. player.Name ..
          " (level " .. data.mulletLevel .. ", kills " .. data.kills .. ")")
end)

Players.PlayerRemoving:Connect(function(player: Player)
    saveData(player)
    playerData[player.UserId] = nil
    print("[MulletService] Saved and cleaned up data for " .. player.Name)
end)

-- Periodic auto-save
task.spawn(function()
    while true do
        task.wait(MulletConfig.Timing.SessionSaveInterval)
        for _, player in ipairs(Players:GetPlayers()) do
            saveData(player)
        end
    end
end)

print("[MulletService] Initialized")

return MulletService
