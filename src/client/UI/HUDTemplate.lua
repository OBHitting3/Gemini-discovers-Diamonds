--[[
    HUDTemplate.lua
    Creates the main always-visible HUD for Palm Springs Paradise.
    Mobile-optimized: avoids joystick zones (bottom-left/right),
    uses large touch targets, and scales for all screen sizes.

    Layout:
    - Top bar: SunCoins, Prestige, Level
    - Left panel buttons: Plot, Garden, Fashion, Shop, Events
    - Notification area handled by UIController
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local HUDTemplate = {}

local C = GameConfig.Colors

---------------------------------------------------------------------------
-- HELPER: Create styled button
---------------------------------------------------------------------------

local function createButton(name: string, text: string, icon: string, parent: Instance, layoutOrder: number): TextButton
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(1, 0, 0, 48)
    btn.BackgroundColor3 = C.UIBackground
    btn.BorderSizePixel = 0
    btn.Text = icon .. "  " .. text
    btn.TextColor3 = C.UIText
    btn.TextScaled = false
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = true
    btn.LayoutOrder = layoutOrder
    btn.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = C.UIPrimary
    stroke.Thickness = 1.5
    stroke.Transparency = 0.3
    stroke.Parent = btn

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 8)
    padding.Parent = btn

    return btn
end

---------------------------------------------------------------------------
-- BUILD HUD
---------------------------------------------------------------------------

function HUDTemplate:build(screenGui: ScreenGui, uiController)
    -----------------------------------------------------------------
    -- SAFE AREA GUARD  (notch / home bar on iOS)
    -----------------------------------------------------------------
    local safeInsets = game:GetService("GuiService"):GetGuiInset()
    -- safeInsets accounts for notch and home bar on iOS

    pcall(function()
        screenGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
    end)

    -----------------------------------------------------------------
    -- TOP BAR  (coins, prestige, level)
    -----------------------------------------------------------------
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0, 44)
    topBar.Position = UDim2.new(0, 0, 0, 0)
    topBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    topBar.BackgroundTransparency = 0.5
    topBar.BorderSizePixel = 0
    topBar.Parent = screenGui

    -- Coin display
    local coinFrame = Instance.new("Frame")
    coinFrame.Name = "CoinFrame"
    coinFrame.Size = UDim2.new(0, 150, 0, 34)
    coinFrame.Position = UDim2.new(0, 10, 0, 5)
    coinFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    coinFrame.BackgroundTransparency = 0.3
    coinFrame.BorderSizePixel = 0
    coinFrame.Parent = topBar

    local coinCorner = Instance.new("UICorner")
    coinCorner.CornerRadius = UDim.new(0, 6)
    coinCorner.Parent = coinFrame

    local coinIcon = Instance.new("TextLabel")
    coinIcon.Name = "CoinIcon"
    coinIcon.Size = UDim2.new(0, 30, 1, 0)
    coinIcon.Position = UDim2.new(0, 4, 0, 0)
    coinIcon.BackgroundTransparency = 1
    coinIcon.Text = "SC"
    coinIcon.TextColor3 = C.UISunCoin
    coinIcon.TextScaled = true
    coinIcon.Font = Enum.Font.GothamBold
    coinIcon.Parent = coinFrame

    local coinLabel = Instance.new("TextLabel")
    coinLabel.Name = "CoinAmount"
    coinLabel.Size = UDim2.new(1, -40, 1, 0)
    coinLabel.Position = UDim2.new(0, 36, 0, 0)
    coinLabel.BackgroundTransparency = 1
    coinLabel.Text = "100 SC"
    coinLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    coinLabel.TextScaled = true
    coinLabel.Font = Enum.Font.GothamBold
    coinLabel.TextXAlignment = Enum.TextXAlignment.Left
    coinLabel.Parent = coinFrame

    -- Prestige display
    local prestigeFrame = Instance.new("Frame")
    prestigeFrame.Name = "PrestigeFrame"
    prestigeFrame.Size = UDim2.new(0, 120, 0, 34)
    prestigeFrame.Position = UDim2.new(0, 170, 0, 5)
    prestigeFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    prestigeFrame.BackgroundTransparency = 0.3
    prestigeFrame.BorderSizePixel = 0
    prestigeFrame.Parent = topBar

    local prestigeCorner = Instance.new("UICorner")
    prestigeCorner.CornerRadius = UDim.new(0, 6)
    prestigeCorner.Parent = prestigeFrame

    local prestigeIcon = Instance.new("TextLabel")
    prestigeIcon.Size = UDim2.new(0, 20, 1, 0)
    prestigeIcon.Position = UDim2.new(0, 4, 0, 0)
    prestigeIcon.BackgroundTransparency = 1
    prestigeIcon.Text = "P"
    prestigeIcon.TextColor3 = C.DustyPink
    prestigeIcon.TextScaled = true
    prestigeIcon.Font = Enum.Font.GothamBold
    prestigeIcon.Parent = prestigeFrame

    local prestigeLabel = Instance.new("TextLabel")
    prestigeLabel.Name = "PrestigeAmount"
    prestigeLabel.Size = UDim2.new(1, -30, 1, 0)
    prestigeLabel.Position = UDim2.new(0, 26, 0, 0)
    prestigeLabel.BackgroundTransparency = 1
    prestigeLabel.Text = "0"
    prestigeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    prestigeLabel.TextScaled = true
    prestigeLabel.Font = Enum.Font.Gotham
    prestigeLabel.TextXAlignment = Enum.TextXAlignment.Left
    prestigeLabel.Parent = prestigeFrame

    -- Level display
    local levelFrame = Instance.new("Frame")
    levelFrame.Name = "LevelFrame"
    levelFrame.Size = UDim2.new(0, 70, 0, 34)
    levelFrame.Position = UDim2.new(0, 300, 0, 5)
    levelFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    levelFrame.BackgroundTransparency = 0.3
    levelFrame.BorderSizePixel = 0
    levelFrame.Parent = topBar

    local levelCorner = Instance.new("UICorner")
    levelCorner.CornerRadius = UDim.new(0, 6)
    levelCorner.Parent = levelFrame

    local levelLabel = Instance.new("TextLabel")
    levelLabel.Name = "LevelText"
    levelLabel.Size = UDim2.new(1, -8, 1, 0)
    levelLabel.Position = UDim2.new(0, 4, 0, 0)
    levelLabel.BackgroundTransparency = 1
    levelLabel.Text = "Lv.1"
    levelLabel.TextColor3 = C.Turquoise
    levelLabel.TextScaled = true
    levelLabel.Font = Enum.Font.GothamBold
    levelLabel.Parent = levelFrame

    -- Register HUD references with UIController
    uiController:setHUDReferences(coinLabel, prestigeLabel, levelLabel)

    -----------------------------------------------------------------
    -- LEFT BUTTON COLUMN  (vertically centered, 9:16 safe)
    -----------------------------------------------------------------
    local sidebar = Instance.new("Frame")
    sidebar.Name = "ButtonColumn"
    sidebar.Size = UDim2.new(0, 56, 0, 280)
    sidebar.Position = UDim2.new(0, 12, 0.5, -120)
    sidebar.AnchorPoint = Vector2.new(0, 0.5)
    sidebar.BackgroundTransparency = 1
    sidebar.BorderSizePixel = 0
    sidebar.Parent = screenGui

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 6)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = sidebar

    -- Panel buttons
    local plotBtn = createButton("PlotBtn", "My Plot", "H", sidebar, 1)
    local gardenBtn = createButton("GardenBtn", "Garden", "G", sidebar, 2)
    local fashionBtn = createButton("FashionBtn", "Fashion", "F", sidebar, 3)
    local shopBtn = createButton("ShopBtn", "Shops", "S", sidebar, 4)
    local eventBtn = createButton("EventBtn", "Events", "E", sidebar, 5)

    -- Connect buttons to panel toggles
    plotBtn.MouseButton1Click:Connect(function()
        uiController:togglePanel("plot")
    end)
    gardenBtn.MouseButton1Click:Connect(function()
        uiController:togglePanel("garden")
    end)
    fashionBtn.MouseButton1Click:Connect(function()
        uiController:togglePanel("fashion")
    end)
    shopBtn.MouseButton1Click:Connect(function()
        uiController:togglePanel("shop")
    end)
    eventBtn.MouseButton1Click:Connect(function()
        uiController:togglePanel("event")
    end)

    -----------------------------------------------------------------
    -- GAME TITLE (small, top-right)
    -----------------------------------------------------------------
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "GameTitle"
    titleLabel.Size = UDim2.new(0, 200, 0, 30)
    titleLabel.Position = UDim2.new(1, -210, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Palm Springs Paradise"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextTransparency = 0.3
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Right
    titleLabel.Parent = screenGui

    print("[HUDTemplate] HUD built")
end

return HUDTemplate
