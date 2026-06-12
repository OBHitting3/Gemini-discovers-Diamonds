--[[
    WorldService.lua
    Generates and manages the 2048x2048 Palm Springs world.
    - Creates 7 themed zones with boundaries
    - Manages zone detection for players
    - Spawns environmental props (palm trees, cacti, etc.)
    - Sets up desert sunset skybox
    - Handles egg spawn points per zone
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local Constants = require(game.ReplicatedStorage.Modules.Shared.Constants)
local Signal = require(game.ReplicatedStorage.Modules.Shared.Signal)
local Remotes = require(game.ReplicatedStorage.Modules.Shared.Remotes)

local WorldService = {}
WorldService.__index = WorldService

-- ═══════════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════════
local zones = {} -- { [zoneName] = { Part, Data, EggSpawns } }
local playerZones = {} -- { [userId] = currentZoneName }
local eggSpawnPoints = {} -- { [zoneName] = { Vector3, ... } }

WorldService.PlayerZoneChanged = Signal.new()

-- ═══════════════════════════════════════════════════════════════
-- TERRAIN / SKYBOX
-- ═══════════════════════════════════════════════════════════════

local function setupSkybox()
    -- Desert sunset atmosphere
    local atmosphere = Instance.new("Atmosphere")
    atmosphere.Density = 0.3
    atmosphere.Offset = 0.25
    atmosphere.Color = Color3.fromRGB(255, 200, 150)
    atmosphere.Decay = Color3.fromRGB(255, 150, 100)
    atmosphere.Glare = 0.5
    atmosphere.Haze = 2
    atmosphere.Parent = Lighting

    -- Warm sunset lighting
    Lighting.ClockTime = 17.5 -- late afternoon golden hour
    Lighting.GeographicLatitude = 33.83 -- Palm Springs latitude
    Lighting.Ambient = Color3.fromRGB(80, 60, 40)
    Lighting.OutdoorAmbient = Color3.fromRGB(120, 90, 60)
    Lighting.Brightness = 2.5
    Lighting.ColorShift_Bottom = Color3.fromRGB(200, 130, 80)
    Lighting.ColorShift_Top = Color3.fromRGB(255, 200, 150)

    -- Bloom for warm glow
    local bloom = Instance.new("BloomEffect")
    bloom.Intensity = 0.4
    bloom.Size = 24
    bloom.Threshold = 1.2
    bloom.Parent = Lighting

    -- Color correction for warm desert tones
    local colorCorrection = Instance.new("ColorCorrectionEffect")
    colorCorrection.Brightness = 0.02
    colorCorrection.Contrast = 0.1
    colorCorrection.Saturation = 0.15
    colorCorrection.TintColor = Color3.fromRGB(255, 240, 220)
    colorCorrection.Parent = Lighting

    -- Sun rays
    local sunRays = Instance.new("SunRaysEffect")
    sunRays.Intensity = 0.12
    sunRays.Spread = 0.8
    sunRays.Parent = Lighting
end

-- ═══════════════════════════════════════════════════════════════
-- WORLD GENERATION
-- ═══════════════════════════════════════════════════════════════

local function createBaseTerrain()
    local workspace = game.Workspace

    -- Main ground plane
    local ground = Instance.new("Part")
    ground.Name = "DesertGround"
    ground.Size = Vector3.new(Constants.WORLD_SIZE, 4, Constants.WORLD_SIZE)
    ground.Position = Vector3.new(0, -2, 0)
    ground.Anchored = true
    ground.Material = Enum.Material.Sand
    ground.Color = Color3.fromRGB(210, 180, 140)
    ground.Parent = workspace

    -- Invisible world boundaries
    local wallHeight = 100
    local wallThickness = 10
    local half = Constants.WORLD_SIZE / 2

    local wallPositions = {
        { Vector3.new(half + wallThickness / 2, wallHeight / 2, 0), Vector3.new(wallThickness, wallHeight, Constants.WORLD_SIZE) },
        { Vector3.new(-half - wallThickness / 2, wallHeight / 2, 0), Vector3.new(wallThickness, wallHeight, Constants.WORLD_SIZE) },
        { Vector3.new(0, wallHeight / 2, half + wallThickness / 2), Vector3.new(Constants.WORLD_SIZE, wallHeight, wallThickness) },
        { Vector3.new(0, wallHeight / 2, -half - wallThickness / 2), Vector3.new(Constants.WORLD_SIZE, wallHeight, wallThickness) },
    }

    for i, wallData in wallPositions do
        local wall = Instance.new("Part")
        wall.Name = "WorldBoundary_" .. i
        wall.Position = wallData[1]
        wall.Size = wallData[2]
        wall.Anchored = true
        wall.Transparency = 1
        wall.CanCollide = true
        wall.Parent = workspace
    end
end

local function createZone(zoneName: string, zoneData: table)
    local workspace = game.Workspace

    -- Zone folder
    local zoneFolder = Instance.new("Folder")
    zoneFolder.Name = zoneName
    zoneFolder.Parent = workspace:FindFirstChild("Zones") or (function()
        local f = Instance.new("Folder")
        f.Name = "Zones"
        f.Parent = workspace
        return f
    end)()

    -- Zone boundary (invisible, used for detection)
    local boundary = Instance.new("Part")
    boundary.Name = "ZoneBoundary"
    boundary.Shape = Enum.PartType.Cylinder
    boundary.Size = Vector3.new(4, zoneData.Radius * 2, zoneData.Radius * 2)
    boundary.CFrame = CFrame.new(zoneData.Center) * CFrame.Angles(0, 0, math.rad(90))
    boundary.Anchored = true
    boundary.Transparency = 1
    boundary.CanCollide = false
    boundary.Parent = zoneFolder

    -- Zone ground coloring (visual indicator)
    local zoneGround = Instance.new("Part")
    zoneGround.Name = "ZoneGround"
    zoneGround.Size = Vector3.new(zoneData.Radius * 2, 0.5, zoneData.Radius * 2)
    zoneGround.Position = zoneData.Center + Vector3.new(0, 0.1, 0)
    zoneGround.Anchored = true
    zoneGround.Material = Enum.Material.Sand
    zoneGround.Transparency = 0.7
    zoneGround.CanCollide = false
    zoneGround.Parent = zoneFolder

    -- Zone sign
    local sign = Instance.new("Part")
    sign.Name = "ZoneSign"
    sign.Size = Vector3.new(12, 6, 1)
    sign.Position = zoneData.Center + Vector3.new(0, 8, -zoneData.Radius + 10)
    sign.Anchored = true
    sign.Material = Enum.Material.SmoothPlastic
    sign.Color = Color3.fromRGB(45, 45, 45)
    sign.Parent = zoneFolder

    local signGui = Instance.new("SurfaceGui")
    signGui.Face = Enum.NormalId.Front
    signGui.Parent = sign

    local signLabel = Instance.new("TextLabel")
    signLabel.Size = UDim2.new(1, 0, 1, 0)
    signLabel.BackgroundTransparency = 1
    signLabel.Text = zoneData.DisplayName
    signLabel.TextColor3 = Color3.fromRGB(255, 220, 150)
    signLabel.TextScaled = true
    signLabel.Font = Enum.Font.GothamBold
    signLabel.Parent = signGui

    -- Spawn point (for spawn zone)
    if zoneData.SpawnZone then
        local spawn = Instance.new("SpawnLocation")
        spawn.Name = "MainSpawn"
        spawn.Size = Vector3.new(20, 1, 20)
        spawn.Position = zoneData.Center + Vector3.new(0, 0.5, 0)
        spawn.Anchored = true
        spawn.Material = Enum.Material.SmoothPlastic
        spawn.Color = Color3.fromRGB(220, 180, 120)
        spawn.TeamColor = BrickColor.new("Sand red")
        spawn.Parent = zoneFolder
    end

    -- Store zone reference
    zones[zoneName] = {
        Folder = zoneFolder,
        Data = zoneData,
        Boundary = boundary,
        EggSpawns = {},
    }

    return zoneFolder
end

local function createPalmTree(position: Vector3, parent: Instance)
    local trunk = Instance.new("Part")
    trunk.Name = "PalmTrunk"
    trunk.Size = Vector3.new(2, 20, 2)
    trunk.Position = position + Vector3.new(0, 10, 0)
    trunk.Anchored = true
    trunk.Material = Enum.Material.Wood
    trunk.Color = Color3.fromRGB(139, 90, 43)
    trunk.Shape = Enum.PartType.Cylinder
    trunk.CFrame = CFrame.new(position + Vector3.new(0, 10, 0)) * CFrame.Angles(0, 0, math.rad(90))
    trunk.Parent = parent

    -- Simple leaf canopy
    local canopy = Instance.new("Part")
    canopy.Name = "PalmCanopy"
    canopy.Size = Vector3.new(12, 4, 12)
    canopy.Position = position + Vector3.new(0, 21, 0)
    canopy.Anchored = true
    canopy.Material = Enum.Material.Grass
    canopy.Color = Color3.fromRGB(34, 120, 50)
    canopy.Shape = Enum.PartType.Ball
    canopy.Parent = parent
end

local function createCactus(position: Vector3, parent: Instance)
    local body = Instance.new("Part")
    body.Name = "Cactus"
    body.Size = Vector3.new(2, math.random(4, 8), 2)
    body.Position = position + Vector3.new(0, body.Size.Y / 2, 0)
    body.Anchored = true
    body.Material = Enum.Material.SmoothPlastic
    body.Color = Color3.fromRGB(50, 130, 50)
    body.Parent = parent

    -- Arms (random)
    if math.random() > 0.4 then
        local arm = Instance.new("Part")
        arm.Name = "CactusArm"
        arm.Size = Vector3.new(1.5, 4, 1.5)
        arm.Position = position + Vector3.new(2, body.Size.Y * 0.6, 0)
        arm.Anchored = true
        arm.Material = Enum.Material.SmoothPlastic
        arm.Color = Color3.fromRGB(50, 130, 50)
        arm.Parent = parent
    end
end

local function populateZoneProps(zoneName: string, zoneData: table)
    local folder = zones[zoneName].Folder
    local propsFolder = Instance.new("Folder")
    propsFolder.Name = "Props"
    propsFolder.Parent = folder

    local center = zoneData.Center
    local radius = zoneData.Radius

    -- Scatter palm trees
    local palmCount = math.floor(radius / 20)
    for _ = 1, palmCount do
        local angle = math.random() * math.pi * 2
        local dist = math.random() * radius * 0.8
        local pos = center + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
        createPalmTree(pos, propsFolder)
    end

    -- Scatter cacti
    local cactusCount = math.floor(radius / 15)
    for _ = 1, cactusCount do
        local angle = math.random() * math.pi * 2
        local dist = math.random() * radius * 0.9
        local pos = center + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
        createCactus(pos, propsFolder)
    end
end

local function createEggSpawnPoints(zoneName: string, zoneData: table)
    local folder = zones[zoneName].Folder
    local eggsFolder = Instance.new("Folder")
    eggsFolder.Name = "EggSpawns"
    eggsFolder.Parent = folder

    local center = zoneData.Center
    local radius = zoneData.Radius

    -- Number of egg spawn points per zone
    local spawnCount = math.floor(radius / 30)

    local spawnPoints = {}
    for i = 1, spawnCount do
        local angle = (i / spawnCount) * math.pi * 2
        local dist = radius * 0.5 + math.random() * radius * 0.3
        local pos = center + Vector3.new(math.cos(angle) * dist, 1, math.sin(angle) * dist)

        local spawnPart = Instance.new("Part")
        spawnPart.Name = "EggSpawn_" .. i
        spawnPart.Size = Vector3.new(4, 0.5, 4)
        spawnPart.Position = pos
        spawnPart.Anchored = true
        spawnPart.Material = Enum.Material.Neon
        spawnPart.Color = Color3.fromRGB(255, 200, 100)
        spawnPart.Transparency = 0.5
        spawnPart.CanCollide = false
        spawnPart.Parent = eggsFolder

        table.insert(spawnPoints, pos)
    end

    zones[zoneName].EggSpawns = spawnPoints
    eggSpawnPoints[zoneName] = spawnPoints
end

-- ═══════════════════════════════════════════════════════════════
-- ZONE-SPECIFIC BUILDS
-- ═══════════════════════════════════════════════════════════════

local function buildDowntown(folder)
    -- Trade Hub building
    local tradeHub = Instance.new("Part")
    tradeHub.Name = "TradeHub"
    tradeHub.Size = Vector3.new(40, 16, 40)
    tradeHub.Position = Vector3.new(30, 8, 30)
    tradeHub.Anchored = true
    tradeHub.Material = Enum.Material.SmoothPlastic
    tradeHub.Color = Color3.fromRGB(220, 200, 170)
    tradeHub.Parent = folder

    -- Shop stands
    for i = 1, 4 do
        local shop = Instance.new("Part")
        shop.Name = "Shop_" .. i
        shop.Size = Vector3.new(8, 8, 8)
        shop.Position = Vector3.new(-40 + (i * 20), 4, -20)
        shop.Anchored = true
        shop.Material = Enum.Material.SmoothPlastic
        shop.Color = Color3.fromRGB(200, 160, 120)
        shop.Parent = folder
    end

    -- Leaderboard pedestals
    for i = 1, 3 do
        local pedestal = Instance.new("Part")
        pedestal.Name = "LeaderboardPedestal_" .. i
        pedestal.Size = Vector3.new(6, 10 - (i * 2), 6)
        pedestal.Position = Vector3.new(60 + (i * 8), (10 - (i * 2)) / 2, 0)
        pedestal.Anchored = true
        pedestal.Material = Enum.Material.Marble
        pedestal.Color = Color3.fromRGB(240, 220, 180)
        pedestal.Parent = folder
    end
end

local function buildHotSprings(folder)
    local center = Constants.ZoneData[Constants.Zones.HOT_SPRINGS].Center

    -- Hot spring pools
    for i = 1, 3 do
        local pool = Instance.new("Part")
        pool.Name = "HotSpring_" .. i
        pool.Shape = Enum.PartType.Cylinder
        pool.Size = Vector3.new(2, 20 + i * 5, 20 + i * 5)
        pool.CFrame = CFrame.new(center + Vector3.new((i - 2) * 35, -0.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
        pool.Anchored = true
        pool.Material = Enum.Material.Water
        pool.Color = Color3.fromRGB(60, 180, 220)
        pool.Transparency = 0.3
        pool.Parent = folder
    end

    -- Hatching altar
    local altar = Instance.new("Part")
    altar.Name = "HatchingAltar"
    altar.Size = Vector3.new(10, 3, 10)
    altar.Position = center + Vector3.new(0, 1.5, 50)
    altar.Anchored = true
    altar.Material = Enum.Material.Marble
    altar.Color = Color3.fromRGB(255, 220, 180)
    altar.Parent = folder
end

local function buildIndianCanyons(folder)
    local center = Constants.ZoneData[Constants.Zones.INDIAN_CANYONS].Center

    -- Canyon walls
    for i = 1, 6 do
        local wall = Instance.new("Part")
        wall.Name = "CanyonWall_" .. i
        wall.Size = Vector3.new(8, math.random(30, 60), math.random(40, 80))
        wall.Position = center + Vector3.new(
            math.cos(i * math.pi / 3) * 100,
            wall.Size.Y / 2,
            math.sin(i * math.pi / 3) * 100
        )
        wall.Anchored = true
        wall.Material = Enum.Material.Sandstone
        wall.Color = Color3.fromRGB(180 + math.random(-20, 20), 130 + math.random(-20, 20), 90)
        wall.Parent = folder
    end

    -- Parkour platforms
    for i = 1, 12 do
        local platform = Instance.new("Part")
        platform.Name = "ParkourPlatform_" .. i
        platform.Size = Vector3.new(6, 2, 6)
        platform.Position = center + Vector3.new(
            math.cos(i * 0.5) * (30 + i * 8),
            4 + i * 5,
            math.sin(i * 0.5) * (30 + i * 8)
        )
        platform.Anchored = true
        platform.Material = Enum.Material.Slate
        platform.Color = Color3.fromRGB(160, 120, 80)
        platform.Parent = folder
    end
end

local function buildWindFarm(folder)
    local center = Constants.ZoneData[Constants.Zones.WIND_FARM].Center

    -- Wind turbines
    for i = 1, 8 do
        local base = Instance.new("Part")
        base.Name = "Turbine_" .. i
        base.Size = Vector3.new(4, 50, 4)
        local angle = (i / 8) * math.pi * 2
        base.Position = center + Vector3.new(math.cos(angle) * 120, 25, math.sin(angle) * 120)
        base.Anchored = true
        base.Material = Enum.Material.Metal
        base.Color = Color3.fromRGB(230, 230, 230)
        base.Parent = folder

        -- Turbine nacelle
        local nacelle = Instance.new("Part")
        nacelle.Name = "Nacelle_" .. i
        nacelle.Size = Vector3.new(6, 4, 4)
        nacelle.Position = base.Position + Vector3.new(0, 27, 0)
        nacelle.Anchored = true
        nacelle.Material = Enum.Material.Metal
        nacelle.Color = Color3.fromRGB(240, 240, 240)
        nacelle.Parent = folder
    end

    -- Speed boost pads
    for i = 1, 4 do
        local pad = Instance.new("Part")
        pad.Name = "SpeedBoost_" .. i
        pad.Size = Vector3.new(10, 0.5, 10)
        local angle = (i / 4) * math.pi * 2
        pad.Position = center + Vector3.new(math.cos(angle) * 60, 0.25, math.sin(angle) * 60)
        pad.Anchored = true
        pad.Material = Enum.Material.Neon
        pad.Color = Color3.fromRGB(0, 200, 255)
        pad.Transparency = 0.3
        pad.Parent = folder
    end
end

local function buildTramwaySummit(folder)
    local center = Constants.ZoneData[Constants.Zones.TRAMWAY_SUMMIT].Center

    -- Mountain base
    local mountain = Instance.new("Part")
    mountain.Name = "Mountain"
    mountain.Size = Vector3.new(200, 200, 200)
    mountain.Position = center + Vector3.new(0, -10, 0)
    mountain.Anchored = true
    mountain.Material = Enum.Material.Rock
    mountain.Color = Color3.fromRGB(140, 120, 100)
    mountain.Shape = Enum.PartType.Ball
    mountain.Parent = folder

    -- Summit platform
    local summit = Instance.new("Part")
    summit.Name = "SummitPlatform"
    summit.Size = Vector3.new(60, 2, 60)
    summit.Position = center + Vector3.new(0, 200, 0)
    summit.Anchored = true
    summit.Material = Enum.Material.Slate
    summit.Color = Color3.fromRGB(160, 140, 120)
    summit.Parent = folder

    -- Tram cable (visual)
    local cable = Instance.new("Part")
    cable.Name = "TramCable"
    cable.Size = Vector3.new(2, 2, 300)
    cable.CFrame = CFrame.lookAt(center + Vector3.new(0, 100, 0), center + Vector3.new(0, 200, -150))
    cable.Anchored = true
    cable.Material = Enum.Material.Metal
    cable.Color = Color3.fromRGB(100, 100, 100)
    cable.Parent = folder

    -- VIP zone marker
    local vipZone = Instance.new("Part")
    vipZone.Name = "VIPZone"
    vipZone.Size = Vector3.new(30, 1, 30)
    vipZone.Position = center + Vector3.new(0, 201, 20)
    vipZone.Anchored = true
    vipZone.Material = Enum.Material.Neon
    vipZone.Color = Color3.fromRGB(255, 215, 0)
    vipZone.Transparency = 0.5
    vipZone.Parent = folder
end

local function buildNeighborhood(folder)
    -- Plots are generated by PlotService, just create the grid area marker
    local center = Constants.ZoneData[Constants.Zones.NEIGHBORHOOD].Center

    local plotArea = Instance.new("Part")
    plotArea.Name = "PlotAreaMarker"
    plotArea.Size = Vector3.new(400, 0.5, 400) -- big enough for 100 32x32 plots (10x10 grid)
    plotArea.Position = center + Vector3.new(0, 0.1, 0)
    plotArea.Anchored = true
    plotArea.Material = Enum.Material.Concrete
    plotArea.Color = Color3.fromRGB(190, 170, 140)
    plotArea.Transparency = 0.3
    plotArea.CanCollide = false
    plotArea.Parent = folder
end

local function buildFairgrounds(folder)
    local center = Constants.ZoneData[Constants.Zones.FAIRGROUNDS].Center

    -- Main stage
    local stage = Instance.new("Part")
    stage.Name = "MainStage"
    stage.Size = Vector3.new(60, 12, 30)
    stage.Position = center + Vector3.new(0, 6, 0)
    stage.Anchored = true
    stage.Material = Enum.Material.SmoothPlastic
    stage.Color = Color3.fromRGB(40, 40, 40)
    stage.Parent = folder

    -- Ferris wheel center
    local ferrisCenter = Instance.new("Part")
    ferrisCenter.Name = "FerrisWheelHub"
    ferrisCenter.Shape = Enum.PartType.Cylinder
    ferrisCenter.Size = Vector3.new(4, 80, 80)
    ferrisCenter.CFrame = CFrame.new(center + Vector3.new(80, 40, -60)) * CFrame.Angles(0, 0, math.rad(90))
    ferrisCenter.Anchored = true
    ferrisCenter.Material = Enum.Material.Metal
    ferrisCenter.Color = Color3.fromRGB(255, 100, 100)
    ferrisCenter.Parent = folder

    -- Event tents
    for i = 1, 5 do
        local tent = Instance.new("Part")
        tent.Name = "EventTent_" .. i
        tent.Size = Vector3.new(20, 15, 20)
        tent.Position = center + Vector3.new(-60 + (i * 25), 7.5, 60)
        tent.Anchored = true
        tent.Material = Enum.Material.Fabric
        tent.Color = Color3.fromRGB(
            math.random(150, 255),
            math.random(100, 200),
            math.random(100, 200)
        )
        tent.Parent = folder
    end
end

-- Zone builders lookup
local ZONE_BUILDERS = {
    [Constants.Zones.DOWNTOWN] = buildDowntown,
    [Constants.Zones.HOT_SPRINGS] = buildHotSprings,
    [Constants.Zones.INDIAN_CANYONS] = buildIndianCanyons,
    [Constants.Zones.WIND_FARM] = buildWindFarm,
    [Constants.Zones.TRAMWAY_SUMMIT] = buildTramwaySummit,
    [Constants.Zones.NEIGHBORHOOD] = buildNeighborhood,
    [Constants.Zones.FAIRGROUNDS] = buildFairgrounds,
}

-- ═══════════════════════════════════════════════════════════════
-- ZONE DETECTION
-- ═══════════════════════════════════════════════════════════════

local function getPlayerZone(position: Vector3): string?
    local closestZone = nil
    local closestDist = math.huge

    for zoneName, zoneInfo in zones do
        local center = zoneInfo.Data.Center
        local radius = zoneInfo.Data.Radius
        local dist = (Vector3.new(position.X, 0, position.Z) - Vector3.new(center.X, 0, center.Z)).Magnitude

        if dist <= radius and dist < closestDist then
            closestDist = dist
            closestZone = zoneName
        end
    end

    return closestZone
end

local function updatePlayerZones()
    for _, player in Players:GetPlayers() do
        local character = player.Character
        if character then
            local root = character:FindFirstChild("HumanoidRootPart")
            if root then
                local newZone = getPlayerZone(root.Position)
                local oldZone = playerZones[player.UserId]

                if newZone ~= oldZone then
                    playerZones[player.UserId] = newZone
                    WorldService.PlayerZoneChanged:Fire(player, newZone, oldZone)
                    Remotes.GetEvent("ZoneEntered"):FireClient(player, newZone)
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════════════════════════════

function WorldService.GetZone(zoneName: string)
    return zones[zoneName]
end

function WorldService.GetPlayerZone(player: Player): string?
    return playerZones[player.UserId]
end

function WorldService.GetEggSpawnPoints(zoneName: string): { Vector3 }
    return eggSpawnPoints[zoneName] or {}
end

function WorldService.GetAllZones()
    return zones
end

-- ═══════════════════════════════════════════════════════════════
-- INIT
-- ═══════════════════════════════════════════════════════════════

function WorldService.Init()
    print("[WorldService] Generating Palm Springs world...")

    setupSkybox()
    createBaseTerrain()

    -- Generate all 7 zones
    for zoneName, zoneData in Constants.ZoneData do
        local folder = createZone(zoneName, zoneData)

        -- Build zone-specific structures
        local builder = ZONE_BUILDERS[zoneName]
        if builder then
            builder(folder)
        end

        -- Add props
        populateZoneProps(zoneName, zoneData)

        -- Create egg spawn points
        createEggSpawnPoints(zoneName, zoneData)

        print(string.format("  [WorldService] Zone '%s' created (%d egg spawns)",
            zoneData.DisplayName, #(zones[zoneName].EggSpawns)))
    end

    -- Zone detection heartbeat (throttled to every 0.5s for performance)
    local zoneCheckAccum = 0
    RunService.Heartbeat:Connect(function(dt)
        zoneCheckAccum += dt
        if zoneCheckAccum >= 0.5 then
            zoneCheckAccum = 0
            updatePlayerZones()
        end
    end)

    -- Cleanup on player leave
    Players.PlayerRemoving:Connect(function(player)
        playerZones[player.UserId] = nil
    end)

    print("[WorldService] World generation complete! " .. tostring(Constants.WORLD_SIZE) .. "x" .. tostring(Constants.WORLD_SIZE) .. " studs")
end

return WorldService
