--[[
    HomeBuilder.lua
    Builds 4 distinct single-story mid-century modern home prefabs.
    ALL homes are STRICTLY single-story (flat-roof or butterfly-roof).
    Maximum height: 12 studs including roof.

    Styles:
      A — "The Kaufmann"  flat-roof, L-shaped, kidney pool, breeze-block
      B — "The Frey"      butterfly-roof, rectangular, carport, glass 3-sides
      C — "The Wexler"    flat-roof, courtyard, dusty-pink accent, 2x breeze
      D — "The Neutra"    butterfly-roof, long rect, full glass front, reflecting pool

    LOCKED VISUAL IDENTITY — turquoise pools, concrete patios,
    floor-to-ceiling glass, breeze-block screens, pastel accents.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Utilities  = require(ReplicatedStorage:WaitForChild("Utilities"))

local C = GameConfig.Colors

local HomeBuilder = {}
HomeBuilder._partCount = 0

---------------------------------------------------------------------------
-- HELPER: accent color by style name
---------------------------------------------------------------------------
local function getAccent(styleName: string): Color3
    local style = GameConfig.HomeStyles[styleName]
    if style and style.accentColor then
        return C[style.accentColor] or C.Terracotta
    end
    return C.Terracotta
end

---------------------------------------------------------------------------
-- SHARED COMPONENTS
---------------------------------------------------------------------------

--- Build a turquoise kidney pool.
local function buildPool(parent, origin: CFrame, sizeX: number, sizeZ: number): number
    local parts = 0
    -- Pool basin (slightly recessed)
    local basin = Utilities.createPart({
        Name = "PoolBasin",
        Size = Vector3.new(sizeX, 1.5, sizeZ),
        CFrame = origin * CFrame.new(0, -0.75, 0),
        Color = C.Turquoise,
        Material = Enum.Material.Glass,
        Transparency = 0.3,
        Reflectance = 0.2,
        Tag = "Pool",
        Parent = parent,
    })
    parts += 1

    -- Pool rim
    local rimThickness = 0.4
    local rimParts = {
        { Vector3.new(sizeX + rimThickness * 2, 0.3, rimThickness), CFrame.new(0, 0.15, sizeZ / 2 + rimThickness / 2) },
        { Vector3.new(sizeX + rimThickness * 2, 0.3, rimThickness), CFrame.new(0, 0.15, -sizeZ / 2 - rimThickness / 2) },
        { Vector3.new(rimThickness, 0.3, sizeZ), CFrame.new(sizeX / 2 + rimThickness / 2, 0.15, 0) },
        { Vector3.new(rimThickness, 0.3, sizeZ), CFrame.new(-sizeX / 2 - rimThickness / 2, 0.15, 0) },
    }
    for i, rim in ipairs(rimParts) do
        Utilities.createPart({
            Name = "PoolRim_" .. i,
            Size = rim[1],
            CFrame = origin * rim[2],
            Color = C.Concrete,
            Material = Enum.Material.Concrete,
            Tag = "Pool",
            Parent = parent,
        })
        parts += 1
    end

    return parts
end

--- Build a concrete patio slab.
local function buildPatio(parent, origin: CFrame, sizeX: number, sizeZ: number): number
    Utilities.createPart({
        Name = "Patio",
        Size = Vector3.new(sizeX, 0.3, sizeZ),
        CFrame = origin * CFrame.new(0, 0.15, 0),
        Color = C.Concrete,
        Material = Enum.Material.Concrete,
        Tag = "Patio",
        Parent = parent,
    })
    return 1
end

--- Build a breeze-block screen wall.
local function buildBreezeScreen(parent, origin: CFrame, width: number, height: number): number
    local parts = 0
    -- Frame
    Utilities.createPart({
        Name = "BreezeBlockFrame",
        Size = Vector3.new(width, height, 0.8),
        CFrame = origin * CFrame.new(0, height / 2, 0),
        Color = C.BreezeBlock,
        Material = Enum.Material.Concrete,
        Transparency = 0.4,
        Tag = "BreezeBlock",
        Parent = parent,
    })
    parts += 1
    return parts
end

--- Build a flat roof slab over a rectangular area.
local function buildFlatRoof(parent, origin: CFrame, sizeX: number, sizeZ: number, height: number): number
    Utilities.createPart({
        Name = "FlatRoof",
        Size = Vector3.new(sizeX + 2, 0.5, sizeZ + 2), -- slight overhang
        CFrame = origin * CFrame.new(0, height + 0.25, 0),
        Color = C.RoofDarkGrey,
        Material = Enum.Material.Concrete,
        Tag = "Roof",
        Parent = parent,
    })
    return 1
end

--- Build a butterfly roof (V-shape) over a rectangular area.
local function buildButterflyRoof(parent, origin: CFrame, sizeX: number, sizeZ: number, height: number): number
    local parts = 0
    local halfX = sizeX / 2 + 1
    local overhang = sizeZ + 2

    -- Left wing (tilted down toward center)
    Utilities.createPart({
        Name = "ButterflyRoof_L",
        Size = Vector3.new(halfX, 0.4, overhang),
        CFrame = origin * CFrame.new(-halfX / 2, height + 1, 0) *
                 CFrame.Angles(0, 0, math.rad(8)),
        Color = C.RoofDarkGrey,
        Material = Enum.Material.Concrete,
        Tag = "Roof",
        Parent = parent,
    })
    parts += 1

    -- Right wing (tilted down toward center)
    Utilities.createPart({
        Name = "ButterflyRoof_R",
        Size = Vector3.new(halfX, 0.4, overhang),
        CFrame = origin * CFrame.new(halfX / 2, height + 1, 0) *
                 CFrame.Angles(0, 0, math.rad(-8)),
        Color = C.RoofDarkGrey,
        Material = Enum.Material.Concrete,
        Tag = "Roof",
        Parent = parent,
    })
    parts += 1

    return parts
end

--- Build a floor-to-ceiling glass wall.
local function buildGlassWall(parent, origin: CFrame, width: number, height: number): number
    Utilities.createPart({
        Name = "GlassWall",
        Size = Vector3.new(width, height, 0.3),
        CFrame = origin * CFrame.new(0, height / 2, 0),
        Color = C.Glass,
        Material = Enum.Material.Glass,
        Transparency = C.GlassTransparency,
        Tag = "GlassWall",
        Parent = parent,
    })
    return 1
end

--- Build a solid wall.
local function buildWall(parent, origin: CFrame, width: number, height: number, color: Color3?): number
    Utilities.createPart({
        Name = "Wall",
        Size = Vector3.new(width, height, 0.5),
        CFrame = origin * CFrame.new(0, height / 2, 0),
        Color = color or C.WallWhite,
        Material = Enum.Material.SmoothPlastic,
        Tag = "Wall",
        Parent = parent,
    })
    return 1
end

--- Build a floor slab.
local function buildFloor(parent, origin: CFrame, sizeX: number, sizeZ: number): number
    Utilities.createPart({
        Name = "Floor",
        Size = Vector3.new(sizeX, 0.4, sizeZ),
        CFrame = origin * CFrame.new(0, 0.2, 0),
        Color = C.Concrete,
        Material = Enum.Material.SmoothPlastic,
        Tag = "Floor",
        Parent = parent,
    })
    return 1
end

---------------------------------------------------------------------------
-- STYLE A: "THE KAUFMANN"
-- Flat-roof, L-shaped plan, turquoise kidney pool, breeze-block screen
---------------------------------------------------------------------------

local function buildKaufmann(plotPos: Vector3): (Model, number)
    local parts = 0
    local model = Instance.new("Model")
    model.Name = "Home_Kaufmann"
    local wallH = 8

    -- Main wing (24 × 16)
    local mainOrigin = CFrame.new(plotPos) * CFrame.new(-8, 0, -8)
    parts += buildFloor(model, mainOrigin, 24, 16)

    -- Back wall
    parts += buildWall(model, mainOrigin * CFrame.new(0, 0, -8), 24, wallH)
    -- Left wall
    parts += buildWall(model, mainOrigin * CFrame.new(-12, 0, 0) * CFrame.Angles(0, math.rad(90), 0), 16, wallH)
    -- Glass front (facing pool)
    parts += buildGlassWall(model, mainOrigin * CFrame.new(0, 0, 8), 24, wallH)

    -- L-wing (12 × 12) extending right
    local wingOrigin = CFrame.new(plotPos) * CFrame.new(12, 0, 2)
    parts += buildFloor(model, wingOrigin, 12, 12)
    parts += buildWall(model, wingOrigin * CFrame.new(0, 0, -6), 12, wallH)
    parts += buildWall(model, wingOrigin * CFrame.new(6, 0, 0) * CFrame.Angles(0, math.rad(90), 0), 12, wallH)
    parts += buildGlassWall(model, wingOrigin * CFrame.new(0, 0, 6), 12, wallH)

    -- Flat roof over both wings
    parts += buildFlatRoof(model, mainOrigin, 24, 16, wallH)
    parts += buildFlatRoof(model, wingOrigin, 12, 12, wallH)

    -- Turquoise kidney pool (in front of main wing)
    local poolOrigin = CFrame.new(plotPos) * CFrame.new(-5, 0, 16)
    parts += buildPool(model, poolOrigin, 12, 6)

    -- Concrete patio between house and pool
    local patioOrigin = CFrame.new(plotPos) * CFrame.new(-5, 0, 10)
    parts += buildPatio(model, patioOrigin, 20, 4)

    -- Breeze-block screen (privacy wall on west side)
    parts += buildBreezeScreen(model, CFrame.new(plotPos) * CFrame.new(-22, 0, 0), 8, wallH)

    -- Accent detail (terracotta planter ledge on front)
    Utilities.createPart({
        Name = "AccentLedge",
        Size = Vector3.new(24, 0.4, 1),
        CFrame = mainOrigin * CFrame.new(0, 0.2, 8.5),
        Color = getAccent("Kaufmann"),
        Material = Enum.Material.SmoothPlastic,
        Parent = model,
    })
    parts += 1

    return model, parts
end

---------------------------------------------------------------------------
-- STYLE B: "THE FREY"
-- Butterfly-roof, rectangular plan, carport, glass 3-sides, small pool
---------------------------------------------------------------------------

local function buildFrey(plotPos: Vector3): (Model, number)
    local parts = 0
    local model = Instance.new("Model")
    model.Name = "Home_Frey"
    local wallH = 8

    -- Main rectangle (28 × 14)
    local origin = CFrame.new(plotPos)
    parts += buildFloor(model, origin, 28, 14)

    -- Back wall only solid wall
    parts += buildWall(model, origin * CFrame.new(0, 0, -7), 28, wallH)
    -- Glass on left, right, front
    parts += buildGlassWall(model, origin * CFrame.new(-14, 0, 0) * CFrame.Angles(0, math.rad(90), 0), 14, wallH)
    parts += buildGlassWall(model, origin * CFrame.new(14, 0, 0) * CFrame.Angles(0, math.rad(90), 0), 14, wallH)
    parts += buildGlassWall(model, origin * CFrame.new(0, 0, 7), 28, wallH)

    -- Butterfly roof
    parts += buildButterflyRoof(model, origin, 28, 14, wallH)

    -- Covered carport (open structure to the left)
    local carportOrigin = origin * CFrame.new(-20, 0, 0)
    parts += buildFloor(model, carportOrigin, 8, 10)
    parts += buildFlatRoof(model, carportOrigin, 8, 10, wallH - 1)
    -- Carport support columns (2 thin pillars)
    for _, cx in ipairs({-3, 3}) do
        Utilities.createPart({
            Name = "CarportColumn",
            Size = Vector3.new(0.6, wallH - 1, 0.6),
            CFrame = carportOrigin * CFrame.new(cx, (wallH - 1) / 2, 5),
            Color = C.WallWhite,
            Material = Enum.Material.SmoothPlastic,
            Parent = model,
        })
        parts += 1
    end

    -- Small kidney pool (right side)
    parts += buildPool(model, origin * CFrame.new(10, 0, 14), 8, 5)

    -- Patio
    parts += buildPatio(model, origin * CFrame.new(0, 0, 10), 20, 4)

    -- Accent
    Utilities.createPart({
        Name = "AccentStripe",
        Size = Vector3.new(28, 0.3, 0.3),
        CFrame = origin * CFrame.new(0, wallH - 0.5, -7.3),
        Color = getAccent("Frey"),
        Material = Enum.Material.Neon,
        Parent = model,
    })
    parts += 1

    return model, parts
end

---------------------------------------------------------------------------
-- STYLE C: "THE WEXLER"
-- Flat-roof, open-plan with central courtyard, dusty-pink accent, 2x breeze
---------------------------------------------------------------------------

local function buildWexler(plotPos: Vector3): (Model, number)
    local parts = 0
    local model = Instance.new("Model")
    model.Name = "Home_Wexler"
    local wallH = 8

    -- U-shape: main body + two wings around courtyard
    local origin = CFrame.new(plotPos)

    -- Back wing (30 × 10)
    local backOrigin = origin * CFrame.new(0, 0, -10)
    parts += buildFloor(model, backOrigin, 30, 10)
    parts += buildWall(model, backOrigin * CFrame.new(0, 0, -5), 30, wallH)
    parts += buildGlassWall(model, backOrigin * CFrame.new(0, 0, 5), 30, wallH)

    -- Left wing (10 × 12)
    local leftOrigin = origin * CFrame.new(-10, 0, 1)
    parts += buildFloor(model, leftOrigin, 10, 12)
    parts += buildWall(model, leftOrigin * CFrame.new(-5, 0, 0) * CFrame.Angles(0, math.rad(90), 0), 12, wallH)

    -- Right wing (10 × 12)
    local rightOrigin = origin * CFrame.new(10, 0, 1)
    parts += buildFloor(model, rightOrigin, 10, 12)
    parts += buildWall(model, rightOrigin * CFrame.new(5, 0, 0) * CFrame.Angles(0, math.rad(90), 0), 12, wallH)

    -- Dusty-pink accent wall (interior back of courtyard)
    parts += buildWall(model, backOrigin * CFrame.new(0, 0, 5.3), 10, wallH, C.DustyPink)

    -- Flat roofs over all three wings
    parts += buildFlatRoof(model, backOrigin, 30, 10, wallH)
    parts += buildFlatRoof(model, leftOrigin, 10, 12, wallH)
    parts += buildFlatRoof(model, rightOrigin, 10, 12, wallH)

    -- Central courtyard pool
    parts += buildPool(model, origin * CFrame.new(0, 0, 2), 8, 6)

    -- Patio (courtyard floor around pool)
    parts += buildPatio(model, origin * CFrame.new(0, 0, 2), 14, 10)

    -- Breeze-block screens on both sides
    parts += buildBreezeScreen(model, origin * CFrame.new(-16, 0, 0), 6, wallH)
    parts += buildBreezeScreen(model, origin * CFrame.new(16, 0, 0), 6, wallH)

    return model, parts
end

---------------------------------------------------------------------------
-- STYLE D: "THE NEUTRA"
-- Butterfly-roof, long rectangle, full glass front, reflecting pool
---------------------------------------------------------------------------

local function buildNeutra(plotPos: Vector3): (Model, number)
    local parts = 0
    local model = Instance.new("Model")
    model.Name = "Home_Neutra"
    local wallH = 8

    -- Long rectangular plan (36 × 12)
    local origin = CFrame.new(plotPos)
    parts += buildFloor(model, origin, 36, 12)

    -- Back wall
    parts += buildWall(model, origin * CFrame.new(0, 0, -6), 36, wallH)
    -- Side walls
    parts += buildWall(model, origin * CFrame.new(-18, 0, 0) * CFrame.Angles(0, math.rad(90), 0), 12, wallH)
    parts += buildWall(model, origin * CFrame.new(18, 0, 0) * CFrame.Angles(0, math.rad(90), 0), 12, wallH)
    -- Full glass front
    parts += buildGlassWall(model, origin * CFrame.new(0, 0, 6), 36, wallH)

    -- Butterfly roof
    parts += buildButterflyRoof(model, origin, 36, 12, wallH)

    -- Reflecting pool (thin turquoise strip along the front)
    Utilities.createPart({
        Name = "ReflectingPool",
        Size = Vector3.new(30, 0.8, 2),
        CFrame = origin * CFrame.new(0, -0.4, 10),
        Color = C.Turquoise,
        Material = Enum.Material.Glass,
        Transparency = 0.3,
        Reflectance = 0.3,
        Tag = "Pool",
        Parent = model,
    })
    parts += 1

    -- Concrete patio with built-in seating
    parts += buildPatio(model, origin * CFrame.new(0, 0, 8), 30, 3)

    -- Built-in bench (concrete)
    Utilities.createPart({
        Name = "BuiltInBench",
        Size = Vector3.new(10, 1.5, 2),
        CFrame = origin * CFrame.new(-8, 0.75, 8),
        Color = C.Concrete,
        Material = Enum.Material.Concrete,
        Parent = model,
    })
    parts += 1

    -- Accent detail
    Utilities.createPart({
        Name = "AccentBeam",
        Size = Vector3.new(0.4, 0.4, 14),
        CFrame = origin * CFrame.new(0, wallH + 1.5, 0),
        Color = getAccent("Neutra"),
        Material = Enum.Material.SmoothPlastic,
        Parent = model,
    })
    parts += 1

    return model, parts
end

---------------------------------------------------------------------------
-- PUBLIC API
---------------------------------------------------------------------------

local styleBuilders = {
    Kaufmann = buildKaufmann,
    Frey     = buildFrey,
    Wexler   = buildWexler,
    Neutra   = buildNeutra,
}

--- Build a home on a plot.
--- @param plotPosition Vector3 — center of the plot
--- @param style string — "Kaufmann" | "Frey" | "Wexler" | "Neutra"
--- @return Model?, number — the home model and part count (or nil on error)
function HomeBuilder:buildHome(plotPosition: Vector3, style: string): (Model?, number)
    local builder = styleBuilders[style]
    if not builder then
        warn("[HomeBuilder] Unknown style: " .. tostring(style))
        return nil, 0
    end

    local model, parts = builder(plotPosition)
    if model then
        model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart")
        CollectionService:AddTag(model, "MCMHome")
        CollectionService:AddTag(model, "Home_" .. style)

        -- Parent to Workspace plots folder
        local plotsFolder = workspace:FindFirstChild("Plots")
        if not plotsFolder then
            plotsFolder = Instance.new("Folder")
            plotsFolder.Name = "Plots"
            plotsFolder.Parent = workspace
        end
        model.Parent = plotsFolder

        self._partCount += parts
        print("[HomeBuilder] Built " .. style .. " at " ..
              tostring(plotPosition) .. " (" .. parts .. " parts)")
    end

    return model, parts
end

--- Get total parts used by HomeBuilder.
function HomeBuilder:getPartCount(): number
    return self._partCount
end

return HomeBuilder
