--[[
    HeistController.lua (Client)
    Client-side heist flow: countdown UI, lockpicking minigame input,
    steal cam replay, and notifications.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Modules.Shared.Remotes)
local Signal = require(ReplicatedStorage.Modules.Shared.Signal)

local HeistController = {}

HeistController.CountdownStarted = Signal.new()
HeistController.LockpickStarted = Signal.new()
HeistController.LockpickProgress = Signal.new()
HeistController.HeistCompleted = Signal.new()
HeistController.StealCamTriggered = Signal.new()
HeistController.HeistNotification = Signal.new()

local currentHeist = nil

function HeistController.StartHeist(targetUserId: number)
    Remotes.GetEvent("HeistStartRequest"):FireServer(targetUserId)
end

function HeistController.SendLockpickInput(direction: string)
    Remotes.GetEvent("HeistLockpickInput"):FireServer(direction)
end

function HeistController.IsInHeist(): boolean
    return currentHeist ~= nil
end

function HeistController.Init(player)
    -- Countdown phase
    Remotes.GetEvent("HeistCountdown").OnClientEvent:Connect(function(data)
        currentHeist = {
            TargetName = data.TargetName,
            TargetUserId = data.TargetUserId,
            Phase = "Countdown",
        }
        HeistController.CountdownStarted:Fire(data)
    end)

    -- Lockpick phase
    Remotes.GetEvent("HeistLockpickStart").OnClientEvent:Connect(function(data)
        if currentHeist then
            currentHeist.Phase = "Lockpick"
            currentHeist.SequenceLength = data.SequenceLength
            currentHeist.TimeLimit = data.TimeLimit
        end
        HeistController.LockpickStarted:Fire(data)
    end)

    -- Lockpick progress feedback
    Remotes.GetEvent("HeistLockpickInput").OnClientEvent:Connect(function(data)
        HeistController.LockpickProgress:Fire(data)
    end)

    -- Heist result
    Remotes.GetEvent("HeistResult").OnClientEvent:Connect(function(data)
        currentHeist = nil
        HeistController.HeistCompleted:Fire(data)
    end)

    -- Steal cam (when YOU get heisted)
    Remotes.GetEvent("HeistStealCam").OnClientEvent:Connect(function(data)
        HeistController.StealCamTriggered:Fire(data)
    end)

    -- General heist notifications
    Remotes.GetEvent("HeistNotification").OnClientEvent:Connect(function(data)
        HeistController.HeistNotification:Fire(data)
    end)
end

return HeistController
