--[[
    EggClient.client.lua
    Shows job menu (press J) — the 5 silly hair-collecting mini-games.
    Displays job timer and outcome.
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")

local MulletConfig = require(ReplicatedStorage:WaitForChild("MulletConfig"))

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local Remotes     = ReplicatedStorage:WaitForChild("Remotes", 15)

local evStartJob     = Remotes:WaitForChild("StartJob",         15)
local evJobStarted   = Remotes:WaitForChild("JobStarted",       15)
local evJobCompleted = Remotes:WaitForChild("JobCompleted",      15)
local evJobFailed    = Remotes:WaitForChild("JobFailed",         15)
local evNotify       = Remotes:WaitForChild("NotifyPlayer",      15)

---------------------------------------------------------------------------
-- JOB MENU UI
---------------------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name           = "JobGui"
gui.ResetOnSpawn   = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Enabled        = false
gui.Parent         = PlayerGui

local panel = Instance.new("Frame")
panel.Size              = UDim2.new(0, 500, 0, 420)
panel.Position          = UDim2.new(0.5, -250, 0.5, -210)
panel.BackgroundColor3  = MulletConfig.Colors.Background
panel.BackgroundTransparency = 0.05
panel.BorderSizePixel   = 0
panel.Parent            = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

-- Title
local titleBar = Instance.new("Frame")
titleBar.Size             = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundColor3 = MulletConfig.Colors.Secondary
titleBar.BorderSizePixel  = 0
titleBar.Parent           = panel
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 14)

local titlePatch = Instance.new("Frame")
titlePatch.Size             = UDim2.new(1, 0, 0.5, 0)
titlePatch.Position         = UDim2.new(0, 0, 0.5, 0)
titlePatch.BackgroundColor3 = MulletConfig.Colors.Secondary
titlePatch.BorderSizePixel  = 0
titlePatch.Parent           = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size               = UDim2.new(0.8, 0, 1, 0)
titleLabel.Position           = UDim2.new(0, 14, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3         = Color3.fromRGB(255, 255, 255)
titleLabel.Font               = Enum.Font.GothamBlack
titleLabel.TextScaled         = true
titleLabel.Text               = "💇 HAIR JOBS"
titleLabel.Parent             = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size               = UDim2.new(0, 36, 0, 36)
closeBtn.Position           = UDim2.new(1, -44, 0, 7)
closeBtn.BackgroundColor3   = Color3.fromRGB(180, 50, 50)
closeBtn.BorderSizePixel    = 0
closeBtn.Text               = "✕"
closeBtn.TextColor3         = Color3.fromRGB(255, 255, 255)
closeBtn.Font               = Enum.Font.GothamBold
closeBtn.TextScaled         = true
closeBtn.Parent             = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

-- Job list
local jobScroll = Instance.new("ScrollingFrame")
jobScroll.Size              = UDim2.new(1, -20, 1, -62)
jobScroll.Position          = UDim2.new(0, 10, 0, 58)
jobScroll.BackgroundTransparency = 1
jobScroll.ScrollBarThickness = 4
jobScroll.BorderSizePixel   = 0
jobScroll.CanvasSize        = UDim2.new(0, 0, 0, #MulletConfig.Jobs * 74)
jobScroll.Parent            = panel

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding   = UDim.new(0, 6)
listLayout.Parent    = jobScroll

-- Build job cards
for i, job in ipairs(MulletConfig.Jobs) do
    local card = Instance.new("Frame")
    card.Size             = UDim2.new(1, -8, 0, 66)
    card.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    card.BorderSizePixel  = 0
    card.LayoutOrder      = i
    card.Parent           = jobScroll
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size               = UDim2.new(0.65, 0, 0, 28)
    nameLabel.Position           = UDim2.new(0, 10, 0, 6)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3         = MulletConfig.Colors.Primary
    nameLabel.Font               = Enum.Font.GothamBold
    nameLabel.TextScaled         = true
    nameLabel.TextXAlignment     = Enum.TextXAlignment.Left
    nameLabel.Text               = job.name
    nameLabel.Parent             = card

    local descLabel = Instance.new("TextLabel")
    descLabel.Size               = UDim2.new(0.65, 0, 0, 26)
    descLabel.Position           = UDim2.new(0, 10, 0, 34)
    descLabel.BackgroundTransparency = 1
    descLabel.TextColor3         = Color3.fromRGB(180, 180, 180)
    descLabel.Font               = Enum.Font.Gotham
    descLabel.TextScaled         = true
    descLabel.TextXAlignment     = Enum.TextXAlignment.Left
    descLabel.TextWrapped        = true
    descLabel.Text               = job.description
    descLabel.Parent             = card

    local rewardLabel = Instance.new("TextLabel")
    rewardLabel.Size               = UDim2.new(0.15, 0, 1, -8)
    rewardLabel.Position           = UDim2.new(0.66, 0, 0, 4)
    rewardLabel.BackgroundTransparency = 1
    rewardLabel.TextColor3         = MulletConfig.Colors.Hair
    rewardLabel.Font               = Enum.Font.GothamBold
    rewardLabel.TextScaled         = true
    rewardLabel.Text               = "+" .. job.hairReward .. "\nhair"
    rewardLabel.Parent             = card

    local goBtn = Instance.new("TextButton")
    goBtn.Size              = UDim2.new(0.15, -6, 0, 40)
    goBtn.Position          = UDim2.new(0.84, 0, 0.5, -20)
    goBtn.BackgroundColor3  = MulletConfig.Colors.Secondary
    goBtn.BorderSizePixel   = 0
    goBtn.Text              = "GO!"
    goBtn.TextColor3        = Color3.fromRGB(255, 255, 255)
    goBtn.Font              = Enum.Font.GothamBold
    goBtn.TextScaled        = true
    goBtn.Parent            = card
    Instance.new("UICorner", goBtn).CornerRadius = UDim.new(0, 6)

    goBtn.MouseButton1Click:Connect(function()
        evStartJob:FireServer(job.id)
        gui.Enabled = false
    end)
end

---------------------------------------------------------------------------
-- JOB TIMER (shows during active job)
---------------------------------------------------------------------------

local jobTimerFrame = Instance.new("Frame")
jobTimerFrame.Size              = UDim2.new(0, 300, 0, 50)
jobTimerFrame.Position          = UDim2.new(0.5, -150, 0, 60)
jobTimerFrame.BackgroundColor3  = MulletConfig.Colors.Secondary
jobTimerFrame.BackgroundTransparency = 0.2
jobTimerFrame.BorderSizePixel   = 0
jobTimerFrame.Visible           = false
jobTimerFrame.Parent            = PlayerGui:WaitForChild("MulletHUD") or gui
Instance.new("UICorner", jobTimerFrame).CornerRadius = UDim.new(0, 8)

local jobTimerLabel = Instance.new("TextLabel")
jobTimerLabel.Size               = UDim2.new(1, -8, 1, 0)
jobTimerLabel.Position           = UDim2.new(0, 4, 0, 0)
jobTimerLabel.BackgroundTransparency = 1
jobTimerLabel.TextColor3         = Color3.fromRGB(255, 255, 255)
jobTimerLabel.Font               = Enum.Font.GothamBold
jobTimerLabel.TextScaled         = true
jobTimerLabel.Text               = ""
jobTimerLabel.Parent             = jobTimerFrame

---------------------------------------------------------------------------
-- OPEN / CLOSE
---------------------------------------------------------------------------

closeBtn.MouseButton1Click:Connect(function()
    gui.Enabled = false
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.J then
        gui.Enabled = not gui.Enabled
    end
end)

---------------------------------------------------------------------------
-- JOB EVENT LISTENERS
---------------------------------------------------------------------------

evJobStarted.OnClientEvent:Connect(function(data)
    gui.Enabled = false
    jobTimerFrame.Visible = true
    jobTimerLabel.Text = "🎯 " .. (data.jobName or "Job") .. " — " .. (data.timeLimit or 15) .. "s"

    local remaining = data.timeLimit or 15
    task.spawn(function()
        while remaining > 0 and jobTimerFrame.Visible do
            task.wait(1)
            remaining -= 1
            jobTimerLabel.Text = "🎯 " .. (data.jobName or "Job") .. " — " .. remaining .. "s"
        end
    end)
end)

evJobCompleted.OnClientEvent:Connect(function(data)
    jobTimerFrame.Visible = false
    jobTimerLabel.Text = ""
end)

evJobFailed.OnClientEvent:Connect(function()
    jobTimerFrame.Visible = false
    jobTimerLabel.Text = ""
end)

print("[JobClient] Ready — press J to open Jobs menu")
