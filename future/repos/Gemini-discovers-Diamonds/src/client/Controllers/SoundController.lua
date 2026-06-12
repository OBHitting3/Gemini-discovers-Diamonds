--[[
    SoundController.lua
    Ambient sound system for Palm Springs Paradise.
    Manages background ambience, zone-based sound transitions,
    and UI/interaction sound effects.

    Sound IDs are Roblox asset placeholders — replace with
    real uploaded audio after publish.
]]

local Players           = game:GetService("Players")
local SoundService      = game:GetService("SoundService")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig    = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteManager = require(ReplicatedStorage:WaitForChild("RemoteManager"))

local SoundController = {}

SoundController._sounds = {}
SoundController._currentZone = "desert"
SoundController._masterVolume = 0.5

---------------------------------------------------------------------------
-- SOUND DEFINITIONS
-- Using Roblox library sound IDs that are freely available.
-- Replace with custom uploads for production.
---------------------------------------------------------------------------

local SOUND_DEFS = {
    -- Ambient loops
    desert_ambience = {
        id = "rbxassetid://9112854440",  -- gentle wind / nature
        volume = 0.3,
        looped = true,
        group = "ambient",
    },
    pool_water = {
        id = "rbxassetid://6677463651",  -- water lapping
        volume = 0.15,
        looped = true,
        group = "ambient",
    },
    boulevard_chatter = {
        id = "rbxassetid://9112854440",  -- light ambience
        volume = 0.1,
        looped = true,
        group = "ambient",
    },

    -- UI sounds
    ui_click = {
        id = "rbxassetid://6895079853",  -- soft click
        volume = 0.4,
        looped = false,
        group = "ui",
    },
    ui_success = {
        id = "rbxassetid://6895079853",  -- success chime
        volume = 0.5,
        looped = false,
        group = "ui",
    },
    ui_purchase = {
        id = "rbxassetid://6895079853",  -- cash register
        volume = 0.5,
        looped = false,
        group = "ui",
    },

    -- Interaction sounds
    plant_seed = {
        id = "rbxassetid://6895079853",  -- soft thud
        volume = 0.4,
        looped = false,
        group = "sfx",
    },
    water_splash = {
        id = "rbxassetid://6677463651",  -- water pour
        volume = 0.5,
        looped = false,
        group = "sfx",
    },
    harvest_pop = {
        id = "rbxassetid://6895079853",  -- pop
        volume = 0.5,
        looped = false,
        group = "sfx",
    },
    fashion_fanfare = {
        id = "rbxassetid://6895079853",  -- fanfare
        volume = 0.6,
        looped = false,
        group = "sfx",
    },
    level_up = {
        id = "rbxassetid://6895079853",  -- ascending chime
        volume = 0.7,
        looped = false,
        group = "sfx",
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

    -- Listen for game events that trigger sounds
    self:_connectEventSounds()

    print("[SoundController] Initialized — " ..
          tostring(self:_countSounds()) .. " sounds loaded")
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
    if not sound or not sound.IsPlaying then return end

    if fadeTime and fadeTime > 0 then
        local tween = TweenService:Create(sound,
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
function SoundController:playSFX(name: string)
    local sound = self._sounds[name]
    if sound then
        -- Clone for overlapping one-shots
        if sound.IsPlaying and not sound.Looped then
            local clone = sound:Clone()
            clone.Parent = SoundService
            clone:Play()
            clone.Ended:Connect(function()
                clone:Destroy()
            end)
        else
            sound:Play()
        end
    end
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
            if not player or not player.Character then continue end
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end

            local pos = hrp.Position
            local newZone = "desert"

            -- Check if near El Paseo boulevard
            if math.abs(pos.X) < 30 and pos.Z > world.ElPaseoStart.Z and pos.Z < world.ElPaseoEnd.Z then
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
        TweenService:Create(desertSound,
            TweenInfo.new(1, Enum.EasingStyle.Linear),
            { Volume = targetVol }
        ):Play()
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
                self:playSFX("fashion_fanfare")
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
end

---------------------------------------------------------------------------
-- HELPERS
---------------------------------------------------------------------------

function SoundController:_countSounds(): number
    local count = 0
    for _ in pairs(self._sounds) do count += 1 end
    return count
end

return SoundController
