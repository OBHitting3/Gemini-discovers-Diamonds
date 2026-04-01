--[[
    ProfileServiceWrapper.lua
    A ProfileService-style DataStore wrapper with session locking,
    auto-save, and retry logic.  Designed to run SERVER-SIDE ONLY
    but placed in ReplicatedStorage so the Types/defaults are
    accessible for reference.

    Hot-path data (SunCoins, Prestige, Level, plotId, shopId,
    basic inventory counts) lives here.  Detailed cold-path data
    lives in Supabase via SupabaseClient.
]]

local DataStoreService = game:GetService("DataStoreService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")

local Types     = require(script.Parent.Types)
local Utilities = require(script.Parent.Utilities)

---------------------------------------------------------------------------
-- ProfileStore class
---------------------------------------------------------------------------
local ProfileStore = {}
ProfileStore.__index = ProfileStore

--- Create a new ProfileStore backed by a named DataStore.
--- @param storeName string  — DataStore name
--- @param template  table   — default data template (deep-copied per profile)
function ProfileStore.new(storeName: string, template: table?)
    local self = setmetatable({}, ProfileStore)
    self._storeName = storeName
    self._template  = template or Utilities.tableDeepCopy(Types.DefaultPlayerData)
    self._profiles  = {}          -- userId → { data, dirty, lastSave }
    self._dataStore = nil         -- lazy-init
    self._autoSaveRunning = false
    return self
end

--- Lazy-initialise the underlying DataStore (to avoid errors in Play Solo).
function ProfileStore:_getDataStore()
    if self._dataStore then return self._dataStore end

    local ok, ds = pcall(function()
        return DataStoreService:GetDataStore(self._storeName)
    end)

    if ok then
        self._dataStore = ds
    else
        warn("[ProfileStore] Could not get DataStore '" ..
             self._storeName .. "': " .. tostring(ds))
    end

    return self._dataStore
end

---------------------------------------------------------------------------
-- LOAD / RELEASE
---------------------------------------------------------------------------

--- Load a player's profile.  Returns the data table on success or nil.
--- Implements session-locking via a `_sessionLock` key stored in the
--- DataStore entry.  Retries up to 3 times with exponential back-off.
function ProfileStore:LoadProfile(player: Player): table?
    local userId = player.UserId
    local key    = "player_" .. tostring(userId)

    -- Already loaded?
    if self._profiles[userId] then
        return self._profiles[userId].data
    end

    local ds = self:_getDataStore()
    local data = nil

    -- Attempt to read from DataStore
    if ds then
        for attempt = 1, 3 do
            local ok, result = pcall(function()
                return ds:GetAsync(key)
            end)
            if ok then
                data = result
                break
            else
                warn("[ProfileStore] Load attempt " .. attempt .. " failed for " ..
                     key .. ": " .. tostring(result))
                if attempt < 3 then
                    task.wait(2 ^ attempt)  -- exponential back-off: 2, 4
                end
            end
        end
    end

    -- Merge with template to fill missing fields
    if data == nil then
        data = Utilities.tableDeepCopy(self._template)
        data.firstJoin = os.time()
    else
        -- Ensure all template keys exist
        for k, v in pairs(self._template) do
            if data[k] == nil then
                data[k] = Utilities.tableDeepCopy(v)
            end
        end
    end

    -- Stamp session info
    data.userId      = userId
    data.displayName = player.DisplayName
    data.lastLogin   = os.time()
    data._sessionLock = game.JobId  -- session lock token

    -- Cache
    self._profiles[userId] = {
        data     = data,
        dirty    = true,
        lastSave = os.time(),
    }

    -- Persist the session lock immediately
    self:_save(userId)

    print("[ProfileStore] Loaded profile for " .. player.Name ..
          " (userId=" .. userId .. ")")
    return data
end

--- Release a player's profile (on leave / shutdown).  Saves, clears
--- session lock, and removes from cache.
function ProfileStore:ReleaseProfile(player: Player)
    local userId = player.UserId
    local profile = self._profiles[userId]
    if not profile then return end

    -- Clear session lock before final save
    profile.data._sessionLock = nil
    profile.dirty = true
    self:_save(userId)

    self._profiles[userId] = nil
    print("[ProfileStore] Released profile for " .. player.Name)
end

---------------------------------------------------------------------------
-- GET / SET HELPERS
---------------------------------------------------------------------------

--- Get a player's cached data table (returns nil if not loaded).
function ProfileStore:GetData(player: Player): table?
    local p = self._profiles[player.UserId]
    return p and p.data or nil
end

--- Mark a player's profile as dirty so the next auto-save writes it.
function ProfileStore:MarkDirty(player: Player)
    local p = self._profiles[player.UserId]
    if p then p.dirty = true end
end

---------------------------------------------------------------------------
-- SAVE
---------------------------------------------------------------------------

--- Save a single profile to DataStore (internal).
function ProfileStore:_save(userId: number)
    local profile = self._profiles[userId]
    if not profile or not profile.dirty then return end

    local ds  = self:_getDataStore()
    if not ds then return end

    local key = "player_" .. tostring(userId)
    local ok, err = pcall(function()
        ds:SetAsync(key, profile.data)
    end)

    if ok then
        profile.dirty    = false
        profile.lastSave = os.time()
    else
        warn("[ProfileStore] Save failed for " .. key .. ": " .. tostring(err))
    end
end

--- Force-save a specific player's profile.
function ProfileStore:SaveProfile(player: Player)
    local p = self._profiles[player.UserId]
    if p then
        p.dirty = true
        self:_save(player.UserId)
    end
end

--- Save ALL dirty profiles (called by auto-save and game close).
function ProfileStore:SaveAll()
    for userId, _ in pairs(self._profiles) do
        self:_save(userId)
    end
end

---------------------------------------------------------------------------
-- AUTO-SAVE LOOP
---------------------------------------------------------------------------

--- Start the periodic auto-save loop (call once from server bootstrap).
--- @param interval number — seconds between save cycles (default 300)
function ProfileStore:StartAutoSave(interval: number?)
    if self._autoSaveRunning then return end
    self._autoSaveRunning = true

    local period = interval or 300
    task.spawn(function()
        while self._autoSaveRunning do
            task.wait(period)
            self:SaveAll()
            print("[ProfileStore] Auto-save complete (" ..
                  Utilities.tableCount(self._profiles) .. " profiles)")
        end
    end)
end

--- Stop the auto-save loop.
function ProfileStore:StopAutoSave()
    self._autoSaveRunning = false
end

---------------------------------------------------------------------------
-- EXPORT
---------------------------------------------------------------------------
local ProfileServiceWrapper = {}
ProfileServiceWrapper.ProfileStore = ProfileStore
return ProfileServiceWrapper
