--[[
    MulletClient.client.lua
    Client-side controller for mullet progression display.

    Responsibilities:
      - Listen for UpdateMulletLevel events and update the HUD
      - Display level-up animations and style name announcements
      - Show kill counter and current mullet style in the UI
      - Reflect stat changes (walk speed set server-side) locally in UI
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local MulletConfig = require(ReplicatedStorage:WaitForChild("MulletConfig"))

local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")
local Remotes      = ReplicatedStorage:WaitForChild("Remotes", 15)

local function waitForEvent(name: string): RemoteEvent
    return Remotes:WaitForChild(name, 15) :: RemoteEvent
end

local evUpdateMullet = waitForEvent("UpdateMulletLevel")
local evNotify       = waitForEvent("NotifyPlayer")

---------------------------------------------------------------------------
-- STATE
---------------------------------------------------------------------------
local currentLevel = 0
local currentKills = 0

---------------------------------------------------------------------------
-- HUD SETUP
---------------------------------------------------------------------------
-- We construct a minimal HUD in code so the client works without a
-- pre-built ScreenGui in StarterGui.

local screenGui = Instance.new("ScreenGui")
screenGui.Name            = "MulletHUD"
screenGui.ResetOnSpawn    = false
screenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
screenGui.Parent          = PlayerGui

-- Mullet level badge (top-left)
local levelFrame = Instance.new("Frame")
levelFrame.Name              = "LevelFrame"
levelFrame.Size              = UDim2.new(0, 220, 0, 70)
levelFrame.Position          = UDim2.new(0, 12, 0, 12)
levelFrame.BackgroundColor3  = MulletConfig.Colors.Background
levelFrame.BackgroundTransparency = 0.2
levelFrame.BorderSizePixel   = 0
levelFrame.Parent            = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = levelFrame

local styleLabel = Instance.new("TextLabel")
styleLabel.Name              = "StyleLabel"
styleLabel.Size              = UDim2.new(1, -8, 0, 28)
styleLabel.Position          = UDim2.new(0, 8, 0, 4)
styleLabel.BackgroundTransparency = 1
styleLabel.TextColor3        = MulletConfig.Colors.Primary
styleLabel.TextScaled        = true
styleLabel.Font              = Enum.Font.GothamBold
styleLabel.Text              = "Baby Mullet"
styleLabel.Parent            = levelFrame

local killLabel = Instance.new("TextLabel")
killLabel.Name               = "KillLabel"
killLabel.Size               = UDim2.new(1, -8, 0, 22)
killLabel.Position           = UDim2.new(0, 8, 0, 36)
killLabel.BackgroundTransparency = 1
killLabel.TextColor3         = MulletConfig.Colors.Text
killLabel.TextScaled         = true
killLabel.Font               = Enum.Font.Gotham
killLabel.Text               = "Kills: 0"
killLabel.Parent             = levelFrame

-- Level-up announcement banner (center screen, hidden by default)
local announceBanner = Instance.new("Frame")
announceBanner.Name              = "AnnounceBanner"
announceBanner.Size              = UDim2.new(0, 500, 0, 80)
announceBanner.Position          = UDim2.new(0.5, -250, 0.3, 0)
announceBanner.BackgroundColor3  = MulletConfig.Colors.Primary
announceBanner.BackgroundTransparency = 0.15
announceBanner.BorderSizePixel   = 0
announceBanner.Visible           = false
announceBanner.Parent            = screenGui

local announceCorner = Instance.new("UICorner")
announceCorner.CornerRadius = UDim.new(0, 12)
announceCorner.Parent = announceBanner

local announceLabel = Instance.new("TextLabel")
announceLabel.Name               = "AnnounceLabel"
announceLabel.Size               = UDim2.new(1, -16, 1, -8)
announceLabel.Position           = UDim2.new(0, 8, 0, 4)
announceLabel.BackgroundTransparency = 1
announceLabel.TextColor3         = MulletConfig.Colors.Text
announceLabel.TextScaled         = true
announceLabel.Font               = Enum.Font.GothamBlack
announceLabel.Text               = ""
announceLabel.Parent             = announceBanner

---------------------------------------------------------------------------
-- HELPERS
---------------------------------------------------------------------------

local function updateHUD(data: table)
    currentLevel = data.level or currentLevel
    currentKills = data.kills or currentKills

    local styleName = data.styleName or
        MulletConfig.Mullet.StyleUnlocks[currentLevel] or "Baby Mullet"

    styleLabel.Text = "✂ " .. styleName
    killLabel.Text  = "Kills: " .. currentKills ..
        " | Level " .. currentLevel .. "/" .. MulletConfig.Mullet.MaxLevel
end

local announceThread: thread? = nil

local function showLevelUpBanner(styleName: string)
    announceLabel.Text = "MULLET EVOLVED!\n" .. styleName
    announceBanner.Visible = true
    announceBanner.BackgroundTransparency = 0.15

    -- Fade in
    TweenService:Create(announceBanner, TweenInfo.new(0.3), {
        BackgroundTransparency = 0,
    }):Play()

    -- Cancel any existing hide timer
    if announceThread then
        task.cancel(announceThread)
    end

    announceThread = task.delay(3, function()
        TweenService:Create(announceBanner, TweenInfo.new(0.5), {
            BackgroundTransparency = 1,
        }):Play()
        task.wait(0.5)
        announceBanner.Visible = false
        announceThread = nil
    end)
end

---------------------------------------------------------------------------
-- NOTIFICATION TOAST (reused by NotifyPlayer)
---------------------------------------------------------------------------

local toastQueue: { string } = {}
local toastActive = false

local toastFrame = Instance.new("Frame")
toastFrame.Name              = "ToastFrame"
toastFrame.Size              = UDim2.new(0, 340, 0, 48)
toastFrame.Position          = UDim2.new(0.5, -170, 1, -70)
toastFrame.BackgroundColor3  = MulletConfig.Colors.Background
toastFrame.BackgroundTransparency = 0.2
toastFrame.BorderSizePixel   = 0
toastFrame.Visible           = false
toastFrame.Parent            = screenGui

local toastCorner = Instance.new("UICorner")
toastCorner.CornerRadius = UDim.new(0, 8)
toastCorner.Parent = toastFrame

local toastLabel = Instance.new("TextLabel")
toastLabel.Size              = UDim2.new(1, -12, 1, -8)
toastLabel.Position          = UDim2.new(0, 6, 0, 4)
toastLabel.BackgroundTransparency = 1
toastLabel.TextColor3        = MulletConfig.Colors.Text
toastLabel.TextScaled        = true
toastLabel.Font              = Enum.Font.Gotham
toastLabel.Text              = ""
toastLabel.Parent            = toastFrame

local function showToast(message: string)
    table.insert(toastQueue, message)
    if toastActive then return end

    task.spawn(function()
        toastActive = true
        while #toastQueue > 0 do
            local msg = table.remove(toastQueue, 1)
            toastLabel.Text = msg
            toastFrame.Visible = true
            TweenService:Create(toastFrame, TweenInfo.new(0.2), {
                BackgroundTransparency = 0,
            }):Play()
            task.wait(2.5)
            TweenService:Create(toastFrame, TweenInfo.new(0.3), {
                BackgroundTransparency = 1,
            }):Play()
            task.wait(0.3)
            toastFrame.Visible = false
        end
        toastActive = false
    end)
end

---------------------------------------------------------------------------
-- REMOTE EVENT LISTENERS
---------------------------------------------------------------------------

evUpdateMullet.OnClientEvent:Connect(function(data: table)
    local prevLevel = currentLevel
    updateHUD(data)

    if data.level and data.level > prevLevel then
        local styleName = data.styleName or
            MulletConfig.Mullet.StyleUnlocks[data.level] or "???"
        showLevelUpBanner(styleName)
    end
end)

evNotify.OnClientEvent:Connect(function(message: string)
    showToast(tostring(message))
end)

---------------------------------------------------------------------------
-- REQUEST INITIAL DATA
---------------------------------------------------------------------------
task.spawn(function()
    local fnGetData = Remotes:WaitForChild("GetPlayerData", 15) :: RemoteFunction
    if fnGetData then
        local ok, data = pcall(function()
            return fnGetData:InvokeServer()
        end)
        if ok and data then
            updateHUD({
                level     = data.mulletLevel or 0,
                styleName = MulletConfig.Mullet.StyleUnlocks[data.mulletLevel or 0] or "Baby Mullet",
                kills     = data.kills or 0,
            })
        end
    end
end)

print("[MulletClient] HUD initialized")
