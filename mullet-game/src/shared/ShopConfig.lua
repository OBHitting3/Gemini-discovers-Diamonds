--[[
    ShopConfig.lua
    Defines all purchasable items in the in-game coin shop.
    Items are grouped by category: Weapons, Abilities, Cosmetics, Boosts.
    Prices are in coins unless noted otherwise.
]]

local ShopConfig = {}

---------------------------------------------------------------------------
-- ITEM CATEGORIES
---------------------------------------------------------------------------
ShopConfig.Categories = {
    "Weapons",
    "Abilities",
    "Cosmetics",
    "Boosts",
    "Eggs",
}

---------------------------------------------------------------------------
-- WEAPONS
---------------------------------------------------------------------------
ShopConfig.Weapons = {
    {
        id          = "weapon_scissors",
        name        = "Barber Scissors",
        description = "The classic. Quick slashes, low damage.",
        price       = 0,       -- starter weapon (free)
        damage      = 15,
        attackSpeed = 0.4,     -- seconds per swing
        range       = 5,
        icon        = "rbxassetid://0",
    },
    {
        id          = "weapon_razor",
        name        = "Straight Razor",
        description = "A sleek razor with high crit chance.",
        price       = 150,
        damage      = 25,
        attackSpeed = 0.5,
        range       = 4,
        critChance  = 0.20,
        icon        = "rbxassetid://0",
    },
    {
        id          = "weapon_hairdryer",
        name        = "Turbo Hair Dryer",
        description = "Launches a gust of hot air in an AoE cone.",
        price       = 400,
        damage      = 20,
        attackSpeed = 0.8,
        range       = 12,
        aoe         = true,
        icon        = "rbxassetid://0",
    },
    {
        id          = "weapon_combofork",
        name        = "Combo Fork",
        description = "A hair fork that deals combo multiplier damage.",
        price       = 700,
        damage      = 30,
        attackSpeed = 0.3,
        range       = 5,
        comboMultiplier = 1.5,  -- damage multiplied per consecutive hit
        icon        = "rbxassetid://0",
    },
    {
        id          = "weapon_legendary_shear",
        name        = "Legendary Power Shear",
        description = "Mythical shears that can sever reality itself.",
        price       = 2000,
        damage      = 80,
        attackSpeed = 1.0,
        range       = 6,
        icon        = "rbxassetid://0",
    },
}

---------------------------------------------------------------------------
-- ABILITIES
---------------------------------------------------------------------------
ShopConfig.Abilities = {
    {
        id          = "ability_dash",
        name        = "Mullet Dash",
        description = "Dash forward at high speed, damaging enemies in your path.",
        price       = 200,
        cooldown    = 8,    -- seconds
        damage      = 30,
        icon        = "rbxassetid://0",
    },
    {
        id          = "ability_windmill",
        name        = "Windmill Spin",
        description = "Spin your weapon in a 360° arc, hitting all nearby enemies.",
        price       = 300,
        cooldown    = 12,
        damage      = 25,
        radius      = 8,
        icon        = "rbxassetid://0",
    },
    {
        id          = "ability_hairwave",
        name        = "Hair Wave",
        description = "Send a shockwave of mullet energy forward.",
        price       = 450,
        cooldown    = 15,
        damage      = 50,
        range       = 20,
        icon        = "rbxassetid://0",
    },
    {
        id          = "ability_berserker",
        name        = "Berserker Mode",
        description = "Double damage and attack speed for 5 seconds.",
        price       = 600,
        cooldown    = 30,
        duration    = 5,
        icon        = "rbxassetid://0",
    },
}

---------------------------------------------------------------------------
-- COSMETICS
---------------------------------------------------------------------------
ShopConfig.Cosmetics = {
    -- Trails
    {
        id          = "cosmetic_trail_fire",
        name        = "Fire Trail",
        description = "Leave a fiery trail as you run.",
        price       = 250,
        type        = "trail",
        icon        = "rbxassetid://0",
    },
    {
        id          = "cosmetic_trail_lightning",
        name        = "Lightning Trail",
        description = "Crackle with electricity as you move.",
        price       = 350,
        type        = "trail",
        icon        = "rbxassetid://0",
    },
    -- Kill effects
    {
        id          = "cosmetic_kill_confetti",
        name        = "Confetti Explosion",
        description = "Enemies explode into confetti on defeat.",
        price       = 300,
        type        = "killEffect",
        icon        = "rbxassetid://0",
    },
    {
        id          = "cosmetic_kill_coins",
        name        = "Coin Burst",
        description = "Enemies burst into coins on defeat (cosmetic only).",
        price       = 400,
        type        = "killEffect",
        icon        = "rbxassetid://0",
    },
    -- Chat tags
    {
        id          = "cosmetic_tag_rockstar",
        name        = "Rockstar Tag",
        description = "Show [Rockstar] next to your name.",
        price       = 150,
        type        = "chatTag",
        tagText     = "Rockstar",
        icon        = "rbxassetid://0",
    },
    {
        id          = "cosmetic_tag_legend",
        name        = "Legend Tag",
        description = "Show [Legend] next to your name.",
        price       = 500,
        type        = "chatTag",
        tagText     = "Legend",
        icon        = "rbxassetid://0",
    },
}

---------------------------------------------------------------------------
-- BOOSTS (temporary modifiers, purchased per-session or per-timer)
---------------------------------------------------------------------------
ShopConfig.Boosts = {
    {
        id          = "boost_2x_coins",
        name        = "2× Coin Boost",
        description = "Double all coin earnings for 10 minutes.",
        price       = 200,
        duration    = 600,   -- seconds
        coinMult    = 2.0,
        icon        = "rbxassetid://0",
    },
    {
        id          = "boost_speed",
        name        = "Speed Boost",
        description = "+8 walk speed for 5 minutes.",
        price       = 150,
        duration    = 300,
        speedBonus  = 8,
        icon        = "rbxassetid://0",
    },
    {
        id          = "boost_magnet",
        name        = "Coin Magnet",
        description = "Automatically collect coins within 15 studs for 5 minutes.",
        price       = 175,
        duration    = 300,
        magnetRadius = 15,
        icon        = "rbxassetid://0",
    },
    {
        id          = "boost_lucky",
        name        = "Lucky Charm",
        description = "1.5× egg luck for 10 minutes.",
        price       = 250,
        duration    = 600,
        luckMult    = 1.5,
        icon        = "rbxassetid://0",
    },
}

---------------------------------------------------------------------------
-- STOCK EGGS (purchasable via coin shop; see EggConfig for full defs)
---------------------------------------------------------------------------
ShopConfig.Eggs = {
    { eggId = "basic",  name = "Basic Egg",  price = 100 },
    { eggId = "golden", name = "Golden Egg", price = 500 },
}

---------------------------------------------------------------------------
-- Lookup helper (non-config function, runs before freeze)
---------------------------------------------------------------------------
local _allItems = {}
for _, category in ipairs(ShopConfig.Categories) do
    local items = ShopConfig[category]
    if items then
        for _, item in ipairs(items) do
            _allItems[item.id] = item
        end
    end
end

function ShopConfig.getItem(id: string): table?
    return _allItems[id]
end

---------------------------------------------------------------------------
-- Freeze
---------------------------------------------------------------------------
if table.freeze then
    for key, v in pairs(ShopConfig) do
        if type(v) == "table" and key ~= "getItem" then
            for _, sv in pairs(v) do
                if type(sv) == "table" then
                    table.freeze(sv)
                end
            end
            table.freeze(v)
        end
    end
end

return ShopConfig
