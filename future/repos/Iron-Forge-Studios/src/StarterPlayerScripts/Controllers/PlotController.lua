--[[
    PlotController.lua (Client)
    Handles building mode UI, furniture placement preview,
    grid snapping visualization, and plot data sync.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Remotes = require(ReplicatedStorage.Modules.Shared.Remotes)
local Constants = require(ReplicatedStorage.Modules.Shared.Constants)
local FurnitureDatabase = require(ReplicatedStorage.Modules.Data.FurnitureDatabase)
local Signal = require(ReplicatedStorage.Modules.Shared.Signal)

local PlotController = {}

PlotController.PlotDataReceived = Signal.new()
PlotController.BuildModeChanged = Signal.new()

local myPlotData = nil
local buildMode = false
local selectedFurniture = nil
local previewPart = nil

function PlotController.GetPlotData(): table?
    return myPlotData
end

function PlotController.IsBuildMode(): boolean
    return buildMode
end

function PlotController.ToggleBuildMode()
    buildMode = not buildMode
    PlotController.BuildModeChanged:Fire(buildMode)

    if not buildMode and previewPart then
        previewPart:Destroy()
        previewPart = nil
        selectedFurniture = nil
    end
end

function PlotController.SelectFurniture(itemId: string)
    local def = FurnitureDatabase.GetById(itemId)
    if not def then return end

    selectedFurniture = def

    -- Create preview ghost
    if previewPart then previewPart:Destroy() end
    previewPart = Instance.new("Part")
    previewPart.Name = "PlacementPreview"
    previewPart.Size = def.Size or Vector3.new(2, 2, 2)
    previewPart.Material = Enum.Material.ForceField
    previewPart.Color = Color3.fromRGB(100, 255, 100)
    previewPart.Transparency = 0.5
    previewPart.Anchored = true
    previewPart.CanCollide = false
    previewPart.Parent = game.Workspace
end

function PlotController.PlaceFurniture(x: number, y: number, z: number, rotation: number)
    if not selectedFurniture then return end
    Remotes.GetEvent("PlotPlaceFurniture"):FireServer(
        selectedFurniture.Id, x, y or 0.5, z, rotation or 0
    )
end

function PlotController.RemoveFurniture(index: number)
    Remotes.GetEvent("PlotRemoveFurniture"):FireServer(index)
end

function PlotController.DisplayIcon(iconUID: number, x: number, z: number)
    Remotes.GetEvent("PlotDisplayIcon"):FireServer(iconUID, x, z)
end

function PlotController.RemoveDisplay(iconUID: number)
    Remotes.GetEvent("PlotRemoveDisplay"):FireServer(iconUID)
end

function PlotController.RatePlot(targetUserId: number, stars: number)
    Remotes.GetEvent("PlotRate"):FireServer(targetUserId, stars)
end

function PlotController.VisitPlot(targetUserId: number)
    Remotes.GetEvent("PlotVisit"):FireServer(targetUserId)
end

function PlotController.GetFurnitureCategories()
    return FurnitureDatabase.GetCategories()
end

function PlotController.GetFurnitureByCategory(category: string)
    return FurnitureDatabase.GetByCategory(category)
end

function PlotController.Init(player)
    -- Receive plot data from server
    Remotes.GetEvent("PlotDataSync").OnClientEvent:Connect(function(data)
        if myPlotData then
            -- Merge updates
            for key, value in data do
                myPlotData[key] = value
            end
        else
            myPlotData = data
        end
        PlotController.PlotDataReceived:Fire(myPlotData)
    end)
end

return PlotController
