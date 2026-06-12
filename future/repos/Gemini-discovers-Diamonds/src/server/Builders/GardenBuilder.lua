--[[
    GardenBuilder.lua
    Builds the shared community desert garden with 16 planting plots
    (4×4 grid), irrigation channels, entrance arch, and tool shed.

    The garden is a collaborative space — any player can water any plant.
    Plant visuals are updated by GardenService via :updatePlantVisual().

    Part budget: < 100 parts.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Utilities  = require(ReplicatedStorage:WaitForChild("Utilities"))

local C = GameConfig.Colors

local GardenBuilder = {}
GardenBuilder._partCount = 0
GardenBuilder._plotParts = {}   -- plotIndex → { bed, plant, ... }

---------------------------------------------------------------------------
-- BUILD GARDEN
---------------------------------------------------------------------------

function GardenBuilder:buildGarden(): number
    local parts = 0
    local world = GameConfig.World
    local gardenPos = world.GardenPosition
    local gardenSize = world.GardenSize

    -- Create garden folder
    local folder = Instance.new("Folder")
    folder.Name = "DesertGarden"
    folder.Parent = workspace
    self._folder = folder

    local origin = CFrame.new(gardenPos)

    -- Garden ground (dark soil base)
    Utilities.createPart({
        Name = "GardenGround",
        Size = Vector3.new(gardenSize.X, 0.4, gardenSize.Z),
        CFrame = origin * CFrame.new(0, 0.2, 0),
        Color = Color3.fromRGB(120, 90, 60),
        Material = Enum.Material.Ground,
        Tag = "Garden",
        Parent = folder,
    })
    parts += 1

    -- Fence (4 sides, simple low wall)
    local fenceH = 3
    local halfX = gardenSize.X / 2
    local halfZ = gardenSize.Z / 2
    local fences = {
        { CFrame.new(0, fenceH / 2, -halfZ - 0.25), Vector3.new(gardenSize.X + 1, fenceH, 0.5) },
        { CFrame.new(0, fenceH / 2, halfZ + 0.25),  Vector3.new(gardenSize.X + 1, fenceH, 0.5) },
        { CFrame.new(-halfX - 0.25, fenceH / 2, 0), Vector3.new(0.5, fenceH, gardenSize.Z) },
        { CFrame.new(halfX + 0.25, fenceH / 2, 0),  Vector3.new(0.5, fenceH, gardenSize.Z) },
    }
    for i, f in ipairs(fences) do
        Utilities.createPart({
            Name = "Fence_" .. i,
            Size = f[2],
            CFrame = origin * f[1],
            Color = Color3.fromRGB(160, 120, 70),
            Material = Enum.Material.Wood,
            Transparency = 0.3,
            Tag = "Garden",
            Parent = folder,
        })
        parts += 1
    end

    -- Entrance arch (front of garden, gap in south fence)
    local archH = 5
    -- Left post
    Utilities.createPart({
        Name = "ArchPostL",
        Size = Vector3.new(0.8, archH, 0.8),
        CFrame = origin * CFrame.new(-2, archH / 2, halfZ + 0.25),
        Color = Color3.fromRGB(139, 90, 43),
        Material = Enum.Material.Wood,
        Tag = "Garden",
        Parent = folder,
    })
    parts += 1
    -- Right post
    Utilities.createPart({
        Name = "ArchPostR",
        Size = Vector3.new(0.8, archH, 0.8),
        CFrame = origin * CFrame.new(2, archH / 2, halfZ + 0.25),
        Color = Color3.fromRGB(139, 90, 43),
        Material = Enum.Material.Wood,
        Tag = "Garden",
        Parent = folder,
    })
    parts += 1
    -- Crossbeam
    Utilities.createPart({
        Name = "ArchBeam",
        Size = Vector3.new(5, 0.5, 1),
        CFrame = origin * CFrame.new(0, archH, halfZ + 0.25),
        Color = Color3.fromRGB(139, 90, 43),
        Material = Enum.Material.Wood,
        Tag = "Garden",
        Parent = folder,
    })
    parts += 1

    -- Arch sign
    local archSign = Utilities.createPart({
        Name = "GardenSign",
        Size = Vector3.new(4, 1.5, 0.3),
        CFrame = origin * CFrame.new(0, archH + 1, halfZ + 0.5),
        Color = C.WallWhite,
        Material = Enum.Material.SmoothPlastic,
        Tag = "Garden",
        Parent = folder,
    })
    parts += 1

    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Front
    gui.Parent = archSign
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "DESERT GARDEN"
    lbl.TextColor3 = C.CactusGreen
    lbl.TextScaled = true
    lbl.Font = Enum.Font.GothamBold
    lbl.Parent = gui

    -- Planting plots (4×4 grid)
    local plotSize = world.GardenPlotSize  -- 4×0.5×4
    local plotSpacing = 2   -- gap between plots
    local totalPlotW = 4 * plotSize.X + 3 * plotSpacing
    local totalPlotZ = 4 * plotSize.Z + 3 * plotSpacing
    local startX = -totalPlotW / 2 + plotSize.X / 2
    local startZ = -totalPlotZ / 2 + plotSize.Z / 2

    for row = 0, 3 do
        for col = 0, 3 do
            local plotIndex = row * 4 + col + 1
            local px = startX + col * (plotSize.X + plotSpacing)
            local pz = startZ + row * (plotSize.Z + plotSpacing)

            -- Raised bed
            local bed = Utilities.createPart({
                Name = "GardenPlot_" .. plotIndex,
                Size = Vector3.new(plotSize.X, plotSize.Y, plotSize.Z),
                CFrame = origin * CFrame.new(px, 0.4 + plotSize.Y / 2, pz),
                Color = Color3.fromRGB(100, 70, 40),
                Material = Enum.Material.Ground,
                Tag = "GardenPlot",
                Parent = folder,
            })
            bed:SetAttribute("PlotIndex", plotIndex)
            parts += 1

            -- Proximity prompt for interaction
            local prompt = Instance.new("ProximityPrompt")
            prompt.Name = "GardenPrompt"
            prompt.ActionText = "Plant Seed"
            prompt.ObjectText = "Garden Plot #" .. plotIndex
            prompt.MaxActivationDistance = 8
            prompt.HoldDuration = 0.5
            prompt.Parent = bed

            -- Plant placeholder (invisible, scaled up when planted)
            local plant = Utilities.createPart({
                Name = "Plant_" .. plotIndex,
                Size = Vector3.new(0.1, 0.1, 0.1),
                CFrame = origin * CFrame.new(px, 1, pz),
                Color = C.CactusGreen,
                Material = Enum.Material.Grass,
                Transparency = 1,
                CanCollide = false,
                Tag = "GardenPlant",
                Parent = folder,
            })
            plant:SetAttribute("PlotIndex", plotIndex)
            parts += 1

            self._plotParts[plotIndex] = {
                bed = bed,
                plant = plant,
                prompt = prompt,
            }
        end
    end

    -- Irrigation channels (thin turquoise strips between rows)
    for row = 0, 2 do
        local iz = startZ + row * (plotSize.Z + plotSpacing) + plotSize.Z / 2 + plotSpacing / 2
        Utilities.createPart({
            Name = "Irrigation_" .. (row + 1),
            Size = Vector3.new(totalPlotW, 0.1, 0.6),
            CFrame = origin * CFrame.new(0, 0.45, iz),
            Color = C.Turquoise,
            Material = Enum.Material.Glass,
            Transparency = 0.4,
            Tag = "Garden",
            Parent = folder,
        })
        parts += 1
    end

    -- Tool shed (small structure in corner)
    local shedOrigin = origin * CFrame.new(-halfX + 5, 0, -halfZ + 5)
    local shedW, shedH, shedD = 6, 5, 6

    -- Shed floor
    Utilities.createPart({
        Name = "ShedFloor",
        Size = Vector3.new(shedW, 0.3, shedD),
        CFrame = shedOrigin * CFrame.new(0, 0.15, 0),
        Color = C.Concrete,
        Material = Enum.Material.Concrete,
        Tag = "Garden",
        Parent = folder,
    })
    parts += 1

    -- Shed walls (3 sides, open front)
    for i, wall in ipairs({
        { CFrame.new(0, shedH / 2, -shedD / 2), Vector3.new(shedW, shedH, 0.4) },
        { CFrame.new(-shedW / 2, shedH / 2, 0), Vector3.new(0.4, shedH, shedD) },
        { CFrame.new(shedW / 2, shedH / 2, 0),  Vector3.new(0.4, shedH, shedD) },
    }) do
        Utilities.createPart({
            Name = "ShedWall_" .. i,
            Size = wall[2],
            CFrame = shedOrigin * wall[1],
            Color = Color3.fromRGB(160, 120, 70),
            Material = Enum.Material.Wood,
            Tag = "Garden",
            Parent = folder,
        })
        parts += 1
    end

    -- Shed flat roof
    Utilities.createPart({
        Name = "ShedRoof",
        Size = Vector3.new(shedW + 1, 0.3, shedD + 1),
        CFrame = shedOrigin * CFrame.new(0, shedH + 0.15, 0),
        Color = C.RoofDarkGrey,
        Material = Enum.Material.Metal,
        Tag = "Garden",
        Parent = folder,
    })
    parts += 1

    self._partCount += parts
    print("[GardenBuilder] Desert garden built (" .. parts .. " parts)")
    return parts
end

---------------------------------------------------------------------------
-- PLANT VISUAL UPDATES
---------------------------------------------------------------------------

--- Update the visual appearance of a plant at a given plot index.
--- @param plotIndex number — 1–16
--- @param growthStage string — "empty"|"seed"|"sprout"|"growing"|"mature"|"wilting"|"dead"
--- @param plantColor Color3? — optional color override based on plant type
function GardenBuilder:updatePlantVisual(plotIndex: number, growthStage: string, plantColor: Color3?)
    local plotData = self._plotParts[plotIndex]
    if not plotData then return end

    local plant = plotData.plant
    local prompt = plotData.prompt
    local color = plantColor or C.CactusGreen

    local stages = {
        empty   = { size = Vector3.new(0.1, 0.1, 0.1), transparency = 1, promptText = "Plant Seed" },
        seed    = { size = Vector3.new(0.5, 0.3, 0.5),  transparency = 0, promptText = "Water" },
        sprout  = { size = Vector3.new(1, 1.5, 1),      transparency = 0, promptText = "Water" },
        growing = { size = Vector3.new(2, 3, 2),         transparency = 0, promptText = "Water" },
        mature  = { size = Vector3.new(2.5, 4, 2.5),    transparency = 0, promptText = "Harvest" },
        wilting = { size = Vector3.new(2, 2.5, 2),       transparency = 0, promptText = "Water NOW!" },
        dead    = { size = Vector3.new(1, 0.5, 1),       transparency = 0, promptText = "Clear" },
    }

    local stage = stages[growthStage] or stages.empty

    plant.Size = stage.size
    plant.Transparency = stage.transparency
    -- Reposition Y so it sits on top of the bed
    local bed = plotData.bed
    plant.CFrame = bed.CFrame * CFrame.new(0, bed.Size.Y / 2 + stage.size.Y / 2, 0)

    -- Color based on stage
    if growthStage == "wilting" then
        plant.Color = Color3.fromRGB(180, 160, 50)  -- yellow-brown
    elseif growthStage == "dead" then
        plant.Color = Color3.fromRGB(100, 80, 60)   -- dark brown
    elseif growthStage == "seed" then
        plant.Color = Color3.fromRGB(139, 90, 43)   -- seed brown
    else
        plant.Color = color
    end

    -- Update prompt
    if prompt then
        prompt.ActionText = stage.promptText
    end
end

--- Get the garden folder reference.
function GardenBuilder:getFolder()
    return self._folder
end

--- Get plot parts for a specific index.
function GardenBuilder:getPlotParts(plotIndex: number)
    return self._plotParts[plotIndex]
end

function GardenBuilder:getPartCount(): number
    return self._partCount
end

return GardenBuilder
