--[[
    ShopClient.client.lua
    Client-side shop UI controller.

    Responsibilities:
      - Fetch shop inventory from ShopService via GetShopInventory remote function
      - Render a scrollable tabbed shop UI (Weapons, Abilities, Cosmetics, Boosts, Eggs)
      - Display item price, description, and owned/purchased state
      - Send PurchaseShopItem requests to the server
      - Handle ShopPurchaseResult responses and update UI accordingly
      - Track local coin balance received from UpdateCoins events
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local MulletConfig = require(ReplicatedStorage:WaitForChild("MulletConfig"))
local ShopConfig   = require(ReplicatedStorage:WaitForChild("ShopConfig"))

local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")
local Remotes      = ReplicatedStorage:WaitForChild("Remotes", 15)

local function waitEvent(name: string): RemoteEvent
    return Remotes:WaitForChild(name, 15) :: RemoteEvent
end

local function waitFunc(name: string): RemoteFunction
    return Remotes:WaitForChild(name, 15) :: RemoteFunction
end

local evPurchaseItem = waitEvent("PurchaseShopItem")
local evPurchaseRes  = waitEvent("ShopPurchaseResult")
local evCoinsUpdate  = waitEvent("UpdateCoins")
local fnGetShop      = waitFunc("GetShopInventory")

---------------------------------------------------------------------------
-- LOCAL STATE
---------------------------------------------------------------------------
local localCoins    = 0
local shopOpen      = false
local activeCategory = "Weapons"
local shopInventory: table = {}

---------------------------------------------------------------------------
-- UI CONSTRUCTION
---------------------------------------------------------------------------

local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "ShopGui"
screenGui.ResetOnSpawn   = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Enabled        = false
screenGui.Parent         = PlayerGui

-- Backdrop (semi-transparent overlay)
local backdrop = Instance.new("Frame")
backdrop.Name              = "Backdrop"
backdrop.Size              = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3  = Color3.fromRGB(0, 0, 0)
backdrop.BackgroundTransparency = 0.5
backdrop.BorderSizePixel   = 0
backdrop.Parent            = screenGui

-- Main panel
local panel = Instance.new("Frame")
panel.Name              = "ShopPanel"
panel.Size              = UDim2.new(0, 700, 0, 520)
panel.Position          = UDim2.new(0.5, -350, 0.5, -260)
panel.BackgroundColor3  = MulletConfig.Colors.Background
panel.BackgroundTransparency = 0.05
panel.BorderSizePixel   = 0
panel.Parent            = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 14)
panelCorner.Parent = panel

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size             = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundColor3 = MulletConfig.Colors.Primary
titleBar.BorderSizePixel  = 0
titleBar.Parent           = panel

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 14)
titleCorner.Parent = titleBar

-- Fix bottom corners of title bar
local titlePatch = Instance.new("Frame")
titlePatch.Size             = UDim2.new(1, 0, 0.5, 0)
titlePatch.Position         = UDim2.new(0, 0, 0.5, 0)
titlePatch.BackgroundColor3 = MulletConfig.Colors.Primary
titlePatch.BorderSizePixel  = 0
titlePatch.Parent           = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size               = UDim2.new(0.7, 0, 1, 0)
titleLabel.Position           = UDim2.new(0, 16, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3         = MulletConfig.Colors.Text
titleLabel.Font               = Enum.Font.GothamBlack
titleLabel.TextScaled         = true
titleLabel.Text               = "✂  MULLET SHOP"
titleLabel.Parent             = titleBar

local coinDisplay = Instance.new("TextLabel")
coinDisplay.Name              = "CoinDisplay"
coinDisplay.Size              = UDim2.new(0.25, 0, 0.8, 0)
coinDisplay.Position          = UDim2.new(0.73, 0, 0.1, 0)
coinDisplay.BackgroundTransparency = 1
coinDisplay.TextColor3        = MulletConfig.Colors.Coin
coinDisplay.Font              = Enum.Font.GothamBold
coinDisplay.TextScaled        = true
coinDisplay.Text              = "🪙 0"
coinDisplay.Parent            = titleBar

-- Close button
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

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 6)
closeBtnCorner.Parent = closeBtn

-- Category tabs
local tabBar = Instance.new("Frame")
tabBar.Name              = "TabBar"
tabBar.Size              = UDim2.new(1, 0, 0, 42)
tabBar.Position          = UDim2.new(0, 0, 0, 50)
tabBar.BackgroundColor3  = Color3.fromRGB(30, 30, 30)
tabBar.BorderSizePixel   = 0
tabBar.Parent            = panel

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection  = Enum.FillDirection.Horizontal
tabLayout.SortOrder      = Enum.SortOrder.LayoutOrder
tabLayout.Padding        = UDim.new(0, 2)
tabLayout.Parent         = tabBar

local tabButtons: { [string]: TextButton } = {}

for i, category in ipairs(ShopConfig.Categories) do
    local tabBtn = Instance.new("TextButton")
    tabBtn.Name              = category .. "Tab"
    tabBtn.Size              = UDim2.new(1 / #ShopConfig.Categories, -2, 1, 0)
    tabBtn.BackgroundColor3  = Color3.fromRGB(40, 40, 40)
    tabBtn.BorderSizePixel   = 0
    tabBtn.TextColor3        = MulletConfig.Colors.Text
    tabBtn.Font              = Enum.Font.GothamBold
    tabBtn.TextScaled        = true
    tabBtn.Text              = category
    tabBtn.LayoutOrder       = i
    tabBtn.Parent            = tabBar
    tabButtons[category]     = tabBtn
end

-- Item scroll frame
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name              = "ItemScroll"
scrollFrame.Size              = UDim2.new(1, -20, 1, -108)
scrollFrame.Position          = UDim2.new(0, 10, 0, 98)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 6
scrollFrame.BorderSizePixel   = 0
scrollFrame.CanvasSize        = UDim2.new(0, 0, 0, 0)
scrollFrame.Parent            = panel

local itemLayout = Instance.new("UIGridLayout")
itemLayout.CellSize    = UDim2.new(0, 200, 0, 140)
itemLayout.CellPadding = UDim2.new(0, 10, 0, 10)
itemLayout.SortOrder   = Enum.SortOrder.LayoutOrder
itemLayout.Parent      = scrollFrame

---------------------------------------------------------------------------
-- ITEM CARD BUILDER
---------------------------------------------------------------------------

local function buildItemCard(item: table, index: number)
    local card = Instance.new("Frame")
    card.Name             = item.id
    card.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    card.BorderSizePixel  = 0
    card.LayoutOrder      = index
    card.Parent           = scrollFrame

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size               = UDim2.new(1, -8, 0, 26)
    nameLabel.Position           = UDim2.new(0, 4, 0, 4)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3         = MulletConfig.Colors.Text
    nameLabel.Font               = Enum.Font.GothamBold
    nameLabel.TextScaled         = true
    nameLabel.Text               = item.name or item.id
    nameLabel.Parent             = card

    local descLabel = Instance.new("TextLabel")
    descLabel.Size               = UDim2.new(1, -8, 0, 56)
    descLabel.Position           = UDim2.new(0, 4, 0, 32)
    descLabel.BackgroundTransparency = 1
    descLabel.TextColor3         = Color3.fromRGB(180, 180, 180)
    descLabel.Font               = Enum.Font.Gotham
    descLabel.TextScaled         = true
    descLabel.TextWrapped        = true
    descLabel.Text               = item.description or ""
    descLabel.Parent             = card

    local buyBtn = Instance.new("TextButton")
    buyBtn.Size              = UDim2.new(1, -12, 0, 32)
    buyBtn.Position          = UDim2.new(0, 6, 1, -38)
    buyBtn.BorderSizePixel   = 0
    buyBtn.Font              = Enum.Font.GothamBold
    buyBtn.TextScaled        = true
    buyBtn.TextColor3        = MulletConfig.Colors.Text
    buyBtn.Parent            = card

    local buyCorner = Instance.new("UICorner")
    buyCorner.CornerRadius = UDim.new(0, 6)
    buyCorner.Parent = buyBtn

    local price = item.price or 0
    if price == 0 then
        buyBtn.Text            = "FREE / STARTER"
        buyBtn.BackgroundColor3 = Color3.fromRGB(60, 130, 60)
        buyBtn.Active          = false
    else
        buyBtn.Text            = "🪙 " .. price
        buyBtn.BackgroundColor3 = MulletConfig.Colors.Primary
    end

    buyBtn.MouseButton1Click:Connect(function()
        if price > 0 and localCoins >= price then
            evPurchaseItem:FireServer(item.id)
            buyBtn.Text = "..."
            buyBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            task.delay(3, function()
                buyBtn.Text = "🪙 " .. price
                buyBtn.BackgroundColor3 = MulletConfig.Colors.Primary
            end)
        elseif price > 0 then
            buyBtn.Text = "No coins!"
            buyBtn.BackgroundColor3 = MulletConfig.Colors.Danger
            task.delay(1.5, function()
                buyBtn.Text = "🪙 " .. price
                buyBtn.BackgroundColor3 = MulletConfig.Colors.Primary
            end)
        end
    end)

    return card
end

---------------------------------------------------------------------------
-- RENDER CATEGORY
---------------------------------------------------------------------------

local function renderCategory(category: string)
    -- Clear existing items
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local items = shopInventory[category] or ShopConfig[category] or {}
    for i, item in ipairs(items) do
        buildItemCard(item, i)
    end

    -- Update canvas size
    local rows = math.ceil(#items / 3)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, rows * 150 + 10)

    -- Highlight active tab
    for cat, btn in pairs(tabButtons) do
        btn.BackgroundColor3 = cat == category
            and MulletConfig.Colors.Primary
            or  Color3.fromRGB(40, 40, 40)
    end

    activeCategory = category
end

---------------------------------------------------------------------------
-- SHOP OPEN/CLOSE
---------------------------------------------------------------------------

local function openShop()
    if shopOpen then return end
    shopOpen = true
    screenGui.Enabled = true

    -- Fetch latest inventory
    local ok, inv = pcall(function()
        return fnGetShop:InvokeServer()
    end)
    if ok and inv then
        shopInventory = inv
    end

    renderCategory(activeCategory)
end

local function closeShop()
    shopOpen = false
    screenGui.Enabled = false
end

closeBtn.MouseButton1Click:Connect(closeShop)

for category, btn in pairs(tabButtons) do
    btn.MouseButton1Click:Connect(function()
        renderCategory(category)
    end)
end

---------------------------------------------------------------------------
-- SHOP OPEN TRIGGER — press "B" to toggle shop
---------------------------------------------------------------------------
local UserInputService = game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.B then
        if shopOpen then closeShop() else openShop() end
    end
end)

---------------------------------------------------------------------------
-- REMOTE LISTENERS
---------------------------------------------------------------------------

evCoinsUpdate.OnClientEvent:Connect(function(newBalance: number)
    localCoins = newBalance
    coinDisplay.Text = "🪙 " .. newBalance
end)

evPurchaseRes.OnClientEvent:Connect(function(result: table)
    if result and result.success then
        -- Refresh the shop display
        if shopOpen then
            renderCategory(activeCategory)
        end
    end
end)

print("[ShopClient] Initialized (press B to open shop)")
