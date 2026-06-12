--[[
    Signal.lua
    Lightweight custom signal/event implementation.
    Used for decoupled module communication without RemoteEvents.
]]

local Signal = {}
Signal.__index = Signal

export type Connection = {
    Disconnect: (self: Connection) -> (),
}

function Signal.new()
    local self = setmetatable({}, Signal)
    self._listeners = {}
    self._nextId = 1
    return self
end

function Signal:Connect(callback: (...any) -> ()): Connection
    local id = self._nextId
    self._nextId += 1
    self._listeners[id] = callback

    return {
        Disconnect = function()
            self._listeners[id] = nil
        end,
    }
end

function Signal:Once(callback: (...any) -> ()): Connection
    local connection
    connection = self:Connect(function(...)
        connection:Disconnect()
        callback(...)
    end)
    return connection
end

function Signal:Fire(...)
    for _, callback in self._listeners do
        task.spawn(callback, ...)
    end
end

function Signal:Wait()
    local thread = coroutine.running()
    self:Once(function(...)
        task.spawn(thread, ...)
    end)
    return coroutine.yield()
end

function Signal:DisconnectAll()
    table.clear(self._listeners)
end

function Signal:Destroy()
    self:DisconnectAll()
    setmetatable(self, nil)
end

return Signal
