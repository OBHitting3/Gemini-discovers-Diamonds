--[[
    TradeService.lua (Server)
    Direct player-to-player trading with marketplace support.
    - 30-sec confirm timer
    - 5% tax on DC transfers
    - Trade history logging
    - Cross-server marketplace via MessagingService
    - Server-side validation on all transfers
]]

local Players = game:GetService("Players")
local MessagingService = game:GetService("MessagingService")

local Constants = require(game.ReplicatedStorage.Modules.Shared.Constants)
local Util = require(game.ReplicatedStorage.Modules.Shared.Util)
local Remotes = require(game.ReplicatedStorage.Modules.Shared.Remotes)
local DataService = require(game.ServerScriptService.Services.DataService)
local IconDatabase = require(game.ReplicatedStorage.Modules.Data.IconDatabase)
local RateLimiter = require(game.ServerScriptService.Modules.RateLimiter)

local TradeService = {}

-- ═══════════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════════
local activeTrades = {} -- { [tradeId] = tradeSession }
local playerInTrade = {} -- { [userId] = tradeId }
local tradeLimiter = RateLimiter.new({
    MaxCalls = Constants.RateLimit.TRADE_REQUESTS_PER_MINUTE,
    WindowSeconds = 60,
})

local tradeIdCounter = 0

-- Marketplace listings (in-memory for this server, synced cross-server)
local marketplace = {} -- { [listingId] = { SellerUserId, IconId, IconUID, AskingPrice, ListedAt } }

-- ═══════════════════════════════════════════════════════════════
-- TRADE SESSION
-- ═══════════════════════════════════════════════════════════════

local function createTradeId(): string
    tradeIdCounter += 1
    return "trade_" .. tostring(tradeIdCounter) .. "_" .. tostring(os.time())
end

local function cleanupTrade(tradeId: string)
    local trade = activeTrades[tradeId]
    if not trade then return end

    playerInTrade[trade.Player1Id] = nil
    playerInTrade[trade.Player2Id] = nil
    activeTrades[tradeId] = nil
end

local function handleTradeRequest(sender: Player, targetUserId: number)
    if type(targetUserId) ~= "number" then return end

    -- Rate limit
    if not tradeLimiter:Check(sender) then return end

    -- Can't trade with self
    if sender.UserId == targetUserId then return end

    -- Check if either player is already in trade
    if playerInTrade[sender.UserId] then
        Remotes.GetEvent("TradeResponse"):FireClient(sender, {
            Type = "Error",
            Reason = "AlreadyInTrade",
        })
        return
    end

    if playerInTrade[targetUserId] then
        Remotes.GetEvent("TradeResponse"):FireClient(sender, {
            Type = "Error",
            Reason = "TargetInTrade",
        })
        return
    end

    -- Check target settings
    local target = Players:GetPlayerByUserId(targetUserId)
    if not target then return end

    local targetData = DataService.GetData(target)
    if targetData and targetData.Settings and not targetData.Settings.ShowTradeRequests then
        Remotes.GetEvent("TradeResponse"):FireClient(sender, {
            Type = "Error",
            Reason = "TradeRequestsDisabled",
        })
        return
    end

    -- Create trade session
    local tradeId = createTradeId()
    activeTrades[tradeId] = {
        TradeId = tradeId,
        Player1Id = sender.UserId,
        Player2Id = targetUserId,
        Player1Offer = { Icons = {}, DC = 0 },
        Player2Offer = { Icons = {}, DC = 0 },
        Player1Confirmed = false,
        Player2Confirmed = false,
        CreatedAt = os.time(),
        Phase = "Pending", -- Pending, Open, Confirming, Complete, Cancelled
    }

    playerInTrade[sender.UserId] = tradeId

    -- Send request to target
    Remotes.GetEvent("TradeRequest"):FireClient(target, {
        TradeId = tradeId,
        SenderName = sender.Name,
        SenderUserId = sender.UserId,
    })

    -- Auto-expire after 30 seconds if not accepted
    task.delay(30, function()
        local trade = activeTrades[tradeId]
        if trade and trade.Phase == "Pending" then
            cleanupTrade(tradeId)
            Remotes.GetEvent("TradeResponse"):FireClient(sender, {
                Type = "Expired",
                TradeId = tradeId,
            })
        end
    end)
end

local function handleTradeResponse(player: Player, tradeId: string, accepted: boolean)
    if type(tradeId) ~= "string" or type(accepted) ~= "boolean" then return end

    local trade = activeTrades[tradeId]
    if not trade then return end
    if trade.Player2Id ~= player.UserId then return end
    if trade.Phase ~= "Pending" then return end

    if not accepted then
        local sender = Players:GetPlayerByUserId(trade.Player1Id)
        cleanupTrade(tradeId)
        if sender then
            Remotes.GetEvent("TradeResponse"):FireClient(sender, {
                Type = "Declined",
                TradeId = tradeId,
            })
        end
        return
    end

    -- Accept trade
    trade.Phase = "Open"
    playerInTrade[player.UserId] = tradeId

    local sender = Players:GetPlayerByUserId(trade.Player1Id)
    if sender then
        Remotes.GetEvent("TradeResponse"):FireClient(sender, {
            Type = "Accepted",
            TradeId = tradeId,
        })
    end
    Remotes.GetEvent("TradeResponse"):FireClient(player, {
        Type = "Accepted",
        TradeId = tradeId,
    })
end

local function handleTradeUpdateOffer(player: Player, tradeId: string, iconUIDs: { number }, dcAmount: number)
    if type(tradeId) ~= "string" then return end
    iconUIDs = type(iconUIDs) == "table" and iconUIDs or {}
    dcAmount = type(dcAmount) == "number" and math.max(0, math.floor(dcAmount)) or 0

    local trade = activeTrades[tradeId]
    if not trade or trade.Phase ~= "Open" then return end

    local isPlayer1 = trade.Player1Id == player.UserId
    local isPlayer2 = trade.Player2Id == player.UserId
    if not isPlayer1 and not isPlayer2 then return end

    -- Validate icons
    local validIcons = {}
    for _, uid in iconUIDs do
        if type(uid) == "number" then
            local icon = DataService.GetIcon(player, uid)
            if icon and not icon.VaultSlot then
                table.insert(validIcons, uid)
                if #validIcons >= Constants.Trade.MAX_ITEMS_PER_SIDE then break end
            end
        end
    end

    -- Validate DC
    local data = DataService.GetData(player)
    if data then
        dcAmount = math.min(dcAmount, data.Currency)
    end

    local offer = { Icons = validIcons, DC = dcAmount }

    if isPlayer1 then
        trade.Player1Offer = offer
    else
        trade.Player2Offer = offer
    end

    -- Reset confirms when offer changes
    trade.Player1Confirmed = false
    trade.Player2Confirmed = false

    -- Notify both players of updated offer
    local p1 = Players:GetPlayerByUserId(trade.Player1Id)
    local p2 = Players:GetPlayerByUserId(trade.Player2Id)

    local tradeState = {
        Type = "OfferUpdate",
        TradeId = tradeId,
        Player1Offer = trade.Player1Offer,
        Player2Offer = trade.Player2Offer,
    }

    if p1 then Remotes.GetEvent("TradeUpdateOffer"):FireClient(p1, tradeState) end
    if p2 then Remotes.GetEvent("TradeUpdateOffer"):FireClient(p2, tradeState) end
end

local function handleTradeConfirm(player: Player, tradeId: string)
    if type(tradeId) ~= "string" then return end

    local trade = activeTrades[tradeId]
    if not trade or trade.Phase ~= "Open" then return end

    if trade.Player1Id == player.UserId then
        trade.Player1Confirmed = true
    elseif trade.Player2Id == player.UserId then
        trade.Player2Confirmed = true
    else
        return
    end

    -- Notify other player
    local p1 = Players:GetPlayerByUserId(trade.Player1Id)
    local p2 = Players:GetPlayerByUserId(trade.Player2Id)
    local confirmState = {
        Type = "ConfirmUpdate",
        TradeId = tradeId,
        Player1Confirmed = trade.Player1Confirmed,
        Player2Confirmed = trade.Player2Confirmed,
    }
    if p1 then Remotes.GetEvent("TradeConfirm"):FireClient(p1, confirmState) end
    if p2 then Remotes.GetEvent("TradeConfirm"):FireClient(p2, confirmState) end

    -- Both confirmed? Execute trade
    if trade.Player1Confirmed and trade.Player2Confirmed then
        TradeService._executeTrade(trade)
    end
end

function TradeService._executeTrade(trade)
    trade.Phase = "Complete"

    local p1 = Players:GetPlayerByUserId(trade.Player1Id)
    local p2 = Players:GetPlayerByUserId(trade.Player2Id)
    local data1 = p1 and DataService.GetData(p1)
    local data2 = p2 and DataService.GetData(p2)

    if not data1 or not data2 then
        cleanupTrade(trade.TradeId)
        return
    end

    -- Re-validate all items still exist and are owned
    local function validateOffer(player, offer)
        for _, uid in offer.Icons do
            local icon = DataService.GetIcon(player, uid)
            if not icon or icon.VaultSlot ~= nil then return false end
        end
        if offer.DC > 0 then
            local data = DataService.GetData(player)
            if not data or data.Currency < offer.DC then return false end
        end
        return true
    end

    if not validateOffer(p1, trade.Player1Offer) or not validateOffer(p2, trade.Player2Offer) then
        local errorMsg = { Type = "Error", Reason = "ValidationFailed", TradeId = trade.TradeId }
        if p1 then Remotes.GetEvent("TradeComplete"):FireClient(p1, errorMsg) end
        if p2 then Remotes.GetEvent("TradeComplete"):FireClient(p2, errorMsg) end
        cleanupTrade(trade.TradeId)
        return
    end

    -- Transfer P1 icons to P2
    for _, uid in trade.Player1Offer.Icons do
        local icon = DataService.GetIcon(p1, uid)
        if icon then
            local iconId = icon.IconId
            local evolution = icon.Evolution
            DataService.RemoveIcon(p1, uid)
            DataService.AddIcon(p2, iconId, evolution)
        end
    end

    -- Transfer P2 icons to P1
    for _, uid in trade.Player2Offer.Icons do
        local icon = DataService.GetIcon(p2, uid)
        if icon then
            local iconId = icon.IconId
            local evolution = icon.Evolution
            DataService.RemoveIcon(p2, uid)
            DataService.AddIcon(p1, iconId, evolution)
        end
    end

    -- Transfer DC with tax
    local taxRate = Constants.Trade.TAX_PERCENT / 100
    if trade.Player1Offer.DC > 0 then
        local amount = trade.Player1Offer.DC
        local tax = math.floor(amount * taxRate)
        DataService.SpendCurrency(p1, amount)
        DataService.AddCurrency(p2, amount - tax)
    end
    if trade.Player2Offer.DC > 0 then
        local amount = trade.Player2Offer.DC
        local tax = math.floor(amount * taxRate)
        DataService.SpendCurrency(p2, amount)
        DataService.AddCurrency(p1, amount - tax)
    end

    -- Log trade history (capped at 50)
    local tradeLog = {
        TradeId = trade.TradeId,
        Timestamp = os.time(),
        Partner = nil, -- set per-player
        Gave = nil,
        Received = nil,
    }

    local function addTradeHistory(data, partnerId, gaveOffer, receivedOffer)
        local entry = Util.ShallowCopy(tradeLog)
        entry.Partner = partnerId
        entry.Gave = gaveOffer
        entry.Received = receivedOffer
        table.insert(data.TradeHistory, 1, entry)
        if #data.TradeHistory > 50 then
            table.remove(data.TradeHistory)
        end
        data.TradeCount = (data.TradeCount or 0) + 1
    end

    addTradeHistory(data1, trade.Player2Id, trade.Player1Offer, trade.Player2Offer)
    addTradeHistory(data2, trade.Player1Id, trade.Player2Offer, trade.Player1Offer)

    -- Notify completion
    local completeMsg = { Type = "Complete", TradeId = trade.TradeId }
    if p1 then Remotes.GetEvent("TradeComplete"):FireClient(p1, completeMsg) end
    if p2 then Remotes.GetEvent("TradeComplete"):FireClient(p2, completeMsg) end

    cleanupTrade(trade.TradeId)
end

local function handleTradeCancel(player: Player, tradeId: string)
    if type(tradeId) ~= "string" then return end

    local trade = activeTrades[tradeId]
    if not trade then return end
    if trade.Player1Id ~= player.UserId and trade.Player2Id ~= player.UserId then return end

    local p1 = Players:GetPlayerByUserId(trade.Player1Id)
    local p2 = Players:GetPlayerByUserId(trade.Player2Id)

    local cancelMsg = {
        Type = "Cancelled",
        TradeId = tradeId,
        CancelledBy = player.Name,
    }
    if p1 then Remotes.GetEvent("TradeCancel"):FireClient(p1, cancelMsg) end
    if p2 then Remotes.GetEvent("TradeCancel"):FireClient(p2, cancelMsg) end

    cleanupTrade(tradeId)
end

-- ═══════════════════════════════════════════════════════════════
-- MARKETPLACE (Cross-server via MessagingService)
-- ═══════════════════════════════════════════════════════════════

local function handleMarketplaceList(player: Player, data: table)
    -- Returns current marketplace listings
    local listings = {}
    for id, listing in marketplace do
        table.insert(listings, {
            ListingId = id,
            SellerUserId = listing.SellerUserId,
            SellerName = listing.SellerName,
            IconId = listing.IconId,
            AskingPrice = listing.AskingPrice,
            ListedAt = listing.ListedAt,
        })
    end
    return listings
end

function TradeService._setupCrossServer()
    local topic = Constants.Trade.CROSS_SERVER_TOPIC

    -- Subscribe to cross-server trade messages
    local success, err = pcall(function()
        MessagingService:SubscribeAsync(topic, function(message)
            local data = message.Data
            if data.Type == "NewListing" then
                marketplace[data.ListingId] = data.Listing
            elseif data.Type == "RemoveListing" then
                marketplace[data.ListingId] = nil
            end
        end)
    end)

    if not success then
        warn("[TradeService] Cross-server setup failed:", err)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- INIT
-- ═══════════════════════════════════════════════════════════════

function TradeService.Init()
    Remotes.GetEvent("TradeRequest").OnServerEvent:Connect(handleTradeRequest)
    Remotes.GetEvent("TradeResponse").OnServerEvent:Connect(handleTradeResponse)
    Remotes.GetEvent("TradeUpdateOffer").OnServerEvent:Connect(handleTradeUpdateOffer)
    Remotes.GetEvent("TradeConfirm").OnServerEvent:Connect(handleTradeConfirm)
    Remotes.GetEvent("TradeCancel").OnServerEvent:Connect(handleTradeCancel)
    Remotes.GetFunction("MarketplaceList").OnServerInvoke = handleMarketplaceList

    -- Cross-server marketplace
    TradeService._setupCrossServer()

    -- Cleanup on leave
    Players.PlayerRemoving:Connect(function(player)
        local tradeId = playerInTrade[player.UserId]
        if tradeId then
            handleTradeCancel(player, tradeId)
        end
        tradeLimiter:CleanupPlayer(player)
    end)

    print("[TradeService] Initialized")
end

return TradeService
