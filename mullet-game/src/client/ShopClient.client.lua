--[[
    ShopClient.client.lua
    Simple coin shop — buy mullet styles and cosmetics.
    Press B to open.
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")

local MulletConfig = require(ReplicatedStorage:WaitForChild("MulletConfig"))

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local Remotes     = ReplicatedStorage:WaitForChild("Remotes", 15)

local evNotify = Remotes:WaitForChild("NotifyPlayer", 15)
local evCoins  = Remotes:WaitForChild("UpdateCoins",  15)

---------------------------------------------------------------------------
-- SHOP ITEMS
---------------------------------------------------------------------------
local SHOP_ITEMS = {
    { id = "style_rainbow",  name = "Rainbow Mullet Style",  price = 50,  description = "Your mullet cycles through all colors!" },
    { id = "style_flames",   name = "Flame Mullet Style",    price = 75,  description = "Your mullet looks like it's on fire!" },
    { id = "trail_coins",    name = "Coin Trail",            price = 40,  description = "Leave a trail of coins as you run." },
    { id = "trail_hair",     name = "Hair Trail",            price = 30,  description = "Hair floats behind you as you move." },
    { id = "vacuum_turbo",   name = "Turbo Vacuum",          price = 100, description = "Collect hair from twice as far away!" },
    { id = "vacuum_mega",    name = "Mega Vacuum",           price = 200, description = "The biggest vacuum. Hair flies to you!" },
}

local localCoins = 0
local owned = {}

---------------------------------------------------------------------------
-- UI
---------------------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name           = "ShopGui"
gui.ResetOnSpawn   = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Enabled        = false
gui.Parent         = PlayerGui

local bg = Instance.new("Frame")
bg.Size              = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3  = Color3.fromRGB(0, 0, 0)
bg.BackgroundTransparency = 0.5
bg.BorderSizePixel   = 0
bg.Parent            = gui

local panel = Instance.new("Frame")
panel.Size              = UDim2.new(0, 560, 0, 480)
panel.Position          = UDim2.new(0.5, -280, 0.5, -240)
panel.BackgroundColor3  = MulletConfig.Colors.Background
panel.BackgroundTransparency = 0.05
panel.BorderSizePixel   = 0
panel.Parent            = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size             = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundColor3 = MulletConfig.Colors.Primary
titleBar.BorderSizePixel  = 0
titleBar.Parent           = panel
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 14)

local titlePatch = Instance.new("Frame")
titlePatch.Size             = UDim2.new(1, 0, 0.5, 0)
titlePatch.Position         = UDim2.new(0, 0, 0.5, 0)
titlePatch.BackgroundColor3 = MulletConfig.Colors.Primary
titlePatch.BorderSizePixel  = 0
titlePatch.Parent           = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size               = UDim2.new(0.6, 0, 1, 0)
titleLabel.Position           = UDim2.new(0, 14, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3         = Color3.fromRGB(255, 255, 255)
titleLabel.Font               = Enum.Font.GothamBlack
titleLabel.TextScaled         = true
titleLabel.Text               = "🛒 MULLET SHOP"
titleLabel.Parent             = titleBar

local coinDisplay = Instance.new("TextLabel")
coinDisplay.Size               = UDim2.new(0.28, 0, 0.8, 0)
coinDisplay.Position           = UDim2.new(0.68, 0, 0.1, 0)
coinDisplay.BackgroundTransparency = 1
coinDisplay.TextColor3         = MulletConfig.Colors.Coin
coinDisplay.Font               = Enum.Font.GothamBold
coinDisplay.TextScaled         = true
coinDisplay.Text               = "🪙 0"
coinDisplay.Parent             = titleBar

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

-- Item scroll
local scroll = Instance.new("ScrollingFrame")
scroll.Size              = UDim2.new(1, -20, 1, -62)
scroll.Position          = UDim2.new(0, 10, 0, 58)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 4
scroll.BorderSizePixel   = 0
scroll.CanvasSize        = UDim2.new(0, 0, 0, math.ceil(#SHOP_ITEMS / 2) * 160 + 10)
scroll.Parent            = panel

local grid = Instance.new("UIGridLayout")
grid.CellSize    = UDim2.new(0, 248, 0, 148)
grid.CellPadding = UDim2.new(0, 8, 0, 8)
grid.SortOrder   = Enum.SortOrder.LayoutOrder
grid.Parent      = scroll

-- Build item cards
local buyButtons = {}

for i, item in ipairs(SHOP_ITEMS) do
    local card = Instance.new("Frame")
    card.Name             = item.id
    card.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    card.BorderSizePixel  = 0
    card.LayoutOrder      = i
    card.Parent           = scroll
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size               = UDim2.new(1, -8, 0, 30)
    nameLbl.Position           = UDim2.new(0, 4, 0, 6)
    nameLbl.BackgroundTransparency = 1
    nameLbl.TextColor3         = MulletConfig.Colors.Primary
    nameLbl.Font               = Enum.Font.GothamBold
    nameLbl.TextScaled         = true
    nameLbl.Text               = item.name
    nameLbl.Parent             = card

    local descLbl = Instance.new("TextLabel")
    descLbl.Size               = UDim2.new(1, -8, 0, 56)
    descLbl.Position           = UDim2.new(0, 4, 0, 38)
    descLbl.BackgroundTransparency = 1
    descLbl.TextColor3         = Color3.fromRGB(180, 180, 180)
    descLbl.Font               = Enum.Font.Gotham
    descLbl.TextScaled         = true
    descLbl.TextWrapped        = true
    descLbl.Text               = item.description
    descLbl.Parent             = card

    local buyBtn = Instance.new("TextButton")
    buyBtn.Size              = UDim2.new(1, -12, 0, 36)
    buyBtn.Position          = UDim2.new(0, 6, 1, -42)
    buyBtn.BackgroundColor3  = MulletConfig.Colors.Secondary
    buyBtn.BorderSizePixel   = 0
    buyBtn.Text              = "🪙 " .. item.price
    buyBtn.TextColor3        = Color3.fromRGB(255, 255, 255)
    buyBtn.Font              = Enum.Font.GothamBold
    buyBtn.TextScaled        = true
    buyBtn.Parent            = card
    Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 6)

    buyButtons[item.id] = buyBtn

    buyBtn.MouseButton1Click:Connect(function()
        if owned[item.id] then
            evNotify:FireServer()
            return
        end
        if localCoins >= item.price then
            owned[item.id] = true
            buyBtn.Text = "✅ Owned"
            buyBtn.BackgroundColor3 = Color3.fromRGB(60, 130, 60)
            -- In a full game this would fire a server event to validate purchase
        else
            buyBtn.Text = "Need more coins!"
            buyBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
            task.delay(1.5, function()
                buyBtn.Text = "🪙 " .. item.price
                buyBtn.BackgroundColor3 = MulletConfig.Colors.Secondary
            end)
        end
    end)
end

---------------------------------------------------------------------------
-- OPEN / CLOSE
---------------------------------------------------------------------------

closeBtn.MouseButton1Click:Connect(function() gui.Enabled = false end)
bg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        gui.Enabled = false
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.B then
        gui.Enabled = not gui.Enabled
    end
end)

evCoins.OnClientEvent:Connect(function(amount)
    localCoins = amount
    coinDisplay.Text = "🪙 " .. amount
end)

print("[ShopClient] Ready — press B to open shop")
