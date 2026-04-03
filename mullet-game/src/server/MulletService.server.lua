--[[
    MulletService.server.lua
    Tracks each player's hair collected and mullet level.
    As players collect hair, their mullet grows bigger and changes color.
    Saves progress via DataStore.
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService  = game:GetService("DataStoreService")

local MulletConfig = require(ReplicatedStorage:WaitForChild("MulletConfig"))

-- Remotes folder
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
    Remotes = Instance.new("Folder")
    Remotes.Name = "Remotes"
    Remotes.Parent = ReplicatedStorage
end

local function getOrCreateEvent(name)
    local e = Remotes:FindFirstChild(name)
    if e and e:IsA("RemoteEvent") then return e end
    local ev = Instance.new("RemoteEvent")
    ev.Name = name
    ev.Parent = Remotes
    return ev
end

local function getOrCreateFunction(name)
    local e = Remotes:FindFirstChild(name)
    if e and e:IsA("RemoteFunction") then return e end
    local fn = Instance.new("RemoteFunction")
    fn.Name = name
    fn.Parent = Remotes
    return fn
end

local evUpdateMullet = getOrCreateEvent("UpdateMulletLevel")
local evNotify       = getOrCreateEvent("NotifyPlayer")
local evCoins        = getOrCreateEvent("UpdateCoins")
local fnGetData      = getOrCreateFunction("GetPlayerData")

---------------------------------------------------------------------------
-- DataStore
---------------------------------------------------------------------------
local Store = DataStoreService:GetDataStore("MulletGame_v2")

---------------------------------------------------------------------------
-- Player state
---------------------------------------------------------------------------
local playerData = {}

local DEFAULT = {
    hairCollected  = 0,       -- this session
    hairAllTime    = 0,       -- lifetime total
    mulletLevel    = 0,
    coins          = 0,
    roundsPlayed   = 0,
}

local function deepCopy(t)
    local c = {}
    for k, v in pairs(t) do
        c[k] = type(v) == "table" and deepCopy(v) or v
    end
    return c
end

local function getMulletLevel(hair)
    local levels = MulletConfig.Mullet.SizeLevels
    local level  = 0
    for i, threshold in ipairs(levels) do
        if hair >= threshold then
            level = i - 1
        end
    end
    return math.min(level, MulletConfig.Mullet.MaxLevel)
end

---------------------------------------------------------------------------
-- Apply speed bonus to character
---------------------------------------------------------------------------
local function applySpeed(player, data)
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local bonus = MulletConfig.Mullet.SpeedBonus[data.mulletLevel] or 0
    hum.WalkSpeed = MulletConfig.Mullet.BaseWalkSpeed + bonus
end

---------------------------------------------------------------------------
-- Load / Save
---------------------------------------------------------------------------
local function load(player)
    local key = "player_" .. player.UserId
    local ok, result = pcall(function() return Store:GetAsync(key) end)
    local data
    if ok and type(result) == "table" then
        data = result
        for k, v in pairs(DEFAULT) do
            if data[k] == nil then
                data[k] = type(v) == "table" and deepCopy(v) or v
            end
        end
    else
        data = deepCopy(DEFAULT)
    end
    -- Reset per-session hair each login
    data.hairCollected = 0
    playerData[player.UserId] = data
    return data
end

local function save(player)
    local data = playerData[player.UserId]
    if not data then return end
    local key = "player_" .. player.UserId
    pcall(function() Store:SetAsync(key, data) end)
end

---------------------------------------------------------------------------
-- PUBLIC API
---------------------------------------------------------------------------
local MulletService = {}

function MulletService:getData(player)
    return playerData[player.UserId]
end

--- Called when a player collects hair (from HairService)
function MulletService:addHair(player, amount)
    local data = playerData[player.UserId]
    if not data then return end

    data.hairCollected = data.hairCollected + amount
    data.hairAllTime   = data.hairAllTime + amount

    local newLevel = getMulletLevel(data.hairCollected)
    local leveledUp = newLevel > data.mulletLevel

    if leveledUp then
        data.mulletLevel = newLevel
        applySpeed(player, data)
        local color = MulletConfig.Mullet.Colors[newLevel]
        local size  = MulletConfig.Mullet.Sizes[newLevel]
        evUpdateMullet:FireClient(player, {
            level  = newLevel,
            color  = color,
            size   = size,
            hair   = data.hairCollected,
        })
        evNotify:FireClient(player, "Mullet Level " .. newLevel .. "! Looking fresh!")
        print("[MulletService] " .. player.Name .. " mullet level " .. newLevel)
    else
        -- Still send hair count update even without level up
        evUpdateMullet:FireClient(player, {
            level = data.mulletLevel,
            hair  = data.hairCollected,
        })
    end
end

--- Award coins to a player
function MulletService:addCoins(player, amount, reason)
    local data = playerData[player.UserId]
    if not data then return end
    data.coins = math.min(data.coins + amount, MulletConfig.Economy.MaxCoins)
    evCoins:FireClient(player, data.coins)
    if reason then
        print("[MulletService] +" .. amount .. " coins (" .. reason .. ") → " .. player.Name)
    end
end

--- Reset session hair (called at start of each round)
function MulletService:resetRound(player)
    local data = playerData[player.UserId]
    if not data then return end
    data.hairCollected = 0
    data.mulletLevel   = 0
    data.roundsPlayed  = data.roundsPlayed + 1
    applySpeed(player, data)
    evUpdateMullet:FireClient(player, {
        level = 0,
        color = MulletConfig.Mullet.Colors[0],
        size  = MulletConfig.Mullet.Sizes[0],
        hair  = 0,
    })
end

---------------------------------------------------------------------------
-- Remote
---------------------------------------------------------------------------
fnGetData.OnServerInvoke = function(player)
    local data = playerData[player.UserId]
    if not data then return nil end
    return deepCopy(data)
end

---------------------------------------------------------------------------
-- Lifecycle
---------------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
    local data = load(player)

    -- Setup leaderstat for hair
    local ls = Instance.new("Folder")
    ls.Name = "leaderstats"
    ls.Parent = player

    local hairStat = Instance.new("IntValue")
    hairStat.Name  = "Hair"
    hairStat.Value = data.hairAllTime
    hairStat.Parent = ls

    local coinStat = Instance.new("IntValue")
    coinStat.Name  = "Coins"
    coinStat.Value = data.coins
    coinStat.Parent = ls

    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        applySpeed(player, data)
        evUpdateMullet:FireClient(player, {
            level = data.mulletLevel,
            color = MulletConfig.Mullet.Colors[data.mulletLevel],
            size  = MulletConfig.Mullet.Sizes[data.mulletLevel],
            hair  = data.hairCollected,
        })
        evCoins:FireClient(player, data.coins)
    end)

    print("[MulletService] " .. player.Name .. " joined. Hair all-time: " .. data.hairAllTime)
end)

Players.PlayerRemoving:Connect(function(player)
    save(player)
    playerData[player.UserId] = nil
end)

-- Auto-save every 2 minutes
task.spawn(function()
    while true do
        task.wait(120)
        for _, p in ipairs(Players:GetPlayers()) do
            save(p)
        end
    end
end)

print("[MulletService] Ready — The Mullet Game by TheMullet_King")

return MulletService
