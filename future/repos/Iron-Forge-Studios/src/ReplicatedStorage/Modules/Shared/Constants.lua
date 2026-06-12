--[[
    Constants.lua
    Central configuration for Palm Springs Paradise: Steal the Oasis
    All tuning values, enums, and shared config live here.
]]

local Constants = {}

-- ═══════════════════════════════════════════════════════════════
-- WORLD
-- ═══════════════════════════════════════════════════════════════
Constants.WORLD_SIZE = 2048 -- studs per axis
Constants.MAX_PLAYERS = 100
Constants.TICK_RATE = 1 / 60 -- 60 FPS target

Constants.Zones = {
    DOWNTOWN         = "DowntownPalmSprings",
    HOT_SPRINGS      = "AguaCalienteHotSprings",
    INDIAN_CANYONS   = "IndianCanyons",
    WIND_FARM        = "WindFarmValley",
    TRAMWAY_SUMMIT   = "AerialTramwaySummit",
    NEIGHBORHOOD     = "MidCenturyNeighborhood",
    FAIRGROUNDS      = "CoachellaFairgrounds",
}

Constants.ZoneData = {
    [Constants.Zones.DOWNTOWN] = {
        DisplayName = "Downtown Palm Springs",
        Description = "Spawn, shops, Trade Hub, leaderboards",
        Center = Vector3.new(0, 0, 0),
        Radius = 300,
        SpawnZone = true,
    },
    [Constants.Zones.HOT_SPRINGS] = {
        DisplayName = "Agua Caliente Hot Springs",
        Description = "Rare egg spawns, social area, hatching",
        Center = Vector3.new(500, 0, 200),
        Radius = 250,
    },
    [Constants.Zones.INDIAN_CANYONS] = {
        DisplayName = "Indian Canyons",
        Description = "Parkour, hidden eggs",
        Center = Vector3.new(-400, 0, 500),
        Radius = 280,
    },
    [Constants.Zones.WIND_FARM] = {
        DisplayName = "Wind Farm Valley",
        Description = "Tech icons, speed boosts",
        Center = Vector3.new(0, 0, -600),
        Radius = 300,
    },
    [Constants.Zones.TRAMWAY_SUMMIT] = {
        DisplayName = "Aerial Tramway Summit",
        Description = "Legendary eggs, VIP area",
        Center = Vector3.new(-600, 200, -300),
        Radius = 200,
    },
    [Constants.Zones.NEIGHBORHOOD] = {
        DisplayName = "Mid-Century Neighborhood",
        Description = "100 player oasis plots, 32x32 each",
        Center = Vector3.new(600, 0, -400),
        Radius = 400,
    },
    [Constants.Zones.FAIRGROUNDS] = {
        DisplayName = "Coachella Fairgrounds",
        Description = "Events, festivals",
        Center = Vector3.new(-200, 0, -800),
        Radius = 350,
    },
}

-- ═══════════════════════════════════════════════════════════════
-- ECONOMY
-- ═══════════════════════════════════════════════════════════════
Constants.CURRENCY_NAME = "DesertCoins"
Constants.CURRENCY_ABBREVIATION = "DC"
Constants.STARTING_CURRENCY = 500
Constants.TRADE_TAX_PERCENT = 5
Constants.VISITOR_INCOME_PER_DAY = 1 -- DC per unique visitor per day

-- ═══════════════════════════════════════════════════════════════
-- EGGS
-- ═══════════════════════════════════════════════════════════════
Constants.EggTiers = {
    { Name = "Common Egg",     Cost = 100,   Color = Color3.fromRGB(139, 119, 101) },
    { Name = "Uncommon Egg",   Cost = 500,   Color = Color3.fromRGB(72, 160, 120) },
    { Name = "Rare Egg",       Cost = 2500,  Color = Color3.fromRGB(65, 105, 225) },
    { Name = "Legendary Egg",  Cost = 10000, Color = Color3.fromRGB(218, 165, 32) },
}

-- ═══════════════════════════════════════════════════════════════
-- RARITIES
-- ═══════════════════════════════════════════════════════════════
Constants.Rarities = {
    Common    = { Weight = 4500, PassiveIncome = 1,   Color = Color3.fromRGB(180, 180, 180) },
    Uncommon  = { Weight = 2500, PassiveIncome = 3,   Color = Color3.fromRGB(76, 175, 80) },
    Rare      = { Weight = 1500, PassiveIncome = 8,   Color = Color3.fromRGB(33, 150, 243) },
    Epic      = { Weight = 800,  PassiveIncome = 20,  Color = Color3.fromRGB(156, 39, 176) },
    Legendary = { Weight = 400,  PassiveIncome = 50,  Color = Color3.fromRGB(255, 193, 7) },
    Mythical  = { Weight = 290,  PassiveIncome = 150, Color = Color3.fromRGB(244, 67, 54) },
    SECRET    = { Weight = 10,   PassiveIncome = 500, Color = Color3.fromRGB(255, 255, 255) },
}

Constants.RARITY_ORDER = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical", "SECRET" }
Constants.TOTAL_RARITY_WEIGHT = 10000

-- ═══════════════════════════════════════════════════════════════
-- EVOLUTION
-- ═══════════════════════════════════════════════════════════════
Constants.Evolutions = {
    { Name = "Shiny",    DupesRequired = 3,  Multiplier = 2  },
    { Name = "Golden",   DupesRequired = 5,  Multiplier = 4  },
    { Name = "Diamond",  DupesRequired = 10, Multiplier = 8  },
    { Name = "Celestial",DupesRequired = 25, Multiplier = 16 },
}

-- ═══════════════════════════════════════════════════════════════
-- HEIST
-- ═══════════════════════════════════════════════════════════════
Constants.Heist = {
    COUNTDOWN_SECONDS = 10,
    LOCKPICK_SECONDS = 15,
    FAIL_COOLDOWN_SECONDS = 30 * 60, -- 30 minutes
    TARGET_COOLDOWN_SECONDS = 30 * 60,
    NEWBIE_SHIELD_SECONDS = 30 * 60,
    DAILY_ATTEMPTS = 10,
    SERVER_HOP_LOCKOUT_SECONDS = 5 * 60,
    FREE_VAULT_SLOTS = 3,
    VAULT_EXPANSION_SLOTS = 5,
    VAULT_EXPANSION_ROBUX = 199,
}

-- ═══════════════════════════════════════════════════════════════
-- BUILDING / PLOTS
-- ═══════════════════════════════════════════════════════════════
Constants.Plot = {
    SIZE = 32, -- studs
    GRID_CELL = 1, -- 1 stud grid snapping
    MAX_ITEMS = 200,
    STAR_RATING_MAX = 5,
    MAX_PLOTS_DEFAULT = 1,
    MAX_PLOTS_ARCHITECT = 2,
}

-- ═══════════════════════════════════════════════════════════════
-- GAME PASSES
-- ═══════════════════════════════════════════════════════════════
Constants.GamePasses = {
    DesertVIP = {
        Name = "Desert VIP",
        Robux = 799,
        PassId = 0, -- Replace with real ID
        Benefits = { "2x income", "VIP zone access", "Gold name tag" },
    },
    HeistMaster = {
        Name = "Heist Master",
        Robux = 499,
        PassId = 0,
        Benefits = { "3 extra daily heists", "Heist radar" },
    },
    AutoCollector = {
        Name = "Auto-Collector",
        Robux = 399,
        PassId = 0,
        Benefits = { "Offline income up to 8hr" },
    },
    OasisArchitect = {
        Name = "Oasis Architect",
        Robux = 349,
        PassId = 0,
        Benefits = { "Double plots", "Exclusive furniture" },
    },
    SpeedDemon = {
        Name = "Speed Demon",
        Robux = 249,
        PassId = 0,
        Benefits = { "2x walk speed", "Desert cart", "Zone teleport" },
    },
    MegaBundle = {
        Name = "Mega Bundle",
        Robux = 1999,
        PassId = 0,
        Benefits = { "All passes", "10000 DC", "SECRET egg" },
    },
}

-- ═══════════════════════════════════════════════════════════════
-- DEVELOPER PRODUCTS
-- ═══════════════════════════════════════════════════════════════
Constants.DevProducts = {
    DC1000       = { Name = "1,000 Desert Coins",  Robux = 99,  DC = 1000,  ProductId = 0 },
    DC5000       = { Name = "5,000 Desert Coins",  Robux = 399, DC = 5000,  ProductId = 0 },
    PremiumEgg   = { Name = "Premium Egg",         Robux = 149, DC = 0,     ProductId = 0 },
    LegendaryEgg = { Name = "Legendary Egg",       Robux = 499, DC = 0,     ProductId = 0 },
    LuckyBoost   = { Name = "Lucky Boost (30min)", Robux = 49,  DC = 0,     ProductId = 0 },
    Shield       = { Name = "Heist Shield (1hr)",  Robux = 79,  DC = 0,     ProductId = 0 },
    VaultExpand  = { Name = "Vault +5 Slots",      Robux = 199, DC = 0,     ProductId = 0 },
}

-- ═══════════════════════════════════════════════════════════════
-- RATE LIMITING
-- ═══════════════════════════════════════════════════════════════
Constants.RateLimit = {
    REMOTE_CALLS_PER_SECOND = 10,
    TRADE_REQUESTS_PER_MINUTE = 5,
    EGG_HATCHES_PER_SECOND = 2,
    HEIST_START_COOLDOWN = 5,
}

-- ═══════════════════════════════════════════════════════════════
-- DATASTORE
-- ═══════════════════════════════════════════════════════════════
Constants.DataStore = {
    NAME = "PalmSpringsParadise_v2",
    PLAYER_KEY_PREFIX = "Player_",
    AUTOSAVE_INTERVAL = 60,
    RETRY_ATTEMPTS = 3,
    RETRY_DELAY = 2,
    SESSION_LOCK_DURATION = 1800,
}

-- ═══════════════════════════════════════════════════════════════
-- TRADING
-- ═══════════════════════════════════════════════════════════════
Constants.Trade = {
    CONFIRM_TIMER = 30,
    MAX_ITEMS_PER_SIDE = 10,
    TAX_PERCENT = 5,
    CROSS_SERVER_TOPIC = "PalmSpringsTrade",
}

return Constants
