--[[
    EggService.lua (Server)
    Handles egg hatching, rarity rolls, evolution, and passive income.
    All economy mutations are server-authoritative with rate limiting.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Constants = require(game.ReplicatedStorage.Modules.Shared.Constants)
local IconDatabase = require(game.ReplicatedStorage.Modules.Data.IconDatabase)
local Util = require(game.ReplicatedStorage.Modules.Shared.Util)
local Remotes = require(game.ReplicatedStorage.Modules.Shared.Remotes)
local DataService = require(game.ServerScriptService.Services.DataService)
local RateLimiter = require(game.ServerScriptService.Modules.RateLimiter)

local EggService = {}

-- ═══════════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════════
local hatchLimiter = RateLimiter.new({
    MaxCalls = Constants.RateLimit.EGG_HATCHES_PER_SECOND,
    WindowSeconds = 1,
})

local passiveIncomeAccum = 0
local PASSIVE_TICK_INTERVAL = 10 -- calc every 10s, award proportional income

-- ═══════════════════════════════════════════════════════════════
-- RARITY ROLL
-- ═══════════════════════════════════════════════════════════════

local function rollRarity(): string
    local items = {}
    for rarityName, rarityData in Constants.Rarities do
        table.insert(items, { Item = rarityName, Weight = rarityData.Weight })
    end
    return Util.WeightedRandom(items)
end

local function pickIconForRarity(rarity: string): table?
    local pool = IconDatabase.GetByRarity(rarity)
    if #pool == 0 then return nil end
    return pool[math.random(1, #pool)]
end

local function getIncomeMultiplier(player)
    local data = DataService.GetData(player)
    if not data then return 1 end

    local mult = 1
    if data.OwnedPasses["DesertVIP"] then
        mult = mult * 2
    end

    -- Check active boosts
    local now = os.time()
    for _, boost in data.ActiveBoosts do
        if boost.BoostType == "LuckyBoost" and boost.ExpiresAt > now then
            -- Lucky boost is for hatching, not income - skip here
        end
    end

    return mult
end

-- ═══════════════════════════════════════════════════════════════
-- EGG HATCHING
-- ═══════════════════════════════════════════════════════════════

local function handleEggHatch(player: Player, eggTierIndex: number)
    -- Rate limit
    if not hatchLimiter:Check(player) then
        return
    end

    -- Validate tier
    if type(eggTierIndex) ~= "number" then return end
    eggTierIndex = math.floor(eggTierIndex)
    if eggTierIndex < 1 or eggTierIndex > #Constants.EggTiers then return end

    local eggTier = Constants.EggTiers[eggTierIndex]
    local data = DataService.GetData(player)
    if not data then return end

    -- Check affordability (server-side)
    if not DataService.CanAfford(player, eggTier.Cost) then
        Remotes.GetEvent("EggHatchResult"):FireClient(player, {
            Success = false,
            Reason = "NotEnoughCoins",
        })
        return
    end

    -- Deduct cost
    if not DataService.SpendCurrency(player, eggTier.Cost) then
        return
    end

    -- Roll rarity
    local rarity = rollRarity()

    -- Check lucky boost (increases chance of rarer icons)
    local now = os.time()
    for _, boost in data.ActiveBoosts do
        if boost.BoostType == "LuckyBoost" and boost.ExpiresAt > now then
            -- Re-roll once if Common, keep better result
            if rarity == "Common" then
                local reroll = rollRarity()
                local order = Constants.RARITY_ORDER
                local function rarityIndex(r)
                    for i, v in order do
                        if v == r then return i end
                    end
                    return 1
                end
                if rarityIndex(reroll) > rarityIndex(rarity) then
                    rarity = reroll
                end
            end
            break
        end
    end

    -- Pick icon
    local iconDef = pickIconForRarity(rarity)
    if not iconDef then
        -- Refund if something went wrong
        DataService.AddCurrency(player, eggTier.Cost)
        return
    end

    -- Add to inventory
    local iconInstance = DataService.AddIcon(player, iconDef.Id)
    if not iconInstance then
        DataService.AddCurrency(player, eggTier.Cost)
        return
    end

    -- Update stats
    DataService.Update(player, "EggsHatched", function(old)
        return old + 1
    end)

    -- Recalculate passive income
    EggService.RecalcPassiveIncome(player)

    -- Send result to client
    Remotes.GetEvent("EggHatchResult"):FireClient(player, {
        Success = true,
        Icon = {
            Id = iconDef.Id,
            Name = iconDef.Name,
            Rarity = iconDef.Rarity,
            Category = iconDef.Category,
            Description = iconDef.Description,
            UID = iconInstance.UID,
            Evolution = iconInstance.Evolution,
        },
        EggTier = eggTier.Name,
    })
end

-- ═══════════════════════════════════════════════════════════════
-- EVOLUTION
-- ═══════════════════════════════════════════════════════════════

local function handleEvolve(player: Player, targetIconUID: number)
    if type(targetIconUID) ~= "number" then return end

    local data = DataService.GetData(player)
    if not data then return end

    -- Find the target icon
    local targetIcon = DataService.GetIcon(player, targetIconUID)
    if not targetIcon then
        Remotes.GetEvent("EvolveIconResult"):FireClient(player, {
            Success = false,
            Reason = "IconNotFound",
        })
        return
    end

    -- Determine next evolution
    local currentEvo = targetIcon.Evolution
    local nextEvo = nil
    local dupesNeeded = 0

    if currentEvo == "Base" then
        nextEvo = Constants.Evolutions[1]
    else
        for i, evo in Constants.Evolutions do
            if evo.Name == currentEvo and i < #Constants.Evolutions then
                nextEvo = Constants.Evolutions[i + 1]
                break
            end
        end
    end

    if not nextEvo then
        Remotes.GetEvent("EvolveIconResult"):FireClient(player, {
            Success = false,
            Reason = "MaxEvolution",
        })
        return
    end

    dupesNeeded = nextEvo.DupesRequired

    -- Count duplicates (same IconId, Base evolution, not the target)
    local dupeCount = 0
    local dupesToConsume = {}
    for _, icon in data.Icons do
        if icon.IconId == targetIcon.IconId
            and icon.UID ~= targetIconUID
            and icon.Evolution == "Base"
            and not icon.Displayed
            and icon.VaultSlot == nil then
            dupeCount += 1
            table.insert(dupesToConsume, icon.UID)
            if dupeCount >= dupesNeeded then break end
        end
    end

    if dupeCount < dupesNeeded then
        Remotes.GetEvent("EvolveIconResult"):FireClient(player, {
            Success = false,
            Reason = "NotEnoughDupes",
            Have = dupeCount,
            Need = dupesNeeded,
        })
        return
    end

    -- Consume dupes
    for _, uid in dupesToConsume do
        DataService.RemoveIcon(player, uid)
    end

    -- Evolve the target
    targetIcon.Evolution = nextEvo.Name

    -- Recalculate passive income
    EggService.RecalcPassiveIncome(player)

    -- Notify client
    Remotes.GetEvent("PlayerDataUpdate"):FireClient(player, "Icons", data.Icons)
    Remotes.GetEvent("EvolveIconResult"):FireClient(player, {
        Success = true,
        IconUID = targetIconUID,
        NewEvolution = nextEvo.Name,
        Multiplier = nextEvo.Multiplier,
    })
end

-- ═══════════════════════════════════════════════════════════════
-- PASSIVE INCOME
-- ═══════════════════════════════════════════════════════════════

function EggService.RecalcPassiveIncome(player: Player)
    local data = DataService.GetData(player)
    if not data then return end

    local totalIncome = 0
    for _, icon in data.Icons do
        local iconDef = IconDatabase.GetById(icon.IconId)
        if iconDef then
            local rarityData = Constants.Rarities[iconDef.Rarity]
            if rarityData then
                local baseIncome = rarityData.PassiveIncome

                -- Apply evolution multiplier
                local evoMult = 1
                for _, evo in Constants.Evolutions do
                    if evo.Name == icon.Evolution then
                        evoMult = evo.Multiplier
                        break
                    end
                end

                totalIncome += baseIncome * evoMult
            end
        end
    end

    data.TotalPassiveIncome = totalIncome
end

local function tickPassiveIncome(dt: number)
    passiveIncomeAccum += dt
    if passiveIncomeAccum < PASSIVE_TICK_INTERVAL then return end
    passiveIncomeAccum = 0

    for _, player in Players:GetPlayers() do
        if DataService.IsLoaded(player) then
            local data = DataService.GetData(player)
            if data and data.TotalPassiveIncome > 0 then
                -- Income is DC/min, convert to per-tick
                local incomePerTick = (data.TotalPassiveIncome / 60) * PASSIVE_TICK_INTERVAL
                local mult = getIncomeMultiplier(player)
                local awarded = math.floor(incomePerTick * mult)

                if awarded > 0 then
                    DataService.AddCurrency(player, awarded)
                    DataService.Update(player, "TotalEarned", function(old)
                        return old + awarded
                    end)
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- INIT
-- ═══════════════════════════════════════════════════════════════

function EggService.Init()
    Remotes.GetEvent("EggHatchRequest").OnServerEvent:Connect(handleEggHatch)
    Remotes.GetEvent("EvolveIconRequest").OnServerEvent:Connect(handleEvolve)

    -- Passive income heartbeat
    RunService.Heartbeat:Connect(tickPassiveIncome)

    -- Recalculate income when data loads
    DataService.PlayerDataLoaded:Connect(function(player)
        EggService.RecalcPassiveIncome(player)
    end)

    -- Cleanup
    Players.PlayerRemoving:Connect(function(player)
        hatchLimiter:CleanupPlayer(player)
    end)

    print("[EggService] Initialized")
end

return EggService
