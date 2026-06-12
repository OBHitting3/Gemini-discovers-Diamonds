--[[
    ItemCatalog.lua
    Complete catalog of all purchasable / placeable items in
    Palm Springs Paradise.  Organized into four categories:
      1. Furniture  (MCM home decor)
      2. Plants     (desert garden)
      3. Boutique   (El Paseo shop goods)
      4. Fashion    (outfit items for runway)

    Every item has an id, name, category, price, and rendering metadata.
]]

local ItemCatalog = {}

---------------------------------------------------------------------------
-- 1. FURNITURE  (~20 MCM items)
---------------------------------------------------------------------------
ItemCatalog.Furniture = {
    {
        id          = "eames_lounge",
        name        = "Eames Lounge Chair",
        category    = "seating",
        price       = 120,
        size        = { x = 3, y = 3, z = 3 },
        color       = "Terracotta",
        material    = "SmoothPlastic",
        description = "Iconic mid-century lounger with leather cushion feel",
    },
    {
        id          = "kidney_table",
        name        = "Kidney Coffee Table",
        category    = "table",
        price       = 80,
        size        = { x = 4, y = 1.5, z = 3 },
        color       = "WallWhite",
        material    = "SmoothPlastic",
        description = "Organic boomerang-shaped table in classic white",
    },
    {
        id          = "boomerang_table",
        name        = "Boomerang Side Table",
        category    = "table",
        price       = 60,
        size        = { x = 2, y = 1.5, z = 2 },
        color       = "Turquoise",
        material    = "SmoothPlastic",
        description = "Small curved side table in turquoise",
    },
    {
        id          = "starburst_clock",
        name        = "Starburst Wall Clock",
        category    = "decor",
        price       = 45,
        size        = { x = 3, y = 3, z = 0.5 },
        color       = "UISunCoin",
        material    = "SmoothPlastic",
        description = "Gold starburst clock — the MCM icon",
    },
    {
        id          = "nelson_lamp",
        name        = "Nelson Bubble Lamp",
        category    = "lighting",
        price       = 90,
        size        = { x = 2, y = 4, z = 2 },
        color       = "WallWhite",
        material    = "SmoothPlastic",
        description = "Soft-glow orb lamp on slender stand",
    },
    {
        id          = "butterfly_chair",
        name        = "Butterfly Chair",
        category    = "seating",
        price       = 75,
        size        = { x = 3, y = 3, z = 3 },
        color       = "DustyPink",
        material    = "Fabric",
        description = "Sling-seat butterfly frame in dusty pink",
    },
    {
        id          = "credenza",
        name        = "Walnut Credenza",
        category    = "table",
        price       = 150,
        size        = { x = 6, y = 2.5, z = 1.5 },
        color       = "PalmTrunk",
        material    = "Wood",
        description = "Long low walnut cabinet with sliding doors",
    },
    {
        id          = "modular_sofa",
        name        = "Modular Sofa Section",
        category    = "seating",
        price       = 100,
        size        = { x = 4, y = 2, z = 3 },
        color       = "Turquoise",
        material    = "Fabric",
        description = "Turquoise upholstered sofa module",
    },
    {
        id          = "outdoor_lounge",
        name        = "Poolside Lounger",
        category    = "outdoor",
        price       = 65,
        size        = { x = 2, y = 1.5, z = 6 },
        color       = "WallWhite",
        material    = "SmoothPlastic",
        description = "Reclining pool lounge chair",
    },
    {
        id          = "bar_cart",
        name        = "Brass Bar Cart",
        category    = "table",
        price       = 85,
        size        = { x = 2, y = 3, z = 1.5 },
        color       = "UISunCoin",
        material    = "SmoothPlastic",
        description = "Two-tier brass rolling bar cart",
    },
    {
        id          = "planter_box",
        name        = "Concrete Planter Box",
        category    = "outdoor",
        price       = 35,
        size        = { x = 2, y = 2, z = 2 },
        color       = "Concrete",
        material    = "Concrete",
        description = "Square concrete planter for succulents",
    },
    {
        id          = "sunburst_mirror",
        name        = "Sunburst Mirror",
        category    = "decor",
        price       = 55,
        size        = { x = 3, y = 3, z = 0.5 },
        color       = "UISunCoin",
        material    = "SmoothPlastic",
        description = "Round mirror with gold sunburst frame",
    },
    {
        id          = "arc_floor_lamp",
        name        = "Arc Floor Lamp",
        category    = "lighting",
        price       = 95,
        size        = { x = 2, y = 6, z = 2 },
        color       = "WallWhite",
        material    = "SmoothPlastic",
        description = "Arching chrome floor lamp with dome shade",
    },
    {
        id          = "egg_chair",
        name        = "Egg Pod Chair",
        category    = "seating",
        price       = 130,
        size        = { x = 3, y = 4, z = 3 },
        color       = "WallWhite",
        material    = "SmoothPlastic",
        description = "Futuristic egg-shaped swivel chair",
    },
    {
        id          = "terrazzo_table",
        name        = "Terrazzo Dining Table",
        category    = "table",
        price       = 110,
        size        = { x = 5, y = 2.5, z = 5 },
        color       = "Concrete",
        material    = "Marble",
        description = "Round terrazzo table with tapered legs",
    },
    {
        id          = "shag_rug",
        name        = "Shag Area Rug",
        category    = "decor",
        price       = 40,
        size        = { x = 6, y = 0.2, z = 4 },
        color       = "DustyPink",
        material    = "Fabric",
        description = "Plush dusty-pink area rug",
    },
    {
        id          = "patio_umbrella",
        name        = "Patio Umbrella",
        category    = "outdoor",
        price       = 50,
        size        = { x = 4, y = 6, z = 4 },
        color       = "Terracotta",
        material    = "Fabric",
        description = "Large terracotta shade umbrella on pole",
    },
    {
        id          = "hanging_planter",
        name        = "Macrame Hanging Planter",
        category    = "decor",
        price       = 30,
        size        = { x = 1.5, y = 3, z = 1.5 },
        color       = "CactusGreen",
        material    = "SmoothPlastic",
        description = "Woven planter with trailing greenery",
    },
    {
        id          = "record_player",
        name        = "Vintage Record Player",
        category    = "decor",
        price       = 70,
        size        = { x = 2, y = 1, z = 1.5 },
        color       = "PalmTrunk",
        material    = "Wood",
        description = "Walnut-cased turntable with built-in speakers",
    },
    {
        id          = "breeze_screen",
        name        = "Decorative Breeze Block Screen",
        category    = "outdoor",
        price       = 55,
        size        = { x = 6, y = 6, z = 1 },
        color       = "BreezeBlock",
        material    = "Concrete",
        description = "Freestanding geometric breeze-block wall panel",
    },
    -- Modernism Week special editions
    {
        id          = "mw_starburst_clock",
        name        = "MW Platinum Starburst Clock",
        category    = "decor",
        price       = 200,
        size        = { x = 3, y = 3, z = 0.5 },
        color       = "WallWhite",
        material    = "SmoothPlastic",
        description = "Limited Modernism Week platinum edition clock",
    },
    {
        id          = "mw_eames_rocker",
        name        = "MW Eames Rocking Chair",
        category    = "seating",
        price       = 250,
        size        = { x = 3, y = 3, z = 3 },
        color       = "Turquoise",
        material    = "SmoothPlastic",
        description = "Limited Modernism Week turquoise Eames rocker",
    },
    {
        id          = "mw_nelson_bench",
        name        = "MW Nelson Platform Bench",
        category    = "seating",
        price       = 180,
        size        = { x = 6, y = 1.5, z = 2 },
        color       = "PalmTrunk",
        material    = "Wood",
        description = "Limited Modernism Week slatted platform bench",
    },
}

---------------------------------------------------------------------------
-- 2. PLANTS  (~10 desert plants)
---------------------------------------------------------------------------
ItemCatalog.Plants = {
    {
        id              = "saguaro_cactus",
        name            = "Saguaro Cactus",
        seedPrice       = 20,
        growTime         = 300,
        waterInterval   = 120,
        harvestValue    = 50,
        prestigeReward  = 5,
        description     = "Tall columnar cactus — iconic desert sentinel",
    },
    {
        id              = "barrel_cactus",
        name            = "Barrel Cactus",
        seedPrice       = 15,
        growTime         = 240,
        waterInterval   = 150,
        harvestValue    = 35,
        prestigeReward  = 3,
        description     = "Round ribbed cactus with golden spines",
    },
    {
        id              = "agave",
        name            = "Blue Agave",
        seedPrice       = 25,
        growTime         = 360,
        waterInterval   = 100,
        harvestValue    = 60,
        prestigeReward  = 8,
        description     = "Dramatic rosette of blue-green leaves",
    },
    {
        id              = "desert_marigold",
        name            = "Desert Marigold",
        seedPrice       = 10,
        growTime         = 180,
        waterInterval   = 90,
        harvestValue    = 25,
        prestigeReward  = 2,
        description     = "Bright yellow wildflower that thrives in sand",
    },
    {
        id              = "bougainvillea",
        name            = "Bougainvillea",
        seedPrice       = 30,
        growTime         = 300,
        waterInterval   = 80,
        harvestValue    = 70,
        prestigeReward  = 10,
        description     = "Cascading magenta blooms over arching branches",
    },
    {
        id              = "palm_tree",
        name            = "Fan Palm Sapling",
        seedPrice       = 40,
        growTime         = 420,
        waterInterval   = 120,
        harvestValue    = 80,
        prestigeReward  = 12,
        description     = "Young California fan palm — garden centerpiece",
    },
    {
        id              = "bird_of_paradise",
        name            = "Bird of Paradise",
        seedPrice       = 35,
        growTime         = 300,
        waterInterval   = 90,
        harvestValue    = 65,
        prestigeReward  = 8,
        description     = "Tropical plant with orange crane-like flowers",
    },
    {
        id              = "prickly_pear",
        name            = "Prickly Pear Cactus",
        seedPrice       = 12,
        growTime         = 200,
        waterInterval   = 160,
        harvestValue    = 30,
        prestigeReward  = 3,
        description     = "Flat-padded cactus with edible fruit",
    },
    {
        id              = "ocotillo",
        name            = "Ocotillo",
        seedPrice       = 22,
        growTime         = 280,
        waterInterval   = 140,
        harvestValue    = 45,
        prestigeReward  = 5,
        description     = "Tall spindly stems tipped with red flowers",
    },
    {
        id              = "desert_sage",
        name            = "Desert Sage",
        seedPrice       = 8,
        growTime         = 150,
        waterInterval   = 100,
        harvestValue    = 20,
        prestigeReward  = 2,
        description     = "Fragrant silver-green herb of the high desert",
    },
}

---------------------------------------------------------------------------
-- 3. BOUTIQUE GOODS  (~12 El Paseo shop items)
---------------------------------------------------------------------------
ItemCatalog.BoutiqueGoods = {
    {
        id          = "designer_sunglasses",
        name        = "Designer Sunglasses",
        category    = "accessory",
        basePrice   = 45,
        description = "Oversized retro frames with gradient lenses",
    },
    {
        id          = "straw_sunhat",
        name        = "Wide-Brim Straw Hat",
        category    = "accessory",
        basePrice   = 30,
        description = "Woven straw hat perfect for poolside shade",
    },
    {
        id          = "turquoise_bracelet",
        name        = "Turquoise Cuff Bracelet",
        category    = "accessory",
        basePrice   = 55,
        description = "Hammered silver cuff with turquoise stone",
    },
    {
        id          = "desert_art_print",
        name        = "Desert Landscape Print",
        category    = "art",
        basePrice   = 80,
        description = "Framed print of a Joshua Tree sunset panorama",
    },
    {
        id          = "palm_springs_poster",
        name        = "Vintage PS Travel Poster",
        category    = "art",
        basePrice   = 60,
        description = "Retro-style poster: 'Palm Springs — Desert Playground'",
    },
    {
        id          = "ceramic_vase",
        name        = "Handmade Ceramic Vase",
        category    = "home",
        basePrice   = 40,
        description = "Speckled terracotta vase with organic form",
    },
    {
        id          = "cactus_candle",
        name        = "Cactus Blossom Candle",
        category    = "home",
        basePrice   = 25,
        description = "Soy candle with desert flower fragrance",
    },
    {
        id          = "vintage_record",
        name        = "Vintage Vinyl Record",
        category    = "vintage",
        basePrice   = 35,
        description = "Classic mid-century jazz LP in sleeve",
    },
    {
        id          = "silk_scarf",
        name        = "Palm Print Silk Scarf",
        category    = "fashion",
        basePrice   = 50,
        description = "Luxe silk scarf with tropical palm motif",
    },
    {
        id          = "cocktail_recipe_book",
        name        = "Desert Cocktails Book",
        category    = "home",
        basePrice   = 20,
        description = "Hardcover book of classic Palm Springs cocktail recipes",
    },
    {
        id          = "woven_basket",
        name        = "Handwoven Market Basket",
        category    = "home",
        basePrice   = 30,
        description = "Natural fiber basket with leather handles",
    },
    {
        id          = "crystal_geode",
        name        = "Desert Crystal Geode",
        category    = "vintage",
        basePrice   = 70,
        description = "Split geode revealing amethyst crystals inside",
    },
}

---------------------------------------------------------------------------
-- 4. FASHION OUTFIT ITEMS  (~15 items across categories)
---------------------------------------------------------------------------
ItemCatalog.FashionOutfits = {
    -- Poolside
    {
        id             = "poolside_sarong",
        name           = "Poolside Sarong Set",
        category       = "poolside",
        price          = 40,
        prestigeBonus  = 5,
        description    = "Flowing turquoise sarong with matching top",
    },
    {
        id             = "swim_cabana",
        name           = "Cabana Swim Outfit",
        category       = "poolside",
        price          = 35,
        prestigeBonus  = 4,
        description    = "Classic striped swim set in retro cut",
    },
    -- Cocktail
    {
        id             = "cocktail_sequin",
        name           = "Sequin Cocktail Dress",
        category       = "cocktail",
        price          = 90,
        prestigeBonus  = 12,
        description    = "Sparkling dusty-pink cocktail number",
    },
    {
        id             = "cocktail_blazer",
        name           = "Linen Blazer Set",
        category       = "cocktail",
        price          = 75,
        prestigeBonus  = 10,
        description    = "Cream linen blazer with matching trousers",
    },
    -- Desert Casual
    {
        id             = "desert_denim",
        name           = "Desert Denim Look",
        category       = "desert_casual",
        price          = 30,
        prestigeBonus  = 3,
        description    = "Sun-faded denim with cactus embroidery",
    },
    {
        id             = "boho_maxi",
        name           = "Boho Maxi Dress",
        category       = "desert_casual",
        price          = 50,
        prestigeBonus  = 6,
        description    = "Flowing terracotta maxi with fringe detail",
    },
    -- Formal (Modernism Week)
    {
        id             = "mw_tuxedo",
        name           = "Modernism Week Tuxedo",
        category       = "formal",
        price          = 150,
        prestigeBonus  = 20,
        description    = "Sleek black tuxedo with turquoise pocket square",
    },
    {
        id             = "mw_gown",
        name           = "Modernism Week Gown",
        category       = "formal",
        price          = 160,
        prestigeBonus  = 22,
        description    = "Floor-length white gown with architectural lines",
    },
    -- Vintage
    {
        id             = "vintage_swing",
        name           = "Vintage Swing Dress",
        category       = "vintage",
        price          = 60,
        prestigeBonus  = 8,
        description    = "1960s-inspired swing dress in pastel print",
    },
    {
        id             = "vintage_bowling",
        name           = "Retro Bowling Shirt",
        category       = "vintage",
        price          = 40,
        prestigeBonus  = 5,
        description    = "Two-tone bowling shirt with atomic print",
    },
    -- Resort
    {
        id             = "resort_kaftan",
        name           = "Resort Kaftan",
        category       = "resort",
        price          = 55,
        prestigeBonus  = 7,
        description    = "Lightweight kaftan with palm leaf print",
    },
    {
        id             = "resort_linen",
        name           = "Linen Resort Set",
        category       = "resort",
        price          = 65,
        prestigeBonus  = 8,
        description    = "Relaxed linen shirt and shorts in sand tone",
    },
    {
        id             = "resort_jumpsuit",
        name           = "Wide-Leg Jumpsuit",
        category       = "resort",
        price          = 70,
        prestigeBonus  = 9,
        description    = "Terracotta wide-leg jumpsuit with belt",
    },
    -- Extras
    {
        id             = "cactus_print_set",
        name           = "Cactus Print Co-ord",
        category       = "desert_casual",
        price          = 45,
        prestigeBonus  = 5,
        description    = "Matching cactus-print shirt and shorts",
    },
    {
        id             = "sunset_ombre",
        name           = "Sunset Ombre Dress",
        category       = "cocktail",
        price          = 85,
        prestigeBonus  = 11,
        description    = "Gradient dress fading from pink to gold",
    },
}

---------------------------------------------------------------------------
-- LOOKUP HELPERS
---------------------------------------------------------------------------

--- Find a furniture item by ID
function ItemCatalog.getFurniture(id: string)
    for _, item in ipairs(ItemCatalog.Furniture) do
        if item.id == id then return item end
    end
    return nil
end

--- Find a plant by ID
function ItemCatalog.getPlant(id: string)
    for _, item in ipairs(ItemCatalog.Plants) do
        if item.id == id then return item end
    end
    return nil
end

--- Find a boutique good by ID
function ItemCatalog.getBoutiqueGood(id: string)
    for _, item in ipairs(ItemCatalog.BoutiqueGoods) do
        if item.id == id then return item end
    end
    return nil
end

--- Find a fashion outfit by ID
function ItemCatalog.getFashionOutfit(id: string)
    for _, item in ipairs(ItemCatalog.FashionOutfits) do
        if item.id == id then return item end
    end
    return nil
end

--- Find any item across all catalogs by ID
function ItemCatalog.getAnyItem(id: string)
    return ItemCatalog.getFurniture(id)
        or ItemCatalog.getPlant(id)
        or ItemCatalog.getBoutiqueGood(id)
        or ItemCatalog.getFashionOutfit(id)
end

return ItemCatalog
