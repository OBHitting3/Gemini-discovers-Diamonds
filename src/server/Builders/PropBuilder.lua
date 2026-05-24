--[[
    PropBuilder.lua
    MCM-styled procedural 3D props (Parts → Models).
    Karl requests new shapes in Cursor chat; agents add builders here.

    Priority: AssetRegistry imported mesh → PropBuilder → ItemCatalog box fallback.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local ProceduralAssetCatalog = require(ReplicatedStorage:WaitForChild("ProceduralAssetCatalog"))
local Utilities = require(ReplicatedStorage:WaitForChild("Utilities"))

local C = GameConfig.Colors

local PropBuilder = {}

local BUILDERS: { [string]: (Instance, CFrame) -> (Model?, number) } = {}

local function tagModel(model: Model, slug: string)
    CollectionService:AddTag(model, "PSP_ProceduralProp")
    model:SetAttribute("ProceduralSlug", slug)
end

local function part(props: { [string]: any }): Part
    return Utilities.createPart(props)
end

BUILDERS.eames_lounge = function(parent, origin)
    local parts = {}
    local base = part({
        Name = "Seat",
        Size = Vector3.new(2.8, 1.2, 2.8),
        CFrame = origin * CFrame.new(0, 1.2, 0),
        Color = C.Terracotta,
        Material = Enum.Material.Fabric,
        Parent = parent,
    })
    table.insert(parts, base)
    table.insert(
        parts,
        part({
            Name = "Back",
            Size = Vector3.new(2.8, 2.4, 0.6),
            CFrame = origin * CFrame.new(0, 2.2, -1.2),
            Color = C.Terracotta,
            Material = Enum.Material.Fabric,
            Parent = parent,
        })
    )
    table.insert(
        parts,
        part({
            Name = "Ottoman",
            Size = Vector3.new(2, 0.8, 2),
            CFrame = origin * CFrame.new(0, 0.6, 2.4),
            Color = C.WallWhite,
            Material = Enum.Material.SmoothPlastic,
            Parent = parent,
        })
    )
    local model = Utilities.createModel("eames_lounge", parts, parent)
    tagModel(model, "eames_lounge")
    return model, #parts
end

BUILDERS.starburst_clock = function(parent, origin)
    local parts = {}
    table.insert(
        parts,
        part({
            Name = "ClockFace",
            Size = Vector3.new(0.4, 3, 3),
            CFrame = origin * CFrame.new(0, 4, 0),
            Color = C.WallWhite,
            Shape = Enum.PartType.Cylinder,
            Parent = parent,
        })
    )
    for i = 1, 12 do
        local angle = (i / 12) * math.pi * 2
        table.insert(
            parts,
            part({
                Name = "Ray_" .. i,
                Size = Vector3.new(0.25, 0.35, 2.2),
                CFrame = origin * CFrame.new(0, 4, 0) * CFrame.Angles(0, angle, math.rad(90)),
                Color = C.UISunCoin,
                Material = Enum.Material.Metal,
                Parent = parent,
            })
        )
    end
    local model = Utilities.createModel("starburst_clock", parts, parent)
    tagModel(model, "starburst_clock")
    return model, #parts
end

BUILDERS.pool_lounger = function(parent, origin)
    local parts = {}
    table.insert(
        parts,
        part({
            Name = "Cushion",
            Size = Vector3.new(2, 0.6, 5.5),
            CFrame = origin * CFrame.new(0, 0.8, 0) * CFrame.Angles(math.rad(-12), 0, 0),
            Color = C.WallWhite,
            Material = Enum.Material.Fabric,
            Parent = parent,
        })
    )
    table.insert(
        parts,
        part({
            Name = "Frame",
            Size = Vector3.new(2.2, 0.3, 5.8),
            CFrame = origin * CFrame.new(0, 0.35, 0),
            Color = C.Concrete,
            Material = Enum.Material.Metal,
            Parent = parent,
        })
    )
    local model = Utilities.createModel("pool_lounger", parts, parent)
    tagModel(model, "pool_lounger")
    return model, #parts
end

BUILDERS.flamingo_lawn = function(parent, origin)
    local parts = {}
    table.insert(
        parts,
        part({
            Name = "Stake",
            Size = Vector3.new(0.2, 3, 0.2),
            CFrame = origin * CFrame.new(0, 1.5, 0),
            Color = C.Concrete,
            Material = Enum.Material.Metal,
            Parent = parent,
        })
    )
    table.insert(
        parts,
        part({
            Name = "Body",
            Size = Vector3.new(1.2, 1.4, 2),
            CFrame = origin * CFrame.new(0, 3.2, 0),
            Color = C.DustyPink,
            Material = Enum.Material.SmoothPlastic,
            Parent = parent,
        })
    )
    table.insert(
        parts,
        part({
            Name = "Neck",
            Size = Vector3.new(0.5, 1.8, 0.5),
            CFrame = origin * CFrame.new(0, 4.2, 0.6) * CFrame.Angles(math.rad(-30), 0, 0),
            Color = C.DustyPink,
            Parent = parent,
        })
    )
    local model = Utilities.createModel("flamingo_lawn", parts, parent)
    tagModel(model, "flamingo_lawn")
    return model, #parts
end

BUILDERS.desert_rose_planter = function(parent, origin)
    local parts = {}
    table.insert(
        parts,
        part({
            Name = "Pot",
            Size = Vector3.new(2.2, 1.4, 2.2),
            CFrame = origin * CFrame.new(0, 0.7, 0),
            Color = C.Terracotta,
            Material = Enum.Material.Slate,
            Parent = parent,
        })
    )
    for i = 1, 5 do
        local angle = (i / 5) * math.pi * 2
        table.insert(
            parts,
            part({
                Name = "Bloom_" .. i,
                Size = Vector3.new(0.6, 0.6, 0.6),
                CFrame = origin * CFrame.new(math.cos(angle) * 0.5, 1.6, math.sin(angle) * 0.5),
                Color = C.DustyPink,
                Shape = Enum.PartType.Ball,
                Parent = parent,
            })
        )
    end
    local model = Utilities.createModel("desert_rose_planter", parts, parent)
    tagModel(model, "desert_rose_planter")
    return model, #parts
end

BUILDERS.palm_planter = function(parent, origin)
    local parts = {}
    table.insert(
        parts,
        part({
            Name = "Planter",
            Size = Vector3.new(2.5, 1.2, 2.5),
            CFrame = origin * CFrame.new(0, 0.6, 0),
            Color = C.Concrete,
            Material = Enum.Material.Concrete,
            Parent = parent,
        })
    )
    table.insert(
        parts,
        part({
            Name = "Trunk",
            Size = Vector3.new(0.6, 3, 0.6),
            CFrame = origin * CFrame.new(0, 2.4, 0),
            Color = C.PalmTrunk,
            Material = Enum.Material.Wood,
            Parent = parent,
        })
    )
    for i = 1, 6 do
        local angle = (i / 6) * math.pi * 2
        table.insert(
            parts,
            part({
                Name = "Frond_" .. i,
                Size = Vector3.new(0.3, 2.5, 1.2),
                CFrame = origin
                    * CFrame.new(math.cos(angle) * 0.8, 3.8, math.sin(angle) * 0.8)
                    * CFrame.Angles(math.rad(-35), angle, 0),
                Color = C.PalmCanopy,
                Material = Enum.Material.Grass,
                Parent = parent,
            })
        )
    end
    local model = Utilities.createModel("palm_planter", parts, parent)
    tagModel(model, "palm_planter")
    return model, #parts
end

BUILDERS.martini_table = function(parent, origin)
    local parts = {}
    for i = 1, 3 do
        local angle = (i / 3) * math.pi * 2
        table.insert(
            parts,
            part({
                Name = "Leg_" .. i,
                Size = Vector3.new(0.25, 2.2, 0.25),
                CFrame = origin * CFrame.new(math.cos(angle) * 0.9, 1.1, math.sin(angle) * 0.9),
                Color = C.UISunCoin,
                Material = Enum.Material.Metal,
                Parent = parent,
            })
        )
    end
    table.insert(
        parts,
        part({
            Name = "Top",
            Size = Vector3.new(2.4, 0.35, 2.4),
            CFrame = origin * CFrame.new(0, 2.3, 0),
            Color = C.Turquoise,
            Material = Enum.Material.SmoothPlastic,
            Shape = Enum.PartType.Cylinder,
            Parent = parent,
        })
    )
    local model = Utilities.createModel("martini_table", parts, parent)
    tagModel(model, "martini_table")
    return model, #parts
end

BUILDERS.breeze_block_column = function(parent, origin)
    local parts = {}
    local cols, rows = 3, 4
    for row = 0, rows - 1 do
        for col = 0, cols - 1 do
            if (row + col) % 2 == 0 then
                table.insert(
                    parts,
                    part({
                        Name = "Block_" .. row .. "_" .. col,
                        Size = Vector3.new(1.4, 1.4, 0.6),
                        CFrame = origin * CFrame.new((col - 1) * 1.5, row * 1.5 + 0.75, 0),
                        Color = C.BreezeBlock,
                        Material = Enum.Material.Concrete,
                        Parent = parent,
                    })
                )
            end
        end
    end
    local model = Utilities.createModel("breeze_block_column", parts, parent)
    tagModel(model, "breeze_block_column")
    return model, #parts
end

--- Map ItemCatalog furniture id → procedural builder slug (when ids differ).
local ITEM_ALIASES: { [string]: string } = {
    outdoor_lounge = "pool_lounger",
    boomerang_table = "martini_table",
    planter_box = "desert_rose_planter",
}

function PropBuilder:canBuild(slugOrItemId: string): boolean
    local slug = ITEM_ALIASES[slugOrItemId] or slugOrItemId
    return BUILDERS[slug] ~= nil
end

function PropBuilder:build(slugOrItemId: string, parent: Instance, origin: CFrame): (Model?, number)
    local slug = ITEM_ALIASES[slugOrItemId] or slugOrItemId
    local builder = BUILDERS[slug]
    if not builder then
        return nil, 0
    end
    return builder(parent, origin)
end

function PropBuilder:listBuildableSlugs(): { string }
    local slugs = {}
    for slug in pairs(BUILDERS) do
        table.insert(slugs, slug)
    end
    table.sort(slugs)
    return slugs
end

function PropBuilder:getCatalogEntry(slugOrItemId: string)
    local slug = ITEM_ALIASES[slugOrItemId] or slugOrItemId
    return ProceduralAssetCatalog.getBySlug(slug)
        or ProceduralAssetCatalog.getByItemCatalogId(slugOrItemId)
end

return PropBuilder
