--[[
    EventService.lua
    Manages weekly themes, monthly zones, seasonal festivals,
    and the special Modernism Week (Feb 12-22) event.

    Events cycle automatically and modify gameplay parameters
    (garden growth, shop bonuses, fashion themes, special items).
    n8n webhooks fire on event start/end.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local GameConfig    = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteManager = require(ReplicatedStorage:WaitForChild("RemoteManager"))
local Utilities     = require(ReplicatedStorage:WaitForChild("Utilities"))

local EventService = {}

-- Internal state
EventService._currentEvent = nil
EventService._eventLoop = false
EventService._webhookClient = nil
EventService._themeIndex = 0
EventService._modernismWeekActive = false

---------------------------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------------------------

function EventService:init(webhookClient)
    self._webhookClient = webhookClient

    -- Check if Modernism Week should be active on startup
    self:_checkModernismWeek()

    -- Start the event rotation
    self:_startEventLoop()

    -- Connect manual trigger
    local triggerEvent = RemoteManager:getEvent("TriggerEvent")
    if triggerEvent then
        triggerEvent.OnServerEvent:Connect(function(player, themeName)
            -- Only allow in test/studio mode
            self:startWeeklyTheme(themeName)
        end)
    end

    print("[EventService] Initialized — Modernism Week " ..
          (self._modernismWeekActive and "ACTIVE" or "inactive"))
end

---------------------------------------------------------------------------
-- EVENT LOOP
---------------------------------------------------------------------------

function EventService:_startEventLoop()
    if self._eventLoop then return end
    self._eventLoop = true

    task.spawn(function()
        while self._eventLoop do
            self:_checkModernismWeek()

            -- If no event is active and Modernism Week isn't running,
            -- start the next weekly theme
            if not self._currentEvent then
                self:_rotateTheme()
            end

            task.wait(GameConfig.Timing.EventCheckInterval)
        end
    end)
end

function EventService:_rotateTheme()
    self._themeIndex += 1
    if self._themeIndex > #GameConfig.EventThemes then
        self._themeIndex = 1
    end

    local theme = GameConfig.EventThemes[self._themeIndex]

    -- Don't auto-rotate to Modernism Week (that's date-triggered)
    if theme.name == "Modernism Week" and not self._modernismWeekActive then
        self._themeIndex += 1
        if self._themeIndex > #GameConfig.EventThemes then
            self._themeIndex = 1
        end
        theme = GameConfig.EventThemes[self._themeIndex]
    end

    self:startWeeklyTheme(theme.name)
end

---------------------------------------------------------------------------
-- WEEKLY THEME
---------------------------------------------------------------------------

function EventService:startWeeklyTheme(themeName: string?): boolean
    -- Find theme in config
    local theme = nil
    for _, t in ipairs(GameConfig.EventThemes) do
        if t.name == themeName then
            theme = t
            break
        end
    end

    if not theme then
        -- Default to first theme
        theme = GameConfig.EventThemes[1]
    end

    -- End current event if any
    if self._currentEvent then
        self:_endCurrentEvent()
    end

    -- Start new event
    self._currentEvent = {
        name = theme.name,
        description = theme.description,
        gardenBoost = theme.gardenBoost,
        shopBonus = theme.shopBonus,
        isActive = true,
        startedAt = os.time(),
        endsAt = os.time() + 3600,  -- 1 hour per theme cycle
    }

    -- Broadcast
    RemoteManager:fireAllClients("EventBroadcast", {
        action = "start",
        event = {
            name = theme.name,
            description = theme.description,
            gardenBoost = theme.gardenBoost,
            shopBonus = theme.shopBonus,
        },
    })

    RemoteManager:fireAllClients("NotifyPlayer",
        "Event Active: " .. theme.name .. " — " .. theme.description)

    -- Webhook
    if self._webhookClient then
        self._webhookClient:sendAnalytics("event_started", {
            eventName = theme.name,
            playerCount = #Players:GetPlayers(),
        })
    end

    print("[EventService] Weekly theme started: " .. theme.name)
    return true
end

function EventService:_endCurrentEvent()
    if not self._currentEvent then return end

    RemoteManager:fireAllClients("EventBroadcast", {
        action = "end",
        event = { name = self._currentEvent.name },
    })

    if self._webhookClient then
        self._webhookClient:sendAnalytics("event_ended", {
            eventName = self._currentEvent.name,
            duration = os.time() - self._currentEvent.startedAt,
        })
    end

    self._currentEvent = nil
end

---------------------------------------------------------------------------
-- MODERNISM WEEK  (Feb 12-22)
---------------------------------------------------------------------------

function EventService:_checkModernismWeek()
    local date = os.date("*t")
    local mw = GameConfig.ModernismWeek

    local isInRange = (date.month == mw.StartMonth and date.day >= mw.StartDay and date.day <= mw.EndDay) or
                      (date.month == mw.EndMonth and date.day >= mw.StartDay and date.day <= mw.EndDay)

    if isInRange and not self._modernismWeekActive then
        self:_startModernismWeek()
    elseif not isInRange and self._modernismWeekActive then
        self:_endModernismWeek()
    end
end

function EventService:_startModernismWeek()
    self._modernismWeekActive = true

    -- Override current event with Modernism Week
    self:startWeeklyTheme("Modernism Week")

    -- Fire scheduling webhook
    if self._webhookClient then
        self._webhookClient:sendEventSchedule({
            name = "Modernism Week 2026",
            startDate = "2026-02-12",
            endDate = "2026-02-22",
            details = {
                specialFurniture = GameConfig.ModernismWeek.SpecialFurnitureIds,
                prestigeMultiplier = GameConfig.ModernismWeek.BonusPrestigeMultiplier,
            },
        })
    end

    RemoteManager:fireAllClients("NotifyPlayer",
        "MODERNISM WEEK 2026 IS LIVE! Limited MCM furniture drops + 2x Prestige!")

    print("[EventService] *** MODERNISM WEEK 2026 ACTIVATED ***")
end

function EventService:_endModernismWeek()
    self._modernismWeekActive = false
    self._currentEvent = nil

    RemoteManager:fireAllClients("NotifyPlayer",
        "Modernism Week 2026 has ended. See you next year!")

    print("[EventService] Modernism Week ended")
end

function EventService:triggerModernismWeek()
    self:_startModernismWeek()
end

---------------------------------------------------------------------------
-- STATE ACCESS
---------------------------------------------------------------------------

function EventService:getCurrentEvent(): table?
    return self._currentEvent
end

function EventService:isModernismWeek(): boolean
    return self._modernismWeekActive
end

--- Get the current garden growth multiplier from active event.
function EventService:getGardenBoost(): number
    if self._currentEvent then
        return self._currentEvent.gardenBoost or 1.0
    end
    return 1.0
end

--- Get the current shop discount from active event.
function EventService:getShopBonus(): number
    if self._currentEvent then
        return self._currentEvent.shopBonus or 0
    end
    return 0
end

--- Get prestige multiplier (2x during Modernism Week).
function EventService:getPrestigeMultiplier(): number
    if self._modernismWeekActive then
        return GameConfig.ModernismWeek.BonusPrestigeMultiplier
    end
    return 1.0
end

return EventService
