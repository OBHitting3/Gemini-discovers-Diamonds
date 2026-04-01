--[[
    FashionUI.lua
    Fashion event interface: event announcement, join button,
    outfit selection, voting, results display.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig    = require(ReplicatedStorage:WaitForChild("GameConfig"))
local ItemCatalog   = require(ReplicatedStorage:WaitForChild("ItemCatalog"))

local FashionUI = {}
local C = GameConfig.Colors

function FashionUI:build(screenGui: ScreenGui, uiController, fashionController)
    local panel = Instance.new("Frame")
    panel.Name = "FashionPanel"
    panel.Size = UDim2.new(0, 320, 0, 420)
    panel.Position = UDim2.new(0.3, 0, 0.15, 0)
    panel.BackgroundColor3 = C.UIBackground
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = panel

    local stroke = Instance.new("UIStroke")
    stroke.Color = C.DustyPink
    stroke.Thickness = 2
    stroke.Parent = panel

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = C.DustyPink
    title.BackgroundTransparency = 0.1
    title.BorderSizePixel = 0
    title.Text = "FASHION RUNWAY"
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
        uiController:hidePanel("fashion")
    end)

    -- Event status
    local eventStatus = Instance.new("TextLabel")
    eventStatus.Name = "EventStatus"
    eventStatus.Size = UDim2.new(1, -20, 0, 50)
    eventStatus.Position = UDim2.new(0, 10, 0, 48)
    eventStatus.BackgroundColor3 = Color3.fromRGB(240, 235, 245)
    eventStatus.BorderSizePixel = 0
    eventStatus.Text = "No event currently active.\nEvents run every 10 minutes!"
    eventStatus.TextColor3 = C.UIText
    eventStatus.TextScaled = true
    eventStatus.TextWrapped = true
    eventStatus.Font = Enum.Font.Gotham
    eventStatus.Parent = panel

    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 6)
    statusCorner.Parent = eventStatus

    -- Action buttons
    local joinBtn = Instance.new("TextButton")
    joinBtn.Name = "JoinBtn"
    joinBtn.Size = UDim2.new(0.45, 0, 0, 44)
    joinBtn.Position = UDim2.new(0.025, 0, 0, 108)
    joinBtn.BackgroundColor3 = C.UIPrimary
    joinBtn.Text = "Join Event"
    joinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    joinBtn.TextScaled = true
    joinBtn.Font = Enum.Font.GothamBold
    joinBtn.Parent = panel

    local joinCorner = Instance.new("UICorner")
    joinCorner.CornerRadius = UDim.new(0, 8)
    joinCorner.Parent = joinBtn

    joinBtn.MouseButton1Click:Connect(function()
        fashionController:joinEvent()
    end)

    local walkBtn = Instance.new("TextButton")
    walkBtn.Name = "WalkBtn"
    walkBtn.Size = UDim2.new(0.45, 0, 0, 44)
    walkBtn.Position = UDim2.new(0.525, 0, 0, 108)
    walkBtn.BackgroundColor3 = C.DustyPink
    walkBtn.Text = "Walk Runway"
    walkBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    walkBtn.TextScaled = true
    walkBtn.Font = Enum.Font.GothamBold
    walkBtn.Parent = panel

    local walkCorner = Instance.new("UICorner")
    walkCorner.CornerRadius = UDim.new(0, 8)
    walkCorner.Parent = walkBtn

    walkBtn.MouseButton1Click:Connect(function()
        fashionController:walkRunway()
    end)

    -- Outfit selection
    local outfitLabel = Instance.new("TextLabel")
    outfitLabel.Size = UDim2.new(1, -20, 0, 20)
    outfitLabel.Position = UDim2.new(0, 10, 0, 162)
    outfitLabel.BackgroundTransparency = 1
    outfitLabel.Text = "Outfits:"
    outfitLabel.TextColor3 = C.UIText
    outfitLabel.TextScaled = true
    outfitLabel.Font = Enum.Font.GothamBold
    outfitLabel.TextXAlignment = Enum.TextXAlignment.Left
    outfitLabel.Parent = panel

    local outfitScroll = Instance.new("ScrollingFrame")
    outfitScroll.Size = UDim2.new(1, -20, 0, 220)
    outfitScroll.Position = UDim2.new(0, 10, 0, 186)
    outfitScroll.BackgroundTransparency = 1
    outfitScroll.BorderSizePixel = 0
    outfitScroll.ScrollBarThickness = 4
    outfitScroll.CanvasSize = UDim2.new(0, 0, 0, #ItemCatalog.FashionOutfits * 48)
    outfitScroll.Parent = panel

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 4)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = outfitScroll

    for i, outfit in ipairs(ItemCatalog.FashionOutfits) do
        local itemFrame = Instance.new("Frame")
        itemFrame.Size = UDim2.new(1, -8, 0, 42)
        itemFrame.BackgroundColor3 = Color3.fromRGB(248, 244, 248)
        itemFrame.BorderSizePixel = 0
        itemFrame.LayoutOrder = i
        itemFrame.Parent = outfitScroll

        local itemCorner = Instance.new("UICorner")
        itemCorner.CornerRadius = UDim.new(0, 4)
        itemCorner.Parent = itemFrame

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.45, 0, 1, 0)
        nameLabel.Position = UDim2.new(0, 6, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = outfit.name
        nameLabel.TextColor3 = C.UIText
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = itemFrame

        local catLabel = Instance.new("TextLabel")
        catLabel.Size = UDim2.new(0.2, 0, 1, 0)
        catLabel.Position = UDim2.new(0.45, 0, 0, 0)
        catLabel.BackgroundTransparency = 1
        catLabel.Text = outfit.category
        catLabel.TextColor3 = C.DustyPink
        catLabel.TextScaled = true
        catLabel.Font = Enum.Font.Gotham
        catLabel.Parent = itemFrame

        local submitBtn = Instance.new("TextButton")
        submitBtn.Size = UDim2.new(0.28, 0, 0, 30)
        submitBtn.Position = UDim2.new(0.7, 0, 0, 6)
        submitBtn.BackgroundColor3 = C.DustyPink
        submitBtn.Text = "Wear"
        submitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        submitBtn.TextScaled = true
        submitBtn.Font = Enum.Font.GothamBold
        submitBtn.Parent = itemFrame

        local submitCorner = Instance.new("UICorner")
        submitCorner.CornerRadius = UDim.new(0, 4)
        submitCorner.Parent = submitBtn

        submitBtn.MouseButton1Click:Connect(function()
            fashionController:submitOutfit({
                name = outfit.name,
                category = outfit.category,
                items = { outfit.id },
            })
        end)
    end

    -- Update event status periodically
    task.spawn(function()
        while true do
            task.wait(2)
            local event = fashionController:getCurrentEvent()
            if event then
                eventStatus.Text = "ACTIVE: " .. event.theme ..
                    "\nJoin and walk the runway!"
                eventStatus.BackgroundColor3 = Color3.fromRGB(220, 255, 220)
            else
                eventStatus.Text = "No event currently active.\nEvents run every 10 minutes!"
                eventStatus.BackgroundColor3 = Color3.fromRGB(240, 235, 245)
            end
        end
    end)

    uiController:registerPanel("fashion", panel)
    print("[FashionUI] Built")
end

return FashionUI
