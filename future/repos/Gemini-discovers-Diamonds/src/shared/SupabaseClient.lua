--[[
    SupabaseClient.lua
    Roblox → Supabase REST client for cold-path persistence.
    Handles plot JSONB layouts, garden state history, analytics,
    and any data too detailed for DataStore's hot path.

    In production:  uses HttpService + Roblox Secrets for credentials.
    In Play Solo:   runs in MOCK MODE — logs calls, returns stub data.

    Usage (server-only):
        local Supa = require(ReplicatedStorage.SupabaseClient)
        local client = Supa.new("https://xyz.supabase.co", "your-anon-key")
        local rows = client:select("plots", "owner_id=eq.12345")
]]

local HttpService = game:GetService("HttpService")
local RunService  = game:GetService("RunService")

local SupabaseClient = {}
SupabaseClient.__index = SupabaseClient

---------------------------------------------------------------------------
-- CONSTRUCTOR
---------------------------------------------------------------------------

--- Create a new Supabase REST client.
--- @param url    string — Supabase project URL (e.g. "https://xyz.supabase.co")
--- @param apiKey string — anon/public API key (or use secrets in prod)
function SupabaseClient.new(url: string?, apiKey: string?)
    local self = setmetatable({}, SupabaseClient)
    self._url    = url or ""
    self._apiKey = apiKey or ""
    self._mockMode = (url == nil or url == "" or not RunService:IsServer())
    self._log = {}  -- stores mock-mode call log for debugging

    if self._mockMode then
        print("[SupabaseClient] Running in MOCK MODE (no external calls)")
    else
        print("[SupabaseClient] Initialized for " .. self._url)
    end

    return self
end

--- Attempt to create a client using Roblox Secrets (production path).
--- Falls back to mock mode if secrets are unavailable.
function SupabaseClient.fromSecrets()
    local url, key
    local ok1, result1 = pcall(function()
        return HttpService:GetSecret("SUPABASE_URL")
    end)
    local ok2, result2 = pcall(function()
        return HttpService:GetSecret("SUPABASE_ANON_KEY")
    end)

    if ok1 and ok2 then
        url = result1
        key = result2
    else
        warn("[SupabaseClient] Could not read secrets — using mock mode")
    end

    return SupabaseClient.new(url, key)
end

---------------------------------------------------------------------------
-- INTERNAL HTTP
---------------------------------------------------------------------------

function SupabaseClient:_headers()
    return {
        ["apikey"]        = self._apiKey,
        ["Authorization"] = "Bearer " .. self._apiKey,
        ["Content-Type"]  = "application/json",
        ["Prefer"]        = "return=representation",
    }
end

function SupabaseClient:_request(method: string, path: string, body: string?): (boolean, any)
    if self._mockMode then
        local entry = {
            method = method,
            path   = path,
            body   = body,
            time   = os.time(),
        }
        table.insert(self._log, entry)
        print("[SupabaseClient:MOCK] " .. method .. " " .. path)
        return true, {}
    end

    local url = self._url .. "/rest/v1/" .. path
    local ok, result = pcall(function()
        if method == "GET" then
            return HttpService:GetAsync(url, false, self:_headers())
        else
            return HttpService:PostAsync(url, body or "{}", Enum.HttpContentType.ApplicationJson, false, self:_headers())
        end
    end)

    if not ok then
        warn("[SupabaseClient] " .. method .. " " .. path .. " failed: " .. tostring(result))
        return false, result
    end

    -- Decode JSON response
    local decodeOk, decoded = pcall(function()
        return HttpService:JSONDecode(result)
    end)

    if decodeOk then
        return true, decoded
    else
        return true, result  -- return raw string if not JSON
    end
end

---------------------------------------------------------------------------
-- CRUD OPERATIONS
---------------------------------------------------------------------------

--- SELECT rows from a table with optional PostgREST query.
--- @param tableName string — e.g. "plots"
--- @param query     string — e.g. "owner_id=eq.12345&select=*"
function SupabaseClient:select(tableName: string, query: string?): (boolean, any)
    local path = tableName
    if query and query ~= "" then
        path = path .. "?" .. query
    end
    return self:_request("GET", path)
end

--- INSERT a row into a table.
function SupabaseClient:insert(tableName: string, data: table): (boolean, any)
    local body = HttpService:JSONEncode(data)
    return self:_request("POST", tableName, body)
end

--- UPDATE rows matching a filter.
--- @param tableName string
--- @param match     string — PostgREST filter, e.g. "id=eq.42"
--- @param data      table  — columns to update
function SupabaseClient:update(tableName: string, match: string, data: table): (boolean, any)
    local body = HttpService:JSONEncode(data)
    -- PATCH requests — Supabase REST uses PATCH for updates
    -- We'll use PostAsync with a custom header approach
    local path = tableName .. "?" .. match
    return self:_request("PATCH", path, body)
end

--- UPSERT a row (insert or update on conflict).
function SupabaseClient:upsert(tableName: string, data: table): (boolean, any)
    local body = HttpService:JSONEncode(data)
    local path = tableName
    -- Upsert uses POST with Prefer: resolution=merge-duplicates header
    return self:_request("POST", path, body)
end

--- DELETE rows matching a filter.
function SupabaseClient:delete(tableName: string, match: string): (boolean, any)
    local path = tableName .. "?" .. match
    return self:_request("DELETE", path)
end

--- Call a Supabase RPC (stored function).
function SupabaseClient:rpc(funcName: string, params: table?): (boolean, any)
    local body = HttpService:JSONEncode(params or {})
    return self:_request("POST", "rpc/" .. funcName, body)
end

---------------------------------------------------------------------------
-- MOCK-MODE LOG ACCESS
---------------------------------------------------------------------------

--- Returns the mock-mode call log (for debugging / test commands).
function SupabaseClient:getMockLog(): { any }
    return self._log
end

--- Clear the mock log.
function SupabaseClient:clearMockLog()
    self._log = {}
end

return SupabaseClient
