--[[
    RateLimiter.lua
    Per-player rate limiting for remote calls.
    Prevents exploiters from spamming server remotes.
]]

local RateLimiter = {}
RateLimiter.__index = RateLimiter

export type RateLimiterConfig = {
    MaxCalls: number,
    WindowSeconds: number,
}

function RateLimiter.new(config: RateLimiterConfig)
    local self = setmetatable({}, RateLimiter)
    self._maxCalls = config.MaxCalls
    self._window = config.WindowSeconds
    self._players = {} -- { [userId] = { calls = {}, warned = bool } }
    return self
end

function RateLimiter:Check(player: Player): boolean
    local userId = player.UserId
    local now = os.clock()

    if not self._players[userId] then
        self._players[userId] = { calls = {}, warned = false }
    end

    local data = self._players[userId]
    local calls = data.calls

    -- Remove expired entries
    local cutoff = now - self._window
    local newCalls = {}
    for _, timestamp in calls do
        if timestamp > cutoff then
            table.insert(newCalls, timestamp)
        end
    end
    data.calls = newCalls

    -- Check limit
    if #newCalls >= self._maxCalls then
        if not data.warned then
            data.warned = true
            warn(string.format("[RateLimiter] Player %s (%d) exceeded rate limit: %d/%ds",
                player.Name, userId, self._maxCalls, self._window))
        end
        return false
    end

    -- Record call
    table.insert(data.calls, now)
    data.warned = false
    return true
end

function RateLimiter:CleanupPlayer(player: Player)
    self._players[player.UserId] = nil
end

function RateLimiter:Reset(player: Player)
    if self._players[player.UserId] then
        self._players[player.UserId].calls = {}
        self._players[player.UserId].warned = false
    end
end

return RateLimiter
