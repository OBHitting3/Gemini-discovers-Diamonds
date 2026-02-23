--[[
    GameConfig.lua
    Central configuration / constants for Palm Springs Paradise.
    All colors, economy values, timing, layout positions, and
    gameplay parameters are defined here so every other module
    reads from a single source of truth.

    LOCKED VISUAL IDENTITY — do NOT change sky/palette values
    without updating .cursor/rules/roblox-mcm.md
]]

local GameConfig = {}

---------------------------------------------------------------------------
-- COLOR PALETTE  (Locked Visual Identity)
---------------------------------------------------------------------------
GameConfig.Colors = {
    -- Sky gradient
    SkyTop        = Color3.fromRGB(135, 206, 235),   -- #87CEEB
    SkyBottom     = Color3.fromRGB(224, 240, 255),   -- #E0F0FF
    CloudWhite    = Color3.fromRGB(255, 255, 255),

    -- Architecture accents
    Terracotta    = Color3.fromRGB(204, 119, 34),
    Turquoise     = Color3.fromRGB(64, 224, 208),     -- pool water + accent
    DustyPink     = Color3.fromRGB(213, 166, 189),
    CactusGreen   = Color3.fromRGB(90, 143, 82),

    -- Structural
    Concrete      = Color3.fromRGB(200, 200, 200),
    BreezeBlock   = Color3.fromRGB(220, 220, 210),
    WallWhite     = Color3.fromRGB(245, 245, 245),
    RoofDarkGrey  = Color3.fromRGB(80, 80, 80),
    Glass         = Color3.fromRGB(200, 230, 255),     -- tinted transparent
    GlassTransparency = 0.6,

    -- Environment
    DesertSand    = Color3.fromRGB(237, 201, 175),
    Asphalt       = Color3.fromRGB(60, 60, 60),
    Sidewalk      = Color3.fromRGB(190, 185, 175),
    MountainPurple = Color3.fromRGB(120, 100, 130),
    PalmTrunk     = Color3.fromRGB(139, 90, 43),
    PalmCanopy    = Color3.fromRGB(34, 139, 34),

    -- UI
    UIPrimary     = Color3.fromRGB(64, 224, 208),     -- turquoise
    UISecondary   = Color3.fromRGB(213, 166, 189),    -- dusty pink
    UIBackground  = Color3.fromRGB(255, 252, 245),    -- warm white
    UIText        = Color3.fromRGB(50, 50, 50),
    UIAccent      = Color3.fromRGB(204, 119, 34),     -- terracotta
    UISunCoin     = Color3.fromRGB(255, 200, 50),     -- gold coin
}

---------------------------------------------------------------------------
-- LIGHTING  (Bright Blue Daytime — LOCKED)
---------------------------------------------------------------------------
GameConfig.Lighting = {
    ClockTime           = 12,
    Brightness          = 2,
    GeographicLatitude  = 33.83,   -- Palm Springs, CA
    Ambient             = Color3.fromRGB(135, 206, 235),
    OutdoorAmbient      = Color3.fromRGB(180, 210, 230),
    ColorShift_Top      = Color3.fromRGB(255, 255, 245),
    ColorShift_Bottom   = Color3.fromRGB(200, 200, 210),
    GlobalShadows       = true,
    ShadowSoftness      = 0.2,
    Technology          = Enum.Technology.Future, -- best mobile lighting

    -- Atmosphere
    Atmosphere = {
        Density  = 0.3,
        Offset   = 0.5,
        Color    = Color3.fromRGB(135, 206, 235),
        Decay    = Color3.fromRGB(180, 210, 230),
        Glare    = 0.1,
        Haze     = 1,
    },

    -- Night event override (toggled by NightToggleController)
    NightOverride = {
        ClockTime      = 21,
        Brightness     = 0.5,
        Ambient        = Color3.fromRGB(30, 30, 60),
        OutdoorAmbient = Color3.fromRGB(20, 20, 50),
    },
}

---------------------------------------------------------------------------
-- ECONOMY
---------------------------------------------------------------------------
GameConfig.Economy = {
    StartingCoins     = 100,
    StartingPrestige  = 0,

    -- Plot prices  (SunCoins)
    PlotPrices = {
        [1] = 500,
        [2] = 750,
        [3] = 1000,
        [4] = 1500,
    },

    -- El Paseo storefront rental costs
    StorefrontRental = {
        [1] = 300,
        [2] = 300,
        [3] = 400,
        [4] = 400,
        [5] = 500,
        [6] = 500,
    },

    -- Transaction tax (percentage taken by game sink)
    ShopTaxRate = 0.10,

    -- Fashion event prizes
    FashionPrizes = {
        { place = 1, coins = 200, prestige = 50 },
        { place = 2, coins = 100, prestige = 25 },
        { place = 3, coins = 50,  prestige = 10 },
    },

    -- Anti-exploit
    MaxTransactionsPerMinute = 10,
    MaxCoinGrant             = 10000,

    -- Game Passes (replace 0 with real Roblox game pass IDs after publish)
    GamePasses = {
        VIP         = 0,   -- gold name, priority event queue
        DoubleCoins = 0,   -- 2x SunCoins on all earnings
        AutoWater   = 0,   -- auto-water your garden plants every 90s
    },

    -- Dev Products (replace 0 with real Roblox product IDs after publish)
    DevProducts = {
        SUNCOINS_500  = 0,   -- replace with real Roblox product ID after publish
        SUNCOINS_1200 = 0,
        SUNCOINS_3000 = 0,
    },
    DevProductRewards = {
        [0] = 0,  -- placeholder mapping, replaced after publish
    },
}

---------------------------------------------------------------------------
-- TIMING
---------------------------------------------------------------------------
GameConfig.Timing = {
    -- Garden
    GardenTickInterval    = 5,       -- server tick every 5s
    SeedToSprout          = 60,      -- seconds
    SproutToGrowing       = 120,     -- seconds  (total 180 from plant)
    GrowingToMature       = 120,     -- seconds  (total 300 from plant)
    WiltWarningAfter      = 120,     -- seconds without water → wilt starts
    WiltToDead            = 30,      -- seconds of wilting → dead
    WateringCooldown      = 30,      -- seconds between waterings per player

    -- Fashion
    FashionEventInterval  = 600,     -- 10 minutes between events
    FashionEventDuration  = 120,     -- 2 minutes per event
    FashionMaxParticipants = 5,

    -- Persistence
    AutoSaveInterval      = 300,     -- 5 minutes
    SupabaseSyncInterval  = 60,      -- 1 minute

    -- Events
    EventCheckInterval    = 60,      -- check weekly theme rotation every 60s
}

---------------------------------------------------------------------------
-- WORLD LAYOUT
---------------------------------------------------------------------------
GameConfig.World = {
    -- Terrain
    TerrainSize    = Vector3.new(400, 4, 400),
    TerrainCenter  = Vector3.new(0, -2, 0),

    -- Residential plots  (4 plots in a grid)
    PlotSize       = Vector3.new(60, 0, 60),
    PlotPositions  = {
        [1] = Vector3.new(-80, 0, -80),
        [2] = Vector3.new(80, 0, -80),
        [3] = Vector3.new(-80, 0, 80),
        [4] = Vector3.new(80, 0, 80),
    },

    -- El Paseo boulevard  (runs along Z axis at X=0)
    ElPaseoStart     = Vector3.new(0, 0, -120),
    ElPaseoEnd       = Vector3.new(0, 0, 120),
    ElPaseoWidth     = 12,    -- studs (road width)
    SidewalkWidth    = 6,     -- studs per side

    -- Storefront positions (3 per side of boulevard)
    StorefrontPositions = {
        -- East side (positive X)
        [1] = { position = Vector3.new(18, 0, -80), rotation = 0 },
        [2] = { position = Vector3.new(18, 0, -40), rotation = 0 },
        [3] = { position = Vector3.new(18, 0,   0), rotation = 0 },
        -- West side (negative X)
        [4] = { position = Vector3.new(-18, 0, -80), rotation = 180 },
        [5] = { position = Vector3.new(-18, 0, -40), rotation = 180 },
        [6] = { position = Vector3.new(-18, 0,   0), rotation = 180 },
    },
    StorefrontSize = Vector3.new(20, 12, 16),

    -- Desert garden  (shared community area)
    GardenPosition = Vector3.new(0, 0, 60),
    GardenSize     = Vector3.new(40, 0, 40),
    GardenPlots    = 16,   -- 4×4 grid
    GardenPlotSize = Vector3.new(4, 0.5, 4),

    -- Fashion runway  (poolside area)
    RunwayPosition = Vector3.new(0, 0, -140),
    RunwaySize     = Vector3.new(6, 1, 30),

    -- Mountains  (distant backdrop)
    MountainDistance = 180,
    MountainHeight  = 80,

    -- Spawn
    SpawnPosition  = Vector3.new(0, 3, -100),
}

---------------------------------------------------------------------------
-- PART LIMITS
---------------------------------------------------------------------------
GameConfig.PartLimits = {
    MaxPartsPerPlot  = 200,
    MaxTotalParts    = 5000,
    EnvironmentBudget = 1500,
    HomeBudget       = 50,   -- per home
    StorefrontBudget = 30,   -- per storefront
}

---------------------------------------------------------------------------
-- HOME STYLES
---------------------------------------------------------------------------
GameConfig.HomeStyles = {
    Kaufmann = {
        name        = "The Kaufmann",
        description = "Flat-roof, L-shaped plan with turquoise kidney pool and breeze-block screen",
        roofType    = "flat",
        accentColor = "Terracotta",
        partBudget  = 40,
    },
    Frey = {
        name        = "The Frey",
        description = "Butterfly-roof with covered carport, glass walls on three sides",
        roofType    = "butterfly",
        accentColor = "Turquoise",
        partBudget  = 35,
    },
    Wexler = {
        name        = "The Wexler",
        description = "Flat-roof open-plan with central courtyard and dusty-pink accent wall",
        roofType    = "flat",
        accentColor = "DustyPink",
        partBudget  = 45,
    },
    Neutra = {
        name        = "The Neutra",
        description = "Butterfly-roof with full glass front and reflecting pool",
        roofType    = "butterfly",
        accentColor = "CactusGreen",
        partBudget  = 35,
    },
}

---------------------------------------------------------------------------
-- FASHION THEMES
---------------------------------------------------------------------------
GameConfig.FashionThemes = {
    "Poolside Chic",
    "Desert Noir",
    "Modernism Week Formal",
    "Retro Revival",
    "Sunset Soiree",
    "Cactus Couture",
    "Palm Springs Casual",
    "Vintage Glamour",
}

---------------------------------------------------------------------------
-- EVENT THEMES
---------------------------------------------------------------------------
GameConfig.EventThemes = {
    { name = "Poolside Paradise",  gardenBoost = 1.0, shopBonus = 0,   description = "Default relaxed vibes" },
    { name = "Desert Bloom",       gardenBoost = 1.5, shopBonus = 0,   description = "Garden growth 50% faster" },
    { name = "Retro Revival",      gardenBoost = 1.0, shopBonus = 0.2, description = "Vintage items 20% cheaper in shops" },
    { name = "Modernism Week",     gardenBoost = 1.0, shopBonus = 0,   description = "Limited MCM drops + bonus Prestige" },
    { name = "Sunset Soiree",      gardenBoost = 1.0, shopBonus = 0,   description = "Special evening fashion events" },
    { name = "Cactus Festival",    gardenBoost = 2.0, shopBonus = 0.1, description = "Double garden growth + shop discounts" },
}

---------------------------------------------------------------------------
-- MODERNISM WEEK  (Feb 12-22 — real-world tie-in)
---------------------------------------------------------------------------
GameConfig.ModernismWeek = {
    StartMonth = 2,
    StartDay   = 12,
    EndMonth   = 2,
    EndDay     = 22,
    BonusPrestigeMultiplier = 2.0,
    SpecialFurnitureIds = { "mw_starburst_clock", "mw_eames_rocker", "mw_nelson_bench" },
}

---------------------------------------------------------------------------
-- REMOTE EVENT / FUNCTION NAMES
---------------------------------------------------------------------------
GameConfig.Remotes = {
    Events = {
        "ClaimPlot",
        "PlaceFurniture",
        "RemoveFurniture",
        "WaterPlant",
        "PlantSeed",
        "HarvestPlant",
        "PurchaseItem",
        "SellItem",
        "JoinFashionEvent",
        "SubmitOutfit",
        "VoteOutfit",
        "ClaimShop",
        "UpdateShopInventory",
        "ToggleNight",
        "RequestPlayerData",
        "TriggerEvent",
        "BuildHome",
        -- Server → Client broadcasts
        "GardenStateUpdate",
        "FashionEventUpdate",
        "EventBroadcast",
        "NotifyPlayer",
        "EconomyUpdate",
        "ShopUpdate",
    },
    Functions = {
        "GetPlotData",
        "GetShopData",
        "GetGardenState",
        "GetLeaderboard",
    },
}

---------------------------------------------------------------------------
-- Freeze the config to prevent accidental mutation at runtime
---------------------------------------------------------------------------
if table.freeze then
    -- Deep-freeze isn't built-in; freeze top-level tables
    for key, value in pairs(GameConfig) do
        if type(value) == "table" then
            -- Freeze nested tables one level deep
            for subKey, subValue in pairs(value) do
                if type(subValue) == "table" then
                    table.freeze(subValue)
                end
            end
            table.freeze(value)
        end
    end
    table.freeze(GameConfig)
end

return GameConfig
