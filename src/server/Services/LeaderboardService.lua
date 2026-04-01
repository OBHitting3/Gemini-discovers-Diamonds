--[[
    LeaderboardService.lua
    Global leaderboards for Palm Springs Paradise.
    Tracks top players by SunCoins, Prestige, and Vibes Score.
    Uses OrderedDataStores for persistent cross-server rankings.
    Serves data to clients via GetLeaderboard RemoteFunction.
]]

local DataStoreService  = game:GetService("DataStoreService")
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig    = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteManager = require(ReplicatedStorage:WaitForChild("RemoteManager"))

local LeaderboardService = {}

LeaderboardService._economyService = nil
LeaderboardService._plotService = nil
LeaderboardService._boards = {}         -- boardName → OrderedDataStore
LeaderboardService._cache = {}          -- boardName → { entries, lastUpdate }
LeaderboardService._cacheLifetime = 30  -- seconds

---------------------------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------------------------

function LeaderboardService:init(economyService, plotService)
    self._economyService = economyService
    self._plotService = plotService

    -- Lazy-init ordered data stores (pcall for Play Solo safety)
    pcall(function()
        self._boards.SunCoins = DataStoreService:GetOrderedDataStore("Leaderboard_SunCoins")
        self._boards.Prestige = DataStoreService:GetOrderedDataStore("Leaderboard_Prestige")
        self._boards.Vibes    = DataStoreService:GetOrderedDataStore("Leaderboard_Vibes")
    end)

    -- Wire up the GetLeaderboard RemoteFunction
    local getFunc = RemoteManager:getFunction("GetLeaderboard")
    if getFunc then
        getFunc.OnServerInvoke = function(player, boardName)
            return self:getLeaderboard(boardName or "SunCoins")
        end
    end

    -- Start periodic update loop (push local player stats every 60s)
    self:_startUpdateLoop()

    print("[LeaderboardService] Initialized (SunCoins, Prestige, Vibes)")
end

---------------------------------------------------------------------------
-- PUBLIC API
---------------------------------------------------------------------------

--- Get the top 20 entries for a leaderboard.
--- @param boardName string — "SunCoins" | "Prestige" | "Vibes"
--- @return { { rank: number, name: string, value: number } }
function LeaderboardService:getLeaderboard(boardName: string): { any }
    boardName = boardName or "SunCoins"

    -- Return cached if fresh
    local cached = self._cache[boardName]
    if cached and (os.clock() - cached.lastUpdate) < self._cacheLifetime then
        return cached.entries
    end

    -- Build from local players as fallback / primary
    local entries = self:_buildLocalBoard(boardName)

    -- Try ordered data store for cross-server data
    local ds = self._boards[boardName]
    if ds then
        local ok, pages = pcall(function()
            return ds:GetSortedAsync(false, 20) -- descending, top 20
        end)
        if ok and pages then
            local dsEntries = {}
            local page = pages:GetCurrentPage()
            for rank, entry in ipairs(page) do
                -- entry.key = "user_USERID", entry.value = score
                local userId = tonumber(string.match(entry.key, "user_(%d+)"))
                local name = "Player"
                if userId then
                    local ok2, n = pcall(function()
                        return Players:GetNameFromUserIdAsync(userId)
                    end)
                    if ok2 then name = n end
                end
                table.insert(dsEntries, {
                    rank = rank,
                    name = name,
                    value = entry.value,
                    userId = userId,
                })
            end
            if #dsEntries > 0 then
                entries = dsEntries
            end
        end
    end

    -- Merge local players into the board (they may have newer data)
    entries = self:_mergeLocalPlayers(entries, boardName)

    -- Sort descending and re-rank
    table.sort(entries, function(a, b) return a.value > b.value end)
    for i, e in ipairs(entries) do e.rank = i end

    -- Trim to top 20
    while #entries > 20 do
        table.remove(entries)
    end

    -- Cache it
    self._cache[boardName] = {
        entries = entries,
        lastUpdate = os.clock(),
    }

    return entries
end

---------------------------------------------------------------------------
-- INTERNAL: Build board from current server's players
---------------------------------------------------------------------------

function LeaderboardService:_buildLocalBoard(boardName: string): { any }
    local entries = {}

    for _, player in ipairs(Players:GetPlayers()) do
        local data = self._economyService:getPlayerData(player)
        if data then
            local value = 0
            if boardName == "SunCoins" then
                value = data.sunCoins or 0
            elseif boardName == "Prestige" then
                value = data.prestige or 0
            elseif boardName == "Vibes" then
                local plotId = data.plotId
                if plotId and self._plotService then
                    value = self._plotService:getVibesScore(plotId)
                end
            end

            table.insert(entries, {
                rank = 0,
                name = player.Name,
                value = value,
                userId = player.UserId,
            })
        end
    end

    return entries
end

function LeaderboardService:_mergeLocalPlayers(entries: { any }, boardName: string): { any }
    local existing = {}
    for _, e in ipairs(entries) do
        if e.userId then existing[e.userId] = true end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if not existing[player.UserId] then
            local data = self._economyService:getPlayerData(player)
            if data then
                local value = 0
                if boardName == "SunCoins" then value = data.sunCoins or 0
                elseif boardName == "Prestige" then value = data.prestige or 0
                elseif boardName == "Vibes" then
                    local plotId = data.plotId
                    if plotId and self._plotService then
                        value = self._plotService:getVibesScore(plotId)
                    end
                end
                table.insert(entries, {
                    rank = 0, name = player.Name,
                    value = value, userId = player.UserId,
                })
            end
        end
    end

    return entries
end

---------------------------------------------------------------------------
-- PERIODIC PUSH TO ORDERED DATASTORES
---------------------------------------------------------------------------

function LeaderboardService:_startUpdateLoop()
    task.spawn(function()
        while true do
            task.wait(60)
            self:_pushToDataStores()
        end
    end)
end

function LeaderboardService:_pushToDataStores()
    for _, player in ipairs(Players:GetPlayers()) do
        local data = self._economyService:getPlayerData(player)
        if not data then continue end

        local key = "user_" .. tostring(player.UserId)

        -- SunCoins
        if self._boards.SunCoins then
            pcall(function()
                self._boards.SunCoins:SetAsync(key, math.floor(data.sunCoins or 0))
            end)
        end

        -- Prestige
        if self._boards.Prestige then
            pcall(function()
                self._boards.Prestige:SetAsync(key, math.floor(data.prestige or 0))
            end)
        end

        -- Vibes
        if self._boards.Vibes and data.plotId and self._plotService then
            local vibes = self._plotService:getVibesScore(data.plotId)
            pcall(function()
                self._boards.Vibes:SetAsync(key, math.floor(vibes or 0))
            end)
        end
    end
end

return LeaderboardService
