--[[
    MulletConfig.lua
    Central configuration for The Mullet Game.
    Designed by Karl & Jagr. Character: TheMullet_King.

    Core loop:
      Hair falls from sky → players vacuum/sweep it up → fills the Giant Jar
      → Mullet God appears → rains coins on everyone for 30 seconds → repeat
]]

local MulletConfig = {}

---------------------------------------------------------------------------
-- GAME META
---------------------------------------------------------------------------
MulletConfig.GameName    = "The Mullet Game"
MulletConfig.MulletGodName = "The Mullet God"
MulletConfig.OwnerUsername = "TheMullet_King"

---------------------------------------------------------------------------
-- ROUND SETTINGS
---------------------------------------------------------------------------
MulletConfig.Round = {
    Duration          = 120,   -- seconds per round before maze resets
    CountdownTime     = 10,    -- seconds countdown before round starts
    MazeDifficulties  = { "Easy", "Medium", "Hard" },
    DefaultDifficulty = "Easy",
    -- Hair drops per second per difficulty
    HairDropRate = {
        Easy   = 3,
        Medium = 5,
        Hard   = 8,
    },
}

---------------------------------------------------------------------------
-- HAIR & JAR
---------------------------------------------------------------------------
MulletConfig.Jar = {
    Capacity          = 100,   -- total hair units to fill the jar
    JarPosition       = Vector3.new(0, 5, 0),   -- center of map
    JarSize           = Vector3.new(8, 12, 8),
    FillColor         = Color3.fromRGB(180, 140, 100),  -- hair colour in jar
}

MulletConfig.Hair = {
    PickupValue       = 1,     -- hair units per pickup
    SpawnHeight       = 40,    -- studs above ground hair spawns
    FallSpeed         = 20,    -- studs per second
    PickupRadius      = 4,     -- studs to auto-collect
    MaxHairOnMap      = 50,    -- max loose hair clumps at once
    HairColors = {
        Color3.fromRGB(200, 160, 100),  -- blonde
        Color3.fromRGB(80, 50, 30),     -- brunette
        Color3.fromRGB(30, 30, 30),     -- black
        Color3.fromRGB(200, 80, 40),    -- red
        Color3.fromRGB(150, 150, 150),  -- grey
    },
}

---------------------------------------------------------------------------
-- MULLET GROWTH ON CHARACTER
---------------------------------------------------------------------------
MulletConfig.Mullet = {
    -- Hair collected thresholds for each mullet size level
    SizeLevels = { 0, 5, 15, 30, 50, 75, 100 },

    -- Color of mullet at each level
    Colors = {
        [0] = Color3.fromRGB(200, 160, 100),  -- blonde baby mullet
        [1] = Color3.fromRGB(255, 120, 0),    -- orange
        [2] = Color3.fromRGB(255, 50, 50),    -- red
        [3] = Color3.fromRGB(150, 0, 255),    -- purple
        [4] = Color3.fromRGB(0, 200, 255),    -- electric blue
        [5] = Color3.fromRGB(255, 215, 0),    -- gold
        [6] = Color3.fromRGB(255, 255, 255),  -- legendary white
    },

    -- Scale multiplier for the mullet accessory at each level
    Sizes = {
        [0] = 1.0,
        [1] = 1.3,
        [2] = 1.6,
        [3] = 2.0,
        [4] = 2.5,
        [5] = 3.0,
        [6] = 4.0,
    },

    -- Speed bonus at each level (studs/s added to base)
    SpeedBonus = {
        [0] = 0,
        [1] = 2,
        [2] = 3,
        [3] = 4,
        [4] = 5,
        [5] = 6,
        [6] = 8,
    },

    BaseWalkSpeed = 16,
    MaxLevel      = 6,
}

---------------------------------------------------------------------------
-- MULLET GOD EVENT
---------------------------------------------------------------------------
MulletConfig.MulletGod = {
    RainDuration      = 30,    -- seconds money rains
    CoinsPerSecond    = 5,     -- coins each player gets per second during rain
    BonusForTopCollector = 50, -- extra coins for #1 hair collector
    AppearanceHeight  = 60,    -- studs above map center
    DanceEnabled      = true,
}

---------------------------------------------------------------------------
-- JOBS (mini-games that drop bonus hair)
---------------------------------------------------------------------------
MulletConfig.Jobs = {
    {
        id          = "sleeping_giant",
        name        = "Shave the Sleeping Giant",
        description = "Sneak up and shave him. Wake him and get SWATTED!",
        hairReward  = 10,
        failPenalty = "swat",   -- launches player across map
        spawnKey    = "GiantSpawn",
    },
    {
        id          = "toilet",
        name        = "Unclog the Toilet",
        description = "Plunge that drain! Fall in and do the sewer obby!",
        hairReward  = 8,
        failPenalty = "flush",  -- sends player to sewer obby
        spawnKey    = "ToiletSpawn",
    },
    {
        id          = "chicken",
        name        = "Chase the Hairy Chicken",
        description = "Catch the chicken to grab its hair!",
        hairReward  = 6,
        failPenalty = "egg",    -- chicken lays a hair egg somewhere random
        spawnKey    = "ChickenSpawn",
    },
    {
        id          = "shampoo_surf",
        name        = "Shampoo Surf",
        description = "Surf the shampoo wave and grab hair clumps!",
        hairReward  = 7,
        failPenalty = "slide",  -- wipe out and bump into other players
        spawnKey    = "SurfSpawn",
    },
    {
        id          = "tornado",
        name        = "Tornado Vacuum",
        description = "Vacuum hair off the tornado — or get launched!",
        hairReward  = 12,
        failPenalty = "launch", -- spun out and launched into the maze
        spawnKey    = "TornadoSpawn",
    },
}

---------------------------------------------------------------------------
-- ECONOMY
---------------------------------------------------------------------------
MulletConfig.Economy = {
    StartingCoins         = 0,
    MaxCoins              = 99999,
    HairToJarContribution = 1,   -- 1 hair unit = 1 jar unit
}

---------------------------------------------------------------------------
-- MAZE
---------------------------------------------------------------------------
MulletConfig.Maze = {
    GridSize   = 20,      -- 20×20 grid of cells
    CellSize   = 10,      -- studs per cell
    WallHeight = 8,
    WallThickness = 1,
    Origin     = Vector3.new(-100, 0, -100),
    -- Seed changes each round for a new maze
    RandomSeed = true,
}

---------------------------------------------------------------------------
-- LEADERBOARD
---------------------------------------------------------------------------
MulletConfig.Leaderboard = {
    RefreshInterval = 10,   -- seconds
    MaxEntries      = 10,
    StatName        = "Hair",
    CoinStatName    = "Coins",
}

---------------------------------------------------------------------------
-- UI COLORS
---------------------------------------------------------------------------
MulletConfig.Colors = {
    Primary    = Color3.fromRGB(255, 180, 0),   -- gold
    Secondary  = Color3.fromRGB(255, 80, 0),    -- orange
    Background = Color3.fromRGB(20, 20, 20),
    Text       = Color3.fromRGB(255, 255, 255),
    Jar        = Color3.fromRGB(100, 200, 255),
    Hair       = Color3.fromRGB(200, 160, 100),
    Coin       = Color3.fromRGB(255, 215, 0),
}

---------------------------------------------------------------------------
-- REMOTE NAMES
---------------------------------------------------------------------------
MulletConfig.Remotes = {
    Events = {
        -- Server → Client
        "UpdateMulletLevel",
        "UpdateCoins",
        "UpdateJarFill",
        "MulletGodArrived",
        "MulletGodLeft",
        "MoneyRain",
        "RoundStarted",
        "RoundEnded",
        "NotifyPlayer",
        "JobStarted",
        "JobCompleted",
        "JobFailed",
        "LeaderboardUpdate",
        -- Client → Server
        "CollectHair",
        "StartJob",
        "SwerObbyComplete",
    },
    Functions = {
        "GetPlayerData",
        "GetJarData",
        "GetLeaderboard",
    },
}

---------------------------------------------------------------------------
-- Freeze
---------------------------------------------------------------------------
if table.freeze then
    for _, v in pairs(MulletConfig) do
        if type(v) == "table" then
            for _, sv in pairs(v) do
                if type(sv) == "table" then
                    pcall(table.freeze, sv)
                end
            end
            pcall(table.freeze, v)
        end
    end
    pcall(table.freeze, MulletConfig)
end

return MulletConfig
