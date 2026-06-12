--[[
    EggController.lua (Client)
    Handles egg hatching UI requests and hatch result animations.
    Sends requests to server, receives results, triggers VFX.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Modules.Shared.Remotes)
local Constants = require(ReplicatedStorage.Modules.Shared.Constants)
local IconDatabase = require(ReplicatedStorage.Modules.Data.IconDatabase)
local Signal = require(ReplicatedStorage.Modules.Shared.Signal)

local EggController = {}

EggController.HatchResult = Signal.new()
EggController.EvolveResult = Signal.new()

function EggController.RequestHatch(eggTierIndex: number)
    if eggTierIndex < 1 or eggTierIndex > #Constants.EggTiers then return end
    Remotes.GetEvent("EggHatchRequest"):FireServer(eggTierIndex)
end

function EggController.RequestEvolve(iconUID: number)
    Remotes.GetEvent("EvolveIconRequest"):FireServer(iconUID)
end

function EggController.GetEggTiers()
    return Constants.EggTiers
end

function EggController.Init(player)
    Remotes.GetEvent("EggHatchResult").OnClientEvent:Connect(function(result)
        EggController.HatchResult:Fire(result)

        if result.Success then
            -- Icon data for UI display
            local iconDef = IconDatabase.GetById(result.Icon.Id)
            if iconDef then
                result.Icon.Name = iconDef.Name
                result.Icon.Description = iconDef.Description
            end
        end
    end)

    Remotes.GetEvent("EvolveIconResult").OnClientEvent:Connect(function(result)
        EggController.EvolveResult:Fire(result)
    end)
end

return EggController
