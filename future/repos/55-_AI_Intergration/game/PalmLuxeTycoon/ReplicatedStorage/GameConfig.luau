-- GameConfig: Shared constants for Palm Luxe Tycoon unified economy
-- All modules reference this single source of truth.

local GameConfig = {}

-- Currency
GameConfig.CURRENCY_NAME = "Luxe Coins"
GameConfig.CURRENCY_SHORT = "LC"
GameConfig.STARTING_LC = 1000

-- Economy tuning (Lotka-Volterra DE parameters)
GameConfig.ALPHA = 0.05       -- Price adjustment sensitivity
GameConfig.BETA = 0.8         -- Demand consumption rate
GameConfig.EPSILON = 0.6      -- Demand reproduction rate
GameConfig.DELTA = 0.1        -- Demand natural decay
GameConfig.PRICE_FLOOR_MULT = 0.5
GameConfig.PRICE_CEIL_MULT = 5.0
GameConfig.SINK_DECAY_BASE = 0.98
GameConfig.SINK_SCALE = 1000

-- Item catalog with cross-mode utility weights
GameConfig.ITEMS = {
	Jeep = {
		basePrice = 1000,
		utility = { Racing = 2, Social = 1.2, BR = 1.5 },
		growth = 0.1,
		carry = 5000,
		description = "Off-road Jeep for Joshua Tree excursions",
	},
	Home = {
		basePrice = 5000,
		utility = { Tycoon = 2, Social = 1.5 },
		growth = 0.05,
		carry = 100,
		description = "Movie Colony luxury residence",
	},
	Pet = {
		basePrice = 200,
		utility = { Social = 1.8, Sandbox = 1.2 },
		growth = 0.2,
		carry = 10000,
		description = "Palm Springs desert companion",
	},
	TramTicket = {
		basePrice = 50,
		utility = { Excursion = 1.8 },
		growth = 0.15,
		carry = 2000,
		description = "Aerial Tramway scenic ride pass",
	},
	WindmillReward = {
		basePrice = 100,
		utility = { BR = 1.7, Obby = 1.4 },
		growth = 0.12,
		carry = 3000,
		description = "Windmill farm obby completion reward",
	},
}

-- Rarity multipliers for asset valuation
GameConfig.RARITY_MULT = {
	Common = 1,
	Rare = 1.5,
	Epic = 3,
	Legendary = 5,
}

-- Anti-exploit thresholds
GameConfig.TRUST_PRIOR = 0.5
GameConfig.Z_THRESHOLD = 3
GameConfig.MAX_RETRIES = 3
GameConfig.TRUST_PENALTY_FARM = 0.9
GameConfig.TRUST_PENALTY_DUPE = 0.8
GameConfig.TRUST_BAN_THRESHOLD = 0.3
GameConfig.VELOCITY_MEAN = 2       -- trades/hour baseline
GameConfig.VELOCITY_STDDEV = 1.5

-- Game modes (Places in Universe)
GameConfig.MODES = {
	"Tycoon",       -- South Canyon Dr / Movie Colony real estate
	"Racing",       -- Jeep / Joshua Tree
	"Social",       -- Ace Hotel parties
	"Sandbox",      -- El Paseo building
	"BR",           -- Windmill farm obby with BR-lite
	"Excursion",    -- Aerial Tram
	"Obby",         -- Windmill farm obby
}

-- Monetization tiers (non-predatory, no lootboxes)
GameConfig.MONETIZATION = {
	Starter = { robux = 400, description = "Jeep skin", anchor = "low" },
	VIP = { robux = 800, description = "2x rental income", retention_boost = 0.30 },
	Elite = { robux = 1600, description = "Custom Movie Colony home (LTD)", fomo = true },
}

-- DataStore keys
GameConfig.PROFILE_STORE_NAME = "PlayerData"
GameConfig.DEMAND_TOPIC_PREFIX = "Demand:"
GameConfig.SINK_TOPIC_PREFIX = "Sink:"
GameConfig.PRICE_TOPIC_PREFIX = "Price:"

-- Simulation defaults
GameConfig.SIM_DAYS = 90
GameConfig.SIM_PLAYERS = 5000
GameConfig.SIM_STEPS_PER_DAY = 100
GameConfig.WHALE_PROBABILITY = 0.02

return GameConfig
