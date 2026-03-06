--[[
    WebhookClient.lua
    n8n-ready webhook placeholders for Palm Springs Paradise.
    All methods format correct payloads and are ready for real
    endpoint URLs to be plugged in.  In the meantime they log
    intent and return success.

    Usage (server-only):
        local Webhooks = require(ReplicatedStorage.WebhookClient)
        local client = Webhooks.new({ signupUrl = "https://n8n.example.com/webhook/..." })
        client:sendSignup(playerData)
]]

local HttpService = game:GetService("HttpService")

local WebhookClient = {}
WebhookClient.__index = WebhookClient

---------------------------------------------------------------------------
-- CONSTRUCTOR
---------------------------------------------------------------------------

--- Create a new WebhookClient with optional endpoint URLs.
--- @param config table? — { signupUrl?, eventUrl?, analyticsUrl?, transactionUrl? }
function WebhookClient.new(config: table?)
    local self = setmetatable({}, WebhookClient)
    config = config or {}

    self._endpoints = {
        signup      = config.signupUrl or "",      -- CF7 signup webhook
        event       = config.eventUrl or "",        -- Modernism Week scheduling
        analytics   = config.analyticsUrl or "",    -- general analytics
        transaction = config.transactionUrl or "",  -- shop transactions
    }

    self._log = {}  -- internal log of attempted sends

    print("[WebhookClient] Initialized — " ..
          (self:_hasAnyEndpoint() and "endpoints configured" or "placeholder mode"))
    return self
end

function WebhookClient:_hasAnyEndpoint(): boolean
    for _, url in pairs(self._endpoints) do
        if url ~= "" then return true end
    end
    return false
end

---------------------------------------------------------------------------
-- INTERNAL SEND
---------------------------------------------------------------------------

function WebhookClient:_send(endpointKey: string, payload: table): boolean
    local url = self._endpoints[endpointKey]
    local entry = {
        endpoint = endpointKey,
        payload  = payload,
        time     = os.time(),
        sent     = false,
    }

    if url == "" then
        -- Placeholder mode — log but don't send
        entry.status = "placeholder"
        table.insert(self._log, entry)
        print("[WebhookClient:PLACEHOLDER] " .. endpointKey ..
              " → " .. HttpService:JSONEncode(payload))
        return true
    end

    -- Attempt real HTTP POST
    local body = HttpService:JSONEncode(payload)
    local ok, err = pcall(function()
        HttpService:PostAsync(url, body, Enum.HttpContentType.ApplicationJson)
    end)

    entry.sent   = ok
    entry.status = ok and "sent" or ("error: " .. tostring(err))
    table.insert(self._log, entry)

    if not ok then
        warn("[WebhookClient] Failed to send " .. endpointKey .. ": " .. tostring(err))
    else
        print("[WebhookClient] Sent " .. endpointKey .. " to " .. url)
    end

    return ok
end

---------------------------------------------------------------------------
-- PUBLIC WEBHOOK METHODS
---------------------------------------------------------------------------

--- Send CF7 signup data (new player registration / marketing opt-in).
--- Payload: { userId, displayName, joinedAt, source }
function WebhookClient:sendSignup(playerData: table): boolean
    return self:_send("signup", {
        type        = "player_signup",
        userId      = playerData.userId,
        displayName = playerData.displayName,
        joinedAt    = os.date("!%Y-%m-%dT%H:%M:%SZ", os.time()),
        source      = "palm_springs_paradise",
        gameVersion = "1.0.0-prototype",
    })
end

--- Send Modernism Week 2026 scheduling data (Feb 12-22).
--- Payload: { eventName, startDate, endDate, specialItems, ... }
function WebhookClient:sendEventSchedule(eventData: table): boolean
    return self:_send("event", {
        type       = "event_schedule",
        eventName  = eventData.name or "Modernism Week 2026",
        startDate  = eventData.startDate or "2026-02-12",
        endDate    = eventData.endDate or "2026-02-22",
        details    = eventData.details or {},
        timestamp  = os.date("!%Y-%m-%dT%H:%M:%SZ", os.time()),
    })
end

--- Send analytics event (general-purpose telemetry).
--- Payload: { eventType, data, userId?, sessionId? }
function WebhookClient:sendAnalytics(eventType: string, data: table): boolean
    return self:_send("analytics", {
        type      = "analytics",
        event     = eventType,
        data      = data,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ", os.time()),
        serverId  = game.JobId,
    })
end

--- Send shop transaction for external tracking / reconciliation.
--- Payload: { buyerId, sellerId, itemId, amount, tax, ... }
function WebhookClient:sendShopTransaction(transactionData: table): boolean
    return self:_send("transaction", {
        type      = "shop_transaction",
        buyerId   = transactionData.buyerId,
        sellerId  = transactionData.sellerId,
        itemId    = transactionData.itemId,
        amount    = transactionData.amount,
        tax       = transactionData.tax,
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ", os.time()),
    })
end

---------------------------------------------------------------------------
-- LOG ACCESS
---------------------------------------------------------------------------

--- Returns the webhook call log (for debugging / test commands).
function WebhookClient:getLog(): { any }
    return self._log
end

--- Clear the log.
function WebhookClient:clearLog()
    self._log = {}
end

return WebhookClient
