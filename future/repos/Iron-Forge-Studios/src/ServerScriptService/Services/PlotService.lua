--[[
    PlotService.lua (Server)
    Manages the 32x32 grid-based building system.
    - Plot assignment (100 plots in 10x10 grid)
    - Furniture placement/removal/move with grid snapping
    - Icon Display Pedestals (stealable by heist system)
    - 5-star rating system
    - Visitor income tracking
]]

local Players = game:GetService("Players")

local Constants = require(game.ReplicatedStorage.Modules.Shared.Constants)
local Util = require(game.ReplicatedStorage.Modules.Shared.Util)
local Remotes = require(game.ReplicatedStorage.Modules.Shared.Remotes)
local DataService = require(game.ServerScriptService.Services.DataService)
local FurnitureDatabase = require(game.ReplicatedStorage.Modules.Data.FurnitureDatabase)

local PlotService = {}

-- ═══════════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════════
local plots = {}           -- { [plotIndex] = { Owner, Parts, Position } }
local playerPlots = {}     -- { [userId] = plotIndex }
local GRID_SIZE = 10       -- 10x10 grid of plots
local PLOT_SIZE = Constants.Plot.SIZE
local PLOT_SPACING = 4     -- gap between plots
local plotOrigin = Constants.ZoneData[Constants.Zones.NEIGHBORHOOD].Center

-- ═══════════════════════════════════════════════════════════════
-- PLOT GENERATION
-- ═══════════════════════════════════════════════════════════════

local function generatePlots()
    local zonesFolder = game.Workspace:FindFirstChild("Zones")
    local neighborhoodFolder = zonesFolder and zonesFolder:FindFirstChild(Constants.Zones.NEIGHBORHOOD)
    if not neighborhoodFolder then return end

    local plotsFolder = Instance.new("Folder")
    plotsFolder.Name = "Plots"
    plotsFolder.Parent = neighborhoodFolder

    local totalSize = PLOT_SIZE + PLOT_SPACING
    local gridOffset = (GRID_SIZE * totalSize) / 2

    for row = 0, GRID_SIZE - 1 do
        for col = 0, GRID_SIZE - 1 do
            local plotIndex = row * GRID_SIZE + col + 1
            local x = plotOrigin.X - gridOffset + col * totalSize + PLOT_SIZE / 2
            local z = plotOrigin.Z - gridOffset + row * totalSize + PLOT_SIZE / 2
            local position = Vector3.new(x, 0.1, z)

            -- Plot base
            local base = Instance.new("Part")
            base.Name = "Plot_" .. plotIndex
            base.Size = Vector3.new(PLOT_SIZE, 0.5, PLOT_SIZE)
            base.Position = position
            base.Anchored = true
            base.Material = Enum.Material.Concrete
            base.Color = Color3.fromRGB(200, 180, 150)
            base.Parent = plotsFolder

            -- Plot boundary lines (visual)
            local border = Instance.new("SelectionBox")
            border.Adornee = base
            border.Color3 = Color3.fromRGB(180, 140, 100)
            border.LineThickness = 0.05
            border.Parent = base

            -- Ownership label
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "OwnerLabel"
            billboard.Size = UDim2.new(0, 200, 0, 50)
            billboard.StudsOffset = Vector3.new(0, 5, 0)
            billboard.Parent = base

            local label = Instance.new("TextLabel")
            label.Name = "NameLabel"
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Text = "Available"
            label.TextColor3 = Color3.fromRGB(200, 200, 200)
            label.TextScaled = true
            label.Font = Enum.Font.GothamBold
            label.Parent = billboard

            -- Items folder for placed furniture
            local itemsFolder = Instance.new("Folder")
            itemsFolder.Name = "Items"
            itemsFolder.Parent = base

            plots[plotIndex] = {
                Owner = nil,
                Base = base,
                Position = position,
                ItemsFolder = itemsFolder,
                Label = label,
            }
        end
    end

    print(string.format("[PlotService] Generated %d plots in %dx%d grid", GRID_SIZE * GRID_SIZE, GRID_SIZE, GRID_SIZE))
end

-- ═══════════════════════════════════════════════════════════════
-- PLOT ASSIGNMENT
-- ═══════════════════════════════════════════════════════════════

local function assignPlot(player: Player): number?
    local data = DataService.GetData(player)
    if not data then return nil end

    -- Check if already has a plot
    if playerPlots[player.UserId] then
        return playerPlots[player.UserId]
    end

    -- If data has a saved plot index, try to reclaim it
    if data.Plot.PlotIndex > 0 then
        local savedIndex = data.Plot.PlotIndex
        if plots[savedIndex] and plots[savedIndex].Owner == nil then
            plots[savedIndex].Owner = player.UserId
            plots[savedIndex].Label.Text = player.Name
            plots[savedIndex].Label.TextColor3 = Color3.fromRGB(255, 220, 150)
            playerPlots[player.UserId] = savedIndex
            return savedIndex
        end
    end

    -- Find first available plot
    for index, plot in plots do
        if plot.Owner == nil then
            plot.Owner = player.UserId
            plot.Label.Text = player.Name
            plot.Label.TextColor3 = Color3.fromRGB(255, 220, 150)
            playerPlots[player.UserId] = index
            data.Plot.PlotIndex = index
            return index
        end
    end

    return nil -- all plots taken
end

local function releasePlot(player: Player)
    local plotIndex = playerPlots[player.UserId]
    if plotIndex and plots[plotIndex] then
        -- Clear placed items
        local itemsFolder = plots[plotIndex].ItemsFolder
        if itemsFolder then
            itemsFolder:ClearAllChildren()
        end

        plots[plotIndex].Owner = nil
        plots[plotIndex].Label.Text = "Available"
        plots[plotIndex].Label.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
    playerPlots[player.UserId] = nil
end

-- ═══════════════════════════════════════════════════════════════
-- FURNITURE PLACEMENT
-- ═══════════════════════════════════════════════════════════════

local function isWithinPlot(plotIndex: number, worldPos: Vector3): boolean
    local plot = plots[plotIndex]
    if not plot then return false end

    local halfSize = PLOT_SIZE / 2
    local center = plot.Position
    return math.abs(worldPos.X - center.X) <= halfSize
        and math.abs(worldPos.Z - center.Z) <= halfSize
end

local function snapToGrid(value: number): number
    local grid = Constants.Plot.GRID_CELL
    return math.floor(value / grid + 0.5) * grid
end

local function handlePlaceFurniture(player: Player, itemId: string, x: number, y: number, z: number, rotation: number)
    if type(itemId) ~= "string" or type(x) ~= "number" or type(z) ~= "number" then return end
    rotation = type(rotation) == "number" and rotation or 0

    local plotIndex = playerPlots[player.UserId]
    if not plotIndex then return end

    local data = DataService.GetData(player)
    if not data then return end

    -- Validate furniture exists
    local furnitureDef = FurnitureDatabase.GetById(itemId)
    if not furnitureDef then return end

    -- Check max items
    if #data.Plot.Furniture >= Constants.Plot.MAX_ITEMS then return end

    -- Snap to grid
    x = snapToGrid(x)
    z = snapToGrid(z)
    y = y or 0.5

    local worldPos = Vector3.new(x, y, z)
    if not isWithinPlot(plotIndex, worldPos) then return end

    -- Clamp rotation to 0/90/180/270
    rotation = math.floor(rotation / 90 + 0.5) * 90

    -- Save to data
    local furnitureEntry = {
        ItemId = itemId,
        X = x,
        Y = y,
        Z = z,
        Rotation = rotation,
    }
    table.insert(data.Plot.Furniture, furnitureEntry)

    -- Spawn visual part
    local plot = plots[plotIndex]
    local part = Instance.new("Part")
    part.Name = itemId .. "_" .. #data.Plot.Furniture
    part.Size = furnitureDef.Size or Vector3.new(2, 2, 2)
    part.CFrame = CFrame.new(x, y + part.Size.Y / 2, z) * CFrame.Angles(0, math.rad(rotation), 0)
    part.Anchored = true
    part.Material = furnitureDef.Material or Enum.Material.SmoothPlastic
    part.Color = furnitureDef.Color or Color3.fromRGB(200, 180, 160)
    part.Parent = plot.ItemsFolder

    Remotes.GetEvent("PlotDataSync"):FireClient(player, { Furniture = data.Plot.Furniture })
end

local function handleRemoveFurniture(player: Player, furnitureIndex: number)
    if type(furnitureIndex) ~= "number" then return end

    local plotIndex = playerPlots[player.UserId]
    if not plotIndex then return end

    local data = DataService.GetData(player)
    if not data then return end

    furnitureIndex = math.floor(furnitureIndex)
    if furnitureIndex < 1 or furnitureIndex > #data.Plot.Furniture then return end

    table.remove(data.Plot.Furniture, furnitureIndex)

    -- Rebuild visual (simple approach - clear and re-place)
    PlotService._rebuildPlotVisuals(plotIndex, data)

    Remotes.GetEvent("PlotDataSync"):FireClient(player, { Furniture = data.Plot.Furniture })
end

-- ═══════════════════════════════════════════════════════════════
-- ICON DISPLAY PEDESTALS
-- ═══════════════════════════════════════════════════════════════

local function handleDisplayIcon(player: Player, iconUID: number, x: number, z: number)
    if type(iconUID) ~= "number" or type(x) ~= "number" or type(z) ~= "number" then return end

    local plotIndex = playerPlots[player.UserId]
    if not plotIndex then return end

    local data = DataService.GetData(player)
    if not data then return end

    -- Validate icon ownership
    local icon = DataService.GetIcon(player, iconUID)
    if not icon then return end
    if icon.VaultSlot ~= nil then return end -- can't display vaulted icons
    if icon.Displayed then return end -- already displayed

    -- Snap position
    x = snapToGrid(x)
    z = snapToGrid(z)
    local worldPos = Vector3.new(x, 0, z)
    if not isWithinPlot(plotIndex, worldPos) then return end

    -- Mark as displayed
    icon.Displayed = true
    table.insert(data.Plot.DisplayPedestals, {
        IconUID = iconUID,
        X = x,
        Z = z,
    })

    -- Create visual pedestal
    local plot = plots[plotIndex]
    local pedestal = Instance.new("Part")
    pedestal.Name = "Pedestal_" .. iconUID
    pedestal.Size = Vector3.new(3, 4, 3)
    pedestal.Position = Vector3.new(x, 2, z)
    pedestal.Anchored = true
    pedestal.Material = Enum.Material.Marble
    pedestal.Color = Color3.fromRGB(240, 220, 180)
    pedestal.Parent = plot.ItemsFolder

    -- Pedestal glow
    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(255, 200, 100)
    light.Brightness = 1
    light.Range = 8
    light.Parent = pedestal

    Remotes.GetEvent("PlayerDataUpdate"):FireClient(player, "Icons", data.Icons)
    Remotes.GetEvent("PlotDataSync"):FireClient(player, { DisplayPedestals = data.Plot.DisplayPedestals })
end

local function handleRemoveDisplay(player: Player, iconUID: number)
    if type(iconUID) ~= "number" then return end

    local plotIndex = playerPlots[player.UserId]
    if not plotIndex then return end

    local data = DataService.GetData(player)
    if not data then return end

    local icon = DataService.GetIcon(player, iconUID)
    if not icon or not icon.Displayed then return end

    icon.Displayed = false

    -- Remove from pedestals
    for i, ped in data.Plot.DisplayPedestals do
        if ped.IconUID == iconUID then
            table.remove(data.Plot.DisplayPedestals, i)
            break
        end
    end

    -- Remove visual
    local plot = plots[plotIndex]
    local pedestalPart = plot.ItemsFolder:FindFirstChild("Pedestal_" .. iconUID)
    if pedestalPart then
        pedestalPart:Destroy()
    end

    Remotes.GetEvent("PlayerDataUpdate"):FireClient(player, "Icons", data.Icons)
end

-- ═══════════════════════════════════════════════════════════════
-- RATING & VISITORS
-- ═══════════════════════════════════════════════════════════════

local function handleRate(player: Player, targetUserId: number, stars: number)
    if type(targetUserId) ~= "number" or type(stars) ~= "number" then return end
    if player.UserId == targetUserId then return end

    stars = Util.Clamp(math.floor(stars), 1, Constants.Plot.STAR_RATING_MAX)

    local targetPlayer = Players:GetPlayerByUserId(targetUserId)
    if not targetPlayer then return end

    local targetData = DataService.GetData(targetPlayer)
    if not targetData then return end

    targetData.Plot.TotalRatings = (targetData.Plot.TotalRatings or 0) + 1
    targetData.Plot.RatingSum = (targetData.Plot.RatingSum or 0) + stars
    targetData.Plot.Rating = Util.Round(targetData.Plot.RatingSum / targetData.Plot.TotalRatings, 1)
    targetData.PlotRating = targetData.Plot.Rating

    Remotes.GetEvent("PlotDataSync"):FireClient(targetPlayer, { Rating = targetData.Plot.Rating })
end

local function handleVisit(player: Player, targetUserId: number)
    if type(targetUserId) ~= "number" then return end
    if player.UserId == targetUserId then return end

    local targetPlayer = Players:GetPlayerByUserId(targetUserId)
    if not targetPlayer then return end

    local targetData = DataService.GetData(targetPlayer)
    if not targetData then return end

    local visitorId = tostring(player.UserId)
    if not Util.Contains(targetData.Plot.UniqueVisitorsToday, visitorId) then
        table.insert(targetData.Plot.UniqueVisitorsToday, visitorId)
        DataService.AddCurrency(targetPlayer, Constants.VISITOR_INCOME_PER_DAY)
        targetData.Plot.VisitorIncomeToday = (targetData.Plot.VisitorIncomeToday or 0) + Constants.VISITOR_INCOME_PER_DAY
    end
end

-- ═══════════════════════════════════════════════════════════════
-- VISUAL REBUILD
-- ═══════════════════════════════════════════════════════════════

function PlotService._rebuildPlotVisuals(plotIndex: number, data: table)
    local plot = plots[plotIndex]
    if not plot then return end

    plot.ItemsFolder:ClearAllChildren()

    -- Rebuild furniture
    for _, entry in data.Plot.Furniture do
        local furnitureDef = FurnitureDatabase.GetById(entry.ItemId)
        if furnitureDef then
            local part = Instance.new("Part")
            part.Name = entry.ItemId
            part.Size = furnitureDef.Size or Vector3.new(2, 2, 2)
            part.CFrame = CFrame.new(entry.X, entry.Y + part.Size.Y / 2, entry.Z)
                * CFrame.Angles(0, math.rad(entry.Rotation or 0), 0)
            part.Anchored = true
            part.Material = furnitureDef.Material or Enum.Material.SmoothPlastic
            part.Color = furnitureDef.Color or Color3.fromRGB(200, 180, 160)
            part.Parent = plot.ItemsFolder
        end
    end

    -- Rebuild pedestals
    for _, ped in data.Plot.DisplayPedestals do
        local pedestal = Instance.new("Part")
        pedestal.Name = "Pedestal_" .. ped.IconUID
        pedestal.Size = Vector3.new(3, 4, 3)
        pedestal.Position = Vector3.new(ped.X, 2, ped.Z)
        pedestal.Anchored = true
        pedestal.Material = Enum.Material.Marble
        pedestal.Color = Color3.fromRGB(240, 220, 180)
        pedestal.Parent = plot.ItemsFolder
    end
end

-- ═══════════════════════════════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════════════════════════════

function PlotService.GetPlotForPlayer(userId: number): number?
    return playerPlots[userId]
end

function PlotService.GetPlotData(plotIndex: number): table?
    return plots[plotIndex]
end

-- ═══════════════════════════════════════════════════════════════
-- INIT
-- ═══════════════════════════════════════════════════════════════

function PlotService.Init()
    generatePlots()

    -- Assign plots when data loads
    DataService.PlayerDataLoaded:Connect(function(player, data)
        local plotIndex = assignPlot(player)
        if plotIndex then
            -- Rebuild saved visuals
            PlotService._rebuildPlotVisuals(plotIndex, data)
            Remotes.GetEvent("PlotDataSync"):FireClient(player, {
                PlotIndex = plotIndex,
                Position = plots[plotIndex].Position,
                Furniture = data.Plot.Furniture,
                DisplayPedestals = data.Plot.DisplayPedestals,
                Rating = data.Plot.Rating,
            })
        end
    end)

    -- Remote handlers
    Remotes.GetEvent("PlotPlaceFurniture").OnServerEvent:Connect(handlePlaceFurniture)
    Remotes.GetEvent("PlotRemoveFurniture").OnServerEvent:Connect(handleRemoveFurniture)
    Remotes.GetEvent("PlotDisplayIcon").OnServerEvent:Connect(handleDisplayIcon)
    Remotes.GetEvent("PlotRemoveDisplay").OnServerEvent:Connect(handleRemoveDisplay)
    Remotes.GetEvent("PlotRate").OnServerEvent:Connect(handleRate)
    Remotes.GetEvent("PlotVisit").OnServerEvent:Connect(handleVisit)

    -- Release plots on leave
    Players.PlayerRemoving:Connect(releasePlot)

    -- Daily reset for visitor tracking
    task.spawn(function()
        while true do
            task.wait(3600) -- check hourly
            local today = Util.GetDayNumber()
            for _, player in Players:GetPlayers() do
                local data = DataService.GetData(player)
                if data then
                    -- Simple daily reset check
                    if #data.Plot.UniqueVisitorsToday > 0 then
                        local firstVisitorDay = Util.GetDayNumber()
                        if firstVisitorDay ~= today then
                            data.Plot.UniqueVisitorsToday = {}
                            data.Plot.VisitorIncomeToday = 0
                        end
                    end
                end
            end
        end
    end)

    print("[PlotService] Initialized")
end

return PlotService
