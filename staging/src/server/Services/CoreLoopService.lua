--[[
    CoreLoopService.lua  (STAGING — merge to src/server/Services)
    Orchestrates the Palm Springs Paradise day-phase core loop.

    Hooks into existing services (do not duplicate their logic):
      - GardenService  → growth multiplier from DayPhaseConfig
      - FashionService → optional gate before auto-start events
      - EventService   → broadcast phase for festival UI
      - RemoteManager  → DayPhaseUpdate to clients

    Asset integration:
      - Reads AssetRegistry for future imported templates (no-op until merge)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteManager = require(ReplicatedStorage:WaitForChild("RemoteManager"))
local DayPhaseConfig = require(ReplicatedStorage:WaitForChild("DayPhaseConfig"))
local AssetRegistry = require(ReplicatedStorage:WaitForChild("AssetRegistry"))

local CoreLoopService = {}

CoreLoopService._currentPhase = nil :: DayPhaseConfig.DayPhase?
CoreLoopService._loopRunning = false
CoreLoopService._gardenService = nil
CoreLoopService._fashionService = nil
CoreLoopService._eventService = nil
CoreLoopService._tickInterval = 30 -- seconds between phase checks

export type ServiceRefs = {
    garden: any?,
    fashion: any?,
    event: any?,
}

---------------------------------------------------------------------------
function CoreLoopService:init(refs: ServiceRefs)
    self._gardenService = refs.garden
    self._fashionService = refs.fashion
    self._eventService = refs.event

    self:_ensureDayPhaseRemote()

    local phase = DayPhaseConfig.getCurrentPhase()
    self:_setPhase(phase, true)

    self:_startPhaseLoop()

    print("[CoreLoopService] Initialized — phase: " .. phase)
end

---------------------------------------------------------------------------
function CoreLoopService:getCurrentPhase(): DayPhaseConfig.DayPhase
    return self._currentPhase or DayPhaseConfig.getCurrentPhase()
end

function CoreLoopService:getModifiers()
    return DayPhaseConfig.getModifiers(self:getCurrentPhase())
end

function CoreLoopService:isFashionAllowed(): boolean
    return DayPhaseConfig.getModifiers(self:getCurrentPhase()).fashionEventsAllowed
end

---------------------------------------------------------------------------
function CoreLoopService:_ensureDayPhaseRemote()
    local folder = ReplicatedStorage:FindFirstChild("PalmSpringsRemotes")
    if not folder then return end
    if not folder:FindFirstChild("DayPhaseUpdate") then
        local ev = Instance.new("RemoteEvent")
        ev.Name = "DayPhaseUpdate"
        ev.Parent = folder
    end
end

function CoreLoopService:_startPhaseLoop()
    if self._loopRunning then return end
    self._loopRunning = true

    task.spawn(function()
        while self._loopRunning do
            local nextPhase = DayPhaseConfig.getCurrentPhase()
            if nextPhase ~= self._currentPhase then
                self:_setPhase(nextPhase, false)
            end
            task.wait(self._tickInterval)
        end
    end)
end

function CoreLoopService:_setPhase(phase: DayPhaseConfig.DayPhase, isStartup: boolean)
    local previous = self._currentPhase
    self._currentPhase = phase

    local modifiers = DayPhaseConfig.getModifiers(phase)
    local hint = DayPhaseConfig.getHint(phase)

    self:_applyGardenModifier(modifiers.gardenGrowthMultiplier)
    self:_broadcastPhase(phase, hint, modifiers, previous, isStartup)

    print("[CoreLoopService] Phase → " .. phase ..
        (previous and (" (from " .. previous .. ")") or " (startup)"))
end

function CoreLoopService:_applyGardenModifier(multiplier: number)
    if not self._gardenService then return end
    -- GardenService can read this field each tick (add method on merge)
    if self._gardenService.setGrowthMultiplier then
        self._gardenService:setGrowthMultiplier(multiplier)
    else
        self._gardenService._growthMultiplier = multiplier
    end
end

function CoreLoopService:_broadcastPhase(
    phase: DayPhaseConfig.DayPhase,
    hint: any,
    modifiers: any,
    previous: DayPhaseConfig.DayPhase?,
    isStartup: boolean
)
    local payload = {
        phase = phase,
        previousPhase = previous,
        hint = hint,
        modifiers = modifiers,
        serverTime = os.time(),
        importedAssetCount = self:_countImportedAssets(),
    }

    local ev = RemoteManager:getEvent("DayPhaseUpdate")
    if ev then
        for _, player in ipairs(Players:GetPlayers()) do
            ev:FireClient(player, payload)
        end
    end

    if self._eventService and self._eventService.onDayPhaseChanged then
        self._eventService:onDayPhaseChanged(phase, modifiers)
    end

    if not isStartup then
        for _, player in ipairs(Players:GetPlayers()) do
            RemoteManager:fireClient("NotifyPlayer", player,
                hint.title .. " — " .. hint.body)
        end
    end
end

function CoreLoopService:_countImportedAssets(): number
    local count = 0
    for slug, _ in pairs(AssetRegistry._entries) do
        if AssetRegistry:hasImportedAsset(slug) then
            count += 1
        end
    end
    return count
end

---------------------------------------------------------------------------
-- Optional gate for FashionService auto-events (call before starting event)
---------------------------------------------------------------------------
function CoreLoopService:canStartFashionEvent(): boolean
    return self:isFashionAllowed()
end

return CoreLoopService
