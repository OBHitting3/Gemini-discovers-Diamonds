--[[
    GardenController.lua
    Client-side garden interaction: proximity prompts, real-time
    growth visualization, wilting indicators, and garden state display.
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig    = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteManager = require(ReplicatedStorage:WaitForChild("RemoteManager"))

local GardenController = {}
GardenController._uiController = nil
GardenController._gardenState = {}

---------------------------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------------------------

function GardenController:init(uiController)
    self._uiController = uiController

    -- Listen for garden state updates from server
    local stateEvent = RemoteManager:getEvent("GardenStateUpdate")
    if stateEvent then
        stateEvent.OnClientEvent:Connect(function(state)
            self:_onGardenStateUpdate(state)
        end)
    end

    -- Set up proximity prompt handlers
    task.spawn(function()
        task.wait(5)  -- Wait for garden to build
        self:_setupPromptHandlers()
    end)

    -- Request initial state
    task.spawn(function()
        task.wait(3)
        local getState = RemoteManager:getFunction("GetGardenState")
        if getState then
            local state = RemoteManager:invokeServer("GetGardenState")
            if state then
                self:_onGardenStateUpdate(state)
            end
        end
    end)

    print("[GardenController] Initialized")
end

---------------------------------------------------------------------------
-- PROMPT HANDLERS
---------------------------------------------------------------------------

function GardenController:_setupPromptHandlers()
    local gardenFolder = workspace:FindFirstChild("DesertGarden")
    if not gardenFolder then return end

    for _, child in ipairs(gardenFolder:GetChildren()) do
        if child:IsA("BasePart") and child:GetAttribute("PlotIndex") then
            local prompt = child:FindFirstChild("GardenPrompt")
            if prompt then
                prompt.Triggered:Connect(function(player)
                    if player == Players.LocalPlayer then
                        local plotIndex = child:GetAttribute("PlotIndex")
                        self:_onGardenPromptTriggered(plotIndex)
                    end
                end)
            end
        end
    end
end

function GardenController:_onGardenPromptTriggered(plotIndex: number)
    local plotState = self._gardenState[plotIndex]

    if not plotState or plotState.growthStage == "empty" then
        -- Show seed selection UI
        self._uiController:showPanel("garden")
    elseif plotState.growthStage == "mature" then
        -- Harvest
        RemoteManager:fireServer("HarvestPlant", plotIndex)
    elseif plotState.growthStage == "dead" then
        -- Clear dead plant (auto-handled by server)
        self._uiController:showNotification("This plant has died. It will be cleared soon.")
    else
        -- Water
        RemoteManager:fireServer("WaterPlant", plotIndex)
    end
end

---------------------------------------------------------------------------
-- STATE UPDATES
---------------------------------------------------------------------------

function GardenController:_onGardenStateUpdate(state: table)
    self._gardenState = state

    -- Update prompt text based on state
    local gardenFolder = workspace:FindFirstChild("DesertGarden")
    if not gardenFolder then return end

    for plotIndex, plotData in pairs(state) do
        local bed = gardenFolder:FindFirstChild("GardenPlot_" .. plotIndex)
        if bed then
            local prompt = bed:FindFirstChild("GardenPrompt")
            if prompt then
                if plotData.growthStage == "empty" then
                    prompt.ActionText = "Plant Seed"
                elseif plotData.growthStage == "mature" then
                    prompt.ActionText = "Harvest"
                elseif plotData.growthStage == "wilting" then
                    prompt.ActionText = "Water NOW!"
                elseif plotData.growthStage == "dead" then
                    prompt.ActionText = "Clear"
                else
                    prompt.ActionText = "Water"
                end
            end
        end
    end
end

---------------------------------------------------------------------------
-- ACTIONS
---------------------------------------------------------------------------

function GardenController:plantSeed(plotIndex: number, plantId: string)
    RemoteManager:fireServer("PlantSeed", plotIndex, plantId)
end

function GardenController:waterPlant(plotIndex: number)
    RemoteManager:fireServer("WaterPlant", plotIndex)
end

function GardenController:harvestPlant(plotIndex: number)
    RemoteManager:fireServer("HarvestPlant", plotIndex)
end

---------------------------------------------------------------------------
-- STATE ACCESS
---------------------------------------------------------------------------

function GardenController:getGardenState(): table
    return self._gardenState
end

function GardenController:getPlotState(plotIndex: number): table?
    return self._gardenState[plotIndex]
end

return GardenController
