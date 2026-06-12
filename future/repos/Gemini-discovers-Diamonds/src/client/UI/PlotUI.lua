--[[
    PlotUI.lua
    Plot management interface: home style selection, furniture catalog,
    placement controls, Vibes Score, home tour browser.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig    = require(ReplicatedStorage:WaitForChild("GameConfig"))
local ItemCatalog   = require(ReplicatedStorage:WaitForChild("ItemCatalog"))

local PlotUI = {}
local C = GameConfig.Colors

---------------------------------------------------------------------------
-- BUILD
---------------------------------------------------------------------------

function PlotUI:build(screenGui: ScreenGui, uiController, plotController)
    -- Main panel frame
    local panel = Instance.new("Frame")
    panel.Name = "PlotPanel"
    panel.Size = UDim2.new(0, 320, 0, 450)
    panel.Position = UDim2.new(0.3, 0, 0.15, 0)
    panel.BackgroundColor3 = C.UIBackground
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = panel

    local stroke = Instance.new("UIStroke")
    stroke.Color = C.UIPrimary
    stroke.Thickness = 2
    stroke.Parent = panel

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = C.UIPrimary
    title.BackgroundTransparency = 0.1
    title.BorderSizePixel = 0
    title.Text = "MY PLOT"
    title.TextColor3 = C.UIText
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = panel

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = title

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "X"
    closeBtn.TextColor3 = C.UIText
    closeBtn.TextScaled = true
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = panel
    closeBtn.MouseButton1Click:Connect(function()
        uiController:hidePanel("plot")
    end)

    -- Home style selection section
    local styleSection = Instance.new("TextLabel")
    styleSection.Size = UDim2.new(1, -20, 0, 25)
    styleSection.Position = UDim2.new(0, 10, 0, 48)
    styleSection.BackgroundTransparency = 1
    styleSection.Text = "Choose Home Style:"
    styleSection.TextColor3 = C.UIText
    styleSection.TextScaled = true
    styleSection.Font = Enum.Font.GothamBold
    styleSection.TextXAlignment = Enum.TextXAlignment.Left
    styleSection.Parent = panel

    -- Style buttons
    local styleFrame = Instance.new("Frame")
    styleFrame.Size = UDim2.new(1, -20, 0, 120)
    styleFrame.Position = UDim2.new(0, 10, 0, 75)
    styleFrame.BackgroundTransparency = 1
    styleFrame.Parent = panel

    local styleGrid = Instance.new("UIGridLayout")
    styleGrid.CellSize = UDim2.new(0.48, 0, 0, 55)
    styleGrid.CellPadding = UDim2.new(0.04, 0, 0, 5)
    styleGrid.SortOrder = Enum.SortOrder.LayoutOrder
    styleGrid.Parent = styleFrame

    local styleOrder = { "Kaufmann", "Frey", "Wexler", "Neutra" }
    for i, styleName in ipairs(styleOrder) do
        local style = GameConfig.HomeStyles[styleName]
        local btn = Instance.new("TextButton")
        btn.Name = "Style_" .. styleName
        btn.Text = style.name .. "\n" .. style.roofType .. "-roof"
        btn.TextColor3 = C.UIText
        btn.TextScaled = true
        btn.Font = Enum.Font.Gotham
        btn.BackgroundColor3 = C.UIBackground
        btn.AutoButtonColor = true
        btn.LayoutOrder = i
        btn.Parent = styleFrame

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn

        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = C[style.accentColor] or C.Terracotta
        btnStroke.Thickness = 2
        btnStroke.Parent = btn

        btn.MouseButton1Click:Connect(function()
            plotController:requestBuildHome(styleName)
        end)
    end

    -- Furniture section header
    local furnSection = Instance.new("TextLabel")
    furnSection.Size = UDim2.new(1, -20, 0, 25)
    furnSection.Position = UDim2.new(0, 10, 0, 205)
    furnSection.BackgroundTransparency = 1
    furnSection.Text = "Furniture Catalog:"
    furnSection.TextColor3 = C.UIText
    furnSection.TextScaled = true
    furnSection.Font = Enum.Font.GothamBold
    furnSection.TextXAlignment = Enum.TextXAlignment.Left
    furnSection.Parent = panel

    -- Scrollable furniture list
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "FurnitureScroll"
    scrollFrame.Size = UDim2.new(1, -20, 0, 200)
    scrollFrame.Position = UDim2.new(0, 10, 0, 235)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #ItemCatalog.Furniture * 50)
    scrollFrame.Parent = panel

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 4)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scrollFrame

    for i, item in ipairs(ItemCatalog.Furniture) do
        local itemFrame = Instance.new("Frame")
        itemFrame.Size = UDim2.new(1, -8, 0, 44)
        itemFrame.BackgroundColor3 = Color3.fromRGB(245, 242, 235)
        itemFrame.BorderSizePixel = 0
        itemFrame.LayoutOrder = i
        itemFrame.Parent = scrollFrame

        local itemCorner = Instance.new("UICorner")
        itemCorner.CornerRadius = UDim.new(0, 4)
        itemCorner.Parent = itemFrame

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.55, 0, 1, 0)
        nameLabel.Position = UDim2.new(0, 6, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = item.name
        nameLabel.TextColor3 = C.UIText
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = itemFrame

        local priceLabel = Instance.new("TextLabel")
        priceLabel.Size = UDim2.new(0.2, 0, 1, 0)
        priceLabel.Position = UDim2.new(0.55, 0, 0, 0)
        priceLabel.BackgroundTransparency = 1
        priceLabel.Text = tostring(item.price) .. " SC"
        priceLabel.TextColor3 = C.UISunCoin
        priceLabel.TextScaled = true
        priceLabel.Font = Enum.Font.GothamBold
        priceLabel.Parent = itemFrame

        local placeBtn = Instance.new("TextButton")
        placeBtn.Size = UDim2.new(0.22, 0, 0, 32)
        placeBtn.Position = UDim2.new(0.76, 0, 0, 6)
        placeBtn.BackgroundColor3 = C.UIPrimary
        placeBtn.Text = "Place"
        placeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        placeBtn.TextScaled = true
        placeBtn.Font = Enum.Font.GothamBold
        placeBtn.Parent = itemFrame

        local placeBtnCorner = Instance.new("UICorner")
        placeBtnCorner.CornerRadius = UDim.new(0, 4)
        placeBtnCorner.Parent = placeBtn

        placeBtn.MouseButton1Click:Connect(function()
            plotController:startPlacingFurniture(item.id)
            uiController:hidePanel("plot")
        end)
    end

    -- Register panel
    uiController:registerPanel("plot", panel)
    print("[PlotUI] Built")
end

return PlotUI
