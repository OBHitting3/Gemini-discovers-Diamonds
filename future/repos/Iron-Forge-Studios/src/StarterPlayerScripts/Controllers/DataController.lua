--[[
    DataController.lua (Client)
    Receives and caches player data from server.
    Provides read-only access to local player data.
    Listens for incremental updates via PlayerDataUpdate remote.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Modules.Shared.Remotes)
local Signal = require(ReplicatedStorage.Modules.Shared.Signal)

local DataController = {}

local cachedData = nil
local isLoaded = false

DataController.DataLoaded = Signal.new()
DataController.DataChanged = Signal.new()

function DataController.GetData(): table?
    return cachedData
end

function DataController.IsLoaded(): boolean
    return isLoaded
end

function DataController.WaitForData(): table
    if isLoaded then return cachedData end
    return DataController.DataLoaded:Wait()
end

function DataController.GetCurrency(): number
    return cachedData and cachedData.Currency or 0
end

function DataController.GetIcons(): { table }
    return cachedData and cachedData.Icons or {}
end

function DataController.HasPass(passKey: string): boolean
    return cachedData ~= nil and cachedData.OwnedPasses[passKey] == true
end

function DataController.Init(player)
    -- Initial data load
    Remotes.GetEvent("PlayerDataLoaded").OnClientEvent:Connect(function(data)
        cachedData = data
        isLoaded = true
        DataController.DataLoaded:Fire(data)
    end)

    -- Incremental updates
    Remotes.GetEvent("PlayerDataUpdate").OnClientEvent:Connect(function(field, value)
        if not cachedData then return end

        -- Handle dot-notation paths
        local parts = string.split(field, ".")
        if #parts == 1 then
            local oldValue = cachedData[field]
            cachedData[field] = value
            DataController.DataChanged:Fire(field, value, oldValue)
        else
            local current = cachedData
            for i = 1, #parts - 1 do
                if type(current) ~= "table" then return end
                current = current[parts[i]]
            end
            if type(current) == "table" then
                current[parts[#parts]] = value
                DataController.DataChanged:Fire(field, value)
            end
        end
    end)
end

return DataController
