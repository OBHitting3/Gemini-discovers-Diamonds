--[[
    EnvironmentBuilder.lua
    Builds the complete Palm Springs environment: terrain, sky,
    atmosphere, mountains, roads, palm trees, and desert decorations.

    LOCKED VISUAL IDENTITY:
    - Bright blue daytime sky (#87CEEB → #E0F0FF)
    - Soft midday sun, no orange/sunset
    - Desert sand terrain base
    - Distant purple-grey mountain backdrop
    - Palm-lined El Paseo boulevard

    All geometry is created programmatically via Luau.
    Part budget: < 1,500 for entire environment.
]]

local Lighting         = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Utilities  = require(ReplicatedStorage:WaitForChild("Utilities"))

local EnvironmentBuilder = {}
EnvironmentBuilder._partCount = 0

---------------------------------------------------------------------------
-- MASTER BUILD
---------------------------------------------------------------------------

--- Build the entire environment. Returns total part count.
function EnvironmentBuilder:buildAll(): number
    self._partCount = 0

    -- Create top-level folders in Workspace
    local envFolder = Instance.new("Folder")
    envFolder.Name = "Environment"
    envFolder.Parent = workspace

    self._folder = envFolder

    -- Build in order
    self:_buildSkyAndLighting()
    self:_buildTerrain()
    self:_buildBaseplate()
    self:_buildMountains()
    self:_buildRoads()
    self:_buildPalmTrees()
    self:_buildDecorations()
    self:_buildSpawnPoint()

    print("[EnvironmentBuilder] Build complete — " ..
          self._partCount .. " parts used")
    return self._partCount
end

---------------------------------------------------------------------------
-- SKY & LIGHTING  (LOCKED — bright blue daytime)
---------------------------------------------------------------------------

function EnvironmentBuilder:_buildSkyAndLighting()
    local cfg = GameConfig.Lighting

    -- Core Lighting properties
    Lighting.ClockTime           = cfg.ClockTime
    Lighting.Brightness          = cfg.Brightness
    Lighting.GeographicLatitude  = cfg.GeographicLatitude
    Lighting.Ambient             = cfg.Ambient
    Lighting.OutdoorAmbient      = cfg.OutdoorAmbient
    Lighting.ColorShift_Top      = cfg.ColorShift_Top
    Lighting.ColorShift_Bottom   = cfg.ColorShift_Bottom
    Lighting.GlobalShadows       = cfg.GlobalShadows
    Lighting.ShadowSoftness      = cfg.ShadowSoftness

    -- Technology (use pcall as some versions don't support all values)
    pcall(function()
        Lighting.Technology = cfg.Technology
    end)

    -- Atmosphere
    local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
    if not atmo then
        atmo = Instance.new("Atmosphere")
        atmo.Parent = Lighting
    end
    atmo.Density = cfg.Atmosphere.Density
    atmo.Offset  = cfg.Atmosphere.Offset
    atmo.Color   = cfg.Atmosphere.Color
    atmo.Decay   = cfg.Atmosphere.Decay
    atmo.Glare   = cfg.Atmosphere.Glare
    atmo.Haze    = cfg.Atmosphere.Haze

    -- Sky object (bright blue with default sun)
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if not sky then
        sky = Instance.new("Sky")
        sky.Parent = Lighting
    end
    sky.CelestialBodiesShown = true
    sky.SunAngularSize       = 15
    sky.MoonAngularSize      = 8

    -- Bloom for soft midday glow
    local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
    if not bloom then
        bloom = Instance.new("BloomEffect")
        bloom.Parent = Lighting
    end
    bloom.Intensity = 0.3
    bloom.Size      = 24
    bloom.Threshold = 0.9

    -- Sun rays for that desert feel
    local sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect")
    if not sunRays then
        sunRays = Instance.new("SunRaysEffect")
        sunRays.Parent = Lighting
    end
    sunRays.Intensity = 0.05
    sunRays.Spread    = 0.8

    print("[EnvironmentBuilder] Sky & lighting configured (bright blue daytime)")
end

---------------------------------------------------------------------------
-- TERRAIN  (Sand material flat desert floor)
---------------------------------------------------------------------------

function EnvironmentBuilder:_buildTerrain()
    local terrain = workspace.Terrain
    terrain:Clear()

    local size   = GameConfig.World.TerrainSize
    local center = GameConfig.World.TerrainCenter

    -- Fill a flat region with Sand material
    local region = Region3.new(
        center - size / 2,
        center + size / 2
    )

    -- Align to terrain grid (4-stud voxels)
    region = region:ExpandToGrid(4)

    terrain:FillRegion(region, 4, Enum.Material.Sand)

    print("[EnvironmentBuilder] Terrain filled (sand, " ..
          tostring(size.X) .. "x" .. tostring(size.Z) .. " studs)")
end

---------------------------------------------------------------------------
-- BASEPLATE  (thin concrete slab under the developed area)
---------------------------------------------------------------------------

function EnvironmentBuilder:_buildBaseplate()
    local colors = GameConfig.Colors

    -- Thin ground slab to ensure smooth walk surface over terrain
    local base = Utilities.createPart({
        Name = "DesertBase",
        Size = Vector3.new(300, 0.5, 300),
        CFrame = CFrame.new(0, -0.25, 0),
        Color = colors.DesertSand,
        Material = Enum.Material.Sand,
        Tag = "Environment",
        Parent = self._folder,
    })
    self._partCount += 1
end

---------------------------------------------------------------------------
-- MOUNTAINS  (distant low-poly backdrop)
---------------------------------------------------------------------------

function EnvironmentBuilder:_buildMountains()
    local colors = GameConfig.Colors
    local dist   = GameConfig.World.MountainDistance
    local height = GameConfig.World.MountainHeight

    -- Mountain peak definitions: { xOffset, zOffset, width, height, depth }
    local peaks = {
        -- North range (San Jacinto-inspired)
        { x = -120, z = -dist, w = 80, h = height,      d = 40 },
        { x = -40,  z = -dist, w = 60, h = height * 0.8, d = 35 },
        { x = 40,   z = -dist, w = 70, h = height * 0.9, d = 38 },
        { x = 120,  z = -dist, w = 80, h = height * 0.7, d = 30 },
        -- East range
        { x = dist,  z = -60, w = 40, h = height * 0.6, d = 70 },
        { x = dist,  z = 40,  w = 40, h = height * 0.5, d = 60 },
        -- West range
        { x = -dist, z = -60, w = 40, h = height * 0.5, d = 70 },
        { x = -dist, z = 40,  w = 40, h = height * 0.6, d = 60 },
        -- South range (lower foothills)
        { x = -80, z = dist, w = 60, h = height * 0.4, d = 30 },
        { x = 0,   z = dist, w = 70, h = height * 0.5, d = 35 },
        { x = 80,  z = dist, w = 60, h = height * 0.4, d = 30 },
    }

    for i, peak in ipairs(peaks) do
        -- Base block
        local base = Utilities.createPart({
            Name = "Mountain_" .. i,
            Size = Vector3.new(peak.w, peak.h * 0.6, peak.d),
            CFrame = CFrame.new(peak.x, peak.h * 0.3, peak.z),
            Color = colors.MountainPurple,
            Material = Enum.Material.Rock,
            Tag = "Environment",
            Parent = self._folder,
        })
        self._partCount += 1

        -- Wedge peak on top
        local wedge = Utilities.createWedge({
            Name = "MountainPeak_" .. i,
            Size = Vector3.new(peak.w * 0.8, peak.h * 0.5, peak.d * 0.8),
            CFrame = CFrame.new(peak.x, peak.h * 0.6 + peak.h * 0.25, peak.z)
                     * CFrame.Angles(0, math.rad(math.random(-15, 15)), 0),
            Color = Utilities.lerpColor(colors.MountainPurple, Color3.fromRGB(180, 170, 190), 0.3),
            Material = Enum.Material.Rock,
            Parent = self._folder,
        })
        self._partCount += 1
    end

    print("[EnvironmentBuilder] Mountains built (" .. #peaks * 2 .. " parts)")
end

---------------------------------------------------------------------------
-- ROADS  (El Paseo boulevard + residential side streets)
---------------------------------------------------------------------------

function EnvironmentBuilder:_buildRoads()
    local colors = GameConfig.Colors
    local world  = GameConfig.World

    -- El Paseo main boulevard (runs along Z axis)
    local boulevardLength = (world.ElPaseoEnd - world.ElPaseoStart).Magnitude + 40
    local roadCenter = (world.ElPaseoStart + world.ElPaseoEnd) / 2

    -- Main road surface
    Utilities.createPart({
        Name = "ElPaseo_Road",
        Size = Vector3.new(world.ElPaseoWidth, 0.3, boulevardLength),
        CFrame = CFrame.new(roadCenter.X, 0.15, roadCenter.Z),
        Color = colors.Asphalt,
        Material = Enum.Material.Asphalt,
        Tag = "Road",
        Parent = self._folder,
    })
    self._partCount += 1

    -- Center dividing line
    Utilities.createPart({
        Name = "ElPaseo_CenterLine",
        Size = Vector3.new(0.3, 0.31, boulevardLength),
        CFrame = CFrame.new(roadCenter.X, 0.16, roadCenter.Z),
        Color = Color3.fromRGB(255, 220, 50),
        Material = Enum.Material.SmoothPlastic,
        Tag = "Road",
        Parent = self._folder,
    })
    self._partCount += 1

    -- East sidewalk
    Utilities.createPart({
        Name = "ElPaseo_SidewalkE",
        Size = Vector3.new(world.SidewalkWidth, 0.25, boulevardLength),
        CFrame = CFrame.new(
            roadCenter.X + world.ElPaseoWidth / 2 + world.SidewalkWidth / 2,
            0.125, roadCenter.Z
        ),
        Color = colors.Sidewalk,
        Material = Enum.Material.Concrete,
        Tag = "Road",
        Parent = self._folder,
    })
    self._partCount += 1

    -- West sidewalk
    Utilities.createPart({
        Name = "ElPaseo_SidewalkW",
        Size = Vector3.new(world.SidewalkWidth, 0.25, boulevardLength),
        CFrame = CFrame.new(
            roadCenter.X - world.ElPaseoWidth / 2 - world.SidewalkWidth / 2,
            0.125, roadCenter.Z
        ),
        Color = colors.Sidewalk,
        Material = Enum.Material.Concrete,
        Tag = "Road",
        Parent = self._folder,
    })
    self._partCount += 1

    -- Residential side streets connecting plots to El Paseo
    local sideStreetWidth = 8
    for i, plotPos in pairs(world.PlotPositions) do
        local dir = plotPos.X > 0 and 1 or -1
        local streetLength = math.abs(plotPos.X) - world.ElPaseoWidth / 2 - world.SidewalkWidth
        local streetX = plotPos.X - dir * streetLength / 2

        Utilities.createPart({
            Name = "SideStreet_" .. i,
            Size = Vector3.new(streetLength, 0.3, sideStreetWidth),
            CFrame = CFrame.new(streetX, 0.15, plotPos.Z),
            Color = colors.Asphalt,
            Material = Enum.Material.Asphalt,
            Tag = "Road",
            Parent = self._folder,
        })
        self._partCount += 1

        -- Sidewalk along side street
        Utilities.createPart({
            Name = "SideStreetSidewalk_" .. i,
            Size = Vector3.new(streetLength, 0.25, 3),
            CFrame = CFrame.new(streetX, 0.125, plotPos.Z + sideStreetWidth / 2 + 1.5),
            Color = colors.Sidewalk,
            Material = Enum.Material.Concrete,
            Tag = "Road",
            Parent = self._folder,
        })
        self._partCount += 1
    end

    print("[EnvironmentBuilder] Roads built")
end

---------------------------------------------------------------------------
-- PALM TREES  (~20 trees along El Paseo and residential areas)
---------------------------------------------------------------------------

function EnvironmentBuilder:_buildPalmTrees()
    local colors = GameConfig.Colors
    local world  = GameConfig.World

    --- Build a single palm tree at a position.
    local function buildTree(pos: Vector3, height: number)
        local treeModel = Instance.new("Model")
        treeModel.Name = "PalmTree"

        -- Trunk (cylinder)
        local trunk = Utilities.createPart({
            Name = "Trunk",
            Size = Vector3.new(1.5, height, 1.5),
            CFrame = CFrame.new(pos.X, pos.Y + height / 2, pos.Z),
            Color = colors.PalmTrunk,
            Material = Enum.Material.Wood,
            Shape = Enum.PartType.Cylinder,
        })
        -- Rotate cylinder to stand vertical
        trunk.CFrame = CFrame.new(pos.X, pos.Y + height / 2, pos.Z) *
                        CFrame.Angles(0, 0, math.rad(90))
        trunk.Parent = treeModel
        self._partCount += 1

        -- Canopy (cluster of 3 elongated parts for fronds)
        for j = 1, 3 do
            local angle = math.rad(120 * (j - 1) + math.random(-15, 15))
            local frond = Utilities.createPart({
                Name = "Frond_" .. j,
                Size = Vector3.new(6, 0.5, 2),
                CFrame = CFrame.new(
                    pos.X + math.cos(angle) * 2,
                    pos.Y + height - 0.5,
                    pos.Z + math.sin(angle) * 2
                ) * CFrame.Angles(
                    math.rad(-20 + math.random(-5, 5)),
                    angle,
                    0
                ),
                Color = colors.PalmCanopy,
                Material = Enum.Material.Grass,
            })
            frond.Parent = treeModel
            self._partCount += 1
        end

        treeModel.PrimaryPart = trunk
        CollectionService:AddTag(treeModel, "PalmTree")
        treeModel.Parent = self._folder
    end

    -- El Paseo boulevard trees (both sides, spaced every 30 studs)
    local startZ = world.ElPaseoStart.Z + 10
    local endZ   = world.ElPaseoEnd.Z - 10
    local spacing = 30

    for z = startZ, endZ, spacing do
        -- East side
        buildTree(
            Vector3.new(world.ElPaseoWidth / 2 + world.SidewalkWidth + 1, 0, z),
            Utilities.randomInRange(14, 18)
        )
        -- West side
        buildTree(
            Vector3.new(-world.ElPaseoWidth / 2 - world.SidewalkWidth - 1, 0, z),
            Utilities.randomInRange(14, 18)
        )
    end

    -- Scatter a few trees near residential plots
    for _, plotPos in pairs(world.PlotPositions) do
        for _ = 1, 2 do
            buildTree(
                Vector3.new(
                    plotPos.X + Utilities.randomInRange(-25, 25),
                    0,
                    plotPos.Z + Utilities.randomInRange(-25, 25)
                ),
                Utilities.randomInRange(12, 16)
            )
        end
    end

    print("[EnvironmentBuilder] Palm trees built")
end

---------------------------------------------------------------------------
-- DESERT DECORATIONS  (rocks, small cacti, scrub)
---------------------------------------------------------------------------

function EnvironmentBuilder:_buildDecorations()
    local colors = GameConfig.Colors

    -- Rock formations at various positions
    local rockPositions = {
        Vector3.new(-130, 0, -40),
        Vector3.new(130, 0, 50),
        Vector3.new(-100, 0, 100),
        Vector3.new(100, 0, -110),
        Vector3.new(0, 0, 130),
        Vector3.new(-50, 0, -130),
    }

    for i, pos in ipairs(rockPositions) do
        -- Main rock
        local rock = Utilities.createPart({
            Name = "Rock_" .. i,
            Size = Vector3.new(
                Utilities.randomInRange(4, 8),
                Utilities.randomInRange(2, 5),
                Utilities.randomInRange(4, 8)
            ),
            CFrame = CFrame.new(pos.X, pos.Y + 1, pos.Z) *
                     CFrame.Angles(
                         math.rad(Utilities.randomInRange(-10, 10)),
                         math.rad(Utilities.randomInRange(0, 360)),
                         math.rad(Utilities.randomInRange(-10, 10))
                     ),
            Color = Color3.fromRGB(
                160 + math.random(0, 30),
                140 + math.random(0, 20),
                120 + math.random(0, 20)
            ),
            Material = Enum.Material.Rock,
            Tag = "Decoration",
            Parent = self._folder,
        })
        self._partCount += 1

        -- Smaller companion rock
        local small = Utilities.createPart({
            Name = "SmallRock_" .. i,
            Size = Vector3.new(
                Utilities.randomInRange(1, 3),
                Utilities.randomInRange(1, 2),
                Utilities.randomInRange(1, 3)
            ),
            CFrame = CFrame.new(
                pos.X + Utilities.randomInRange(-3, 3),
                pos.Y + 0.5,
                pos.Z + Utilities.randomInRange(-3, 3)
            ),
            Color = Color3.fromRGB(170, 150, 130),
            Material = Enum.Material.Rock,
            Tag = "Decoration",
            Parent = self._folder,
        })
        self._partCount += 1
    end

    -- Small cacti scatter (simple green cylinders)
    local cactiCount = 15
    for i = 1, cactiCount do
        local angle = math.rad(Utilities.randomInRange(0, 360))
        local dist  = Utilities.randomInRange(50, 140)
        local cx = math.cos(angle) * dist
        local cz = math.sin(angle) * dist

        -- Skip if too close to roads/buildings
        if math.abs(cx) > 15 or math.abs(cz) > 15 then
            local cactus = Utilities.createPart({
                Name = "Cactus_" .. i,
                Size = Vector3.new(
                    Utilities.randomInRange(0.5, 1.5),
                    Utilities.randomInRange(2, 5),
                    Utilities.randomInRange(0.5, 1.5)
                ),
                CFrame = CFrame.new(cx, Utilities.randomInRange(1, 2.5), cz),
                Color = colors.CactusGreen,
                Material = Enum.Material.Grass,
                Shape = Enum.PartType.Cylinder,
                Tag = "Decoration",
                Parent = self._folder,
            })
            -- Stand the cylinder upright
            cactus.CFrame = CFrame.new(cx, cactus.Size.X / 2, cz) *
                            CFrame.Angles(0, 0, math.rad(90))
            self._partCount += 1
        end
    end

    -- Low desert scrub (flat green wedges scattered around)
    for i = 1, 10 do
        local angle = math.rad(Utilities.randomInRange(0, 360))
        local dist  = Utilities.randomInRange(60, 130)
        local sx = math.cos(angle) * dist
        local sz = math.sin(angle) * dist

        if math.abs(sx) > 20 or math.abs(sz) > 20 then
            Utilities.createPart({
                Name = "Scrub_" .. i,
                Size = Vector3.new(
                    Utilities.randomInRange(2, 4),
                    Utilities.randomInRange(0.5, 1.5),
                    Utilities.randomInRange(2, 4)
                ),
                CFrame = CFrame.new(sx, 0.5, sz) *
                         CFrame.Angles(0, math.rad(math.random(0, 360)), 0),
                Color = Color3.fromRGB(
                    80 + math.random(0, 20),
                    120 + math.random(0, 30),
                    70 + math.random(0, 20)
                ),
                Material = Enum.Material.Grass,
                Tag = "Decoration",
                Parent = self._folder,
            })
            self._partCount += 1
        end
    end

    print("[EnvironmentBuilder] Decorations placed")
end

---------------------------------------------------------------------------
-- SPAWN POINT
---------------------------------------------------------------------------

function EnvironmentBuilder:_buildSpawnPoint()
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "MainSpawn"
    spawn.Size = Vector3.new(8, 1, 8)
    spawn.CFrame = CFrame.new(GameConfig.World.SpawnPosition)
    spawn.Anchored = true
    spawn.CanCollide = true
    spawn.Transparency = 1           -- invisible spawn pad
    spawn.TopSurface = Enum.SurfaceType.Smooth
    spawn.BottomSurface = Enum.SurfaceType.Smooth
    spawn.Parent = self._folder
    self._partCount += 1

    print("[EnvironmentBuilder] Spawn point placed at " ..
          tostring(GameConfig.World.SpawnPosition))
end

---------------------------------------------------------------------------
-- ACCESSORS
---------------------------------------------------------------------------

function EnvironmentBuilder:getPartCount(): number
    return self._partCount
end

return EnvironmentBuilder
