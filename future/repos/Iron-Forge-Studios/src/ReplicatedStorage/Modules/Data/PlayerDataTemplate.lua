--[[
    PlayerDataTemplate.lua
    Default player data schema for DataStore v2.
    Every new player gets a deep copy of this template.
]]

local Constants = require(script.Parent.Parent.Shared.Constants)

local PlayerDataTemplate = {
    -- Schema version for migrations
    SchemaVersion = 1,

    -- ═══════════ ECONOMY ═══════════
    Currency = Constants.STARTING_CURRENCY,
    TotalEarned = 0,
    TotalSpent = 0,

    -- ═══════════ INVENTORY ═══════════
    -- Array of owned icon instances: { IconId, UID, Evolution, Displayed, VaultSlot }
    Icons = {},
    -- Unique counter for generating icon instance UIDs
    NextIconUID = 1,

    -- ═══════════ COLLECTION BOOK ═══════════
    -- Set of discovered icon IDs: { [iconId] = true }
    CollectionBook = {},

    -- ═══════════ EGG STATS ═══════════
    EggsHatched = 0,

    -- ═══════════ VAULT ═══════════
    VaultSlots = Constants.Heist.FREE_VAULT_SLOTS,

    -- ═══════════ HEIST ═══════════
    HeistAttemptsToday = 0,
    HeistLastResetDay = 0, -- os.time() day number
    HeistCooldownUntil = 0, -- os.time() timestamp
    HeistTargetCooldowns = {}, -- { [targetUserId] = expiresAt }
    HeistServerJoinTime = 0, -- set on join for server-hop lockout

    -- ═══════════ BUILDING ═══════════
    Plot = {
        PlotIndex = -1, -- assigned on join
        Furniture = {}, -- { { ItemId, X, Y, Z, Rotation } }
        DisplayPedestals = {}, -- { { Position, IconUID } }
        Rating = 0,
        TotalRatings = 0,
        RatingSum = 0,
        UniqueVisitorsToday = {},
        VisitorIncomeToday = 0,
    },

    -- ═══════════ TRADING ═══════════
    TradeHistory = {}, -- recent trades, capped at 50
    TradeCount = 0,

    -- ═══════════ GAME PASSES ═══════════
    OwnedPasses = {}, -- { [passKey] = true }

    -- ═══════════ DEV PRODUCT RECEIPTS ═══════════
    ProcessedReceipts = {}, -- { [receiptId] = true } for idempotency

    -- ═══════════ BOOSTS ═══════════
    ActiveBoosts = {}, -- { { BoostType, ExpiresAt } }

    -- ═══════════ SESSION ═══════════
    LastLogin = 0,
    TotalPlaytime = 0,
    JoinCount = 0,

    -- ═══════════ SETTINGS ═══════════
    Settings = {
        MusicVolume = 0.5,
        SFXVolume = 0.8,
        ShowTradeRequests = true,
        HeistNotifications = true,
    },

    -- ═══════════ NEWBIE SHIELD ═══════════
    NewbieShieldUntil = 0, -- set on first join

    -- ═══════════ LEADERBOARD ═══════════
    TotalPassiveIncome = 0, -- DC/min calculated from owned icons
    HeistsSucceeded = 0,
    HeistsFailed = 0,
    PlotRating = 0,
}

return PlayerDataTemplate
