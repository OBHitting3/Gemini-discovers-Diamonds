--[[
    ZoneConfig.lua
    Defines all zones/areas in the Mullet Game world.
    Each zone has a coin requirement to unlock, enemy scaling,
    spawn positions, and environmental metadata.
]]

local ZoneConfig = {}

---------------------------------------------------------------------------
-- ZONE DEFINITIONS
---------------------------------------------------------------------------
-- Fields per zone:
--   id            unique string identifier
--   name          display name
--   description   flavour text shown in unlock UI
--   unlockCoins   coins needed to unlock the zone (0 = starter zone)
--   spawnCFrame   server-side CFrame string key (matched in workspace)
--   enemyLevel    base enemy level in this zone
--   enemyTypes    which enemy archetypes can spawn here
--   coinDropMult  multiplier on base coin drop rates
--   bossId        which boss spawns in this zone's boss waves (nil = none)
--   music         soundtrack asset id (0 = TBD)
---------------------------------------------------------------------------

ZoneConfig.Zones = {
    {
        id           = "zone_barbershop",
        name         = "The Old Barbershop",
        description  = "Where every mullet journey begins. Waves are gentle here.",
        unlockCoins  = 0,          -- starter zone
        spawnCFrame  = "BarbershopSpawn",
        enemyLevel   = 1,
        enemyTypes   = { "basic_goon", "runner" },
        coinDropMult = 1.0,
        bossId       = nil,
        music        = "rbxassetid://0",
    },
    {
        id           = "zone_alley",
        name         = "Back Alley Brawl",
        description  = "Dark alleys teeming with tougher rivals. Watch your flanks.",
        unlockCoins  = 500,
        spawnCFrame  = "AlleySpawn",
        enemyLevel   = 5,
        enemyTypes   = { "basic_goon", "runner", "brute" },
        coinDropMult = 1.5,
        bossId       = "boss_alley_king",
        music        = "rbxassetid://0",
    },
    {
        id           = "zone_salon",
        name         = "Rival Salon",
        description  = "The enemy has style — and serious firepower. Take it.",
        unlockCoins  = 1500,
        spawnCFrame  = "SalonSpawn",
        enemyLevel   = 12,
        enemyTypes   = { "gunner", "brute", "shielder" },
        coinDropMult = 2.0,
        bossId       = "boss_head_stylist",
        music        = "rbxassetid://0",
    },
    {
        id           = "zone_rooftop",
        name         = "Skyscraper Rooftop",
        description  = "High above the city. One wrong step and it's over.",
        unlockCoins  = 4000,
        spawnCFrame  = "RooftopSpawn",
        enemyLevel   = 22,
        enemyTypes   = { "gunner", "shielder", "drone", "elite_goon" },
        coinDropMult = 3.0,
        bossId       = "boss_rooftop_rager",
        music        = "rbxassetid://0",
    },
    {
        id           = "zone_arena",
        name         = "The Mullet Arena",
        description  = "The ultimate proving ground. Only legends survive here.",
        unlockCoins  = 10000,
        spawnCFrame  = "ArenaSpawn",
        enemyLevel   = 40,
        enemyTypes   = { "elite_goon", "gunner", "shielder", "drone", "berserker" },
        coinDropMult = 5.0,
        bossId       = "boss_mullet_god",
        music        = "rbxassetid://0",
    },
}

---------------------------------------------------------------------------
-- ENEMY ARCHETYPES  (referenced by enemyTypes lists above)
---------------------------------------------------------------------------
ZoneConfig.EnemyArchetypes = {
    basic_goon = {
        id          = "basic_goon",
        name        = "Goon",
        health      = 50,
        damage      = 10,
        speed       = 14,
        coinDrop    = 5,
        attackRange = 5,
    },
    runner = {
        id          = "runner",
        name        = "Runner",
        health      = 30,
        damage      = 8,
        speed       = 20,
        coinDrop    = 4,
        attackRange = 3,
    },
    brute = {
        id          = "brute",
        name        = "Brute",
        health      = 200,
        damage      = 30,
        speed       = 10,
        coinDrop    = 15,
        attackRange = 6,
    },
    gunner = {
        id          = "gunner",
        name        = "Gunner",
        health      = 80,
        damage      = 20,
        speed       = 12,
        coinDrop    = 12,
        attackRange = 20,
        isRanged    = true,
    },
    shielder = {
        id          = "shielder",
        name        = "Shielder",
        health      = 120,
        damage      = 15,
        speed       = 11,
        coinDrop    = 18,
        attackRange = 5,
        blockChance = 0.40,  -- 40% of attacks are blocked
    },
    drone = {
        id          = "drone",
        name        = "Drone",
        health      = 40,
        damage      = 12,
        speed       = 18,
        coinDrop    = 8,
        attackRange = 15,
        isRanged    = true,
        isAerial    = true,
    },
    elite_goon = {
        id          = "elite_goon",
        name        = "Elite Goon",
        health      = 300,
        damage      = 45,
        speed       = 16,
        coinDrop    = 30,
        attackRange = 6,
    },
    berserker = {
        id          = "berserker",
        name        = "Berserker",
        health      = 250,
        damage      = 60,
        speed       = 22,
        coinDrop    = 40,
        attackRange = 5,
        rageThreshold = 0.30,  -- goes berserk below 30% HP
    },
}

---------------------------------------------------------------------------
-- BOSS DEFINITIONS
---------------------------------------------------------------------------
ZoneConfig.Bosses = {
    boss_alley_king = {
        id       = "boss_alley_king",
        name     = "The Alley King",
        health   = 1500,
        damage   = 40,
        speed    = 14,
        coinDrop = 200,
        bossEggDrop = true,   -- drops a boss egg on defeat
        phases   = 2,
    },
    boss_head_stylist = {
        id       = "boss_head_stylist",
        name     = "The Head Stylist",
        health   = 3000,
        damage   = 60,
        speed    = 16,
        coinDrop = 400,
        bossEggDrop = true,
        phases   = 3,
    },
    boss_rooftop_rager = {
        id       = "boss_rooftop_rager",
        name     = "Rooftop Rager",
        health   = 6000,
        damage   = 80,
        speed    = 18,
        coinDrop = 600,
        bossEggDrop = true,
        phases   = 3,
    },
    boss_mullet_god = {
        id       = "boss_mullet_god",
        name     = "The Mullet God",
        health   = 15000,
        damage   = 120,
        speed    = 20,
        coinDrop = 1500,
        bossEggDrop = true,
        phases   = 4,
    },
}

---------------------------------------------------------------------------
-- Helper: get zone by id
---------------------------------------------------------------------------
local _zoneMap = {}
for _, zone in ipairs(ZoneConfig.Zones) do
    _zoneMap[zone.id] = zone
end

function ZoneConfig.getZone(id: string): table?
    return _zoneMap[id]
end

function ZoneConfig.getBoss(id: string): table?
    return ZoneConfig.Bosses[id]
end

---------------------------------------------------------------------------
-- Freeze
---------------------------------------------------------------------------
if table.freeze then
    for key, v in pairs(ZoneConfig) do
        if type(v) == "table" and key ~= "getZone" and key ~= "getBoss" then
            for _, sv in pairs(v) do
                if type(sv) == "table" then
                    table.freeze(sv)
                end
            end
            table.freeze(v)
        end
    end
end

return ZoneConfig
