--[[
    Types.lua
    Luau type definitions for Palm Springs Paradise.
    All data structures shared across server and client are typed here
    so that every module uses a consistent schema.
]]

local Types = {}

---------------------------------------------------------------------------
-- PLAYER DATA  (stored in DataStore hot path)
---------------------------------------------------------------------------
export type PlayerData = {
    userId: number,
    displayName: string,
    sunCoins: number,
    prestige: number,
    level: number,
    plotId: number?,              -- nil if no plot claimed
    shopId: number?,              -- nil if no shop claimed
    homeStyle: string?,           -- "Kaufmann" | "Frey" | "Wexler" | "Neutra"
    inventory: { [string]: number }, -- itemId → quantity
    outfits: { OutfitData },
    stats: PlayerStats,
    lastLogin: number,            -- os.time()
    firstJoin: number,            -- os.time()
}

export type PlayerStats = {
    totalCoinsEarned: number,
    totalPrestigeEarned: number,
    plantsHarvested: number,
    fashionWins: number,
    itemsSold: number,
    itemsBought: number,
    homeTourVisits: number,
}

---------------------------------------------------------------------------
-- DEFAULT PLAYER DATA TEMPLATE
---------------------------------------------------------------------------
Types.DefaultPlayerData: PlayerData = {
    userId = 0,
    displayName = "",
    sunCoins = 100,  -- matches GameConfig.Economy.StartingCoins
    prestige = 0,
    level = 1,
    plotId = nil,
    shopId = nil,
    homeStyle = nil,
    inventory = {},
    outfits = {},
    stats = {
        totalCoinsEarned = 0,
        totalPrestigeEarned = 0,
        plantsHarvested = 0,
        fashionWins = 0,
        itemsSold = 0,
        itemsBought = 0,
        homeTourVisits = 0,
    },
    lastLogin = 0,
    firstJoin = 0,
}

---------------------------------------------------------------------------
-- PLOT DATA  (stored in Supabase cold path as JSONB)
---------------------------------------------------------------------------
export type PlotData = {
    plotId: number,
    ownerId: number?,
    homeStyle: string?,
    furniturePlacements: { FurniturePlacement },
    vibesScore: number,
    partCount: number,
}

export type FurniturePlacement = {
    instanceId: string,        -- unique per placement
    itemId: string,            -- catalog reference
    position: { x: number, y: number, z: number },
    rotation: number,          -- Y-axis degrees
    placedAt: number,          -- os.time()
}

---------------------------------------------------------------------------
-- GARDEN DATA
---------------------------------------------------------------------------
export type GardenState = {
    plots: { GardenPlot },
}

export type GardenPlot = {
    index: number,              -- 1–16
    plantId: string?,           -- nil if empty
    plantedBy: number?,         -- userId
    plantedAt: number?,         -- os.time()
    growthStage: string,        -- "empty" | "seed" | "sprout" | "growing" | "mature" | "wilting" | "dead"
    lastWatered: number?,       -- os.time()
    waterCount: number,
}

---------------------------------------------------------------------------
-- SHOP DATA
---------------------------------------------------------------------------
export type ShopData = {
    shopId: number,              -- storefront slot 1–6
    ownerId: number?,
    displayName: string,
    inventory: { ShopItem },
    totalSales: number,
    rating: number,              -- 0–5
}

export type ShopItem = {
    itemId: string,
    quantity: number,
    price: number,               -- seller-set price in SunCoins
    listedAt: number,            -- os.time()
}

---------------------------------------------------------------------------
-- FASHION DATA
---------------------------------------------------------------------------
export type FashionEvent = {
    eventId: string,
    theme: string,
    isActive: boolean,
    startedAt: number,
    endsAt: number,
    participants: { FashionParticipant },
    votes: { [number]: number },  -- voterId → targetPlayerId
    winnerId: number?,
}

export type FashionParticipant = {
    userId: number,
    displayName: string,
    outfit: OutfitData,
    hasWalked: boolean,
    voteCount: number,
}

export type OutfitData = {
    name: string,
    category: string,
    items: { string },           -- list of item IDs worn
}

---------------------------------------------------------------------------
-- ITEM TYPES  (catalog entries)
---------------------------------------------------------------------------
export type FurnitureItem = {
    id: string,
    name: string,
    category: string,           -- "seating" | "table" | "decor" | "lighting" | "outdoor"
    price: number,
    size: { x: number, y: number, z: number },
    color: string,              -- key into GameConfig.Colors
    material: string?,          -- Enum.Material name
    description: string?,
}

export type PlantItem = {
    id: string,
    name: string,
    seedPrice: number,
    growTime: number,            -- total seconds seed → mature
    waterInterval: number,       -- max seconds between waterings
    harvestValue: number,        -- SunCoins reward
    prestigeReward: number,
    description: string?,
}

export type BoutiqueItem = {
    id: string,
    name: string,
    category: string,            -- "accessory" | "art" | "home" | "fashion" | "vintage"
    basePrice: number,
    description: string?,
}

export type FashionOutfitItem = {
    id: string,
    name: string,
    category: string,            -- "poolside" | "cocktail" | "desert_casual" | "formal" | "vintage" | "resort"
    price: number,
    prestigeBonus: number,
    description: string?,
}

---------------------------------------------------------------------------
-- TRANSACTION LOG
---------------------------------------------------------------------------
export type Transaction = {
    id: string,
    buyerId: number,
    sellerId: number?,           -- nil if system sale
    itemId: string,
    amount: number,
    tax: number,
    timestamp: number,
    reason: string,
}

---------------------------------------------------------------------------
-- EVENT DATA
---------------------------------------------------------------------------
export type GameEvent = {
    name: string,
    description: string,
    gardenBoost: number,
    shopBonus: number,
    isActive: boolean,
    startedAt: number?,
    endsAt: number?,
}

return Types
