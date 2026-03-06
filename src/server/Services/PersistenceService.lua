--[[
    PersistenceService.lua
    Bridges DataStore (hot path) and Supabase (cold path) for
    Palm Springs Paradise hybrid persistence.

    Hot path (DataStore via ProfileServiceWrapper):
      SunCoins, Prestige, Level, plotId, shopId, inventory, stats

    Cold path (Supabase via SupabaseClient):
      Detailed furniture placements, garden history, fashion results,
      transaction logs, analytics

    Fallback: if Supabase is unavailable, all data stays in DataStore.
]]

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileServiceWrapper = require(ReplicatedStorage:WaitForChild("ProfileServiceWrapper"))
local SupabaseClient        = require(ReplicatedStorage:WaitForChild("SupabaseClient"))
local GameConfig            = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Utilities             = require(ReplicatedStorage:WaitForChild("Utilities"))

local PersistenceService = {}

-- Internal state
PersistenceService._profileStore = nil
PersistenceService._supabase = nil
PersistenceService._supabaseQueue = {}   -- batch queue for cold-path writes
PersistenceService._autoSaveRunning = false

---------------------------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------------------------

function PersistenceService:init()
    -- Create DataStore profile store
    self._profileStore = ProfileServiceWrapper.ProfileStore.new(
        "PalmSpringsParadise_v1",
        nil  -- uses Types.DefaultPlayerData as template
    )

    -- Create Supabase client (auto-detects mock mode in Play Solo)
    self._supabase = SupabaseClient.fromSecrets()

    -- Start auto-save
    self._profileStore:StartAutoSave(GameConfig.Timing.AutoSaveInterval)

    -- Start Supabase sync loop
    self:_startSupabaseSync()

    print("[PersistenceService] Initialized (DataStore + Supabase)")
end

---------------------------------------------------------------------------
-- PLAYER LOAD / RELEASE
---------------------------------------------------------------------------

--- Load a player's profile on join.
--- @return table? — the player data table, or nil on failure
function PersistenceService:loadPlayer(player: Player): table?
    local data = self._profileStore:LoadProfile(player)
    if not data then
        warn("[PersistenceService] Failed to load profile for " .. player.Name)
        return nil
    end

    -- Attempt to load detailed data from Supabase
    self:_loadSupabaseData(player, data)

    return data
end

--- Save and release a player's profile on leave.
function PersistenceService:releasePlayer(player: Player)
    -- Flush any pending Supabase writes for this player
    self:_flushSupabaseQueue(player.UserId)

    -- Release DataStore profile
    self._profileStore:ReleaseProfile(player)
end

---------------------------------------------------------------------------
-- SAVE OPERATIONS
---------------------------------------------------------------------------

--- Mark a player's data as dirty (will be saved on next auto-save).
function PersistenceService:markDirty(player: Player)
    self._profileStore:MarkDirty(player)
end

--- Force-save a specific player.
function PersistenceService:savePlayer(player: Player)
    self._profileStore:SaveProfile(player)
end

--- Save ALL players (for game close).
function PersistenceService:saveAll()
    self._profileStore:SaveAll()
    self:_flushAllSupabaseQueues()
    print("[PersistenceService] All players saved")
end

---------------------------------------------------------------------------
-- COLD-PATH: SUPABASE
---------------------------------------------------------------------------

--- Queue a plot layout save for Supabase.
function PersistenceService:savePlotLayout(player: Player, layoutData: table)
    table.insert(self._supabaseQueue, {
        type = "plot_layout",
        userId = player.UserId,
        data = layoutData,
        timestamp = os.time(),
    })
end

--- Queue a garden state save for Supabase.
function PersistenceService:saveGardenState(gardenData: table)
    table.insert(self._supabaseQueue, {
        type = "garden_state",
        data = gardenData,
        timestamp = os.time(),
    })
end

--- Queue an analytics event for Supabase.
function PersistenceService:logAnalytics(eventType: string, data: table)
    table.insert(self._supabaseQueue, {
        type = "analytics",
        event = eventType,
        data = data,
        timestamp = os.time(),
    })
end

--- Queue a transaction log for Supabase.
function PersistenceService:logTransaction(transactionData: table)
    table.insert(self._supabaseQueue, {
        type = "transaction",
        data = transactionData,
        timestamp = os.time(),
    })
end

---------------------------------------------------------------------------
-- SUPABASE SYNC LOOP
---------------------------------------------------------------------------

function PersistenceService:_startSupabaseSync()
    if self._autoSaveRunning then return end
    self._autoSaveRunning = true

    task.spawn(function()
        while self._autoSaveRunning do
            task.wait(GameConfig.Timing.SupabaseSyncInterval)
            self:_processSupabaseQueue()
        end
    end)
end

function PersistenceService:_processSupabaseQueue()
    if #self._supabaseQueue == 0 then return end

    local batch = self._supabaseQueue
    self._supabaseQueue = {}

    -- Process each item
    for _, item in ipairs(batch) do
        local ok, err

        if item.type == "plot_layout" then
            ok, err = self._supabase:upsert("plot_layouts", {
                user_id = item.userId,
                layout_data = item.data,
                updated_at = os.date("!%Y-%m-%dT%H:%M:%SZ", item.timestamp),
            })
        elseif item.type == "garden_state" then
            ok, err = self._supabase:upsert("garden_states", {
                server_id = game.JobId,
                state_data = item.data,
                updated_at = os.date("!%Y-%m-%dT%H:%M:%SZ", item.timestamp),
            })
        elseif item.type == "analytics" then
            ok, err = self._supabase:insert("analytics_events", {
                event_type = item.event,
                event_data = item.data,
                created_at = os.date("!%Y-%m-%dT%H:%M:%SZ", item.timestamp),
            })
        elseif item.type == "transaction" then
            ok, err = self._supabase:insert("transactions", {
                transaction_data = item.data,
                created_at = os.date("!%Y-%m-%dT%H:%M:%SZ", item.timestamp),
            })
        end

        if not ok then
            -- Re-queue failed items (they'll be retried next cycle)
            table.insert(self._supabaseQueue, item)
        end
    end

    if #batch > 0 then
        print("[PersistenceService] Supabase sync: " .. #batch .. " items processed")
    end
end

function PersistenceService:_flushSupabaseQueue(userId: number?)
    -- Process items for a specific user, or all if userId is nil
    local remaining = {}
    local toProcess = {}

    for _, item in ipairs(self._supabaseQueue) do
        if userId == nil or item.userId == userId then
            table.insert(toProcess, item)
        else
            table.insert(remaining, item)
        end
    end

    self._supabaseQueue = remaining

    -- Process immediately
    for _, item in ipairs(toProcess) do
        if item.type == "plot_layout" then
            self._supabase:upsert("plot_layouts", {
                user_id = item.userId,
                layout_data = item.data,
                updated_at = os.date("!%Y-%m-%dT%H:%M:%SZ", item.timestamp),
            })
        end
    end
end

function PersistenceService:_flushAllSupabaseQueues()
    self:_flushSupabaseQueue(nil)
end

---------------------------------------------------------------------------
-- SUPABASE DATA LOADING
---------------------------------------------------------------------------

function PersistenceService:_loadSupabaseData(player: Player, data: table)
    -- Attempt to load detailed plot layout from Supabase
    local ok, result = self._supabase:select("plot_layouts",
        "user_id=eq." .. player.UserId .. "&select=*")

    if ok and type(result) == "table" and #result > 0 then
        -- Merge Supabase data into player data
        local layout = result[1]
        if layout and layout.layout_data then
            data._supabasePlotLayout = layout.layout_data
        end
    end
end

---------------------------------------------------------------------------
-- DATA ACCESS
---------------------------------------------------------------------------

function PersistenceService:getPlayerData(player: Player): table?
    return self._profileStore:GetData(player)
end

function PersistenceService:getSupabaseClient()
    return self._supabase
end

return PersistenceService
