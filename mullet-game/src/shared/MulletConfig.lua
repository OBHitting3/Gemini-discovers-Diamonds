--[[
    MulletConfig.lua
    Central configuration for Mullet Game.
    Defines economy values, multipliers, timing, zone layout,
    and remote event/function names used across all modules.
]]

local MulletConfig = {}

---------------------------------------------------------------------------
-- ECONOMY
---------------------------------------------------------------------------
MulletConfig.Economy = {
    StartingCoins       = 50,
    CoinPerKill         = 10,
    CoinPerWave         = 25,
    BossKillBonus       = 100,
    MaxCoinsPerSession  = 99999,

    -- Multiplier tiers (unlocked via prestige)
    CoinMultipliers = {
        [0] = 1.0,   -- default
        [1] = 1.25,
        [2] = 1.5,
        [3] = 2.0,
    },

    -- Anti-exploit
    MaxCoinGrantPerEvent    = 500,
    MaxTransactionsPerMinute = 20,
}

---------------------------------------------------------------------------
-- MULLET / HAIR PROGRESSION
---------------------------------------------------------------------------
MulletConfig.Mullet = {
    -- Mullet grows one level per milestone kill count
    GrowthMilestones = { 5, 15, 30, 50, 75, 100 },  -- cumulative kills

    -- Mullet level caps style unlocks
    StyleUnlocks = {
        [0] = "Baby Mullet",
        [1] = "Street Mullet",
        [2] = "Rock Mullet",
        [3] = "Power Mullet",
        [4] = "Ultra Mullet",
        [5] = "Legendary Mullet",
        [6] = "Transcendent Mullet",
    },

    -- Speed boost per mullet level (studs/s added to base walk speed)
    SpeedBonus = {
        [0] = 0,
        [1] = 2,
        [2] = 4,
        [3] = 6,
        [4] = 8,
        [5] = 10,
        [6] = 14,
    },

    -- Damage multiplier per mullet level
    DamageMultiplier = {
        [0] = 1.0,
        [1] = 1.1,
        [2] = 1.25,
        [3] = 1.5,
        [4] = 1.75,
        [5] = 2.0,
        [6] = 2.5,
    },

    BaseWalkSpeed = 16,
    MaxLevel      = 6,
}

---------------------------------------------------------------------------
-- WAVES
---------------------------------------------------------------------------
MulletConfig.Waves = {
    EnemiesPerWave     = 10,   -- base; scaled by wave number
    EnemyScaling       = 1.15, -- multiplier per wave
    WaveBreakDuration  = 8,    -- seconds between waves
    MaxWaves           = 30,
    BossWaveInterval   = 5,    -- boss spawns every N waves
}

---------------------------------------------------------------------------
-- TIMING
---------------------------------------------------------------------------
MulletConfig.Timing = {
    RespawnTime         = 5,    -- seconds
    SessionSaveInterval = 120,  -- seconds
    LeaderboardRefresh  = 30,   -- seconds
    ShopRefreshInterval = 600,  -- 10 minutes
}

---------------------------------------------------------------------------
-- REMOTE EVENT / FUNCTION NAMES
---------------------------------------------------------------------------
MulletConfig.Remotes = {
    Events = {
        -- Server → Client
        "UpdateMulletLevel",
        "UpdateCoins",
        "WaveStarted",
        "WaveCompleted",
        "BossSpawned",
        "BossDefeated",
        "PlayerRespawned",
        "ZoneUnlocked",
        "NotifyPlayer",
        "ShopPurchaseResult",
        -- Client → Server
        "RequestRespawn",
        "PurchaseShopItem",
        "PurchaseRobuxItem",
        "EnterZone",
        "CollectCoin",
    },
    Functions = {
        "GetPlayerData",
        "GetShopInventory",
        "GetZoneData",
        "GetLeaderboard",
    },
}

---------------------------------------------------------------------------
-- UI COLORS
---------------------------------------------------------------------------
MulletConfig.Colors = {
    Primary     = Color3.fromRGB(255, 80, 0),    -- fiery orange
    Secondary   = Color3.fromRGB(255, 220, 0),   -- gold
    Background  = Color3.fromRGB(20, 20, 20),    -- near-black
    Text        = Color3.fromRGB(255, 255, 255),
    Accent      = Color3.fromRGB(0, 200, 100),   -- green for coin/health
    Danger      = Color3.fromRGB(220, 40, 40),
    Coin        = Color3.fromRGB(255, 215, 0),
}

---------------------------------------------------------------------------
-- Freeze top-level tables
---------------------------------------------------------------------------
if table.freeze then
    for _, v in pairs(MulletConfig) do
        if type(v) == "table" then
            for _, sv in pairs(v) do
                if type(sv) == "table" then
                    table.freeze(sv)
                end
            end
            table.freeze(v)
        end
    end
    table.freeze(MulletConfig)
end

return MulletConfig
