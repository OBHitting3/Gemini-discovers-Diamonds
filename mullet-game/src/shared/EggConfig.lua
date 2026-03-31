--[[
    EggConfig.lua
    Defines all egg types, their hatching tables, rarity weights,
    costs, and visual metadata for the egg-hatching system.
]]

local EggConfig = {}

---------------------------------------------------------------------------
-- RARITY DEFINITIONS
---------------------------------------------------------------------------
EggConfig.Rarities = {
    Common    = { name = "Common",    color = Color3.fromRGB(180, 180, 180), weight = 60 },
    Uncommon  = { name = "Uncommon",  color = Color3.fromRGB(80, 200, 80),   weight = 25 },
    Rare      = { name = "Rare",      color = Color3.fromRGB(80, 120, 255),  weight = 10 },
    Epic      = { name = "Epic",      color = Color3.fromRGB(160, 60, 220),  weight = 4  },
    Legendary = { name = "Legendary", color = Color3.fromRGB(255, 180, 0),   weight = 1  },
}

---------------------------------------------------------------------------
-- PETS / REWARDS THAT CAN HATCH FROM EGGS
-- Each entry: id, name, rarity, coinBonus, speedBonus, damageBonus
---------------------------------------------------------------------------
EggConfig.Pets = {
    -- Common
    { id = "pet_hamster",     name = "Hamster",       rarity = "Common",    coinBonus = 0.05, speedBonus = 0,    damageBonus = 0    },
    { id = "pet_pigeon",      name = "Pigeon",         rarity = "Common",    coinBonus = 0.05, speedBonus = 0.02, damageBonus = 0    },
    { id = "pet_gecko",       name = "Gecko",          rarity = "Common",    coinBonus = 0,    speedBonus = 0.05, damageBonus = 0    },
    -- Uncommon
    { id = "pet_ferret",      name = "Ferret",         rarity = "Uncommon",  coinBonus = 0.10, speedBonus = 0.05, damageBonus = 0    },
    { id = "pet_parrot",      name = "Parrot",         rarity = "Uncommon",  coinBonus = 0.10, speedBonus = 0,    damageBonus = 0.05 },
    { id = "pet_raccoon",     name = "Raccoon",        rarity = "Uncommon",  coinBonus = 0.15, speedBonus = 0,    damageBonus = 0    },
    -- Rare
    { id = "pet_fox",         name = "Fox",            rarity = "Rare",      coinBonus = 0.20, speedBonus = 0.10, damageBonus = 0    },
    { id = "pet_eagle",       name = "Eagle",          rarity = "Rare",      coinBonus = 0,    speedBonus = 0.15, damageBonus = 0.15 },
    { id = "pet_lynx",        name = "Lynx",           rarity = "Rare",      coinBonus = 0.10, speedBonus = 0.10, damageBonus = 0.20 },
    -- Epic
    { id = "pet_phoenix",     name = "Phoenix",        rarity = "Epic",      coinBonus = 0.30, speedBonus = 0.20, damageBonus = 0.20 },
    { id = "pet_dragon_baby", name = "Baby Dragon",    rarity = "Epic",      coinBonus = 0.25, speedBonus = 0.25, damageBonus = 0.25 },
    -- Legendary
    { id = "pet_cosmic_mullet", name = "Cosmic Mullet Cat", rarity = "Legendary", coinBonus = 0.50, speedBonus = 0.30, damageBonus = 0.30 },
    { id = "pet_thunder_wolf",  name = "Thunder Wolf",      rarity = "Legendary", coinBonus = 0.40, speedBonus = 0.40, damageBonus = 0.40 },
}

---------------------------------------------------------------------------
-- EGG TYPES
---------------------------------------------------------------------------
EggConfig.Eggs = {
    basic = {
        id            = "basic",
        name          = "Basic Egg",
        description   = "A simple egg with common pets inside.",
        coinCost      = 100,
        robuxCost     = 0,      -- free (coin-only)
        hatchDuration = 3,      -- seconds of hatching animation
        rarityTable   = {       -- override weights for this egg
            Common    = 70,
            Uncommon  = 22,
            Rare      = 7,
            Epic      = 1,
            Legendary = 0,
        },
        exclusivePets = {},     -- no exclusives; draws from full Pets table
    },

    golden = {
        id            = "golden",
        name          = "Golden Egg",
        description   = "A premium egg with better odds for rarer pets.",
        coinCost      = 500,
        robuxCost     = 0,
        hatchDuration = 5,
        rarityTable   = {
            Common    = 40,
            Uncommon  = 35,
            Rare      = 18,
            Epic      = 6,
            Legendary = 1,
        },
        exclusivePets = {},
    },

    cosmic = {
        id            = "cosmic",
        name          = "Cosmic Egg",
        description   = "A Robux egg with guaranteed Rare or better.",
        coinCost      = 0,
        robuxCost     = 75,     -- Robux price (developer product)
        hatchDuration = 7,
        rarityTable   = {
            Common    = 0,
            Uncommon  = 30,
            Rare      = 45,
            Epic      = 20,
            Legendary = 5,
        },
        exclusivePets = { "pet_cosmic_mullet" },  -- boosted rate
    },

    boss = {
        id            = "boss",
        name          = "Boss Egg",
        description   = "Earned by defeating bosses. Contains Legendary-only pets.",
        coinCost      = 0,
        robuxCost     = 0,
        hatchDuration = 8,
        rarityTable   = {
            Common    = 0,
            Uncommon  = 0,
            Rare      = 20,
            Epic      = 50,
            Legendary = 30,
        },
        exclusivePets = { "pet_thunder_wolf", "pet_cosmic_mullet" },
    },
}

---------------------------------------------------------------------------
-- LUCK BOOST (e.g., from game passes or temporary power-ups)
---------------------------------------------------------------------------
EggConfig.LuckBoost = {
    Default         = 1.0,
    LuckyEggPass    = 1.5,   -- 50% better rare/legendary odds
    EventWeekend    = 1.25,  -- 25% better during special events
}

---------------------------------------------------------------------------
-- Freeze
---------------------------------------------------------------------------
if table.freeze then
    for _, v in pairs(EggConfig) do
        if type(v) == "table" then
            for _, sv in pairs(v) do
                if type(sv) == "table" then
                    table.freeze(sv)
                end
            end
            table.freeze(v)
        end
    end
    table.freeze(EggConfig)
end

return EggConfig
