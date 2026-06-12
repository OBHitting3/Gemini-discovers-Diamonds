--[[
    EventUI.lua
    Event notifications and info panel: current event banner,
    Modernism Week special display, event bonuses summary.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig    = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteManager = require(ReplicatedStorage:WaitForChild("RemoteManager"))

local EventUI = {}
local C = GameConfig.Colors

function EventUI:build(screenGui: ScreenGui, uiController)
    local panel = Instance.new("Frame")
    panel.Name = "EventPanel"
    panel.Size = UDim2.new(0, 320, 0, 350)
    panel.Position = UDim2.new(0.3, 0, 0.15, 0)
    panel.BackgroundColor3 = C.UIBackground
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = panel

    local stroke = Instance.new("UIStroke")
    stroke.Color = C.Turquoise
    stroke.Thickness = 2
    stroke.Parent = panel

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = C.Turquoise
    title.BackgroundTransparency = 0.1
    title.BorderSizePixel = 0
    title.Text = "EVENTS & FESTIVALS"
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
        uiController:hidePanel("event")
    end)

    -- Current event display
    local currentEventFrame = Instance.new("Frame")
    currentEventFrame.Name = "CurrentEvent"
    currentEventFrame.Size = UDim2.new(1, -20, 0, 70)
    currentEventFrame.Position = UDim2.new(0, 10, 0, 50)
    currentEventFrame.BackgroundColor3 = Color3.fromRGB(240, 252, 250)
    currentEventFrame.BorderSizePixel = 0
    currentEventFrame.Parent = panel

    local eventCorner = Instance.new("UICorner")
    eventCorner.CornerRadius = UDim.new(0, 8)
    eventCorner.Parent = currentEventFrame

    local eventName = Instance.new("TextLabel")
    eventName.Name = "EventName"
    eventName.Size = UDim2.new(1, -12, 0, 30)
    eventName.Position = UDim2.new(0, 6, 0, 5)
    eventName.BackgroundTransparency = 1
    eventName.Text = "No Active Event"
    eventName.TextColor3 = C.UIText
    eventName.TextScaled = true
    eventName.Font = Enum.Font.GothamBold
    eventName.TextXAlignment = Enum.TextXAlignment.Left
    eventName.Parent = currentEventFrame

    local eventDesc = Instance.new("TextLabel")
    eventDesc.Name = "EventDesc"
    eventDesc.Size = UDim2.new(1, -12, 0, 28)
    eventDesc.Position = UDim2.new(0, 6, 0, 35)
    eventDesc.BackgroundTransparency = 1
    eventDesc.Text = "Events rotate automatically"
    eventDesc.TextColor3 = Color3.fromRGB(100, 100, 100)
    eventDesc.TextScaled = true
    eventDesc.TextWrapped = true
    eventDesc.Font = Enum.Font.Gotham
    eventDesc.TextXAlignment = Enum.TextXAlignment.Left
    eventDesc.Parent = currentEventFrame

    -- Modernism Week banner
    local mwBanner = Instance.new("Frame")
    mwBanner.Name = "ModernismWeekBanner"
    mwBanner.Size = UDim2.new(1, -20, 0, 60)
    mwBanner.Position = UDim2.new(0, 10, 0, 130)
    mwBanner.BackgroundColor3 = Color3.fromRGB(250, 245, 230)
    mwBanner.BorderSizePixel = 0
    mwBanner.Parent = panel

    local mwCorner = Instance.new("UICorner")
    mwCorner.CornerRadius = UDim.new(0, 8)
    mwCorner.Parent = mwBanner

    local mwStroke = Instance.new("UIStroke")
    mwStroke.Color = C.Terracotta
    mwStroke.Thickness = 1.5
    mwStroke.Parent = mwBanner

    local mwTitle = Instance.new("TextLabel")
    mwTitle.Size = UDim2.new(1, -12, 0, 25)
    mwTitle.Position = UDim2.new(0, 6, 0, 5)
    mwTitle.BackgroundTransparency = 1
    mwTitle.Text = "MODERNISM WEEK 2026"
    mwTitle.TextColor3 = C.Terracotta
    mwTitle.TextScaled = true
    mwTitle.Font = Enum.Font.GothamBold
    mwTitle.TextXAlignment = Enum.TextXAlignment.Left
    mwTitle.Parent = mwBanner

    local mwDate = Instance.new("TextLabel")
    mwDate.Name = "MWDate"
    mwDate.Size = UDim2.new(1, -12, 0, 22)
    mwDate.Position = UDim2.new(0, 6, 0, 32)
    mwDate.BackgroundTransparency = 1
    mwDate.Text = "Feb 12-22 | Limited MCM drops + 2x Prestige"
    mwDate.TextColor3 = Color3.fromRGB(120, 100, 80)
    mwDate.TextScaled = true
    mwDate.Font = Enum.Font.Gotham
    mwDate.TextXAlignment = Enum.TextXAlignment.Left
    mwDate.Parent = mwBanner

    -- Theme list
    local themeLabel = Instance.new("TextLabel")
    themeLabel.Size = UDim2.new(1, -20, 0, 20)
    themeLabel.Position = UDim2.new(0, 10, 0, 200)
    themeLabel.BackgroundTransparency = 1
    themeLabel.Text = "Event Themes Rotation:"
    themeLabel.TextColor3 = C.UIText
    themeLabel.TextScaled = true
    themeLabel.Font = Enum.Font.GothamBold
    themeLabel.TextXAlignment = Enum.TextXAlignment.Left
    themeLabel.Parent = panel

    local themeScroll = Instance.new("ScrollingFrame")
    themeScroll.Size = UDim2.new(1, -20, 0, 120)
    themeScroll.Position = UDim2.new(0, 10, 0, 224)
    themeScroll.BackgroundTransparency = 1
    themeScroll.BorderSizePixel = 0
    themeScroll.ScrollBarThickness = 4
    themeScroll.CanvasSize = UDim2.new(0, 0, 0, #GameConfig.EventThemes * 36)
    themeScroll.Parent = panel

    local themeList = Instance.new("UIListLayout")
    themeList.Padding = UDim.new(0, 3)
    themeList.SortOrder = Enum.SortOrder.LayoutOrder
    themeList.Parent = themeScroll

    for i, theme in ipairs(GameConfig.EventThemes) do
        local themeItem = Instance.new("Frame")
        themeItem.Size = UDim2.new(1, -4, 0, 32)
        themeItem.BackgroundColor3 = Color3.fromRGB(248, 248, 245)
        themeItem.BorderSizePixel = 0
        themeItem.LayoutOrder = i
        themeItem.Parent = themeScroll

        local themeItemCorner = Instance.new("UICorner")
        themeItemCorner.CornerRadius = UDim.new(0, 4)
        themeItemCorner.Parent = themeItem

        local themeNameLabel = Instance.new("TextLabel")
        themeNameLabel.Size = UDim2.new(0.4, 0, 1, 0)
        themeNameLabel.Position = UDim2.new(0, 6, 0, 0)
        themeNameLabel.BackgroundTransparency = 1
        themeNameLabel.Text = theme.name
        themeNameLabel.TextColor3 = C.UIText
        themeNameLabel.TextScaled = true
        themeNameLabel.Font = Enum.Font.GothamBold
        themeNameLabel.TextXAlignment = Enum.TextXAlignment.Left
        themeNameLabel.Parent = themeItem

        local themeDescLabel = Instance.new("TextLabel")
        themeDescLabel.Size = UDim2.new(0.55, 0, 1, 0)
        themeDescLabel.Position = UDim2.new(0.42, 0, 0, 0)
        themeDescLabel.BackgroundTransparency = 1
        themeDescLabel.Text = theme.description
        themeDescLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
        themeDescLabel.TextScaled = true
        themeDescLabel.TextWrapped = true
        themeDescLabel.Font = Enum.Font.Gotham
        themeDescLabel.TextXAlignment = Enum.TextXAlignment.Left
        themeDescLabel.Parent = themeItem
    end

    -- Listen for event broadcasts to update the display
    local eventBroadcast = RemoteManager:getEvent("EventBroadcast")
    if eventBroadcast then
        eventBroadcast.OnClientEvent:Connect(function(data)
            if data.action == "start" and data.event then
                eventName.Text = data.event.name
                eventDesc.Text = data.event.description or ""
                currentEventFrame.BackgroundColor3 = Color3.fromRGB(220, 255, 220)
            elseif data.action == "end" then
                eventName.Text = "No Active Event"
                eventDesc.Text = "Events rotate automatically"
                currentEventFrame.BackgroundColor3 = Color3.fromRGB(240, 252, 250)
            end
        end)
    end

    uiController:registerPanel("event", panel)
    print("[EventUI] Built")
end

return EventUI
