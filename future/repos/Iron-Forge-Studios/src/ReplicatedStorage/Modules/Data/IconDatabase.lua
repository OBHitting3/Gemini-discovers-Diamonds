--[[
    IconDatabase.lua
    All 50 collectible Desert Icons with their metadata.
    Each icon has: Id, Name, Rarity, Category, Description, ModelId
]]

local Constants = require(script.Parent.Parent.Shared.Constants)

local IconDatabase = {}

IconDatabase.Icons = {
    -- ═══════════ COMMON (≈45%) ═══════════
    { Id = "icon_001", Name = "Midcentury Sofa",       Rarity = "Common",    Category = "Furniture",  Description = "A sleek, low-profile sofa straight from 1958." },
    { Id = "icon_002", Name = "Palm Tree",             Rarity = "Common",    Category = "Nature",     Description = "The iconic California fan palm." },
    { Id = "icon_003", Name = "Cactus Bloom",          Rarity = "Common",    Category = "Nature",     Description = "A blooming barrel cactus in vibrant pink." },
    { Id = "icon_004", Name = "Poolside Lounge",       Rarity = "Common",    Category = "Furniture",  Description = "Relax by the pool in retro style." },
    { Id = "icon_005", Name = "Retro Motel Sign",      Rarity = "Common",    Category = "Landmark",   Description = "A neon-lit sign from a classic desert motel." },
    { Id = "icon_006", Name = "Date Palm Fruit",       Rarity = "Common",    Category = "Nature",     Description = "Sweet dates from the Coachella Valley." },
    { Id = "icon_007", Name = "Desert Pebbles",        Rarity = "Common",    Category = "Nature",     Description = "Smooth, sun-warmed stones." },
    { Id = "icon_008", Name = "Sunscreen Bottle",      Rarity = "Common",    Category = "Accessory",  Description = "SPF 50 — desert essential." },
    { Id = "icon_009", Name = "Tiki Torch",            Rarity = "Common",    Category = "Furniture",  Description = "Flickering flames for evening ambiance." },
    { Id = "icon_010", Name = "Coyote Paw Print",      Rarity = "Common",    Category = "Nature",     Description = "Tracks left by a desert coyote." },
    { Id = "icon_011", Name = "Adobe Brick",           Rarity = "Common",    Category = "Building",   Description = "Traditional sun-dried clay brick." },
    { Id = "icon_012", Name = "Tumble Weed",           Rarity = "Common",    Category = "Nature",     Description = "Rolling through the desert wind." },

    -- ═══════════ UNCOMMON (≈25%) ═══════════
    { Id = "icon_013", Name = "Pink Flamingo",         Rarity = "Uncommon",  Category = "Decor",      Description = "The quintessential lawn ornament." },
    { Id = "icon_014", Name = "Joshua Tree",           Rarity = "Uncommon",  Category = "Nature",     Description = "The twisted icon of the Mojave." },
    { Id = "icon_015", Name = "Wind Turbine",          Rarity = "Uncommon",  Category = "Tech",       Description = "Clean energy from the San Gorgonio Pass." },
    { Id = "icon_016", Name = "Sand Dune Surfer",      Rarity = "Uncommon",  Category = "Sport",      Description = "Catch waves on golden dunes." },
    { Id = "icon_017", Name = "Agua Caliente Spring",  Rarity = "Uncommon",  Category = "Landmark",   Description = "Steaming mineral waters of the Cahuilla." },
    { Id = "icon_018", Name = "Midcentury Lamp",       Rarity = "Uncommon",  Category = "Furniture",  Description = "An atomic-age starburst lamp." },
    { Id = "icon_019", Name = "Desert Iguana",         Rarity = "Uncommon",  Category = "Wildlife",   Description = "Basking on a warm rock." },
    { Id = "icon_020", Name = "Vintage Postcard",      Rarity = "Uncommon",  Category = "Collectible", Description = "Greetings from Palm Springs!" },
    { Id = "icon_021", Name = "Cocktail Umbrella",     Rarity = "Uncommon",  Category = "Accessory",  Description = "Tiny umbrella, big vibes." },
    { Id = "icon_022", Name = "Butterfly Garden",      Rarity = "Uncommon",  Category = "Nature",     Description = "Painted ladies fluttering in the breeze." },

    -- ═══════════ RARE (≈15%) ═══════════
    { Id = "icon_023", Name = "Desert Fox",            Rarity = "Rare",      Category = "Wildlife",   Description = "A kit fox with oversized ears." },
    { Id = "icon_024", Name = "Roadrunner",            Rarity = "Rare",      Category = "Wildlife",   Description = "Beep beep — fastest bird in the desert." },
    { Id = "icon_025", Name = "Desert Tortoise",       Rarity = "Rare",      Category = "Wildlife",   Description = "A wise, ancient shell-dweller." },
    { Id = "icon_026", Name = "Aerial Tram Car",       Rarity = "Rare",      Category = "Landmark",   Description = "Rotating gondola above Chino Canyon." },
    { Id = "icon_027", Name = "Coachella Stage",       Rarity = "Rare",      Category = "Landmark",   Description = "The legendary festival main stage." },
    { Id = "icon_028", Name = "Neon Cactus Sign",      Rarity = "Rare",      Category = "Decor",      Description = "A glowing neon cactus for your oasis." },
    { Id = "icon_029", Name = "Sunset Painting",       Rarity = "Rare",      Category = "Art",        Description = "A canvas capturing the desert sunset." },
    { Id = "icon_030", Name = "Bighorn Sheep",         Rarity = "Rare",      Category = "Wildlife",   Description = "Majestic horns on a rocky ledge." },

    -- ═══════════ EPIC (≈8%) ═══════════
    { Id = "icon_031", Name = "Vintage Cadillac",      Rarity = "Epic",      Category = "Vehicle",    Description = "A pink 1959 Cadillac convertible." },
    { Id = "icon_032", Name = "Frank Sinatra Hat",     Rarity = "Epic",      Category = "Celebrity",  Description = "Ol' Blue Eyes' signature fedora." },
    { Id = "icon_033", Name = "Elvis Sunglasses",      Rarity = "Epic",      Category = "Celebrity",  Description = "Gold-rimmed shades from the King." },
    { Id = "icon_034", Name = "Infinity Pool",         Rarity = "Epic",      Category = "Luxury",     Description = "An edge-to-edge pool overlooking the valley." },
    { Id = "icon_035", Name = "Desert Bloom Tiara",    Rarity = "Epic",      Category = "Accessory",  Description = "Crown of crystallized desert flowers." },
    { Id = "icon_036", Name = "Golden Hour Camera",    Rarity = "Epic",      Category = "Accessory",  Description = "Captures the perfect light, every time." },

    -- ═══════════ LEGENDARY (≈4%) ═══════════
    { Id = "icon_037", Name = "Marilyn Monroe Dress",  Rarity = "Legendary", Category = "Celebrity",  Description = "The iconic white dress, preserved in time." },
    { Id = "icon_038", Name = "Oasis Mirage",          Rarity = "Legendary", Category = "Mystical",   Description = "Is it real? Shimmering water in the sand." },
    { Id = "icon_039", Name = "Golden Palm Trophy",    Rarity = "Legendary", Category = "Award",      Description = "Awarded to the greatest oasis architect." },
    { Id = "icon_040", Name = "Crystal Hummingbird",   Rarity = "Legendary", Category = "Wildlife",   Description = "A hummingbird sculpted from desert quartz." },

    -- ═══════════ MYTHICAL (≈2.9%) ═══════════
    { Id = "icon_041", Name = "Phoenix Feather",       Rarity = "Mythical",  Category = "Mystical",   Description = "A feather from the legendary desert phoenix." },
    { Id = "icon_042", Name = "Stardust Cactus",       Rarity = "Mythical",  Category = "Mystical",   Description = "A cactus that blooms with starlight." },
    { Id = "icon_043", Name = "Eternal Sunset",        Rarity = "Mythical",  Category = "Mystical",   Description = "A bottled sunset that never fades." },

    -- ═══════════ SECRET (≈0.1%) ═══════════
    { Id = "icon_044", Name = "The Lost Oasis Map",    Rarity = "SECRET",    Category = "Legendary",  Description = "A map to a hidden paradise. Only the worthy find it." },
    { Id = "icon_045", Name = "Desert Heart Diamond",  Rarity = "SECRET",    Category = "Gem",        Description = "A flawless diamond formed over millennia." },

    -- ═══════════ ADDITIONAL ICONS (46-50) ═══════════
    { Id = "icon_046", Name = "Retro Radio",           Rarity = "Common",    Category = "Furniture",  Description = "Transistor radio playing oldies." },
    { Id = "icon_047", Name = "Jackrabbit",            Rarity = "Uncommon",  Category = "Wildlife",   Description = "Long ears and lightning speed." },
    { Id = "icon_048", Name = "Scorpion Brooch",       Rarity = "Rare",      Category = "Accessory",  Description = "A jeweled scorpion pin." },
    { Id = "icon_049", Name = "Solar Eclipse Crown",   Rarity = "Epic",      Category = "Mystical",   Description = "Forged during a rare desert eclipse." },
    { Id = "icon_050", Name = "Celestial Compass",     Rarity = "Mythical",  Category = "Mystical",   Description = "Points to whatever your heart desires." },
}

-- Build lookup tables for O(1) access
IconDatabase._byId = {}
IconDatabase._byRarity = {}

for _, rarity in ipairs(Constants.RARITY_ORDER) do
    IconDatabase._byRarity[rarity] = {}
end

for _, icon in ipairs(IconDatabase.Icons) do
    IconDatabase._byId[icon.Id] = icon
    if IconDatabase._byRarity[icon.Rarity] then
        table.insert(IconDatabase._byRarity[icon.Rarity], icon)
    end
end

function IconDatabase.GetById(iconId: string)
    return IconDatabase._byId[iconId]
end

function IconDatabase.GetByRarity(rarity: string)
    return IconDatabase._byRarity[rarity] or {}
end

function IconDatabase.GetAll()
    return IconDatabase.Icons
end

function IconDatabase.GetCount()
    return #IconDatabase.Icons
end

return IconDatabase
