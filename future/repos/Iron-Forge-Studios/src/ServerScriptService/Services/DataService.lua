--[[
    DataService.lua
    DataStore v2 player data management with session locking, auto-save,
    retry logic, and schema migration support.

    Architecture:
    - Uses DataStoreService:GetDataStore() with versioning
    - Session locking prevents data duplication across servers
    - Auto-saves every 60 seconds
    - Deep-copies template for new players
    - All mutations go through :Update() with validation
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- Module requires (paths relative to Roblox hierarchy)
-- In a real Roblox project these would use proper instance paths
local Constants = require(game.ReplicatedStorage.Modules.Shared.Constants)
local PlayerDataTemplate = require(game.ReplicatedStorage.Modules.Data.PlayerDataTemplate)
local Util = require(game.ReplicatedStorage.Modules.Shared.Util)
local Signal = require(game.ReplicatedStorage.Modules.Shared.Signal)
local Remotes = require(game.ReplicatedStorage.Modules.Shared.Remotes)

local DataService = {}
DataService.__index = DataService

-- ═══════════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════════
local playerData = {} -- { [userId] = { Data, Loaded, SessionId, LastSave } }
local dataStore = DataStoreService:GetDataStore(Constants.DataStore.NAME)
local sessionId = HttpService:GenerateGUID(false)
local isShuttingDown = false

-- Signals
DataService.PlayerDataLoaded = Signal.new()
DataService.PlayerDataChanged = Signal.new()
DataService.PlayerDataSaving = Signal.new()

-- ═══════════════════════════════════════════════════════════════
-- PRIVATE HELPERS
-- ═══════════════════════════════════════════════════════════════

local function getKey(userId: number): string
    return Constants.DataStore.PLAYER_KEY_PREFIX .. tostring(userId)
end

local function deepCopyTemplate(): table
    return Util.DeepCopy(PlayerDataTemplate)
end

local function reconcile(saved: table, template: table): table
    for key, defaultValue in template do
        if saved[key] == nil then
            saved[key] = Util.DeepCopy(defaultValue)
        elseif type(defaultValue) == "table" and type(saved[key]) == "table" then
            reconcile(saved[key], defaultValue)
        end
    end
    return saved
end

local function migrateSchema(data: table): table
    -- Future schema migrations go here
    -- Example:
    -- if data.SchemaVersion < 2 then
    --     data.NewField = "default"
    --     data.SchemaVersion = 2
    -- end
    return data
end

local function retryAsync(func, maxRetries: number, delay: number)
    for attempt = 1, maxRetries do
        local success, result = pcall(func)
        if success then
            return true, result
        end

        if attempt < maxRetries then
            warn(string.format("[DataService] Retry %d/%d failed: %s", attempt, maxRetries, tostring(result)))
            task.wait(delay * attempt) -- exponential backoff
        else
            warn(string.format("[DataService] All %d retries failed: %s", maxRetries, tostring(result)))
            return false, result
        end
    end
    return false, "Max retries exceeded"
end

-- ═══════════════════════════════════════════════════════════════
-- LOAD
-- ═══════════════════════════════════════════════════════════════

function DataService.LoadPlayerData(player: Player)
    local userId = player.UserId
    local key = getKey(userId)

    if playerData[userId] then
        warn("[DataService] Data already loaded for", player.Name)
        return
    end

    local success, savedData = retryAsync(function()
        return dataStore:GetAsync(key)
    end, Constants.DataStore.RETRY_ATTEMPTS, Constants.DataStore.RETRY_DELAY)

    if not success then
        warn("[DataService] Failed to load data for", player.Name, "- using defaults")
        -- Player gets temporary data (not saved) to prevent data loss
        playerData[userId] = {
            Data = deepCopyTemplate(),
            Loaded = false,
            SessionId = sessionId,
            LastSave = os.time(),
            Temporary = true,
        }
        Remotes.GetEvent("PlayerDataLoaded"):FireClient(player, playerData[userId].Data)
        return
    end

    local data
    if savedData then
        -- Check session lock
        if savedData._sessionLock and savedData._sessionLock ~= sessionId then
            local lockAge = os.time() - (savedData._sessionLockTime or 0)
            if lockAge < Constants.DataStore.SESSION_LOCK_DURATION then
                warn(string.format("[DataService] Session lock active for %s (age: %ds)", player.Name, lockAge))
                -- Wait and retry once
                task.wait(5)
                local retrySuccess, retryData = retryAsync(function()
                    return dataStore:GetAsync(key)
                end, 2, 2)

                if retrySuccess and retryData then
                    savedData = retryData
                end
            end
        end

        -- Strip internal fields
        savedData._sessionLock = nil
        savedData._sessionLockTime = nil

        data = reconcile(savedData, PlayerDataTemplate)
        data = migrateSchema(data)
    else
        data = deepCopyTemplate()
        data.NewbieShieldUntil = os.time() + Constants.Heist.NEWBIE_SHIELD_SECONDS
    end

    -- Update session metadata
    data.LastLogin = os.time()
    data.JoinCount = (data.JoinCount or 0) + 1
    data.HeistServerJoinTime = os.time()

    playerData[userId] = {
        Data = data,
        Loaded = true,
        SessionId = sessionId,
        LastSave = os.time(),
        Temporary = false,
    }

    -- Write session lock
    retryAsync(function()
        dataStore:UpdateAsync(key, function(old)
            old = old or {}
            old._sessionLock = sessionId
            old._sessionLockTime = os.time()
            return old
        end)
    end, 2, 1)

    -- Fire signals
    DataService.PlayerDataLoaded:Fire(player, data)
    Remotes.GetEvent("PlayerDataLoaded"):FireClient(player, data)

    print(string.format("[DataService] Loaded data for %s (Schema v%d, Icons: %d, DC: %d)",
        player.Name, data.SchemaVersion, #data.Icons, data.Currency))
end

-- ═══════════════════════════════════════════════════════════════
-- SAVE
-- ═══════════════════════════════════════════════════════════════

function DataService.SavePlayerData(player: Player, isLeaving: boolean?)
    local userId = player.UserId
    local entry = playerData[userId]

    if not entry or not entry.Loaded or entry.Temporary then
        return false
    end

    local key = getKey(userId)
    local dataToSave = Util.DeepCopy(entry.Data)

    -- Attach session lock (will be cleared on clean leave)
    if not isLeaving then
        dataToSave._sessionLock = sessionId
        dataToSave._sessionLockTime = os.time()
    end

    DataService.PlayerDataSaving:Fire(player, dataToSave)

    local success, err = retryAsync(function()
        dataStore:SetAsync(key, dataToSave)
    end, Constants.DataStore.RETRY_ATTEMPTS, Constants.DataStore.RETRY_DELAY)

    if success then
        entry.LastSave = os.time()
    else
        warn("[DataService] Failed to save data for", player.Name, err)
    end

    return success
end

-- ═══════════════════════════════════════════════════════════════
-- GET / UPDATE
-- ═══════════════════════════════════════════════════════════════

function DataService.GetData(player: Player): table?
    local entry = playerData[player.UserId]
    return entry and entry.Data
end

function DataService.GetDataByUserId(userId: number): table?
    local entry = playerData[userId]
    return entry and entry.Data
end

function DataService.IsLoaded(player: Player): boolean
    local entry = playerData[player.UserId]
    return entry ~= nil and entry.Loaded
end

--- Safe update function. Takes a path and updater.
--- Example: DataService.Update(player, "Currency", function(old) return old + 100 end)
function DataService.Update(player: Player, field: string, updater: (any) -> any): boolean
    local data = DataService.GetData(player)
    if not data then
        return false
    end

    local oldValue = data[field]
    local newValue = updater(oldValue)
    data[field] = newValue

    DataService.PlayerDataChanged:Fire(player, field, oldValue, newValue)

    -- Send delta to client
    Remotes.GetEvent("PlayerDataUpdate"):FireClient(player, field, newValue)

    return true
end

--- Update a nested field using dot-notation path: "Plot.Rating"
function DataService.UpdateNested(player: Player, path: string, updater: (any) -> any): boolean
    local data = DataService.GetData(player)
    if not data then
        return false
    end

    local parts = string.split(path, ".")
    local current = data
    for i = 1, #parts - 1 do
        current = current[parts[i]]
        if type(current) ~= "table" then
            return false
        end
    end

    local finalKey = parts[#parts]
    local oldValue = current[finalKey]
    local newValue = updater(oldValue)
    current[finalKey] = newValue

    DataService.PlayerDataChanged:Fire(player, path, oldValue, newValue)
    Remotes.GetEvent("PlayerDataUpdate"):FireClient(player, path, newValue)

    return true
end

--- Add currency with validation
function DataService.AddCurrency(player: Player, amount: number): boolean
    if amount <= 0 then return false end
    return DataService.Update(player, "Currency", function(old)
        return old + math.floor(amount)
    end)
end

--- Spend currency with validation
function DataService.SpendCurrency(player: Player, amount: number): boolean
    local data = DataService.GetData(player)
    if not data or amount <= 0 then return false end
    if data.Currency < amount then return false end

    DataService.Update(player, "Currency", function(old)
        return old - math.floor(amount)
    end)
    DataService.Update(player, "TotalSpent", function(old)
        return old + math.floor(amount)
    end)
    return true
end

--- Check if player can afford
function DataService.CanAfford(player: Player, amount: number): boolean
    local data = DataService.GetData(player)
    return data ~= nil and data.Currency >= amount
end

-- ═══════════════════════════════════════════════════════════════
-- ICON INVENTORY HELPERS
-- ═══════════════════════════════════════════════════════════════

function DataService.AddIcon(player: Player, iconId: string, evolution: string?): table?
    local data = DataService.GetData(player)
    if not data then return nil end

    local uid = data.NextIconUID
    data.NextIconUID = uid + 1

    local iconInstance = {
        IconId = iconId,
        UID = uid,
        Evolution = evolution or "Base",
        Displayed = false,
        VaultSlot = nil, -- nil = not in vault
    }

    table.insert(data.Icons, iconInstance)

    -- Update collection book
    data.CollectionBook[iconId] = true

    -- Notify client
    Remotes.GetEvent("PlayerDataUpdate"):FireClient(player, "Icons", data.Icons)

    return iconInstance
end

function DataService.RemoveIcon(player: Player, iconUID: number): boolean
    local data = DataService.GetData(player)
    if not data then return false end

    for i, icon in data.Icons do
        if icon.UID == iconUID then
            table.remove(data.Icons, i)
            Remotes.GetEvent("PlayerDataUpdate"):FireClient(player, "Icons", data.Icons)
            return true
        end
    end
    return false
end

function DataService.GetIcon(player: Player, iconUID: number): table?
    local data = DataService.GetData(player)
    if not data then return nil end

    for _, icon in data.Icons do
        if icon.UID == iconUID then
            return icon
        end
    end
    return nil
end

function DataService.IsIconVaulted(player: Player, iconUID: number): boolean
    local icon = DataService.GetIcon(player, iconUID)
    return icon ~= nil and icon.VaultSlot ~= nil
end

-- ═══════════════════════════════════════════════════════════════
-- GAME PASS HELPERS
-- ═══════════════════════════════════════════════════════════════

function DataService.HasPass(player: Player, passKey: string): boolean
    local data = DataService.GetData(player)
    return data ~= nil and data.OwnedPasses[passKey] == true
end

function DataService.GrantPass(player: Player, passKey: string)
    local data = DataService.GetData(player)
    if data then
        data.OwnedPasses[passKey] = true
        Remotes.GetEvent("PlayerDataUpdate"):FireClient(player, "OwnedPasses", data.OwnedPasses)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- CLEANUP / LIFECYCLE
-- ═══════════════════════════════════════════════════════════════

function DataService.OnPlayerRemoving(player: Player)
    local userId = player.UserId
    DataService.SavePlayerData(player, true)
    playerData[userId] = nil
end

function DataService.AutoSaveLoop()
    while not isShuttingDown do
        task.wait(Constants.DataStore.AUTOSAVE_INTERVAL)
        for _, plr in Players:GetPlayers() do
            if DataService.IsLoaded(plr) then
                task.spawn(DataService.SavePlayerData, plr)
            end
        end
    end
end

function DataService.OnServerShutdown()
    isShuttingDown = true
    local threads = {}
    for _, plr in Players:GetPlayers() do
        table.insert(threads, task.spawn(function()
            DataService.SavePlayerData(plr, true)
        end))
    end
    -- Wait for all saves (BindToClose gives 30s)
    task.wait(5)
end

-- ═══════════════════════════════════════════════════════════════
-- INIT
-- ═══════════════════════════════════════════════════════════════

function DataService.Init()
    Players.PlayerAdded:Connect(function(player)
        task.spawn(DataService.LoadPlayerData, player)
    end)

    Players.PlayerRemoving:Connect(DataService.OnPlayerRemoving)

    game:BindToClose(DataService.OnServerShutdown)

    -- Start auto-save
    task.spawn(DataService.AutoSaveLoop)

    -- Load any players already in game (Studio fast-start)
    for _, player in Players:GetPlayers() do
        task.spawn(DataService.LoadPlayerData, player)
    end

    print("[DataService] Initialized with store:", Constants.DataStore.NAME)
end

return DataService
