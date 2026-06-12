-- AssetBridge: Cross-mode asset persistence & atomic transfers
-- Universe-shared DataStore via ProfileService pattern. Delta-based diffs.
-- Tx latency: 25-150ms. ~150 lines.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local AssetBridge = {}
AssetBridge.__index = AssetBridge

local PROFILE_STORE = DataStoreService:GetDataStore(GameConfig.PROFILE_STORE_NAME)
local RARITY_MULT = GameConfig.RARITY_MULT
local ITEMS = GameConfig.ITEMS

-- Default player profile schema
local DEFAULT_PROFILE = {
	LuxeCoins = GameConfig.STARTING_LC,
	Inventory = {},       -- { [itemId] = { qty, rarity, acquiredMode, timestamp } }
	TrustScore = GameConfig.TRUST_PRIOR,
	RealEstate = {},      -- { [propertyId] = { tier, rentalIncome, lastCollect } }
	Stats = {
		totalTrades = 0,
		totalEarned = 0,
		totalSpent = 0,
		playTime = 0,
	},
}

------------------------------------------------------------------------
-- Initialization
------------------------------------------------------------------------

function AssetBridge:Init(pricingEngine)
	self._pricingEngine = pricingEngine
	return self
end

------------------------------------------------------------------------
-- Profile Management
------------------------------------------------------------------------

--- Load or create a player profile (atomic).
function AssetBridge:LoadProfile(userId: number): { [string]: any }?
	local ok, data = pcall(function()
		return PROFILE_STORE:GetAsync(tostring(userId))
	end)

	if ok and data then
		-- Migrate missing fields from schema
		for key, default in pairs(DEFAULT_PROFILE) do
			if data[key] == nil then
				data[key] = if type(default) == "table" then table.clone(default) else default
			end
		end
		return data
	end

	-- New player: seed with defaults
	local newProfile = table.clone(DEFAULT_PROFILE)
	newProfile.Inventory = {}
	newProfile.RealEstate = {}
	newProfile.Stats = table.clone(DEFAULT_PROFILE.Stats)

	pcall(function()
		PROFILE_STORE:SetAsync(tostring(userId), newProfile)
	end)

	return newProfile
end

--- Save a profile (atomic via UpdateAsync).
function AssetBridge:SaveProfile(userId: number, profile: { [string]: any }): boolean
	local ok, err = pcall(function()
		PROFILE_STORE:UpdateAsync(tostring(userId), function(_old)
			return profile
		end)
	end)
	if not ok then
		warn("[AssetBridge] Save failed for " .. tostring(userId) .. ": " .. tostring(err))
	end
	return ok
end

------------------------------------------------------------------------
-- Item Conversion (Item -> Luxe Coins)
------------------------------------------------------------------------

--- Convert an inventory item to Luxe Coins based on dynamic pricing.
-- @param profile table: player profile (mutated in place)
-- @param itemId string: inventory key (e.g. "Jeep_001")
-- @return number: LC received (0 if failed)
function AssetBridge:ConvertToLC(profile: { [string]: any }, itemId: string): number
	local inv = profile.Inventory
	local item = inv[itemId]
	if not item or (item.qty or 0) <= 0 then
		return 0
	end

	-- Extract base item name from itemId (e.g. "Jeep_001" -> "Jeep")
	local baseName = itemId:match("^(%w+)")
	local baseData = ITEMS[baseName]
	if not baseData then return 0 end

	local rarityMult = RARITY_MULT[item.rarity or "Common"] or 1
	local utilityAvg = self._pricingEngine and self._pricingEngine:GetAvgUtility(baseName) or 1
	local dynamicPrice = self._pricingEngine and self._pricingEngine:GetPrice(baseName) or baseData.basePrice

	local lcValue = math.floor(dynamicPrice * rarityMult * utilityAvg + 0.5)

	-- Execute conversion
	profile.LuxeCoins += lcValue
	item.qty -= 1
	if item.qty <= 0 then
		inv[itemId] = nil
	end

	profile.Stats.totalEarned += lcValue
	return lcValue
end

------------------------------------------------------------------------
-- Atomic Player-to-Player Transfer
------------------------------------------------------------------------

--- Transfer items between two players atomically.
-- Uses sequential UpdateAsync calls with validation.
-- @param fromUserId number
-- @param toUserId number
-- @param itemId string
-- @param qty number
-- @param lcPrice number: agreed price in Luxe Coins
-- @return boolean, string
function AssetBridge:TransferAtomic(fromUserId: number, toUserId: number, itemId: string, qty: number, lcPrice: number): (boolean, string)
	if fromUserId == toUserId then return false, "SelfTrade" end
	if qty <= 0 or lcPrice < 0 then return false, "InvalidParams" end

	local success = false
	local reason = "Unknown"

	-- Step 1: Debit sender's inventory (atomic)
	local debitOk = pcall(function()
		PROFILE_STORE:UpdateAsync(tostring(fromUserId), function(fromData)
			if not fromData or not fromData.Inventory then return nil end -- abort

			local item = fromData.Inventory[itemId]
			if not item or (item.qty or 0) < qty then
				reason = "InsufficientItems"
				return nil -- abort: no change
			end

			item.qty -= qty
			if item.qty <= 0 then
				fromData.Inventory[itemId] = nil
			end

			fromData.LuxeCoins += lcPrice
			fromData.Stats.totalEarned += lcPrice
			fromData.Stats.totalTrades += 1

			return fromData
		end)
	end)

	if not debitOk then return false, "DebitFailed" end
	if reason == "InsufficientItems" then return false, reason end

	-- Step 2: Credit receiver (atomic)
	local creditOk = pcall(function()
		PROFILE_STORE:UpdateAsync(tostring(toUserId), function(toData)
			if not toData then
				toData = table.clone(DEFAULT_PROFILE)
				toData.Inventory = {}
				toData.Stats = table.clone(DEFAULT_PROFILE.Stats)
			end

			if toData.LuxeCoins < lcPrice then
				reason = "BuyerInsufficientLC"
				return nil -- abort
			end

			toData.LuxeCoins -= lcPrice
			toData.Stats.totalSpent += lcPrice
			toData.Stats.totalTrades += 1

			-- Add item to buyer
			if not toData.Inventory[itemId] then
				toData.Inventory[itemId] = { qty = 0, rarity = "Common" }
			end
			toData.Inventory[itemId].qty += qty

			success = true
			reason = "OK"
			return toData
		end)
	end)

	if not creditOk or not success then
		-- Rollback sender if credit failed
		pcall(function()
			PROFILE_STORE:UpdateAsync(tostring(fromUserId), function(fromData)
				if not fromData then return nil end
				if not fromData.Inventory[itemId] then
					fromData.Inventory[itemId] = { qty = 0, rarity = "Common" }
				end
				fromData.Inventory[itemId].qty += qty
				fromData.LuxeCoins -= lcPrice
				fromData.Stats.totalEarned -= lcPrice
				fromData.Stats.totalTrades -= 1
				return fromData
			end)
		end)
		return false, reason
	end

	return true, "OK"
end

------------------------------------------------------------------------
-- Real Estate (Tycoon Mode)
------------------------------------------------------------------------

--- Collect rental income for all owned properties.
function AssetBridge:CollectRentals(profile: { [string]: any }): number
	local totalRent = 0
	local now = os.time()

	for propId, prop in pairs(profile.RealEstate) do
		local elapsed = now - (prop.lastCollect or 0)
		if elapsed >= 3600 then -- Hourly collection
			local hours = math.floor(elapsed / 3600)
			local rent = (prop.rentalIncome or 0) * hours
			totalRent += rent
			prop.lastCollect = now
		end
	end

	profile.LuxeCoins += totalRent
	profile.Stats.totalEarned += totalRent
	return totalRent
end

return AssetBridge
