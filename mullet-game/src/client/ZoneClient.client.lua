--[[
    ZoneClient.client.lua
    Shows the round timer and difficulty selector.
    Press M to open maze difficulty menu.
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")

local MulletConfig = require(ReplicatedStorage:WaitForChild("MulletConfig"))

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local Remotes     = ReplicatedStorage:WaitForChild("Remotes", 15)

local evRoundStarted = Remotes:WaitForChild("RoundStarted",  15)
local evRoundEnded   = Remotes:WaitForChild("RoundEnded",    15)
local evNotify       = Remotes:WaitForChild("NotifyPlayer",  15)

---------------------------------------------------------------------------
-- ROUND TIMER HUD (top right)
---------------------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name           = "ZoneGui"
gui.ResetOnSpawn   = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent         = PlayerGui

local timerFrame = Instance.new("Frame")
timerFrame.Size              = UDim2.new(0, 180, 0, 44)
timerFrame.Position          = UDim2.new(1, -190, 0, 10)
timerFrame.BackgroundColor3  = MulletConfig.Colors.Background
timerFrame.BackgroundTransparency = 0.2
timerFrame.BorderSizePixel   = 0
timerFrame.Parent            = gui
Instance.new("UICorner", timerFrame).CornerRadius = UDim.new(0, 8)

local timerLabel = Instance.new("TextLabel")
timerLabel.Size               = UDim2.new(1, -8, 1, 0)
timerLabel.Position           = UDim2.new(0, 8, 0, 0)
timerLabel.BackgroundTransparency = 1
timerLabel.TextColor3         = MulletConfig.Colors.Text
timerLabel.Font               = Enum.Font.GothamBold
timerLabel.TextScaled         = true
timerLabel.Text               = "⏱ Round: --"
timerLabel.Parent             = timerFrame

local diffLabel = Instance.new("TextLabel")
diffLabel.Size               = UDim2.new(0, 180, 0, 30)
diffLabel.Position           = UDim2.new(1, -190, 0, 58)
diffLabel.BackgroundTransparency = 1
diffLabel.TextColor3         = MulletConfig.Colors.Primary
diffLabel.Font               = Enum.Font.GothamBold
diffLabel.TextScaled         = true
diffLabel.Text               = "Easy Maze"
diffLabel.Parent             = gui

---------------------------------------------------------------------------
-- ROUND EVENTS
---------------------------------------------------------------------------

evRoundStarted.OnClientEvent:Connect(function(data)
    if data and data.difficulty then
        diffLabel.Text = data.difficulty .. " Maze"
    end
    -- Countdown timer display
    local duration = MulletConfig.Round.Duration
    local remaining = duration
    task.spawn(function()
        while remaining > 0 do
            timerLabel.Text = "⏱ " .. remaining .. "s"
            task.wait(1)
            remaining -= 1
        end
        timerLabel.Text = "⏱ Round Over!"
    end)
end)

evRoundEnded.OnClientEvent:Connect(function()
    timerLabel.Text = "⏱ New round starting..."
end)

print("[ZoneClient] Ready")
