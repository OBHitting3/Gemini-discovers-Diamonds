--[[
    StorefrontBuilder.lua
    Builds El Paseo luxury boulevard with 6 modular storefronts
    (3 per side) + al-fresco dining area, planter boxes, and
    signage-ready facades.

    Styles cycle through: Boutique, Gallery, Café, Luxury
    Mountain view corridors are preserved — storefronts are single-story
    with open sightlines above roof level.

    Part budget: < 200 total for the entire boulevard.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Utilities  = require(ReplicatedStorage:WaitForChild("Utilities"))

local C = GameConfig.Colors

local StorefrontBuilder = {}
StorefrontBuilder._partCount = 0

---------------------------------------------------------------------------
-- STOREFRONT STYLES
---------------------------------------------------------------------------

local STYLES = { "Boutique", "Gallery", "Cafe", "Luxury", "Boutique", "Gallery" }

local STYLE_COLORS = {
    Boutique = { facade = C.WallWhite, awning = C.Turquoise,   trim = C.Concrete },
    Gallery  = { facade = C.WallWhite, awning = C.WallWhite,   trim = C.RoofDarkGrey },
    Cafe     = { facade = C.WallWhite, awning = C.Terracotta,  trim = C.DustyPink },
    Luxury   = { facade = C.WallWhite, awning = C.RoofDarkGrey, trim = Color3.fromRGB(200, 170, 60) },
}

---------------------------------------------------------------------------
-- BUILD SINGLE STOREFRONT
---------------------------------------------------------------------------

local function buildStorefront(parent, slotId: number, position: Vector3, rotationY: number, style: string): number
    local parts = 0
    local model = Instance.new("Model")
    model.Name = "Storefront_" .. slotId
    local colors = STYLE_COLORS[style] or STYLE_COLORS.Boutique

    local origin = CFrame.new(position) * CFrame.Angles(0, math.rad(rotationY), 0)
    local sfSize = GameConfig.World.StorefrontSize -- 20 × 12 × 16
    local w, h, d = sfSize.X, sfSize.Y, sfSize.Z

    -- Floor
    Utilities.createPart({
        Name = "Floor",
        Size = Vector3.new(w, 0.3, d),
        CFrame = origin * CFrame.new(0, 0.15, 0),
        Color = C.Sidewalk,
        Material = Enum.Material.SmoothPlastic,
        Tag = "Storefront",
        Parent = model,
    })
    parts += 1

    -- Back wall
    Utilities.createPart({
        Name = "BackWall",
        Size = Vector3.new(w, h, 0.5),
        CFrame = origin * CFrame.new(0, h / 2, -d / 2),
        Color = colors.facade,
        Material = Enum.Material.SmoothPlastic,
        Tag = "Storefront",
        Parent = model,
    })
    parts += 1

    -- Left wall
    Utilities.createPart({
        Name = "LeftWall",
        Size = Vector3.new(0.5, h, d),
        CFrame = origin * CFrame.new(-w / 2, h / 2, 0),
        Color = colors.facade,
        Material = Enum.Material.SmoothPlastic,
        Tag = "Storefront",
        Parent = model,
    })
    parts += 1

    -- Right wall
    Utilities.createPart({
        Name = "RightWall",
        Size = Vector3.new(0.5, h, d),
        CFrame = origin * CFrame.new(w / 2, h / 2, 0),
        Color = colors.facade,
        Material = Enum.Material.SmoothPlastic,
        Tag = "Storefront",
        Parent = model,
    })
    parts += 1

    -- Glass display window (front, large)
    Utilities.createPart({
        Name = "DisplayWindow",
        Size = Vector3.new(w * 0.6, h * 0.7, 0.3),
        CFrame = origin * CFrame.new(0, h * 0.4, d / 2),
        Color = C.Glass,
        Material = Enum.Material.Glass,
        Transparency = C.GlassTransparency,
        Tag = "Storefront",
        Parent = model,
    })
    parts += 1

    -- Door frame (front, beside window)
    Utilities.createPart({
        Name = "DoorFrame",
        Size = Vector3.new(w * 0.2, h * 0.8, 0.4),
        CFrame = origin * CFrame.new(w * 0.35, h * 0.4, d / 2),
        Color = colors.trim,
        Material = Enum.Material.SmoothPlastic,
        Tag = "Storefront",
        Parent = model,
    })
    parts += 1

    -- Front wall (above window)
    Utilities.createPart({
        Name = "FrontWallTop",
        Size = Vector3.new(w, h * 0.25, 0.5),
        CFrame = origin * CFrame.new(0, h * 0.875, d / 2),
        Color = colors.facade,
        Material = Enum.Material.SmoothPlastic,
        Tag = "Storefront",
        Parent = model,
    })
    parts += 1

    -- Awning (extends outward)
    Utilities.createPart({
        Name = "Awning",
        Size = Vector3.new(w, 0.3, 4),
        CFrame = origin * CFrame.new(0, h * 0.75, d / 2 + 2) *
                 CFrame.Angles(math.rad(-5), 0, 0),
        Color = colors.awning,
        Material = Enum.Material.Fabric,
        Tag = "Storefront",
        Parent = model,
    })
    parts += 1

    -- Flat roof
    Utilities.createPart({
        Name = "Roof",
        Size = Vector3.new(w + 1, 0.4, d + 1),
        CFrame = origin * CFrame.new(0, h + 0.2, 0),
        Color = C.RoofDarkGrey,
        Material = Enum.Material.Concrete,
        Tag = "Storefront",
        Parent = model,
    })
    parts += 1

    -- Interior counter
    Utilities.createPart({
        Name = "Counter",
        Size = Vector3.new(w * 0.5, 3, 2),
        CFrame = origin * CFrame.new(0, 1.5, -d / 2 + 3),
        Color = C.Concrete,
        Material = Enum.Material.SmoothPlastic,
        Tag = "Storefront",
        Parent = model,
    })
    parts += 1

    -- Display pedestals (2)
    for i, xOff in ipairs({ -w * 0.25, w * 0.15 }) do
        Utilities.createPart({
            Name = "Pedestal_" .. i,
            Size = Vector3.new(2, 3, 2),
            CFrame = origin * CFrame.new(xOff, 1.5, d / 2 - 3),
            Color = C.WallWhite,
            Material = Enum.Material.SmoothPlastic,
            Tag = "Storefront",
            Parent = model,
        })
        parts += 1
    end

    -- Signage area (SurfaceGui-ready part above awning)
    local signPart = Utilities.createPart({
        Name = "SignBoard",
        Size = Vector3.new(w * 0.7, 2, 0.3),
        CFrame = origin * CFrame.new(0, h * 0.9, d / 2 + 0.3),
        Color = colors.facade,
        Material = Enum.Material.SmoothPlastic,
        Tag = "Storefront",
        Parent = model,
    })
    parts += 1

    -- Add a SurfaceGui with shop name placeholder
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Name = "ShopSign"
    surfaceGui.Face = Enum.NormalId.Front
    surfaceGui.Parent = signPart

    local label = Instance.new("TextLabel")
    label.Name = "ShopName"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = style .. " #" .. slotId
    label.TextColor3 = C.UIText
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = surfaceGui

    -- Claim proximity prompt
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "ClaimShopPrompt"
    prompt.ActionText = "Claim Shop"
    prompt.ObjectText = style .. " Storefront"
    prompt.MaxActivationDistance = 10
    prompt.HoldDuration = 1
    prompt.Parent = signPart

    -- Store metadata as attributes
    model:SetAttribute("SlotId", slotId)
    model:SetAttribute("Style", style)
    model:SetAttribute("Claimed", false)

    model.PrimaryPart = model:FindFirstChild("Floor")
    CollectionService:AddTag(model, "ElPaseoStorefront")
    model.Parent = parent

    return parts
end

---------------------------------------------------------------------------
-- BUILD FULL BOULEVARD
---------------------------------------------------------------------------

function StorefrontBuilder:buildBoulevard(): number
    local parts = 0
    local world = GameConfig.World

    -- Create boulevard folder
    local folder = Instance.new("Folder")
    folder.Name = "ElPaseo"
    folder.Parent = workspace

    -- Build each storefront
    for slotId, slotConfig in pairs(world.StorefrontPositions) do
        local style = STYLES[slotId] or "Boutique"
        local p = buildStorefront(
            folder,
            slotId,
            slotConfig.position,
            slotConfig.rotation,
            style
        )
        parts += p
    end

    -- Planter boxes between storefronts (on sidewalk)
    local planterPositions = {
        Vector3.new(18, 0, -60), Vector3.new(18, 0, -20),
        Vector3.new(-18, 0, -60), Vector3.new(-18, 0, -20),
    }
    for i, pos in ipairs(planterPositions) do
        -- Planter box
        Utilities.createPart({
            Name = "Planter_" .. i,
            Size = Vector3.new(4, 2, 4),
            CFrame = CFrame.new(pos.X, 1, pos.Z),
            Color = C.Concrete,
            Material = Enum.Material.Concrete,
            Tag = "ElPaseoDecor",
            Parent = folder,
        })
        parts += 1

        -- Small plant in planter
        Utilities.createPart({
            Name = "PlanterPlant_" .. i,
            Size = Vector3.new(2, 2, 2),
            CFrame = CFrame.new(pos.X, 3, pos.Z),
            Color = C.CactusGreen,
            Material = Enum.Material.Grass,
            Shape = Enum.PartType.Ball,
            Tag = "ElPaseoDecor",
            Parent = folder,
        })
        parts += 1
    end

    -- Al-fresco dining area at south end of boulevard
    local diningOrigin = CFrame.new(0, 0, 30)

    -- Dining platform
    Utilities.createPart({
        Name = "DiningPlatform",
        Size = Vector3.new(20, 0.3, 16),
        CFrame = diningOrigin * CFrame.new(0, 0.15, 0),
        Color = C.Sidewalk,
        Material = Enum.Material.Brick,
        Tag = "ElPaseoDecor",
        Parent = folder,
    })
    parts += 1

    -- 4 table/chair sets
    for i = 1, 4 do
        local row = math.ceil(i / 2)
        local col = ((i - 1) % 2) * 2 - 1  -- -1 or 1
        local tablePos = diningOrigin * CFrame.new(col * 5, 0, (row - 1) * 7 - 3)

        -- Table
        Utilities.createPart({
            Name = "DiningTable_" .. i,
            Size = Vector3.new(3, 2.5, 3),
            CFrame = tablePos * CFrame.new(0, 1.25, 0),
            Color = C.WallWhite,
            Material = Enum.Material.SmoothPlastic,
            Tag = "ElPaseoDecor",
            Parent = folder,
        })
        parts += 1

        -- Chairs (2 per table)
        for j, cx in ipairs({ -2, 2 }) do
            Utilities.createPart({
                Name = "DiningChair_" .. i .. "_" .. j,
                Size = Vector3.new(1.5, 2, 1.5),
                CFrame = tablePos * CFrame.new(cx, 1, 0),
                Color = C.Terracotta,
                Material = Enum.Material.Fabric,
                Tag = "ElPaseoDecor",
                Parent = folder,
            })
            parts += 1
        end

        -- Umbrella pole + canopy
        Utilities.createPart({
            Name = "UmbrellaPole_" .. i,
            Size = Vector3.new(0.3, 6, 0.3),
            CFrame = tablePos * CFrame.new(0, 3, 0),
            Color = C.RoofDarkGrey,
            Material = Enum.Material.Metal,
            Tag = "ElPaseoDecor",
            Parent = folder,
        })
        parts += 1

        Utilities.createPart({
            Name = "UmbrellaCanopy_" .. i,
            Size = Vector3.new(5, 0.3, 5),
            CFrame = tablePos * CFrame.new(0, 6, 0),
            Color = C.Terracotta,
            Material = Enum.Material.Fabric,
            Tag = "ElPaseoDecor",
            Parent = folder,
        })
        parts += 1
    end

    -- El Paseo sign at the boulevard entrance
    local signPost = Utilities.createPart({
        Name = "ElPaseoSign",
        Size = Vector3.new(8, 3, 0.5),
        CFrame = CFrame.new(0, 5, world.ElPaseoStart.Z + 5),
        Color = C.WallWhite,
        Material = Enum.Material.SmoothPlastic,
        Tag = "ElPaseoDecor",
        Parent = folder,
    })
    parts += 1

    -- Sign text via SurfaceGui
    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Front
    gui.Parent = signPost

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.Text = "EL PASEO"
    txt.TextColor3 = C.Terracotta
    txt.TextScaled = true
    txt.Font = Enum.Font.GothamBold
    txt.Parent = gui

    -- Sign support post
    Utilities.createPart({
        Name = "ElPaseoSignPost",
        Size = Vector3.new(0.5, 6.5, 0.5),
        CFrame = CFrame.new(0, 3.25, world.ElPaseoStart.Z + 5),
        Color = C.RoofDarkGrey,
        Material = Enum.Material.Metal,
        Tag = "ElPaseoDecor",
        Parent = folder,
    })
    parts += 1

    self._partCount += parts
    print("[StorefrontBuilder] El Paseo boulevard built (" .. parts .. " parts)")
    return parts
end

---------------------------------------------------------------------------
-- ACCESSORS
---------------------------------------------------------------------------

function StorefrontBuilder:getPartCount(): number
    return self._partCount
end

return StorefrontBuilder
