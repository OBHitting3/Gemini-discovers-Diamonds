--[[
    PlotController.lua
    Client-side plot interaction: claim prompts, home style selection,
    furniture placement preview/confirm, home tours.
]]

local Players           = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")

local GameConfig    = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteManager = require(ReplicatedStorage:WaitForChild("RemoteManager"))

local PlotController = {}
PlotController._uiController = nil
PlotController._isPlacingFurniture = false
PlotController._ghostPart = nil

---------------------------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------------------------

function PlotController:init(uiController)
    self._uiController = uiController

    -- Set up proximity prompt handlers for plot claiming
    task.spawn(function()
        -- Wait for plot markers to load
        task.wait(3)

        local plotsFolder = workspace:WaitForChild("Plots", 30)
        if not plotsFolder then return end

        for _, marker in ipairs(plotsFolder:GetChildren()) do
            if marker:GetAttribute("PlotId") then
                local prompt = marker:FindFirstChild("ClaimPlotPrompt")
                if prompt then
                    prompt.Triggered:Connect(function(player)
                        if player == Players.LocalPlayer then
                            local plotId = marker:GetAttribute("PlotId")
                            self:_onPlotClaimTriggered(plotId)
                        end
                    end)
                end
            end
        end

        -- Also handle dynamically added prompts
        plotsFolder.DescendantAdded:Connect(function(desc)
            if desc:IsA("ProximityPrompt") and desc.Name == "ClaimPlotPrompt" then
                desc.Triggered:Connect(function(player)
                    if player == Players.LocalPlayer then
                        local marker = desc.Parent
                        local plotId = marker and marker:GetAttribute("PlotId")
                        if plotId then
                            self:_onPlotClaimTriggered(plotId)
                        end
                    end
                end)
            end
        end)
    end)

    print("[PlotController] Initialized")
end

---------------------------------------------------------------------------
-- PLOT CLAIMING
---------------------------------------------------------------------------

function PlotController:_onPlotClaimTriggered(plotId: number)
    -- Show style selection UI or just claim
    -- For prototype: directly claim and prompt for style
    RemoteManager:fireServer("ClaimPlot", plotId)

    -- After a short delay, prompt for home style
    task.delay(1, function()
        self._uiController:showPanel("plot")
    end)
end

---------------------------------------------------------------------------
-- HOME BUILDING
---------------------------------------------------------------------------

--- Request server to build a home with the selected style.
function PlotController:requestBuildHome(style: string)
    RemoteManager:fireServer("BuildHome", style)
end

---------------------------------------------------------------------------
-- FURNITURE PLACEMENT
---------------------------------------------------------------------------

--- Enter furniture placement mode with a ghost preview.
function PlotController:startPlacingFurniture(itemId: string)
    if self._isPlacingFurniture then
        self:cancelPlacement()
    end

    self._isPlacingFurniture = true
    self._currentItemId = itemId

    -- Create ghost preview part
    local ItemCatalog = require(ReplicatedStorage:WaitForChild("ItemCatalog"))
    local item = ItemCatalog.getFurniture(itemId)
    if not item then return end

    local ghost = Instance.new("Part")
    ghost.Name = "GhostPreview"
    ghost.Size = Vector3.new(item.size.x, item.size.y, item.size.z)
    ghost.Anchored = true
    ghost.CanCollide = false
    ghost.Transparency = 0.5
    ghost.Color = GameConfig.Colors.Turquoise
    ghost.Material = Enum.Material.Neon
    ghost.Parent = workspace

    self._ghostPart = ghost
    self._placementRotation = 0

    -- Update ghost position each frame
    self._placementConnection = game:GetService("RunService").RenderStepped:Connect(function()
        self:_updateGhostPosition()
    end)

    self._uiController:showNotification("Click to place, R to rotate, X to cancel")
end

function PlotController:_updateGhostPosition()
    if not self._ghostPart then return end

    local player = Players.LocalPlayer
    local mouse = player:GetMouse()

    if mouse.Target then
        local pos = mouse.Hit.Position + Vector3.new(0, self._ghostPart.Size.Y / 2, 0)
        -- Snap to grid (2-stud grid)
        pos = Vector3.new(
            math.round(pos.X / 2) * 2,
            pos.Y,
            math.round(pos.Z / 2) * 2
        )
        self._ghostPart.CFrame = CFrame.new(pos) *
            CFrame.Angles(0, math.rad(self._placementRotation), 0)
    end
end

--- Confirm current furniture placement.
function PlotController:confirmPlacement()
    if not self._isPlacingFurniture or not self._ghostPart then return end

    local position = self._ghostPart.Position
    local rotation = self._placementRotation

    RemoteManager:fireServer("PlaceFurniture", self._currentItemId, position, rotation)
    self:cancelPlacement()
end

--- Rotate the ghost preview.
function PlotController:rotatePlacement()
    self._placementRotation = (self._placementRotation + 45) % 360
end

--- Cancel furniture placement mode.
function PlotController:cancelPlacement()
    self._isPlacingFurniture = false

    if self._ghostPart then
        self._ghostPart:Destroy()
        self._ghostPart = nil
    end

    if self._placementConnection then
        self._placementConnection:Disconnect()
        self._placementConnection = nil
    end

    self._currentItemId = nil
end

---------------------------------------------------------------------------
-- FURNITURE REMOVAL
---------------------------------------------------------------------------

function PlotController:requestRemoveFurniture(instanceId: string)
    RemoteManager:fireServer("RemoveFurniture", instanceId)
end

---------------------------------------------------------------------------
-- HOME TOURS
---------------------------------------------------------------------------

function PlotController:requestHomeTour(plotId: number)
    -- For prototype: handled by server teleportation
    -- The PlotService will move the player to the target plot
    self._uiController:showNotification("Visiting plot #" .. plotId .. "...")
end

---------------------------------------------------------------------------
-- STATE
---------------------------------------------------------------------------

function PlotController:isPlacingFurniture(): boolean
    return self._isPlacingFurniture
end

return PlotController
