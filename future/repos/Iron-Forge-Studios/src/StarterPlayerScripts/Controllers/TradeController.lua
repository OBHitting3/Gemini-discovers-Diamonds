--[[
    TradeController.lua (Client)
    Client-side trading interface: sending/receiving requests,
    updating offers, confirmation flow, and trade history display.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Modules.Shared.Remotes)
local Signal = require(ReplicatedStorage.Modules.Shared.Signal)

local TradeController = {}

TradeController.TradeRequested = Signal.new()
TradeController.TradeAccepted = Signal.new()
TradeController.TradeDeclined = Signal.new()
TradeController.OfferUpdated = Signal.new()
TradeController.ConfirmUpdated = Signal.new()
TradeController.TradeCompleted = Signal.new()
TradeController.TradeCancelled = Signal.new()
TradeController.TradeError = Signal.new()

local activeTrade = nil

function TradeController.RequestTrade(targetUserId: number)
    Remotes.GetEvent("TradeRequest"):FireServer(targetUserId)
end

function TradeController.RespondToTrade(tradeId: string, accepted: boolean)
    Remotes.GetEvent("TradeResponse"):FireServer(tradeId, accepted)
end

function TradeController.UpdateOffer(tradeId: string, iconUIDs: { number }, dcAmount: number)
    Remotes.GetEvent("TradeUpdateOffer"):FireServer(tradeId, iconUIDs, dcAmount)
end

function TradeController.ConfirmTrade(tradeId: string)
    Remotes.GetEvent("TradeConfirm"):FireServer(tradeId)
end

function TradeController.CancelTrade(tradeId: string)
    Remotes.GetEvent("TradeCancel"):FireServer(tradeId)
end

function TradeController.GetMarketplaceListings()
    return Remotes.GetFunction("MarketplaceList"):InvokeServer()
end

function TradeController.IsInTrade(): boolean
    return activeTrade ~= nil
end

function TradeController.GetActiveTrade(): table?
    return activeTrade
end

function TradeController.Init(player)
    -- Incoming trade request
    Remotes.GetEvent("TradeRequest").OnClientEvent:Connect(function(data)
        TradeController.TradeRequested:Fire(data)
    end)

    -- Trade response (accepted/declined/expired/error)
    Remotes.GetEvent("TradeResponse").OnClientEvent:Connect(function(data)
        if data.Type == "Accepted" then
            activeTrade = { TradeId = data.TradeId }
            TradeController.TradeAccepted:Fire(data)
        elseif data.Type == "Declined" then
            TradeController.TradeDeclined:Fire(data)
        elseif data.Type == "Error" then
            TradeController.TradeError:Fire(data)
        end
    end)

    -- Offer updates
    Remotes.GetEvent("TradeUpdateOffer").OnClientEvent:Connect(function(data)
        TradeController.OfferUpdated:Fire(data)
    end)

    -- Confirm updates
    Remotes.GetEvent("TradeConfirm").OnClientEvent:Connect(function(data)
        TradeController.ConfirmUpdated:Fire(data)
    end)

    -- Trade complete
    Remotes.GetEvent("TradeComplete").OnClientEvent:Connect(function(data)
        activeTrade = nil
        TradeController.TradeCompleted:Fire(data)
    end)

    -- Trade cancelled
    Remotes.GetEvent("TradeCancel").OnClientEvent:Connect(function(data)
        activeTrade = nil
        TradeController.TradeCancelled:Fire(data)
    end)
end

return TradeController
