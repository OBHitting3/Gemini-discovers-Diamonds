--[[
    SoundController.lua
    Ambient sound system for Palm Springs Paradise.
    Manages background ambience, zone-based sound transitions,
    and UI/interaction sound effects.

    Sound IDs are Roblox asset placeholders — replace with
    real uploaded audio after publish.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteManager = require(ReplicatedStorage:WaitForChild("RemoteManager"))
local AssetRegistry = require(ReplicatedStorage:WaitForChild("AssetRegistry"))

local SoundController = {}

SoundController._sounds = {}
SoundController._currentZone = "desert"
SoundController._masterVolume = 0.5
SoundController._fairyWalkEnabled = true
SoundController._walkChimeAccumulator = 0
SoundController._nextWalkChimeIn = 6
SoundController._inTravelZone = false

---------------------------------------------------------------------------
-- SOUND DEFINITIONS
-- Using Roblox library sound IDs that are freely available.
-- Replace with custom uploads for production.
---------------------------------------------------------------------------

local SOUND_DEFS = {
    -- Ambient loops
    desert_ambience = {
        id = "rbxassetid://9112854440", -- gentle wind / nature
        volume = 0.3,
        looped = true,
        group = "ambient",
    },
    pool_water = {
        id = "rbxassetid://6677463651", -- water lapping
        volume = 0.15,
        looped = true,
        group = "ambient",
    },
    boulevard_chatter = {
        id = "rbxassetid://9112854440", -- light ambience
        volume = 0.1,
        looped = true,
        group = "ambient",
    },

    -- UI sounds
    ui_click = {
        id = "rbxassetid://6895079853", -- soft click
        volume = 0.4,
        looped = false,
        group = "ui",
    },
    ui_success = {
        id = "rbxassetid://6895079853", -- success chime
        volume = 0.5,
        looped = false,
        group = "ui",
    },
    ui_purchase = {
        id = "rbxassetid://6895079853", -- cash register
        volume = 0.5,
        looped = false,
        group = "ui",
    },

    -- Interaction sounds
    plant_seed = {
        id = "rbxassetid://6895079853", -- soft thud
        volume = 0.4,
        looped = false,
        group = "sfx",
    },
    water_splash = {
        id = "rbxassetid://6677463651", -- water pour
        volume = 0.5,
        looped = false,
        group = "sfx",
    },
    harvest_pop = {
        id = "rbxassetid://6895079853", -- pop
        volume = 0.5,
        looped = false,
        group = "sfx",
    },
    fashion_fanfare = {
        id = "rbxassetid://6895079853", -- fanfare
        volume = 0.6,
        looped = false,
        group = "sfx",
    },
    level_up = {
        id = "rbxassetid://6895079853", -- ascending chime
        volume = 0.7,
        looped = false,
        group = "sfx",
    },

    -- Fairy sparkle (magic bell — not KarLux voice; swap rbxassetid via AssetRegistry / Manus upload)
    fairy_chime = {
        id = AssetRegistry:getSoundId("fairy_chime"),
        volume = GameConfig.Audio and GameConfig.Audio.WalkChimeVolume or 0.28,
        looped = false,
        group = "fairy",
    },
    fairy_travel = {
        id = AssetRegistry:getSoundId("fairy_travel"),
        volume = GameConfig.Audio and GameConfig.Audio.TravelChimeVolume or 0.45,
        looped = false,
        group = "fairy",
    },
    plane_cabin_hum = {
        id = AssetRegistry:getSoundId("plane_cabin_hum"),
        volume = GameConfig.Audio and GameConfig.Audio.PlaneCabinVolume or 0.12,
        looped = true,
        group = "ambient",
    },
}

---------------------------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------------------------

function SoundController:init()
    -- Create a SoundGroup for volume control
    local soundGroup = Instance.new("SoundGroup")
    soundGroup.Name = "PSPSounds"
    soundGroup.Volume = self._masterVolume
    soundGroup.Parent = SoundService
    self._soundGroup = soundGroup

    -- Pre-create all Sound instances
    for name, def in pairs(SOUND_DEFS) do
        local sound = Instance.new("Sound")
        sound.Name = name
        sound.SoundId = def.id
        sound.Volume = def.volume
        sound.Looped = def.looped or false
        sound.SoundGroup = soundGroup
        sound.Parent = SoundService
        self._sounds[name] = sound
    end

    -- Start desert ambience immediately
    self:playSound("desert_ambience")

    -- Start zone detection loop
    self:_startZoneDetection()

    -- Walk sparkle + travel arrival (plane-landing pad at spawn)
    local audioCfg = GameConfig.Audio
    if audioCfg then
        self._fairyWalkEnabled = audioCfg.FairyWalkEnabledDefault ~= false
        self._nextWalkChimeIn = math.random(audioCfg.WalkChimeIntervalMin, audioCfg.WalkChimeIntervalMax)
    end
    self:_startFairyWalkChimes()
    self:_startTravelArrivalDetection()

    -- Listen for game events that trigger sounds
    self:_connectEventSounds()

    print("[SoundController] Initialized — " .. tostring(self:_countSounds()) .. " sounds loaded")
end

---------------------------------------------------------------------------
-- PLAYBACK
---------------------------------------------------------------------------

--- Play a sound by name.
function SoundController:playSound(name: string)
    local sound = self._sounds[name]
    if sound then
        if not sound.IsPlaying then
            sound:Play()
        end
    end
end

--- Stop a sound by name (with optional fade).
function SoundController:stopSound(name: string, fadeTime: number?)
    local sound = self._sounds[name]
    if not sound or not sound.IsPlaying then
        return
    end

    if fadeTime and fadeTime > 0 then
        local tween = TweenService:Create(
            sound,
            TweenInfo.new(fadeTime, Enum.EasingStyle.Linear),
            { Volume = 0 }
        )
        tween:Play()
        tween.Completed:Connect(function()
            sound:Stop()
            sound.Volume = SOUND_DEFS[name] and SOUND_DEFS[name].volume or 0.5
        end)
    else
        sound:Stop()
    end
end

--- Play a one-shot sound effect.
function SoundController:playSFX(name: string, playbackSpeed: number?)
    local sound = self._sounds[name]
    if sound then
        local speed = playbackSpeed or 1
        -- Clone for overlapping one-shots
        if sound.IsPlaying and not sound.Looped then
            local clone = sound:Clone()
            clone.PlaybackSpeed = speed
            clone.Parent = SoundService
            clone:Play()
            clone.Ended:Connect(function()
                clone:Destroy()
            end)
        else
            sound.PlaybackSpeed = speed
            sound:Play()
        end
    end
end

--- Fairy sparkle (walk or travel). Not branded KarLux audio.
function SoundController:playFairyChime(mode: string?)
    if mode == "travel" then
        self:playSFX("fairy_travel", 1.05)
    else
        self:playSFX("fairy_chime", 0.95 + math.random() * 0.15)
    end
end

function SoundController:setFairyWalkEnabled(enabled: boolean)
    self._fairyWalkEnabled = enabled
end

--- Set master volume (0-1).
function SoundController:setVolume(vol: number)
    self._masterVolume = math.clamp(vol, 0, 1)
    if self._soundGroup then
        self._soundGroup.Volume = self._masterVolume
    end
end

---------------------------------------------------------------------------
-- ZONE-BASED AMBIENT TRANSITIONS
---------------------------------------------------------------------------

function SoundController:_startZoneDetection()
    local world = GameConfig.World

    task.spawn(function()
        while true do
            task.wait(2)
            local player = Players.LocalPlayer
            if not player or not player.Character then
                continue
            end
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then
                continue
            end

            local pos = hrp.Position
            local newZone = "desert"

            -- Check if near El Paseo boulevard
            if
                math.abs(pos.X) < 30
                and pos.Z > world.ElPaseoStart.Z
                and pos.Z < world.ElPaseoEnd.Z
            then
                newZone = "boulevard"
            -- Check if near any pool (residential plots)
            elseif self:_isNearPool(pos) then
                newZone = "poolside"
            -- Check if near garden
            elseif (pos - world.GardenPosition).Magnitude < 30 then
                newZone = "garden"
            -- Check if near runway
            elseif (pos - world.RunwayPosition).Magnitude < 25 then
                newZone = "runway"
            end

            if newZone ~= self._currentZone then
                self:_transitionZone(self._currentZone, newZone)
                self._currentZone = newZone
            end
        end
    end)
end

function SoundController:_isNearPool(pos: Vector3): boolean
    for _, plotPos in pairs(GameConfig.World.PlotPositions) do
        if (pos - plotPos).Magnitude < 35 then
            return true
        end
    end
    return false
end

---------------------------------------------------------------------------
-- FAIRY CHIMES — walking + travel arrival (spawn / "plane landed")
---------------------------------------------------------------------------

function SoundController:_startFairyWalkChimes()
    local audioCfg = GameConfig.Audio
    if not audioCfg then
        return
    end

    RunService.Heartbeat:Connect(function(dt)
        if not self._fairyWalkEnabled then
            return
        end
        local player = Players.LocalPlayer
        if not player or not player.Character then
            return
        end
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not hrp then
            return
        end
        if humanoid.Health <= 0 then
            return
        end

        local moving = humanoid.MoveDirection.Magnitude > 0.15
        if not moving or humanoid.FloorMaterial == Enum.Material.Air then
            self._walkChimeAccumulator = 0
            return
        end

        self._walkChimeAccumulator += dt
        if self._walkChimeAccumulator >= self._nextWalkChimeIn then
            self._walkChimeAccumulator = 0
            self._nextWalkChimeIn = math.random(audioCfg.WalkChimeIntervalMin, audioCfg.WalkChimeIntervalMax)
            self:playFairyChime("walk")
        end
    end)
end

function SoundController:_startTravelArrivalDetection()
    local world = GameConfig.World
    local center = world.TravelArrivalPosition or world.SpawnPosition
    local radius = world.TravelArrivalRadius or 28

    task.spawn(function()
        while true do
            task.wait(1)
            local player = Players.LocalPlayer
            if not player or not player.Character then
                continue
            end
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then
                continue
            end

            local inZone = (hrp.Position - center).Magnitude <= radius
            if inZone and not self._inTravelZone then
                self._inTravelZone = true
                self:playSound("plane_cabin_hum")
                self:playFairyChime("travel")
            elseif not inZone and self._inTravelZone then
                self._inTravelZone = false
                self:stopSound("plane_cabin_hum", 1.5)
            end
        end
    end)
end

function SoundController:_transitionZone(fromZone: string, toZone: string)
    -- Fade out zone-specific sounds
    if fromZone == "poolside" then
        self:stopSound("pool_water", 1)
    elseif fromZone == "boulevard" then
        self:stopSound("boulevard_chatter", 1)
    end

    -- Fade in new zone sounds
    if toZone == "poolside" then
        self:playSound("pool_water")
    elseif toZone == "boulevard" then
        self:playSound("boulevard_chatter")
    end

    -- Desert ambience always plays but volume adjusts
    local desertSound = self._sounds.desert_ambience
    if desertSound then
        local targetVol = (toZone == "desert") and 0.3 or 0.1
        TweenService
            :Create(desertSound, TweenInfo.new(1, Enum.EasingStyle.Linear), { Volume = targetVol })
            :Play()
    end
end

---------------------------------------------------------------------------
-- EVENT-TRIGGERED SOUNDS
---------------------------------------------------------------------------

function SoundController:_connectEventSounds()
    -- Economy updates (purchase sound)
    local econEvent = RemoteManager:getEvent("EconomyUpdate")
    if econEvent then
        econEvent.OnClientEvent:Connect(function(data)
            if data.delta and data.delta < 0 then
                self:playSFX("ui_purchase")
            elseif data.reason and string.find(data.reason, "Level") then
                self:playSFX("level_up")
            end
        end)
    end

    -- Fashion events
    local fashionEvent = RemoteManager:getEvent("FashionEventUpdate")
    if fashionEvent then
        fashionEvent.OnClientEvent:Connect(function(data)
            if data.action == "started" then
                self:playSFX("fashion_fanfare")
            elseif data.action == "ended" then
                self:playSFX("ui_success")
            end
        end)
    end

    -- Garden state updates
    local gardenEvent = RemoteManager:getEvent("GardenStateUpdate")
    if gardenEvent then
        gardenEvent.OnClientEvent:Connect(function()
            -- Subtle ambient sound on garden update
        end)
    end

    -- Server test commands: /fairychime, /travelchime
    local sfxEvent = RemoteManager:getEvent("PlayClientSfx")
    if sfxEvent then
        sfxEvent.OnClientEvent:Connect(function(payload)
            if type(payload) ~= "table" then
                return
            end
            if payload.fairyWalkEnabled ~= nil then
                self:setFairyWalkEnabled(payload.fairyWalkEnabled)
            end
            if payload.mode == "travel" then
                self:playFairyChime("travel")
            elseif payload.mode == "walk" or payload.name == "fairy_chime" then
                self:playFairyChime("walk")
            elseif payload.name then
                self:playSFX(payload.name, payload.playbackSpeed)
            end
        end)
    end
end

---------------------------------------------------------------------------
-- HELPERS
---------------------------------------------------------------------------

function SoundController:_countSounds(): number
    local count = 0
    for _ in pairs(self._sounds) do
        count += 1
    end
    return count
end

return SoundController
