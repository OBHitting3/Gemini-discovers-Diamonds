--[[
    ZoneService.server.lua
    Manages world zones: unlock validation, player zone transitions,
    wave management, enemy spawning coordination, and boss orchestration.

    Responsibilities:
      - Track which zone each player is currently in
      - Validate zone unlock requirements (coin gates)
      - Manage per-zone wave state (wave number, enemy count, boss spawns)
      - Fire wave lifecycle events (WaveStarted, WaveCompleted, BossSpawned, etc.)
      - Coordinate with CoinService for wave rewards
      - Coordinate with MulletService for kill registration
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ZoneConfig   = require(ReplicatedStorage:WaitForChild("ZoneConfig"))
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

local evWaveStarted    = getOrCreateEvent("WaveStarted")
local evWaveCompleted  = getOrCreateEvent("WaveCompleted")
local evBossSpawned    = getOrCreateEvent("BossSpawned")
local evBossDefeated   = getOrCreateEvent("BossDefeated")
local evZoneUnlocked   = getOrCreateEvent("ZoneUnlocked")
local evNotify         = getOrCreateEvent("NotifyPlayer")
local evEnterZone      = getOrCreateEvent("EnterZone")  -- client fires
local fnGetZoneData    = getOrCreateFunction("GetZoneData")

---------------------------------------------------------------------------
-- INJECTED SERVICES
---------------------------------------------------------------------------
local _coinService   = nil
local _mulletService = nil
local _eggService    = nil

---------------------------------------------------------------------------
-- STATE
-- playerZones[userId] = zoneId
-- zoneWaves[zoneId]   = { waveNumber, aliveEnemies, inProgress, bossAlive }
-- playerGroups[zoneId] = { userId, ... }
---------------------------------------------------------------------------
local playerZones:  { [number]: string } = {}
local zoneWaves:    { [string]: table  } = {}
local playerGroups: { [string]: { number } } = {}

local ZoneService = {}

---------------------------------------------------------------------------
-- INIT
---------------------------------------------------------------------------

function ZoneService:init(coinService, mulletService, eggService)
    _coinService   = coinService
    _mulletService = mulletService
    _eggService    = eggService

    -- Initialise wave state for each zone
    for _, zone in ipairs(ZoneConfig.Zones) do
        zoneWaves[zone.id]    = {
            waveNumber   = 0,
            aliveEnemies = 0,
            inProgress   = false,
            bossAlive    = false,
        }
        playerGroups[zone.id] = {}
    end

    print("[ZoneService] Initialized " .. #ZoneConfig.Zones .. " zones")
end

---------------------------------------------------------------------------
-- ZONE HELPERS
---------------------------------------------------------------------------

local function getPlayersInZone(zoneId: string): { Player }
    local result = {}
    local group  = playerGroups[zoneId]
    if not group then return result end

    for _, userId in ipairs(group) do
        local p = Players:GetPlayerByUserId(userId)
        if p then table.insert(result, p) end
    end
    return result
end

local function removeFromZone(userId: number, zoneId: string)
    local group = playerGroups[zoneId]
    if not group then return end
    for i, id in ipairs(group) do
        if id == userId then
            table.remove(group, i)
            return
        end
    end
end

local function fireZonePlayers(zoneId: string, event: RemoteEvent, ...)
    for _, player in ipairs(getPlayersInZone(zoneId)) do
        event:FireClient(player, ...)
    end
end

---------------------------------------------------------------------------
-- WAVE MANAGEMENT
---------------------------------------------------------------------------

local function getEnemyCountForWave(waveNum: number): number
    return math.floor(
        MulletConfig.Waves.EnemiesPerWave *
        (MulletConfig.Waves.EnemyScaling ^ (waveNum - 1))
    )
end

local function isBossWave(waveNum: number): boolean
    return (waveNum % MulletConfig.Waves.BossWaveInterval) == 0
end

--- Called when all enemies (or the boss) in a wave are defeated.
function ZoneService:onWaveEnemyDefeated(zoneId: string)
    local wState = zoneWaves[zoneId]
    if not wState then return end

    wState.aliveEnemies = math.max(0, wState.aliveEnemies - 1)
    if wState.aliveEnemies > 0 then return end

    -- Wave cleared
    wState.inProgress = false
    wState.bossAlive  = false
    local waveNum     = wState.waveNumber

    -- Award coins to players in zone
    if _coinService then
        for _, player in ipairs(getPlayersInZone(zoneId)) do
            _coinService:awardCoins(player, MulletConfig.Economy.CoinPerWave, "wave:" .. waveNum)
        end
    end

    fireZonePlayers(zoneId, evWaveCompleted, {
        zoneId    = zoneId,
        waveNumber = waveNum,
    })

    print("[ZoneService] Zone " .. zoneId .. " wave " .. waveNum .. " cleared")

    if waveNum >= MulletConfig.Waves.MaxWaves then
        fireZonePlayers(zoneId, evNotify, "You've conquered all waves in this zone!")
        return
    end

    -- Schedule next wave after break
    task.delay(MulletConfig.Waves.WaveBreakDuration, function()
        ZoneService:startNextWave(zoneId)
    end)
end

--- Start the next wave in a zone.
function ZoneService:startNextWave(zoneId: string)
    local wState = zoneWaves[zoneId]
    if not wState then return end
    if wState.inProgress then return end

    wState.waveNumber  += 1
    wState.inProgress   = true
    local waveNum       = wState.waveNumber
    local isBoss        = isBossWave(waveNum)
    local enemyCount    = isBoss and 1 or getEnemyCountForWave(waveNum)
    wState.aliveEnemies = enemyCount

    local zone = ZoneConfig.getZone(zoneId)
    if not zone then return end

    fireZonePlayers(zoneId, evWaveStarted, {
        zoneId     = zoneId,
        waveNumber = waveNum,
        isBoss     = isBoss,
        enemyCount = enemyCount,
        enemyLevel = zone.enemyLevel + math.floor(waveNum / 2),
    })

    if isBoss and zone.bossId then
        wState.bossAlive = true
        local boss = ZoneConfig.getBoss(zone.bossId)
        fireZonePlayers(zoneId, evBossSpawned, {
            zoneId   = zoneId,
            bossId   = zone.bossId,
            bossName = boss and boss.name or "Unknown Boss",
        })
        print("[ZoneService] Boss wave " .. waveNum .. " started in " .. zoneId)
    else
        print("[ZoneService] Wave " .. waveNum .. " started in " .. zoneId ..
              " (" .. enemyCount .. " enemies)")
    end
end

--- Called by the combat system when a boss is killed.
function ZoneService:onBossDefeated(zoneId: string, killerPlayer: Player?)
    local wState = zoneWaves[zoneId]
    if not wState or not wState.bossAlive then return end

    wState.bossAlive = false

    local zone = ZoneConfig.getZone(zoneId)
    local boss = zone and zone.bossId and ZoneConfig.getBoss(zone.bossId)

    -- Bonus coins to all players in zone
    if _coinService and boss then
        for _, player in ipairs(getPlayersInZone(zoneId)) do
            _coinService:awardCoins(player, boss.coinDrop, "boss:" .. zone.bossId)
        end
    end

    -- Give boss egg to killer
    if killerPlayer and _eggService and boss and boss.bossEggDrop then
        _eggService:giveEgg(killerPlayer, "boss", 1)
    end

    fireZonePlayers(zoneId, evBossDefeated, {
        zoneId   = zoneId,
        bossId   = zone and zone.bossId,
        bossName = boss and boss.name or "Unknown Boss",
    })

    -- Treat boss as last enemy — clears the wave
    ZoneService:onWaveEnemyDefeated(zoneId)
end

---------------------------------------------------------------------------
-- ZONE TRANSITIONS
---------------------------------------------------------------------------

--- Attempt to move a player into a zone (validates unlock).
function ZoneService:enterZone(player: Player, zoneId: string): boolean
    local zone = ZoneConfig.getZone(zoneId)
    if not zone then
        evNotify:FireClient(player, "Unknown zone!")
        return false
    end

    -- Check unlock
    if zone.unlockCoins > 0 then
        if not _coinService then return false end
        local data = _mulletService and _mulletService:getData(player)
        local unlockedZones = data and data.unlockedZones or {}
        local alreadyUnlocked = false
        for _, id in ipairs(unlockedZones) do
            if id == zoneId then alreadyUnlocked = true ; break end
        end

        if not alreadyUnlocked then
            if not _coinService:deductCoins(player, zone.unlockCoins, "unlock:" .. zoneId) then
                evNotify:FireClient(player,
                    "Need " .. zone.unlockCoins .. " coins to unlock " .. zone.name)
                return false
            end

            -- Persist unlock
            if data then
                table.insert(data.unlockedZones, zoneId)
            end

            evZoneUnlocked:FireClient(player, { zoneId = zoneId, zoneName = zone.name })
            evNotify:FireClient(player, "Unlocked zone: " .. zone.name .. "!")
        end
    end

    -- Move player
    local prevZone = playerZones[player.UserId]
    if prevZone then
        removeFromZone(player.UserId, prevZone)
    end

    playerZones[player.UserId] = zoneId
    table.insert(playerGroups[zoneId], player.UserId)

    -- Persist current zone
    local data = _mulletService and _mulletService:getData(player)
    if data then data.currentZone = zoneId end

    -- Start first wave if zone is empty (was idle)
    local wState = zoneWaves[zoneId]
    if wState and not wState.inProgress and wState.waveNumber == 0 then
        task.delay(3, function()
            ZoneService:startNextWave(zoneId)
        end)
    end

    print("[ZoneService] " .. player.Name .. " entered " .. zone.name)
    return true
end

---------------------------------------------------------------------------
-- REMOTE HANDLERS
---------------------------------------------------------------------------

evEnterZone.OnServerEvent:Connect(function(player: Player, zoneId: string)
    if type(zoneId) ~= "string" then return end
    ZoneService:enterZone(player, zoneId)
end)

fnGetZoneData.OnServerInvoke = function(player: Player): table
    local result = {}
    local data   = _mulletService and _mulletService:getData(player)
    local unlocked = data and data.unlockedZones or { "zone_barbershop" }

    for _, zone in ipairs(ZoneConfig.Zones) do
        local isUnlocked = false
        for _, id in ipairs(unlocked) do
            if id == zone.id then isUnlocked = true ; break end
        end
        local wState = zoneWaves[zone.id] or {}
        table.insert(result, {
            id           = zone.id,
            name         = zone.name,
            description  = zone.description,
            unlockCoins  = zone.unlockCoins,
            isUnlocked   = isUnlocked,
            isCurrent    = playerZones[player.UserId] == zone.id,
            waveNumber   = wState.waveNumber or 0,
            coinDropMult = zone.coinDropMult,
        })
    end
    return result
end

---------------------------------------------------------------------------
-- PLAYER LIFECYCLE
---------------------------------------------------------------------------

Players.PlayerAdded:Connect(function(player: Player)
    playerZones[player.UserId] = nil
end)

Players.PlayerRemoving:Connect(function(player: Player)
    local zoneId = playerZones[player.UserId]
    if zoneId then
        removeFromZone(player.UserId, zoneId)
    end
    playerZones[player.UserId] = nil
end)

print("[ZoneService] Registered")

return ZoneService
