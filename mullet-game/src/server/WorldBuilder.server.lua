--[[
    WorldBuilder.server.lua
    Builds the visual world on server startup:
      1. Colorful sky and lighting
      2. The Giant Jar (center of map, glows and fills visually)
      3. The Mullet God stage/altar (where he arrives)
      4. Decorative props around the maze area
      5. Spawn pads for players
    
    Hair visuals and Mullet God model are handled here too.
]]

local TweenService  = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MulletConfig = require(ReplicatedStorage:WaitForChild("MulletConfig"))

---------------------------------------------------------------------------
-- LIGHTING (fun bright colorful look)
---------------------------------------------------------------------------
local Lighting = game:GetService("Lighting")
Lighting.ClockTime         = 14
Lighting.Brightness        = 3
Lighting.GlobalShadows     = true
Lighting.Ambient           = Color3.fromRGB(100, 80, 140)
Lighting.OutdoorAmbient    = Color3.fromRGB(180, 160, 220)
Lighting.ColorShift_Top    = Color3.fromRGB(255, 220, 180)
Lighting.ColorShift_Bottom = Color3.fromRGB(180, 140, 255)

-- Colorful sky
local sky = Instance.new("Sky")
sky.SkyboxBk = "rbxassetid://6444884337"
sky.SkyboxDn = "rbxassetid://6444884337"
sky.SkyboxFt = "rbxassetid://6444884337"
sky.SkyboxLf = "rbxassetid://6444884337"
sky.SkyboxRt = "rbxassetid://6444884337"
sky.SkyboxUp = "rbxassetid://6444884337"
sky.Parent   = Lighting

-- Bloom effect
local bloom = Instance.new("BloomEffect")
bloom.Intensity = 0.8
bloom.Size      = 24
bloom.Threshold = 0.95
bloom.Parent    = Lighting

-- Color correction — warm and vibrant
local cc = Instance.new("ColorCorrectionEffect")
cc.Brightness  = 0.05
cc.Contrast    = 0.1
cc.Saturation  = 0.3
cc.Parent      = Lighting

---------------------------------------------------------------------------
-- WORLD FOLDER
---------------------------------------------------------------------------
local World = Instance.new("Folder")
World.Name   = "MulletWorld"
World.Parent = workspace

---------------------------------------------------------------------------
-- GROUND PLANE
---------------------------------------------------------------------------
-- Ground — deep purple base
local ground = Instance.new("Part")
ground.Name     = "Ground"
ground.Anchored = true
ground.Size     = Vector3.new(600, 2, 600)
ground.CFrame   = CFrame.new(0, -1, 0)
ground.Color    = Color3.fromRGB(80, 40, 120)   -- deep purple
ground.Material = Enum.Material.SmoothPlastic
ground.TopSurface = Enum.SurfaceType.Smooth
ground.Parent   = World

-- Checkerboard pattern: purple + bright green tiles
for i = -14, 14 do
    for j = -14, 14 do
        local tile = Instance.new("Part")
        tile.Anchored  = true
        tile.Size      = Vector3.new(20, 0.6, 20)
        tile.CFrame    = CFrame.new(i * 20, 0.1, j * 20)
        if (i + j) % 2 == 0 then
            tile.Color    = Color3.fromRGB(60, 180, 80)   -- bright green
        else
            tile.Color    = Color3.fromRGB(100, 50, 160)  -- purple
        end
        tile.Material  = Enum.Material.SmoothPlastic
        tile.TopSurface = Enum.SurfaceType.Smooth
        tile.CanCollide = true
        tile.Parent    = World
    end
end

---------------------------------------------------------------------------
-- THE GIANT JAR (center of map)
---------------------------------------------------------------------------
local jarGroup = Instance.new("Model")
jarGroup.Name   = "GiantJar"
jarGroup.Parent = World

-- Jar base (wide bottom)
local jarBase = Instance.new("Part")
jarBase.Name     = "JarBase"
jarBase.Anchored = true
jarBase.Size     = Vector3.new(10, 2, 10)
jarBase.CFrame   = CFrame.new(0, 1, 0)
jarBase.Color    = Color3.fromRGB(100, 200, 255)
jarBase.Material = Enum.Material.Glass
jarBase.Transparency = 0.3
jarBase.TopSurface = Enum.SurfaceType.Smooth
jarBase.Parent   = jarGroup
Instance.new("UICorner")  -- just for reference

-- Jar body (tall cylinder-ish)
local jarBody = Instance.new("Part")
jarBody.Name     = "JarBody"
jarBody.Anchored = true
jarBody.Size     = Vector3.new(8, 14, 8)
jarBody.CFrame   = CFrame.new(0, 9, 0)
jarBody.Color    = Color3.fromRGB(180, 230, 255)
jarBody.Material = Enum.Material.Glass
jarBody.Transparency = 0.5
jarBody.TopSurface = Enum.SurfaceType.Smooth
jarBody.Parent   = jarGroup

-- Jar neck (narrower top)
local jarNeck = Instance.new("Part")
jarNeck.Name     = "JarNeck"
jarNeck.Anchored = true
jarNeck.Size     = Vector3.new(5, 4, 5)
jarNeck.CFrame   = CFrame.new(0, 18, 0)
jarNeck.Color    = Color3.fromRGB(180, 230, 255)
jarNeck.Material = Enum.Material.Glass
jarNeck.Transparency = 0.4
jarNeck.TopSurface = Enum.SurfaceType.Smooth
jarNeck.Parent   = jarGroup

-- Hair fill visual inside jar (grows as jar fills)
local hairFill = Instance.new("Part")
hairFill.Name        = "HairFill"
hairFill.Anchored    = true
hairFill.Size        = Vector3.new(7, 0.1, 7)
hairFill.CFrame      = CFrame.new(0, 2.1, 0)
hairFill.Color       = Color3.fromRGB(200, 160, 100)
hairFill.Material    = Enum.Material.Neon
hairFill.Transparency = 0.2
hairFill.CanCollide  = false
hairFill.Parent      = jarGroup

-- Glowing rim on top of jar
local jarRim = Instance.new("Part")
jarRim.Name      = "JarRim"
jarRim.Anchored  = true
jarRim.Size      = Vector3.new(6, 1, 6)
jarRim.CFrame    = CFrame.new(0, 21, 0)
jarRim.Color     = Color3.fromRGB(255, 215, 0)
jarRim.Material  = Enum.Material.Neon
jarRim.TopSurface = Enum.SurfaceType.Smooth
jarRim.Parent    = jarGroup

-- Point light inside jar
local jarLight = Instance.new("PointLight")
jarLight.Brightness = 3
jarLight.Color      = Color3.fromRGB(180, 230, 255)
jarLight.Range      = 20
jarLight.Parent     = jarBody

-- Jar label billboard
local jarBillboard = Instance.new("BillboardGui")
jarBillboard.Size        = UDim2.new(0, 200, 0, 50)
jarBillboard.StudsOffset = Vector3.new(0, 12, 0)
jarBillboard.AlwaysOnTop = false
jarBillboard.Parent      = jarBody

local jarLabel = Instance.new("TextLabel")
jarLabel.Size               = UDim2.new(1, 0, 1, 0)
jarLabel.BackgroundTransparency = 1
jarLabel.TextColor3         = Color3.fromRGB(255, 255, 255)
jarLabel.Font               = Enum.Font.GothamBlack
jarLabel.TextScaled         = true
jarLabel.Text               = "🫙 THE GIANT JAR"
jarLabel.TextStrokeTransparency = 0.5
jarLabel.Parent             = jarBillboard

-- Animate jar fill as server broadcasts jar updates
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
local evJarFill = Remotes:WaitForChild("UpdateJarFill", 10)
if evJarFill then
    evJarFill.OnClientEvent:Connect(function(data)
        local pct = data.percent or (data.fill / data.capacity)
        local maxHeight = 13
        local newHeight = math.max(0.1, pct * maxHeight)
        TweenService:Create(hairFill, TweenInfo.new(0.5), {
            Size  = Vector3.new(7, newHeight, 7),
            CFrame = CFrame.new(0, 2.1 + newHeight / 2, 0),
        }):Play()
        -- Color shifts from blonde → gold as jar fills
        local fillColor = Color3.fromRGB(
            200 + math.floor(55 * pct),
            160 + math.floor(55 * pct),
            math.floor(100 * (1 - pct))
        )
        hairFill.Color = fillColor
        jarLight.Color = fillColor
    end)
end

---------------------------------------------------------------------------
-- MULLET GOD ALTAR (raised platform where he appears)
---------------------------------------------------------------------------
local altar = Instance.new("Model")
altar.Name   = "MulletGodAltar"
altar.Parent = World

-- Main stage
local stage = Instance.new("Part")
stage.Name     = "Stage"
stage.Anchored = true
stage.Size     = Vector3.new(40, 4, 40)
stage.CFrame   = CFrame.new(0, 2, -120)
stage.Color    = Color3.fromRGB(80, 50, 120)
stage.Material = Enum.Material.SmoothPlastic
stage.TopSurface = Enum.SurfaceType.Smooth
stage.Parent   = altar

-- Glowing stage border
for _, offset in ipairs({
    Vector3.new(10, 0, 0), Vector3.new(-10, 0, 0),
    Vector3.new(0, 0, 10), Vector3.new(0, 0, -10),
}) do
    local border = Instance.new("Part")
    border.Anchored  = true
    border.Size      = Vector3.new(1, 1, 20)
    if math.abs(offset.X) > 0 then
        border.Size = Vector3.new(1, 1, 20)
    else
        border.Size = Vector3.new(20, 1, 1)
    end
    border.CFrame    = CFrame.new(0 + offset.X, 2.5, -60 + offset.Z)
    border.Color     = Color3.fromRGB(255, 215, 0)
    border.Material  = Enum.Material.Neon
    border.Anchored  = true
    border.Parent    = altar
end

-- Four glowing pillars
for _, pos in ipairs({
    Vector3.new(18, 0, -105), Vector3.new(-18, 0, -105),
    Vector3.new(18, 0, -135), Vector3.new(-18, 0, -135),
}) do
    local pillar = Instance.new("Part")
    pillar.Anchored  = true
    pillar.Size      = Vector3.new(2, 12, 2)
    pillar.CFrame    = CFrame.new(pos.X, 8, pos.Z)
    pillar.Color     = Color3.fromRGB(255, 180, 0)
    pillar.Material  = Enum.Material.Neon
    pillar.Parent    = altar

    local pl = Instance.new("PointLight")
    pl.Brightness = 2
    pl.Color      = Color3.fromRGB(255, 200, 50)
    pl.Range      = 16
    pl.Parent     = pillar
end

-- "MULLET GOD STAGE" sign
local stageBb = Instance.new("BillboardGui")
stageBb.Size        = UDim2.new(0, 300, 0, 60)
stageBb.StudsOffset = Vector3.new(0, 8, 0)
stageBb.Parent      = stage

local stageLbl = Instance.new("TextLabel")
stageLbl.Size               = UDim2.new(1, 0, 1, 0)
stageLbl.BackgroundTransparency = 1
stageLbl.TextColor3         = Color3.fromRGB(255, 215, 0)
stageLbl.Font               = Enum.Font.GothamBlack
stageLbl.TextScaled         = true
stageLbl.Text               = "⚡ MULLET GOD STAGE ⚡"
stageLbl.TextStrokeTransparency = 0.3
stageLbl.Parent             = stageBb

---------------------------------------------------------------------------
-- SPAWN AREA (colorful pads for players)
---------------------------------------------------------------------------
local spawnColors = {
    Color3.fromRGB(255, 80, 80),
    Color3.fromRGB(80, 200, 255),
    Color3.fromRGB(255, 200, 50),
    Color3.fromRGB(100, 255, 100),
}

for i, color in ipairs(spawnColors) do
    local angle = (i - 1) * (math.pi * 2 / #spawnColors)
    local x = math.cos(angle) * 30
    local z = math.sin(angle) * 30 + 120  -- behind the jar

    local pad = Instance.new("Part")
    pad.Anchored  = true
    pad.Size      = Vector3.new(6, 0.5, 6)
    pad.CFrame    = CFrame.new(x, 0.25, z)
    pad.Color     = color
    pad.Material  = Enum.Material.Neon
    pad.Parent    = World

    local padLight = Instance.new("PointLight")
    padLight.Color      = color
    padLight.Brightness = 2
    padLight.Range      = 10
    padLight.Parent     = pad

    -- Spawn location
    local spawn = Instance.new("SpawnLocation")
    spawn.Anchored  = true
    spawn.Size      = Vector3.new(6, 0.5, 6)
    spawn.CFrame    = CFrame.new(x, 0.5, z)
    spawn.TeamColor = BrickColor.new("Medium stone grey")
    spawn.Neutral   = true
    spawn.Duration  = 0
    spawn.Color     = BrickColor.FromColor3(color)
    spawn.Material  = Enum.Material.Neon
    spawn.Parent    = World
end

---------------------------------------------------------------------------
-- DECORATIVE TREES / PROPS around the edges
---------------------------------------------------------------------------
local function makePalmTree(x, z)
    local trunk = Instance.new("Part")
    trunk.Anchored = true
    trunk.Size     = Vector3.new(1.5, 12, 1.5)
    trunk.CFrame   = CFrame.new(x, 6, z)
    trunk.Color    = Color3.fromRGB(139, 90, 43)
    trunk.Material = Enum.Material.Wood
    trunk.Parent   = World

    local canopy = Instance.new("Part")
    canopy.Anchored = true
    canopy.Shape   = Enum.PartType.Ball
    canopy.Size    = Vector3.new(8, 6, 8)
    canopy.CFrame  = CFrame.new(x, 14, z)
    canopy.Color   = Color3.fromRGB(50, 200, 80)
    canopy.Material = Enum.Material.Grass
    canopy.Parent  = World
end

-- Ring of palm trees around the play area
for i = 1, 16 do
    local angle = (i / 16) * math.pi * 2
    local r = 200
    makePalmTree(math.cos(angle) * r, math.sin(angle) * r)
end

---------------------------------------------------------------------------
-- VACUUM TOOL SPAWNER (gives player their vacuum on spawn)
---------------------------------------------------------------------------
-- A vacuum tool sitting on a pedestal near spawn
local pedestal = Instance.new("Part")
pedestal.Name     = "VacuumPedestal"
pedestal.Anchored = true
pedestal.Size     = Vector3.new(6, 2, 6)
pedestal.CFrame   = CFrame.new(40, 1, 120)
pedestal.Color    = Color3.fromRGB(255, 215, 0)
pedestal.Material = Enum.Material.Neon
pedestal.Parent   = World

local pedestalBb = Instance.new("BillboardGui")
pedestalBb.Size        = UDim2.new(0, 200, 0, 50)
pedestalBb.StudsOffset = Vector3.new(0, 4, 0)
pedestalBb.Parent      = pedestal

local pedestalLbl = Instance.new("TextLabel")
pedestalLbl.Size               = UDim2.new(1, 0, 1, 0)
pedestalLbl.BackgroundTransparency = 1
pedestalLbl.TextColor3         = Color3.fromRGB(255, 255, 255)
pedestalLbl.Font               = Enum.Font.GothamBlack
pedestalLbl.TextScaled         = true
pedestalLbl.Text               = "💨 GRAB VACUUM"
pedestalLbl.TextStrokeTransparency = 0.3
pedestalLbl.Parent             = pedestalBb

print("[WorldBuilder] World built — The Mullet Game is ready!")
