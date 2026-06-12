--[[
    PlotService.lua
    Manages residential plot claiming, MCM home building, furniture
    placement/removal, Vibes Score calculation, and home tours.

    Plots are server-authoritative. Client sends requests via
    RemoteEvents; this service validates and executes.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig    = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteManager = require(ReplicatedStorage:WaitForChild("RemoteManager"))
local ItemCatalog   = require(ReplicatedStorage:WaitForChild("ItemCatalog"))
local Utilities     = require(ReplicatedStorage:WaitForChild("Utilities"))

local PlotService = {}

-- Internal state
PlotService._plots = {}           -- plotId → PlotData
PlotService._homeModels = {}      -- plotId → Model
PlotService._economyService = nil
PlotService._homeBuilder = nil
PlotService._persistenceService = nil

---------------------------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------------------------

function PlotService:init(economyService, homeBuilder, persistenceService)
    self._economyService = economyService
    self._homeBuilder = homeBuilder
    self._persistenceService = persistenceService

    -- Initialize plot data
    for plotId = 1, 4 do
        self._plots[plotId] = {
            plotId = plotId,
            ownerId = nil,
            homeStyle = nil,
            furniturePlacements = {},
            vibesScore = 0,
            partCount = 0,
        }
    end

    -- Create plot marker parts (invisible, for proximity prompts)
    local plotsFolder = workspace:FindFirstChild("Plots")
    if not plotsFolder then
        plotsFolder = Instance.new("Folder")
        plotsFolder.Name = "Plots"
        plotsFolder.Parent = workspace
    end

    for plotId, pos in pairs(GameConfig.World.PlotPositions) do
        local marker = Utilities.createPart({
            Name = "PlotMarker_" .. plotId,
            Size = Vector3.new(4, 4, 4),
            CFrame = CFrame.new(pos + Vector3.new(0, 2, 0)),
            Transparency = 0.7,
            Color = GameConfig.Colors.Turquoise,
            Material = Enum.Material.Neon,
            CanCollide = false,
            Tag = "PlotMarker",
            Parent = plotsFolder,
        })
        marker:SetAttribute("PlotId", plotId)

        -- Proximity prompt
        local prompt = Instance.new("ProximityPrompt")
        prompt.Name = "ClaimPlotPrompt"
        prompt.ActionText = "Claim Plot"
        prompt.ObjectText = "Plot #" .. plotId .. " - " ..
                           Utilities.formatCurrency(GameConfig.Economy.PlotPrices[plotId])
        prompt.MaxActivationDistance = 15
        prompt.HoldDuration = 1.5
        prompt.Parent = marker
    end

    -- Connect remote events
    local claimEvent = RemoteManager:getEvent("ClaimPlot")
    if claimEvent then
        claimEvent.OnServerEvent:Connect(function(player, plotId)
            self:claimPlot(player, plotId)
        end)
    end

    local buildEvent = RemoteManager:getEvent("BuildHome")
    if buildEvent then
        buildEvent.OnServerEvent:Connect(function(player, style)
            self:buildHome(player, style)
        end)
    end

    local placeEvent = RemoteManager:getEvent("PlaceFurniture")
    if placeEvent then
        placeEvent.OnServerEvent:Connect(function(player, furnitureId, position, rotation)
            self:placeFurniture(player, furnitureId, position, rotation)
        end)
    end

    local removeEvent = RemoteManager:getEvent("RemoveFurniture")
    if removeEvent then
        removeEvent.OnServerEvent:Connect(function(player, instanceId)
            self:removeFurniture(player, instanceId)
        end)
    end

    -- Remote function for getting plot data
    local getPlotFunc = RemoteManager:getFunction("GetPlotData")
    if getPlotFunc then
        getPlotFunc.OnServerInvoke = function(player, plotId)
            return self:getPlotData(plotId)
        end
    end

    print("[PlotService] Initialized with " .. 4 .. " residential plots")
end

---------------------------------------------------------------------------
-- CLAIM PLOT
---------------------------------------------------------------------------

function PlotService:claimPlot(player: Player, plotId: number): boolean
    -- Validate plotId
    if type(plotId) ~= "number" or plotId < 1 or plotId > 4 then
        warn("[PlotService] Invalid plotId: " .. tostring(plotId))
        return false
    end

    local plot = self._plots[plotId]

    -- Already claimed?
    if plot.ownerId then
        RemoteManager:fireClient("NotifyPlayer", player,
            "This plot is already claimed!")
        return false
    end

    -- Player already owns a plot?
    local data = self._economyService:getPlayerData(player)
    if data and data.plotId then
        RemoteManager:fireClient("NotifyPlayer", player,
            "You already own a plot! (#" .. data.plotId .. ")")
        return false
    end

    -- Afford check
    local price = GameConfig.Economy.PlotPrices[plotId]
    if not self._economyService:removeCoins(player, price, "Claim plot #" .. plotId) then
        RemoteManager:fireClient("NotifyPlayer", player,
            "Not enough SunCoins! Need " .. Utilities.formatCurrency(price))
        return false
    end

    -- Claim it
    plot.ownerId = player.UserId
    if data then
        data.plotId = plotId
    end

    -- Remove claim prompt, show owned indicator
    local plotsFolder = workspace:FindFirstChild("Plots")
    if plotsFolder then
        local marker = plotsFolder:FindFirstChild("PlotMarker_" .. plotId)
        if marker then
            local prompt = marker:FindFirstChild("ClaimPlotPrompt")
            if prompt then prompt:Destroy() end
            marker.Color = GameConfig.Colors.DustyPink
            marker.Transparency = 0.5

            -- Add owner sign
            local gui = Instance.new("BillboardGui")
            gui.Size = UDim2.new(0, 200, 0, 50)
            gui.StudsOffset = Vector3.new(0, 3, 0)
            gui.Parent = marker

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 1, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = player.Name .. "'s Plot"
            lbl.TextColor3 = GameConfig.Colors.UIText
            lbl.TextScaled = true
            lbl.Font = Enum.Font.GothamBold
            lbl.Parent = gui
        end
    end

    self:_markDirty(player)
    RemoteManager:fireClient("NotifyPlayer", player,
        "Plot #" .. plotId .. " claimed! Choose a home style to build.")

    print("[PlotService] " .. player.Name .. " claimed plot #" .. plotId)
    return true
end

---------------------------------------------------------------------------
-- BUILD HOME
---------------------------------------------------------------------------

function PlotService:buildHome(player: Player, style: string): boolean
    -- Validate style
    if not GameConfig.HomeStyles[style] then
        warn("[PlotService] Invalid home style: " .. tostring(style))
        return false
    end

    -- Find player's plot
    local data = self._economyService:getPlayerData(player)
    if not data or not data.plotId then
        RemoteManager:fireClient("NotifyPlayer", player,
            "You need to claim a plot first!")
        return false
    end

    local plotId = data.plotId
    local plot = self._plots[plotId]

    -- Already built?
    if plot.homeStyle then
        RemoteManager:fireClient("NotifyPlayer", player,
            "You already have a home built!")
        return false
    end

    -- Remove existing model if any
    if self._homeModels[plotId] then
        self._homeModels[plotId]:Destroy()
    end

    -- Build the home
    local plotPos = GameConfig.World.PlotPositions[plotId]
    local model, partCount = self._homeBuilder:buildHome(plotPos, style)

    if model then
        self._homeModels[plotId] = model
        plot.homeStyle = style
        plot.partCount = partCount
        data.homeStyle = style
        self:_markDirty(player)

        RemoteManager:fireClient("NotifyPlayer", player,
            "Built " .. GameConfig.HomeStyles[style].name .. "! (" .. partCount .. " parts)")
        print("[PlotService] " .. player.Name .. " built " .. style .. " on plot #" .. plotId)
        return true
    end

    return false
end

---------------------------------------------------------------------------
-- FURNITURE PLACEMENT
---------------------------------------------------------------------------

function PlotService:placeFurniture(player: Player, furnitureId: string, position: Vector3, rotation: number?): boolean
    local data = self._economyService:getPlayerData(player)
    if not data or not data.plotId then
        RemoteManager:fireClient("NotifyPlayer", player, "Claim a plot first!")
        return false
    end

    local plotId = data.plotId
    local plot = self._plots[plotId]

    -- Check item in inventory
    if not self._economyService:hasItem(player, furnitureId) then
        RemoteManager:fireClient("NotifyPlayer", player,
            "You don't have this furniture item!")
        return false
    end

    -- Check part limit
    if plot.partCount >= GameConfig.PartLimits.MaxPartsPerPlot then
        RemoteManager:fireClient("NotifyPlayer", player,
            "Plot part limit reached! Remove something first.")
        return false
    end

    -- Validate position is within plot bounds
    local plotPos = GameConfig.World.PlotPositions[plotId]
    local plotSize = GameConfig.World.PlotSize
    if not Utilities.isInsideBox(position, plotPos, plotSize + Vector3.new(0, 20, 0)) then
        RemoteManager:fireClient("NotifyPlayer", player,
            "Furniture must be placed within your plot!")
        return false
    end

    -- Look up furniture catalog entry
    local item = ItemCatalog.getFurniture(furnitureId)
    if not item then
        warn("[PlotService] Unknown furniture: " .. furnitureId)
        return false
    end

    -- Remove from inventory
    self._economyService:removeItem(player, furnitureId)

    -- Create furniture part
    local rot = rotation or 0
    local itemColor = GameConfig.Colors[item.color] or GameConfig.Colors.WallWhite
    local itemMaterial = Enum.Material[item.material or "SmoothPlastic"] or Enum.Material.SmoothPlastic

    local part = Utilities.createPart({
        Name = "Furniture_" .. furnitureId,
        Size = Vector3.new(item.size.x, item.size.y, item.size.z),
        CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(rot), 0),
        Color = itemColor,
        Material = itemMaterial,
        Tag = "PlacedFurniture",
        Parent = self._homeModels[plotId] or workspace:FindFirstChild("Plots"),
    })

    local instanceId = Utilities.generateId()
    part:SetAttribute("InstanceId", instanceId)
    part:SetAttribute("ItemId", furnitureId)
    part:SetAttribute("OwnerId", player.UserId)

    -- Record placement
    table.insert(plot.furniturePlacements, {
        instanceId = instanceId,
        itemId = furnitureId,
        position = { x = position.X, y = position.Y, z = position.Z },
        rotation = rot,
        placedAt = os.time(),
    })

    plot.partCount += 1
    self:_updateVibesScore(plotId)
    self:_markDirty(player)

    RemoteManager:fireClient("NotifyPlayer", player,
        "Placed " .. item.name .. "! Vibes Score: " .. plot.vibesScore)

    return true
end

function PlotService:removeFurniture(player: Player, instanceId: string): boolean
    local data = self._economyService:getPlayerData(player)
    if not data or not data.plotId then return false end

    local plotId = data.plotId
    local plot = self._plots[plotId]

    -- Find and remove placement record
    local foundIndex = nil
    local foundItemId = nil
    for i, placement in ipairs(plot.furniturePlacements) do
        if placement.instanceId == instanceId then
            foundIndex = i
            foundItemId = placement.itemId
            break
        end
    end

    if not foundIndex then return false end

    -- Remove physical part
    local homeModel = self._homeModels[plotId]
    if homeModel then
        for _, child in ipairs(homeModel:GetDescendants()) do
            if child:IsA("BasePart") and child:GetAttribute("InstanceId") == instanceId then
                child:Destroy()
                break
            end
        end
    end

    -- Update records
    table.remove(plot.furniturePlacements, foundIndex)
    plot.partCount = math.max(0, plot.partCount - 1)

    -- Return item to inventory
    if foundItemId then
        self._economyService:giveItem(player, foundItemId)
    end

    self:_updateVibesScore(plotId)
    self:_markDirty(player)

    return true
end

---------------------------------------------------------------------------
-- VIBES SCORE
---------------------------------------------------------------------------

function PlotService:_updateVibesScore(plotId: number)
    local plot = self._plots[plotId]
    if not plot then return end

    local score = 0

    -- Base points for having a home
    if plot.homeStyle then score += 10 end

    -- Points for furniture variety
    local categories = {}
    for _, placement in ipairs(plot.furniturePlacements) do
        local item = ItemCatalog.getFurniture(placement.itemId)
        if item then
            categories[item.category] = true
            score += 2  -- each piece adds 2
        end
    end

    -- Bonus for category diversity (5 points per unique category)
    for _ in pairs(categories) do
        score += 5
    end

    -- Pool presence bonus
    if plot.homeStyle then score += 5 end  -- all homes have pools

    plot.vibesScore = score
end

function PlotService:getVibesScore(plotId: number): number
    local plot = self._plots[plotId]
    return plot and plot.vibesScore or 0
end

---------------------------------------------------------------------------
-- HOME TOURS
---------------------------------------------------------------------------

function PlotService:startHomeTour(player: Player, targetPlotId: number)
    local plot = self._plots[targetPlotId]
    if not plot or not plot.homeStyle then
        RemoteManager:fireClient("NotifyPlayer", player, "No home to visit!")
        return
    end

    local plotPos = GameConfig.World.PlotPositions[targetPlotId]
    if plotPos and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        player.Character.HumanoidRootPart.CFrame = CFrame.new(plotPos + Vector3.new(0, 5, 15))

        local data = self._economyService:getPlayerData(player)
        if data then
            data.stats.homeTourVisits += 1
        end

        RemoteManager:fireClient("NotifyPlayer", player,
            "Welcome to plot #" .. targetPlotId .. "! Vibes Score: " .. plot.vibesScore)
    end
end

---------------------------------------------------------------------------
-- DATA ACCESS
---------------------------------------------------------------------------

function PlotService:getPlotData(plotId: number): table?
    return self._plots[plotId]
end

function PlotService:getPlayerPlotId(player: Player): number?
    local data = self._economyService:getPlayerData(player)
    return data and data.plotId
end

---------------------------------------------------------------------------
-- INTERNAL
---------------------------------------------------------------------------

function PlotService:_markDirty(player: Player)
    if self._persistenceService then
        self._persistenceService:markDirty(player)
    end
end

return PlotService
