--[[
    ShopUI.lua
    Shop management and browsing interface for El Paseo boutiques.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig    = require(ReplicatedStorage:WaitForChild("GameConfig"))
local ItemCatalog   = require(ReplicatedStorage:WaitForChild("ItemCatalog"))

local ShopUI = {}
local C = GameConfig.Colors

function ShopUI:build(screenGui: ScreenGui, uiController, shopController)
    local panel = Instance.new("Frame")
    panel.Name = "ShopPanel"
    panel.Size = UDim2.new(0, 320, 0, 400)
    panel.Position = UDim2.new(0.3, 0, 0.15, 0)
    panel.BackgroundColor3 = C.UIBackground
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = panel

    local stroke = Instance.new("UIStroke")
    stroke.Color = C.UIAccent
    stroke.Thickness = 2
    stroke.Parent = panel

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = C.Terracotta
    title.BackgroundTransparency = 0.1
    title.BorderSizePixel = 0
    title.Text = "EL PASEO SHOPS"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = panel

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = title

    -- Close
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextScaled = true
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = panel
    closeBtn.MouseButton1Click:Connect(function()
        uiController:hidePanel("shop")
    end)

    -- Shop name input
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.4, 0, 0, 30)
    nameLabel.Position = UDim2.new(0, 10, 0, 48)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "Shop Name:"
    nameLabel.TextColor3 = C.UIText
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = panel

    local nameInput = Instance.new("TextBox")
    nameInput.Size = UDim2.new(0.5, 0, 0, 30)
    nameInput.Position = UDim2.new(0.45, 0, 0, 48)
    nameInput.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    nameInput.BorderSizePixel = 0
    nameInput.Text = "My Boutique"
    nameInput.TextColor3 = C.UIText
    nameInput.TextScaled = true
    nameInput.Font = Enum.Font.Gotham
    nameInput.ClearTextOnFocus = false
    nameInput.Parent = panel

    local nameCorner = Instance.new("UICorner")
    nameCorner.CornerRadius = UDim.new(0, 4)
    nameCorner.Parent = nameInput

    nameInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            shopController:setShopName(nameInput.Text)
        end
    end)

    -- Boutique goods to stock
    local stockLabel = Instance.new("TextLabel")
    stockLabel.Size = UDim2.new(1, -20, 0, 25)
    stockLabel.Position = UDim2.new(0, 10, 0, 86)
    stockLabel.BackgroundTransparency = 1
    stockLabel.Text = "Stock Items:"
    stockLabel.TextColor3 = C.UIText
    stockLabel.TextScaled = true
    stockLabel.Font = Enum.Font.GothamBold
    stockLabel.TextXAlignment = Enum.TextXAlignment.Left
    stockLabel.Parent = panel

    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "ShopItemScroll"
    scrollFrame.Size = UDim2.new(1, -20, 0, 250)
    scrollFrame.Position = UDim2.new(0, 10, 0, 115)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #ItemCatalog.BoutiqueGoods * 50)
    scrollFrame.Parent = panel

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 4)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scrollFrame

    for i, item in ipairs(ItemCatalog.BoutiqueGoods) do
        local itemFrame = Instance.new("Frame")
        itemFrame.Size = UDim2.new(1, -8, 0, 44)
        itemFrame.BackgroundColor3 = Color3.fromRGB(245, 242, 235)
        itemFrame.BorderSizePixel = 0
        itemFrame.LayoutOrder = i
        itemFrame.Parent = scrollFrame

        local itemCorner = Instance.new("UICorner")
        itemCorner.CornerRadius = UDim.new(0, 4)
        itemCorner.Parent = itemFrame

        local nameLabel2 = Instance.new("TextLabel")
        nameLabel2.Size = UDim2.new(0.5, 0, 1, 0)
        nameLabel2.Position = UDim2.new(0, 6, 0, 0)
        nameLabel2.BackgroundTransparency = 1
        nameLabel2.Text = item.name
        nameLabel2.TextColor3 = C.UIText
        nameLabel2.TextScaled = true
        nameLabel2.Font = Enum.Font.Gotham
        nameLabel2.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel2.Parent = itemFrame

        local priceLabel = Instance.new("TextLabel")
        priceLabel.Size = UDim2.new(0.2, 0, 1, 0)
        priceLabel.Position = UDim2.new(0.5, 0, 0, 0)
        priceLabel.BackgroundTransparency = 1
        priceLabel.Text = tostring(item.basePrice) .. " SC"
        priceLabel.TextColor3 = C.UISunCoin
        priceLabel.TextScaled = true
        priceLabel.Font = Enum.Font.GothamBold
        priceLabel.Parent = itemFrame

        local stockBtn = Instance.new("TextButton")
        stockBtn.Size = UDim2.new(0.25, 0, 0, 32)
        stockBtn.Position = UDim2.new(0.73, 0, 0, 6)
        stockBtn.BackgroundColor3 = C.Terracotta
        stockBtn.Text = "Stock"
        stockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        stockBtn.TextScaled = true
        stockBtn.Font = Enum.Font.GothamBold
        stockBtn.Parent = itemFrame

        local stockBtnCorner = Instance.new("UICorner")
        stockBtnCorner.CornerRadius = UDim.new(0, 4)
        stockBtnCorner.Parent = stockBtn

        stockBtn.MouseButton1Click:Connect(function()
            shopController:stockItem(item.id, 1, item.basePrice)
        end)
    end

    uiController:registerPanel("shop", panel)
    print("[ShopUI] Built")
end

return ShopUI
