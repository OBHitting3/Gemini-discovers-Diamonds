--[[
    NightToggleController.lua
    Optional night-mode toggle for events.
    Smoothly transitions Lighting properties between bright blue
    daytime (locked default) and evening mode for special events.

    Night mode is only available when the server enables it.
    Auto-reverts to daytime when event ends.

    LOCKED: Bright blue daytime is the DEFAULT and PERMANENT state.
    Night is an EXCEPTION for events only.
]]

local Lighting     = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig    = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteManager = require(ReplicatedStorage:WaitForChild("RemoteManager"))

local NightToggleController = {}
NightToggleController._uiController = nil
NightToggleController._isNight = false
NightToggleController._enabled = false  -- server controls this
NightToggleController._tweenDuration = 2  -- seconds for transition

---------------------------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------------------------

function NightToggleController:init(uiController)
    self._uiController = uiController

    -- Listen for night toggle from server (via test commands or events)
    local toggleEvent = RemoteManager:getEvent("ToggleNight")
    if toggleEvent then
        toggleEvent.OnClientEvent:Connect(function()
            self:toggle()
        end)
    end

    -- Listen for event broadcasts (auto-enable during sunset events)
    local eventBroadcast = RemoteManager:getEvent("EventBroadcast")
    if eventBroadcast then
        eventBroadcast.OnClientEvent:Connect(function(data)
            if data.action == "start" and data.event then
                if data.event.name == "Sunset Soiree" then
                    self._enabled = true
                    self._uiController:showNotification(
                        "Night mode available! Use the toggle in your HUD.")
                end
            elseif data.action == "end" then
                -- Revert to daytime when any event ends
                if self._isNight then
                    self:_transitionToDay()
                end
                self._enabled = false
            end
        end)
    end

    print("[NightToggleController] Initialized (locked to daytime)")
end

---------------------------------------------------------------------------
-- TOGGLE
---------------------------------------------------------------------------

function NightToggleController:toggle()
    if self._isNight then
        self:_transitionToDay()
    else
        self:_transitionToNight()
    end
end

---------------------------------------------------------------------------
-- TRANSITIONS
---------------------------------------------------------------------------

function NightToggleController:_transitionToNight()
    self._isNight = true

    local nightCfg = GameConfig.Lighting.NightOverride
    local tweenInfo = TweenInfo.new(self._tweenDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

    -- Tween Lighting properties
    TweenService:Create(Lighting, tweenInfo, {
        ClockTime      = nightCfg.ClockTime,
        Brightness     = nightCfg.Brightness,
        Ambient        = nightCfg.Ambient,
        OutdoorAmbient = nightCfg.OutdoorAmbient,
    }):Play()

    -- Tween Atmosphere
    local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmo then
        TweenService:Create(atmo, tweenInfo, {
            Density = 0.5,
            Haze    = 2,
            Glare   = 0,
            Color   = Color3.fromRGB(30, 30, 60),
        }):Play()
    end

    self._uiController:showNotification("Night mode activated")
end

function NightToggleController:_transitionToDay()
    self._isNight = false

    local dayCfg = GameConfig.Lighting
    local tweenInfo = TweenInfo.new(self._tweenDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

    -- Tween back to bright blue daytime
    TweenService:Create(Lighting, tweenInfo, {
        ClockTime      = dayCfg.ClockTime,
        Brightness     = dayCfg.Brightness,
        Ambient        = dayCfg.Ambient,
        OutdoorAmbient = dayCfg.OutdoorAmbient,
    }):Play()

    -- Tween Atmosphere back
    local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmo then
        TweenService:Create(atmo, tweenInfo, {
            Density = dayCfg.Atmosphere.Density,
            Haze    = dayCfg.Atmosphere.Haze,
            Glare   = dayCfg.Atmosphere.Glare,
            Color   = dayCfg.Atmosphere.Color,
        }):Play()
    end

    self._uiController:showNotification("Bright blue daytime restored")
end

---------------------------------------------------------------------------
-- STATE
---------------------------------------------------------------------------

function NightToggleController:isNight(): boolean
    return self._isNight
end

function NightToggleController:isEnabled(): boolean
    return self._enabled
end

return NightToggleController
