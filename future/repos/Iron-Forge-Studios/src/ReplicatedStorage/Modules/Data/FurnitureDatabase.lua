--[[
    FurnitureDatabase.lua
    All placeable furniture items for the 32x32 oasis plots.
    50+ mid-century modern themed items.
]]

local FurnitureDatabase = {}

FurnitureDatabase.Items = {
    -- ═══════════ SEATING ═══════════
    { Id = "furn_001", Name = "Midcentury Sofa",       Category = "Seating",    Size = Vector3.new(4, 2, 2),   Color = Color3.fromRGB(200, 120, 80),  Material = Enum.Material.Fabric },
    { Id = "furn_002", Name = "Eames Lounge Chair",    Category = "Seating",    Size = Vector3.new(2, 2, 2),   Color = Color3.fromRGB(40, 40, 40),    Material = Enum.Material.Leather },
    { Id = "furn_003", Name = "Butterfly Chair",       Category = "Seating",    Size = Vector3.new(2, 2, 2),   Color = Color3.fromRGB(220, 180, 140),  Material = Enum.Material.Fabric },
    { Id = "furn_004", Name = "Poolside Lounger",      Category = "Seating",    Size = Vector3.new(2, 1, 5),   Color = Color3.fromRGB(255, 255, 255),  Material = Enum.Material.SmoothPlastic },
    { Id = "furn_005", Name = "Hanging Egg Chair",     Category = "Seating",    Size = Vector3.new(2, 3, 2),   Color = Color3.fromRGB(180, 160, 140),  Material = Enum.Material.SmoothPlastic },

    -- ═══════════ TABLES ═══════════
    { Id = "furn_006", Name = "Boomerang Coffee Table", Category = "Tables",    Size = Vector3.new(3, 1, 2),   Color = Color3.fromRGB(139, 90, 43),   Material = Enum.Material.Wood },
    { Id = "furn_007", Name = "Terrazzo Dining Table",  Category = "Tables",    Size = Vector3.new(4, 2, 4),   Color = Color3.fromRGB(230, 220, 210),  Material = Enum.Material.Marble },
    { Id = "furn_008", Name = "Glass End Table",        Category = "Tables",    Size = Vector3.new(1, 1, 1),   Color = Color3.fromRGB(180, 220, 255),  Material = Enum.Material.Glass },
    { Id = "furn_009", Name = "Tiki Bar Counter",       Category = "Tables",    Size = Vector3.new(5, 3, 2),   Color = Color3.fromRGB(139, 90, 43),    Material = Enum.Material.Wood },

    -- ═══════════ LIGHTING ═══════════
    { Id = "furn_010", Name = "Starburst Lamp",        Category = "Lighting",   Size = Vector3.new(1, 4, 1),   Color = Color3.fromRGB(255, 215, 0),    Material = Enum.Material.Metal },
    { Id = "furn_011", Name = "Tiki Torch",            Category = "Lighting",   Size = Vector3.new(1, 5, 1),   Color = Color3.fromRGB(139, 90, 43),    Material = Enum.Material.Wood },
    { Id = "furn_012", Name = "Neon Flamingo Sign",    Category = "Lighting",   Size = Vector3.new(3, 4, 0.5), Color = Color3.fromRGB(255, 105, 180),   Material = Enum.Material.Neon },
    { Id = "furn_013", Name = "Paper Lantern String",  Category = "Lighting",   Size = Vector3.new(8, 1, 1),   Color = Color3.fromRGB(255, 200, 100),   Material = Enum.Material.Fabric },

    -- ═══════════ POOL / WATER ═══════════
    { Id = "furn_014", Name = "Kidney Pool",           Category = "Pool",       Size = Vector3.new(8, 1, 5),   Color = Color3.fromRGB(60, 180, 220),   Material = Enum.Material.Glass },
    { Id = "furn_015", Name = "Hot Tub",               Category = "Pool",       Size = Vector3.new(4, 2, 4),   Color = Color3.fromRGB(60, 180, 220),   Material = Enum.Material.Glass },
    { Id = "furn_016", Name = "Fountain",              Category = "Pool",       Size = Vector3.new(3, 4, 3),   Color = Color3.fromRGB(200, 200, 200),   Material = Enum.Material.Marble },

    -- ═══════════ PLANTS ═══════════
    { Id = "furn_017", Name = "Potted Palm",           Category = "Plants",     Size = Vector3.new(2, 6, 2),   Color = Color3.fromRGB(34, 120, 50),    Material = Enum.Material.Grass },
    { Id = "furn_018", Name = "Barrel Cactus",         Category = "Plants",     Size = Vector3.new(2, 2, 2),   Color = Color3.fromRGB(50, 130, 50),    Material = Enum.Material.SmoothPlastic },
    { Id = "furn_019", Name = "Bird of Paradise",      Category = "Plants",     Size = Vector3.new(2, 4, 2),   Color = Color3.fromRGB(255, 120, 0),    Material = Enum.Material.Grass },
    { Id = "furn_020", Name = "Agave Plant",           Category = "Plants",     Size = Vector3.new(3, 2, 3),   Color = Color3.fromRGB(100, 160, 100),   Material = Enum.Material.Grass },
    { Id = "furn_021", Name = "Bougainvillea Trellis", Category = "Plants",     Size = Vector3.new(4, 6, 1),   Color = Color3.fromRGB(200, 50, 100),    Material = Enum.Material.Grass },

    -- ═══════════ DECOR ═══════════
    { Id = "furn_022", Name = "Pink Flamingo Lawn",    Category = "Decor",      Size = Vector3.new(1, 3, 1),   Color = Color3.fromRGB(255, 105, 180),   Material = Enum.Material.SmoothPlastic },
    { Id = "furn_023", Name = "Retro Motel Sign",      Category = "Decor",      Size = Vector3.new(4, 6, 0.5), Color = Color3.fromRGB(255, 100, 100),   Material = Enum.Material.Neon },
    { Id = "furn_024", Name = "Sunburst Mirror",       Category = "Decor",      Size = Vector3.new(3, 3, 0.5), Color = Color3.fromRGB(255, 215, 0),     Material = Enum.Material.Metal },
    { Id = "furn_025", Name = "Desert Rug",            Category = "Decor",      Size = Vector3.new(4, 0.2, 3), Color = Color3.fromRGB(200, 100, 50),    Material = Enum.Material.Fabric },
    { Id = "furn_026", Name = "Vinyl Record Player",   Category = "Decor",      Size = Vector3.new(2, 2, 1),   Color = Color3.fromRGB(139, 90, 43),     Material = Enum.Material.Wood },

    -- ═══════════ STRUCTURES ═══════════
    { Id = "furn_027", Name = "Breeze Block Wall",     Category = "Structure",  Size = Vector3.new(6, 6, 1),   Color = Color3.fromRGB(220, 220, 220),   Material = Enum.Material.Concrete },
    { Id = "furn_028", Name = "Flat Roof Awning",      Category = "Structure",  Size = Vector3.new(8, 0.5, 6), Color = Color3.fromRGB(200, 200, 200),   Material = Enum.Material.Concrete },
    { Id = "furn_029", Name = "Stone Pathway",         Category = "Structure",  Size = Vector3.new(2, 0.2, 6), Color = Color3.fromRGB(180, 170, 160),   Material = Enum.Material.Slate },
    { Id = "furn_030", Name = "Adobe Wall Section",    Category = "Structure",  Size = Vector3.new(6, 4, 1),   Color = Color3.fromRGB(210, 180, 140),   Material = Enum.Material.Sandstone },

    -- ═══════════ ENTERTAINMENT ═══════════
    { Id = "furn_031", Name = "Retro TV Set",          Category = "Entertainment", Size = Vector3.new(2, 3, 2), Color = Color3.fromRGB(139, 90, 43),  Material = Enum.Material.Wood },
    { Id = "furn_032", Name = "Jukebox",               Category = "Entertainment", Size = Vector3.new(2, 4, 1), Color = Color3.fromRGB(200, 50, 50),  Material = Enum.Material.Metal },
    { Id = "furn_033", Name = "Pinball Machine",       Category = "Entertainment", Size = Vector3.new(2, 4, 3), Color = Color3.fromRGB(255, 215, 0),  Material = Enum.Material.Metal },
    { Id = "furn_034", Name = "Outdoor Cinema Screen", Category = "Entertainment", Size = Vector3.new(8, 5, 0.5), Color = Color3.fromRGB(240, 240, 240), Material = Enum.Material.SmoothPlastic },

    -- ═══════════ KITCHEN ═══════════
    { Id = "furn_035", Name = "Retro Fridge",          Category = "Kitchen",    Size = Vector3.new(2, 4, 2),   Color = Color3.fromRGB(150, 220, 200),   Material = Enum.Material.Metal },
    { Id = "furn_036", Name = "BBQ Grill",             Category = "Kitchen",    Size = Vector3.new(3, 3, 2),   Color = Color3.fromRGB(40, 40, 40),      Material = Enum.Material.Metal },
    { Id = "furn_037", Name = "Smoothie Bar",          Category = "Kitchen",    Size = Vector3.new(4, 3, 2),   Color = Color3.fromRGB(255, 200, 100),   Material = Enum.Material.Wood },

    -- ═══════════ VEHICLES (DISPLAY) ═══════════
    { Id = "furn_038", Name = "Pink Cadillac",         Category = "Vehicle",    Size = Vector3.new(6, 3, 3),   Color = Color3.fromRGB(255, 150, 180),   Material = Enum.Material.SmoothPlastic },
    { Id = "furn_039", Name = "Volkswagen Van",        Category = "Vehicle",    Size = Vector3.new(5, 4, 3),   Color = Color3.fromRGB(100, 200, 255),   Material = Enum.Material.SmoothPlastic },
    { Id = "furn_040", Name = "Golf Cart",             Category = "Vehicle",    Size = Vector3.new(3, 3, 2),   Color = Color3.fromRGB(255, 255, 255),   Material = Enum.Material.SmoothPlastic },

    -- ═══════════ ART ═══════════
    { Id = "furn_041", Name = "Hockney Pool Painting", Category = "Art",        Size = Vector3.new(4, 3, 0.3), Color = Color3.fromRGB(60, 180, 220),    Material = Enum.Material.SmoothPlastic },
    { Id = "furn_042", Name = "Warhol Print",          Category = "Art",        Size = Vector3.new(3, 3, 0.3), Color = Color3.fromRGB(255, 100, 100),   Material = Enum.Material.SmoothPlastic },
    { Id = "furn_043", Name = "Desert Sculpture",      Category = "Art",        Size = Vector3.new(2, 5, 2),   Color = Color3.fromRGB(180, 140, 100),   Material = Enum.Material.Marble },

    -- ═══════════ EXCLUSIVE (ARCHITECT PASS) ═══════════
    { Id = "furn_044", Name = "Crystal Pool",          Category = "Exclusive",  Size = Vector3.new(10, 1, 6),  Color = Color3.fromRGB(100, 220, 255),   Material = Enum.Material.Glass,  Exclusive = true },
    { Id = "furn_045", Name = "Gold Palm Tree",        Category = "Exclusive",  Size = Vector3.new(3, 8, 3),   Color = Color3.fromRGB(255, 215, 0),    Material = Enum.Material.Metal,  Exclusive = true },
    { Id = "furn_046", Name = "Holographic DJ Booth",  Category = "Exclusive",  Size = Vector3.new(4, 3, 2),   Color = Color3.fromRGB(150, 100, 255),   Material = Enum.Material.Neon,   Exclusive = true },
    { Id = "furn_047", Name = "Floating Oasis Island", Category = "Exclusive",  Size = Vector3.new(8, 2, 8),   Color = Color3.fromRGB(100, 200, 100),   Material = Enum.Material.Grass,  Exclusive = true },

    -- ═══════════ MISC ═══════════
    { Id = "furn_048", Name = "Fire Pit",              Category = "Misc",       Size = Vector3.new(3, 1, 3),   Color = Color3.fromRGB(60, 60, 60),     Material = Enum.Material.Slate },
    { Id = "furn_049", Name = "Hammock",               Category = "Misc",       Size = Vector3.new(2, 3, 5),   Color = Color3.fromRGB(255, 200, 150),   Material = Enum.Material.Fabric },
    { Id = "furn_050", Name = "Telescope",             Category = "Misc",       Size = Vector3.new(1, 4, 1),   Color = Color3.fromRGB(180, 180, 180),   Material = Enum.Material.Metal },
    { Id = "furn_051", Name = "Icon Display Pedestal", Category = "Special",    Size = Vector3.new(3, 4, 3),   Color = Color3.fromRGB(240, 220, 180),   Material = Enum.Material.Marble },
    { Id = "furn_052", Name = "Welcome Mat",           Category = "Misc",       Size = Vector3.new(3, 0.1, 2), Color = Color3.fromRGB(200, 150, 100),   Material = Enum.Material.Fabric },
}

-- Build O(1) lookup
FurnitureDatabase._byId = {}
FurnitureDatabase._byCategory = {}

for _, item in ipairs(FurnitureDatabase.Items) do
    FurnitureDatabase._byId[item.Id] = item
    if not FurnitureDatabase._byCategory[item.Category] then
        FurnitureDatabase._byCategory[item.Category] = {}
    end
    table.insert(FurnitureDatabase._byCategory[item.Category], item)
end

function FurnitureDatabase.GetById(itemId: string): table?
    return FurnitureDatabase._byId[itemId]
end

function FurnitureDatabase.GetByCategory(category: string): { table }
    return FurnitureDatabase._byCategory[category] or {}
end

function FurnitureDatabase.GetAll(): { table }
    return FurnitureDatabase.Items
end

function FurnitureDatabase.GetCategories(): { string }
    local cats = {}
    for cat, _ in FurnitureDatabase._byCategory do
        table.insert(cats, cat)
    end
    table.sort(cats)
    return cats
end

return FurnitureDatabase
