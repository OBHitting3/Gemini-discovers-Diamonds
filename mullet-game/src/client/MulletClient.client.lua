--[[
    MulletClient.client.lua
    Shows the player's mullet growing bigger and changing color.
    Displays the Giant Jar fill meter, coin count, and hair count on the HUD.
    Shows notifications and the Mullet God arrival screen.
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local MulletConfig = require(ReplicatedStorage:WaitForChild("MulletConfig"))

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local Remotes     = ReplicatedStorage:WaitForChild("Remotes", 15)

local function waitEvent(name)
    return Remotes:WaitForChild(name, 15)
end

local evMullet   = waitEvent("UpdateMulletLevel")
local evCoins    = waitEvent("UpdateCoins")
local evJar      = waitEvent("UpdateJarFill")
local evGodIn    = waitEvent("MulletGodArrived")
local evGodOut   = waitEvent("MulletGodLeft")
local evRain     = waitEvent("MoneyRain")
local evNotify   = waitEvent("NotifyPlayer")

---------------------------------------------------------------------------
-- HUD
---------------------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name           = "MulletHUD"
gui.ResetOnSpawn   = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent         = PlayerGui

-- Coin display (top left)
local coinFrame = Instance.new("Frame")
coinFrame.Size              = UDim2.new(0, 160, 0, 44)
coinFrame.Position          = UDim2.new(0, 10, 0, 10)
coinFrame.BackgroundColor3  = MulletConfig.Colors.Background
coinFrame.BackgroundTransparency = 0.2
coinFrame.BorderSizePixel   = 0
coinFrame.Parent            = gui
Instance.new("UICorner", coinFrame).CornerRadius = UDim.new(0, 8)

local coinLabel = Instance.new("TextLabel")
coinLabel.Size               = UDim2.new(1, -8, 1, 0)
coinLabel.Position           = UDim2.new(0, 8, 0, 0)
coinLabel.BackgroundTransparency = 1
coinLabel.TextColor3         = MulletConfig.Colors.Coin
coinLabel.Font               = Enum.Font.GothamBold
coinLabel.TextScaled         = true
coinLabel.Text               = "🪙 0"
coinLabel.Parent             = coinFrame

-- Hair display (top left, below coins)
local hairFrame = Instance.new("Frame")
hairFrame.Size              = UDim2.new(0, 160, 0, 44)
hairFrame.Position          = UDim2.new(0, 10, 0, 60)
hairFrame.BackgroundColor3  = MulletConfig.Colors.Background
hairFrame.BackgroundTransparency = 0.2
hairFrame.BorderSizePixel   = 0
hairFrame.Parent            = gui
Instance.new("UICorner", hairFrame).CornerRadius = UDim.new(0, 8)

local hairLabel = Instance.new("TextLabel")
hairLabel.Size               = UDim2.new(1, -8, 1, 0)
hairLabel.Position           = UDim2.new(0, 8, 0, 0)
hairLabel.BackgroundTransparency = 1
hairLabel.TextColor3         = MulletConfig.Colors.Hair
hairLabel.Font               = Enum.Font.GothamBold
hairLabel.TextScaled         = true
hairLabel.Text               = "💇 Hair: 0"
hairLabel.Parent             = hairFrame

-- Mullet level badge (top left, below hair)
local mulletFrame = Instance.new("Frame")
mulletFrame.Size              = UDim2.new(0, 160, 0, 44)
mulletFrame.Position          = UDim2.new(0, 10, 0, 110)
mulletFrame.BackgroundColor3  = MulletConfig.Colors.Background
mulletFrame.BackgroundTransparency = 0.2
mulletFrame.BorderSizePixel   = 0
mulletFrame.Parent            = gui
Instance.new("UICorner", mulletFrame).CornerRadius = UDim.new(0, 8)

local mulletLabel = Instance.new("TextLabel")
mulletLabel.Size               = UDim2.new(1, -8, 1, 0)
mulletLabel.Position           = UDim2.new(0, 8, 0, 0)
mulletLabel.BackgroundTransparency = 1
mulletLabel.TextColor3         = MulletConfig.Colors.Primary
mulletLabel.Font               = Enum.Font.GothamBold
mulletLabel.TextScaled         = true
mulletLabel.Text               = "✂ Mullet Lv.0"
mulletLabel.Parent             = mulletFrame

---------------------------------------------------------------------------
-- GIANT JAR METER (center top)
---------------------------------------------------------------------------

local jarOuter = Instance.new("Frame")
jarOuter.Name              = "JarMeter"
jarOuter.Size              = UDim2.new(0, 300, 0, 36)
jarOuter.Position          = UDim2.new(0.5, -150, 0, 10)
jarOuter.BackgroundColor3  = Color3.fromRGB(50, 50, 50)
jarOuter.BackgroundTransparency = 0.3
jarOuter.BorderSizePixel   = 0
jarOuter.Parent            = gui
Instance.new("UICorner", jarOuter).CornerRadius = UDim.new(0, 10)

local jarFill = Instance.new("Frame")
jarFill.Name              = "Fill"
jarFill.Size              = UDim2.new(0, 0, 1, -4)
jarFill.Position          = UDim2.new(0, 2, 0, 2)
jarFill.BackgroundColor3  = MulletConfig.Colors.Hair
jarFill.BorderSizePixel   = 0
jarFill.Parent            = jarOuter
Instance.new("UICorner", jarFill).CornerRadius = UDim.new(0, 8)

local jarTitleLabel = Instance.new("TextLabel")
jarTitleLabel.Size               = UDim2.new(1, 0, 1, 0)
jarTitleLabel.BackgroundTransparency = 1
jarTitleLabel.TextColor3         = Color3.fromRGB(255, 255, 255)
jarTitleLabel.Font               = Enum.Font.GothamBold
jarTitleLabel.TextScaled         = true
jarTitleLabel.Text               = "🫙 The Giant Jar — 0%"
jarTitleLabel.ZIndex             = 2
jarTitleLabel.Parent             = jarOuter

---------------------------------------------------------------------------
-- MULLET GOD ARRIVAL SCREEN
---------------------------------------------------------------------------

local godScreen = Instance.new("Frame")
godScreen.Name              = "GodScreen"
godScreen.Size              = UDim2.new(1, 0, 1, 0)
godScreen.BackgroundColor3  = Color3.fromRGB(255, 180, 0)
godScreen.BackgroundTransparency = 0.3
godScreen.BorderSizePixel   = 0
godScreen.Visible           = false
godScreen.ZIndex            = 10
godScreen.Parent            = gui

local godLabel = Instance.new("TextLabel")
godLabel.Size               = UDim2.new(0.8, 0, 0.3, 0)
godLabel.Position           = UDim2.new(0.1, 0, 0.3, 0)
godLabel.BackgroundTransparency = 1
godLabel.TextColor3         = Color3.fromRGB(255, 255, 255)
godLabel.Font               = Enum.Font.GothamBlack
godLabel.TextScaled         = true
godLabel.TextWrapped        = true
godLabel.Text               = "🪙 THE MULLET GOD HAS ARRIVED! 🪙"
godLabel.ZIndex             = 11
godLabel.Parent             = godScreen

local rainLabel = Instance.new("TextLabel")
rainLabel.Size               = UDim2.new(0.6, 0, 0.15, 0)
rainLabel.Position           = UDim2.new(0.2, 0, 0.6, 0)
rainLabel.BackgroundTransparency = 1
rainLabel.TextColor3         = Color3.fromRGB(255, 255, 200)
rainLabel.Font               = Enum.Font.GothamBold
rainLabel.TextScaled         = true
rainLabel.Text               = "💰 Money rain for 30 seconds! 💰"
rainLabel.ZIndex             = 11
rainLabel.Parent             = godScreen

---------------------------------------------------------------------------
-- TOAST NOTIFICATIONS
---------------------------------------------------------------------------

local toastQueue = {}
local toastBusy  = false

local toast = Instance.new("Frame")
toast.Size              = UDim2.new(0, 380, 0, 50)
toast.Position          = UDim2.new(0.5, -190, 1, -70)
toast.BackgroundColor3  = Color3.fromRGB(30, 30, 30)
toast.BackgroundTransparency = 0.2
toast.BorderSizePixel   = 0
toast.Visible           = false
toast.Parent            = gui
Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 8)

local toastText = Instance.new("TextLabel")
toastText.Size               = UDim2.new(1, -12, 1, 0)
toastText.Position           = UDim2.new(0, 6, 0, 0)
toastText.BackgroundTransparency = 1
toastText.TextColor3         = Color3.fromRGB(255, 255, 255)
toastText.Font               = Enum.Font.Gotham
toastText.TextScaled         = true
toastText.Text               = ""
toastText.Parent             = toast

local function showToast(msg)
    table.insert(toastQueue, msg)
    if toastBusy then return end
    task.spawn(function()
        toastBusy = true
        while #toastQueue > 0 do
            toastText.Text = table.remove(toastQueue, 1)
            toast.Visible  = true
            task.wait(2.5)
            toast.Visible  = false
            task.wait(0.2)
        end
        toastBusy = false
    end)
end

---------------------------------------------------------------------------
-- EVENT LISTENERS
---------------------------------------------------------------------------

evMullet.OnClientEvent:Connect(function(data)
    if data.hair then
        hairLabel.Text = "💇 Hair: " .. data.hair
    end
    if data.level then
        mulletLabel.Text = "✂ Mullet Lv." .. data.level
        if data.color then
            mulletLabel.TextColor3 = data.color
        end
    end
end)

evCoins.OnClientEvent:Connect(function(amount)
    coinLabel.Text = "🪙 " .. amount
end)

evJar.OnClientEvent:Connect(function(data)
    local pct = math.floor((data.percent or (data.fill / data.capacity)) * 100)
    TweenService:Create(jarFill, TweenInfo.new(0.3), {
        Size = UDim2.new(data.percent or (data.fill / data.capacity), -4, 1, -4)
    }):Play()
    jarTitleLabel.Text = "🫙 The Giant Jar — " .. pct .. "%"
end)

evGodIn.OnClientEvent:Connect(function()
    godScreen.Visible = true
    task.delay(4, function()
        godScreen.Visible = false
    end)
end)

evGodOut.OnClientEvent:Connect(function()
    godScreen.Visible = false
end)

evRain.OnClientEvent:Connect(function(data)
    if data.active then
        showToast("💰 MONEY RAIN! Collect those coins!")
    end
end)

evNotify.OnClientEvent:Connect(function(msg)
    showToast(tostring(msg))
end)

print("[MulletClient] HUD ready!")
