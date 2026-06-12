--[[
    UIController.lua (Client)
    Master UI manager. Creates and manages all screen GUIs:
    - HUD (currency, passive income, zone indicator)
    - Egg hatching panel
    - Inventory/Collection Book
    - Heist overlay (countdown, lockpick, steal cam)
    - Building mode toolbar
    - Trade window
    - Settings menu
    - Notification toasts
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Remotes = require(ReplicatedStorage.Modules.Shared.Remotes)
local Constants = require(ReplicatedStorage.Modules.Shared.Constants)
local Util = require(ReplicatedStorage.Modules.Shared.Util)
local Signal = require(ReplicatedStorage.Modules.Shared.Signal)

local UIController = {}

local player = nil
local screenGui = nil

-- UI component references
local hudFrame = nil
local notificationContainer = nil

-- ═══════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════

local function createUICorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

local function createUIStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(100, 80, 60)
    stroke.Thickness = thickness or 1
    stroke.Parent = parent
    return stroke
end

local function createTextButton(name, text, size, position, parent, callback)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = size
    btn.Position = position
    btn.BackgroundColor3 = Color3.fromRGB(60, 50, 40)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 220, 150)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.Parent = parent
    createUICorner(btn, 6)
    createUIStroke(btn, Color3.fromRGB(120, 100, 70))

    if callback then
        btn.MouseButton1Click:Connect(callback)
    end

    return btn
end

-- ═══════════════════════════════════════════════════════════════
-- HUD
-- ═══════════════════════════════════════════════════════════════

local function createHUD()
    hudFrame = Instance.new("Frame")
    hudFrame.Name = "HUD"
    hudFrame.Size = UDim2.new(0, 300, 0, 100)
    hudFrame.Position = UDim2.new(0, 10, 0, 10)
    hudFrame.BackgroundColor3 = Color3.fromRGB(30, 25, 20)
    hudFrame.BackgroundTransparency = 0.2
    hudFrame.Parent = screenGui
    createUICorner(hudFrame, 12)
    createUIStroke(hudFrame, Color3.fromRGB(180, 140, 80), 2)

    -- Currency display
    local currencyLabel = Instance.new("TextLabel")
    currencyLabel.Name = "CurrencyLabel"
    currencyLabel.Size = UDim2.new(1, -20, 0, 35)
    currencyLabel.Position = UDim2.new(0, 10, 0, 5)
    currencyLabel.BackgroundTransparency = 1
    currencyLabel.Text = "DC: 0"
    currencyLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    currencyLabel.TextScaled = true
    currencyLabel.Font = Enum.Font.GothamBold
    currencyLabel.TextXAlignment = Enum.TextXAlignment.Left
    currencyLabel.Parent = hudFrame

    -- Passive income display
    local incomeLabel = Instance.new("TextLabel")
    incomeLabel.Name = "IncomeLabel"
    incomeLabel.Size = UDim2.new(1, -20, 0, 25)
    incomeLabel.Position = UDim2.new(0, 10, 0, 40)
    incomeLabel.BackgroundTransparency = 1
    incomeLabel.Text = "+0 DC/min"
    incomeLabel.TextColor3 = Color3.fromRGB(150, 200, 100)
    incomeLabel.TextScaled = true
    incomeLabel.Font = Enum.Font.GothamMedium
    incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
    incomeLabel.Parent = hudFrame

    -- Zone indicator
    local zoneLabel = Instance.new("TextLabel")
    zoneLabel.Name = "ZoneLabel"
    zoneLabel.Size = UDim2.new(1, -20, 0, 25)
    zoneLabel.Position = UDim2.new(0, 10, 0, 68)
    zoneLabel.BackgroundTransparency = 1
    zoneLabel.Text = "Downtown Palm Springs"
    zoneLabel.TextColor3 = Color3.fromRGB(200, 180, 150)
    zoneLabel.TextScaled = true
    zoneLabel.Font = Enum.Font.Gotham
    zoneLabel.TextXAlignment = Enum.TextXAlignment.Left
    zoneLabel.Parent = hudFrame
end

-- ═══════════════════════════════════════════════════════════════
-- BOTTOM ACTION BAR
-- ═══════════════════════════════════════════════════════════════

local function createActionBar()
    local bar = Instance.new("Frame")
    bar.Name = "ActionBar"
    bar.Size = UDim2.new(0, 600, 0, 60)
    bar.Position = UDim2.new(0.5, -300, 1, -70)
    bar.BackgroundColor3 = Color3.fromRGB(30, 25, 20)
    bar.BackgroundTransparency = 0.2
    bar.Parent = screenGui
    createUICorner(bar, 12)
    createUIStroke(bar, Color3.fromRGB(180, 140, 80), 2)

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 8)
    layout.Parent = bar

    local buttons = {
        { Name = "EggsBtn", Text = "Eggs", Icon = "🥚" },
        { Name = "InventoryBtn", Text = "Icons", Icon = "📦" },
        { Name = "BuildBtn", Text = "Build", Icon = "🏗" },
        { Name = "TradeBtn", Text = "Trade", Icon = "🤝" },
        { Name = "LeaderboardBtn", Text = "Ranks", Icon = "🏆" },
        { Name = "SettingsBtn", Text = "Settings", Icon = "⚙" },
    }

    for _, btnInfo in buttons do
        local btn = Instance.new("TextButton")
        btn.Name = btnInfo.Name
        btn.Size = UDim2.new(0, 85, 0, 45)
        btn.BackgroundColor3 = Color3.fromRGB(50, 42, 35)
        btn.Text = btnInfo.Text
        btn.TextColor3 = Color3.fromRGB(255, 220, 150)
        btn.TextScaled = true
        btn.Font = Enum.Font.GothamBold
        btn.Parent = bar
        createUICorner(btn, 8)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- NOTIFICATION TOASTS
-- ═══════════════════════════════════════════════════════════════

local function createNotificationContainer()
    notificationContainer = Instance.new("Frame")
    notificationContainer.Name = "Notifications"
    notificationContainer.Size = UDim2.new(0, 350, 0, 400)
    notificationContainer.Position = UDim2.new(1, -360, 0, 120)
    notificationContainer.BackgroundTransparency = 1
    notificationContainer.Parent = screenGui

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 5)
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.Parent = notificationContainer
end

local function showNotification(title: string, text: string, duration: number?)
    if not notificationContainer then return end

    duration = duration or 3

    local toast = Instance.new("Frame")
    toast.Name = "Toast"
    toast.Size = UDim2.new(1, 0, 0, 60)
    toast.BackgroundColor3 = Color3.fromRGB(40, 35, 28)
    toast.BackgroundTransparency = 0.1
    toast.Parent = notificationContainer
    createUICorner(toast, 8)
    createUIStroke(toast, Color3.fromRGB(180, 140, 80))

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -10, 0, 22)
    titleLabel.Position = UDim2.new(0, 5, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(255, 220, 150)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = toast

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -10, 0, 25)
    textLabel.Position = UDim2.new(0, 5, 0, 28)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = Color3.fromRGB(200, 190, 170)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.Gotham
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = toast

    -- Animate in
    toast.Position = UDim2.new(1, 0, 0, 0)
    local tweenIn = TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Position = UDim2.new(0, 0, 0, 0),
    })
    tweenIn:Play()

    -- Auto-dismiss
    task.delay(duration, function()
        if toast.Parent then
            local tweenOut = TweenService:Create(toast, TweenInfo.new(0.3), {
                Position = UDim2.new(1, 0, 0, 0),
                BackgroundTransparency = 1,
            })
            tweenOut:Play()
            tweenOut.Completed:Wait()
            toast:Destroy()
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- HUD UPDATES
-- ═══════════════════════════════════════════════════════════════

local function updateHUD(data)
    if not hudFrame then return end

    local currencyLabel = hudFrame:FindFirstChild("CurrencyLabel")
    if currencyLabel and data.Currency then
        currencyLabel.Text = "DC: " .. Util.FormatNumber(data.Currency)
    end

    local incomeLabel = hudFrame:FindFirstChild("IncomeLabel")
    if incomeLabel and data.TotalPassiveIncome then
        incomeLabel.Text = "+" .. Util.FormatNumber(data.TotalPassiveIncome) .. " DC/min"
    end
end

-- ═══════════════════════════════════════════════════════════════
-- INIT
-- ═══════════════════════════════════════════════════════════════

function UIController.Init(localPlayer)
    player = localPlayer

    -- Create main ScreenGui
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PalmSpringsUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = player:WaitForChild("PlayerGui")

    -- Build UI components
    createHUD()
    createActionBar()
    createNotificationContainer()

    -- Listen for data changes to update HUD
    local DataController = require(script.Parent.DataController)

    DataController.DataLoaded:Connect(function(data)
        updateHUD(data)
    end)

    DataController.DataChanged:Connect(function(field, value)
        local data = DataController.GetData()
        if data then
            updateHUD(data)
        end
    end)

    -- Zone changes
    Remotes.GetEvent("ZoneEntered").OnClientEvent:Connect(function(zoneName)
        local zoneLabel = hudFrame and hudFrame:FindFirstChild("ZoneLabel")
        if zoneLabel then
            local zoneData = Constants.ZoneData[zoneName]
            zoneLabel.Text = zoneData and zoneData.DisplayName or "Wilderness"

            -- Flash animation
            zoneLabel.TextColor3 = Color3.fromRGB(255, 255, 200)
            TweenService:Create(zoneLabel, TweenInfo.new(1), {
                TextColor3 = Color3.fromRGB(200, 180, 150),
            }):Play()
        end
    end)

    -- Server notifications
    Remotes.GetEvent("NotificationPush").OnClientEvent:Connect(function(data)
        showNotification(data.Title or "Notice", data.Text or "", data.Duration)
    end)

    -- Expose notification function globally for other controllers
    UIController.ShowNotification = showNotification
end

return UIController
