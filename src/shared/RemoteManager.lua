--[[
    RemoteManager.lua
    Centralized creation and access for all RemoteEvents and
    RemoteFunctions.  The server calls :init() during bootstrap
    to create the instances under ReplicatedStorage.  Both server
    and client call :getEvent() / :getFunction() to retrieve them.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local GameConfig = require(script.Parent.GameConfig)

local RemoteManager = {}
RemoteManager._folder = nil   -- Folder instance holding all remotes

---------------------------------------------------------------------------
-- INITIALIZATION (server-only)
---------------------------------------------------------------------------

--- Creates all RemoteEvents and RemoteFunctions under a shared folder.
--- Must be called exactly once from the server bootstrap script.
function RemoteManager:init()
    assert(RunService:IsServer(), "RemoteManager:init() must run on the server")

    -- Create container folder
    local folder = Instance.new("Folder")
    folder.Name = "PalmSpringsRemotes"
    folder.Parent = ReplicatedStorage

    -- Create RemoteEvents
    for _, eventName in ipairs(GameConfig.Remotes.Events) do
        local remote = Instance.new("RemoteEvent")
        remote.Name = eventName
        remote.Parent = folder
    end

    -- Create RemoteFunctions
    for _, funcName in ipairs(GameConfig.Remotes.Functions) do
        local remote = Instance.new("RemoteFunction")
        remote.Name = funcName
        remote.Parent = folder
    end

    self._folder = folder
    print("[RemoteManager] Initialized " ..
          #GameConfig.Remotes.Events .. " events + " ..
          #GameConfig.Remotes.Functions .. " functions")
end

---------------------------------------------------------------------------
-- ACCESSORS  (server + client)
---------------------------------------------------------------------------

--- Resolves the shared remotes folder, waiting on client if needed.
function RemoteManager:_getFolder()
    if self._folder then return self._folder end

    if RunService:IsClient() then
        self._folder = ReplicatedStorage:WaitForChild("PalmSpringsRemotes", 30)
        if not self._folder then
            warn("[RemoteManager] Timed out waiting for PalmSpringsRemotes folder")
        end
    else
        -- Server should have called :init() first
        self._folder = ReplicatedStorage:FindFirstChild("PalmSpringsRemotes")
    end

    return self._folder
end

--- Get a RemoteEvent by name.
--- @param name string — must match one of GameConfig.Remotes.Events
--- @return RemoteEvent?
function RemoteManager:getEvent(name: string): RemoteEvent?
    local folder = self:_getFolder()
    if not folder then
        warn("[RemoteManager] Cannot get event '" .. name .. "': folder not found")
        return nil
    end

    if RunService:IsClient() then
        return folder:WaitForChild(name, 10)
    else
        return folder:FindFirstChild(name)
    end
end

--- Get a RemoteFunction by name.
--- @param name string — must match one of GameConfig.Remotes.Functions
--- @return RemoteFunction?
function RemoteManager:getFunction(name: string): RemoteFunction?
    local folder = self:_getFolder()
    if not folder then
        warn("[RemoteManager] Cannot get function '" .. name .. "': folder not found")
        return nil
    end

    if RunService:IsClient() then
        return folder:WaitForChild(name, 10)
    else
        return folder:FindFirstChild(name)
    end
end

---------------------------------------------------------------------------
-- CONVENIENCE: fire / invoke wrappers
---------------------------------------------------------------------------

--- Fire a RemoteEvent to all clients  (server → all clients)
function RemoteManager:fireAllClients(eventName: string, ...)
    local event = self:getEvent(eventName)
    if event then
        event:FireAllClients(...)
    else
        warn("[RemoteManager] fireAllClients: event '" .. eventName .. "' not found")
    end
end

--- Fire a RemoteEvent to one client  (server → one client)
function RemoteManager:fireClient(eventName: string, player: Player, ...)
    local event = self:getEvent(eventName)
    if event then
        event:FireClient(player, ...)
    else
        warn("[RemoteManager] fireClient: event '" .. eventName .. "' not found")
    end
end

--- Fire a RemoteEvent to server  (client → server)
function RemoteManager:fireServer(eventName: string, ...)
    local event = self:getEvent(eventName)
    if event then
        event:FireServer(...)
    else
        warn("[RemoteManager] fireServer: event '" .. eventName .. "' not found")
    end
end

--- Invoke a RemoteFunction  (client → server, returns result)
function RemoteManager:invokeServer(funcName: string, ...): any
    local func = self:getFunction(funcName)
    if func then
        return func:InvokeServer(...)
    else
        warn("[RemoteManager] invokeServer: function '" .. funcName .. "' not found")
        return nil
    end
end

return RemoteManager
