--[[
    LeaderboardUI.lua
    Leaderboard panel showing top players by SunCoins, Prestige,
    and Vibes Score. Tab-switching between boards. Auto-refreshes.
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig    = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteManager = require(ReplicatedStorage:WaitForChild("RemoteManager"))

local LeaderboardUI = {}
local C = GameConfig.Colors

function LeaderboardUI:build(screenGui: ScreenGui, uiController)
    local panel = Instance.new("Frame")
    panel.Name = "LeaderboardPanel"
    panel.Size = UDim2.new(0, 300, 0, 420)
    panel.Position = UDim2.new(0.3, 0, 0.15, 0)
    panel.BackgroundColor3 = C.UIBackground
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = panel

    local stroke = Instance.new("UIStroke")
    stroke.Color = C.UISunCoin
    stroke.Thickness = 2
    stroke.Parent = panel

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = C.UISunCoin
    title.BackgroundTransparency = 0.1
    title.BorderSizePixel = 0
    title.Text = "LEADERBOARDS"
    title.TextColor3 = Color3.fromRGB(50, 40, 0)
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
    closeBtn.TextColor3 = Color3.fromRGB(50, 40, 0)
    closeBtn.TextScaled = true
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = panel
    closeBtn.MouseButton1Click:Connect(function()
        uiController:hidePanel("leaderboard")
    end)

    -- Tab buttons
    local tabFrame = Instance.new("Frame")
    tabFrame.Size = UDim2.new(1, -16, 0, 34)
    tabFrame.Position = UDim2.new(0, 8, 0, 46)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Parent = panel

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabFrame

    local boards = { "SunCoins", "Prestige", "Vibes" }
    local tabColors = {
        SunCoins = C.UISunCoin,
        Prestige = C.DustyPink,
        Vibes    = C.Turquoise,
    }
    local tabBtns = {}
    local activeBoard = "SunCoins"

    -- Entry rows container
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "Entries"
    scrollFrame.Size = UDim2.new(1, -16, 1, -100)
    scrollFrame.Position = UDim2.new(0, 8, 0, 88)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.Parent = panel

    local entryLayout = Instance.new("UIListLayout")
    entryLayout.Padding = UDim.new(0, 2)
    entryLayout.SortOrder = Enum.SortOrder.LayoutOrder
    entryLayout.Parent = scrollFrame

    -- Function to populate entries
    local function populateBoard(boardName: string)
        -- Clear existing entries
        for _, child in ipairs(scrollFrame:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end

        -- Fetch from server
        local entries = RemoteManager:invokeServer("GetLeaderboard", boardName)
        if not entries or type(entries) ~= "table" then
            entries = {}
        end

        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #entries * 36)

        local localPlayer = Players.LocalPlayer

        for i, entry in ipairs(entries) do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, -4, 0, 32)
            row.BackgroundColor3 = (entry.userId == localPlayer.UserId)
                and Color3.fromRGB(230, 245, 230) or Color3.fromRGB(250, 250, 248)
            row.BorderSizePixel = 0
            row.LayoutOrder = i
            row.Parent = scrollFrame

            local rowCorner = Instance.new("UICorner")
            rowCorner.CornerRadius = UDim.new(0, 4)
            rowCorner.Parent = row

            -- Rank
            local rankLabel = Instance.new("TextLabel")
            rankLabel.Size = UDim2.new(0, 30, 1, 0)
            rankLabel.Position = UDim2.new(0, 4, 0, 0)
            rankLabel.BackgroundTransparency = 1
            rankLabel.Font = Enum.Font.GothamBold
            rankLabel.TextScaled = true
            rankLabel.TextColor3 = (i <= 3) and tabColors[boardName] or C.UIText
            rankLabel.Text = "#" .. tostring(i)
            rankLabel.Parent = row

            -- Name
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(0.55, 0, 1, 0)
            nameLabel.Position = UDim2.new(0, 38, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Font = Enum.Font.Gotham
            nameLabel.TextScaled = true
            nameLabel.TextColor3 = C.UIText
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Text = entry.name or "???"
            nameLabel.Parent = row

            -- Value
            local valLabel = Instance.new("TextLabel")
            valLabel.Size = UDim2.new(0.3, 0, 1, 0)
            valLabel.Position = UDim2.new(0.68, 0, 0, 0)
            valLabel.BackgroundTransparency = 1
            valLabel.Font = Enum.Font.GothamBold
            valLabel.TextScaled = true
            valLabel.TextColor3 = tabColors[boardName]
            valLabel.Text = tostring(entry.value or 0)
            valLabel.Parent = row
        end

        if #entries == 0 then
            local empty = Instance.new("TextLabel")
            empty.Size = UDim2.new(1, 0, 0, 40)
            empty.BackgroundTransparency = 1
            empty.Text = "No data yet — play to get on the board!"
            empty.TextColor3 = Color3.fromRGB(150, 150, 150)
            empty.TextScaled = true
            empty.Font = Enum.Font.Gotham
            empty.Parent = scrollFrame
        end
    end

    -- Create tab buttons
    for i, boardName in ipairs(boards) do
        local btn = Instance.new("TextButton")
        btn.Name = "Tab_" .. boardName
        btn.Size = UDim2.new(0.32, 0, 1, 0)
        btn.BackgroundColor3 = tabColors[boardName]
        btn.Text = boardName
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextScaled = true
        btn.Font = Enum.Font.GothamBold
        btn.LayoutOrder = i
        btn.Parent = tabFrame

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn

        tabBtns[boardName] = btn

        btn.MouseButton1Click:Connect(function()
            activeBoard = boardName
            -- Highlight active tab
            for name, b in pairs(tabBtns) do
                b.BackgroundTransparency = (name == boardName) and 0 or 0.5
            end
            populateBoard(boardName)
        end)
    end

    -- Set initial active tab
    for name, b in pairs(tabBtns) do
        b.BackgroundTransparency = (name == "SunCoins") and 0 or 0.5
    end

    -- Auto-refresh when panel becomes visible
    panel:GetPropertyChangedSignal("Visible"):Connect(function()
        if panel.Visible then
            populateBoard(activeBoard)
        end
    end)

    uiController:registerPanel("leaderboard", panel)
    print("[LeaderboardUI] Built")
end

return LeaderboardUI
