--[[
    EggClient.client.lua
    Client-side egg hatching UI controller.

    Responsibilities:
      - Display the player's egg inventory
      - Trigger HatchEgg remote events when the player selects an egg to hatch
      - Show animated hatching sequence (spin, crack, reveal)
      - Display hatched pet rarity with colour-coded result card
      - Update egg count labels in real time
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local EggConfig    = require(ReplicatedStorage:WaitForChild("EggConfig"))
local MulletConfig = require(ReplicatedStorage:WaitForChild("MulletConfig"))

local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")
local Remotes      = ReplicatedStorage:WaitForChild("Remotes", 15)

local evHatchEgg    = Remotes:WaitForChild("HatchEgg",       15) :: RemoteEvent
local evHatchResult = Remotes:WaitForChild("EggHatchResult", 15) :: RemoteEvent
local evNotify      = Remotes:WaitForChild("NotifyPlayer",   15) :: RemoteEvent

---------------------------------------------------------------------------
-- LOCAL STATE
---------------------------------------------------------------------------
local eggCounts: { [string]: number } = {}
local isHatching = false
local eggUiOpen  = false

---------------------------------------------------------------------------
-- UI CONSTRUCTION
---------------------------------------------------------------------------

local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "EggGui"
screenGui.ResetOnSpawn   = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Enabled        = false
screenGui.Parent         = PlayerGui

-- Background
local bg = Instance.new("Frame")
bg.Name              = "Background"
bg.Size              = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3  = Color3.fromRGB(0, 0, 0)
bg.BackgroundTransparency = 0.45
bg.BorderSizePixel   = 0
bg.Parent            = screenGui

-- Main panel
local panel = Instance.new("Frame")
panel.Name              = "EggPanel"
panel.Size              = UDim2.new(0, 640, 0, 460)
panel.Position          = UDim2.new(0.5, -320, 0.5, -230)
panel.BackgroundColor3  = MulletConfig.Colors.Background
panel.BackgroundTransparency = 0.05
panel.BorderSizePixel   = 0
panel.Parent            = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 14)
panelCorner.Parent = panel

-- Title
local titleBar = Instance.new("Frame")
titleBar.Size             = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundColor3 = MulletConfig.Colors.Secondary
titleBar.BorderSizePixel  = 0
titleBar.Parent           = panel

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 14)
titleCorner.Parent = titleBar

local titlePatch = Instance.new("Frame")
titlePatch.Size             = UDim2.new(1, 0, 0.5, 0)
titlePatch.Position         = UDim2.new(0, 0, 0.5, 0)
titlePatch.BackgroundColor3 = MulletConfig.Colors.Secondary
titlePatch.BorderSizePixel  = 0
titlePatch.Parent           = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size               = UDim2.new(0.8, 0, 1, 0)
titleLabel.Position           = UDim2.new(0, 16, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3         = MulletConfig.Colors.Background
titleLabel.Font               = Enum.Font.GothamBlack
titleLabel.TextScaled         = true
titleLabel.Text               = "🥚  EGG HATCHERY"
titleLabel.Parent             = titleBar

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

-- Egg grid
local eggScroll = Instance.new("ScrollingFrame")
eggScroll.Name              = "EggScroll"
eggScroll.Size              = UDim2.new(1, -20, 1, -70)
eggScroll.Position          = UDim2.new(0, 10, 0, 60)
eggScroll.BackgroundTransparency = 1
eggScroll.ScrollBarThickness = 6
eggScroll.BorderSizePixel   = 0
eggScroll.CanvasSize        = UDim2.new(0, 0, 0, 0)
eggScroll.Parent            = panel

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize    = UDim2.new(0, 140, 0, 160)
gridLayout.CellPadding = UDim2.new(0, 12, 0, 12)
gridLayout.SortOrder   = Enum.SortOrder.LayoutOrder
gridLayout.Parent      = eggScroll

-- Hatch result overlay
local resultFrame = Instance.new("Frame")
resultFrame.Name              = "ResultFrame"
resultFrame.Size              = UDim2.new(0, 400, 0, 260)
resultFrame.Position          = UDim2.new(0.5, -200, 0.5, -130)
resultFrame.BackgroundColor3  = Color3.fromRGB(20, 20, 20)
resultFrame.BackgroundTransparency = 0.1
resultFrame.BorderSizePixel   = 0
resultFrame.Visible           = false
resultFrame.Parent            = screenGui

local resultCorner = Instance.new("UICorner")
resultCorner.CornerRadius = UDim.new(0, 16)
resultCorner.Parent = resultFrame

local rarityLabel = Instance.new("TextLabel")
rarityLabel.Name              = "RarityLabel"
rarityLabel.Size              = UDim2.new(1, -16, 0, 44)
rarityLabel.Position          = UDim2.new(0, 8, 0, 10)
rarityLabel.BackgroundTransparency = 1
rarityLabel.TextColor3        = MulletConfig.Colors.Secondary
rarityLabel.Font              = Enum.Font.GothamBlack
rarityLabel.TextScaled        = true
rarityLabel.Text              = "LEGENDARY"
rarityLabel.Parent            = resultFrame

local petNameLabel = Instance.new("TextLabel")
petNameLabel.Name             = "PetNameLabel"
petNameLabel.Size             = UDim2.new(1, -16, 0, 36)
petNameLabel.Position         = UDim2.new(0, 8, 0, 58)
petNameLabel.BackgroundTransparency = 1
petNameLabel.TextColor3       = MulletConfig.Colors.Text
petNameLabel.Font             = Enum.Font.GothamBold
petNameLabel.TextScaled       = true
petNameLabel.Text             = ""
petNameLabel.Parent           = resultFrame

local statsLabel = Instance.new("TextLabel")
statsLabel.Name              = "StatsLabel"
statsLabel.Size              = UDim2.new(1, -16, 0, 80)
statsLabel.Position          = UDim2.new(0, 8, 0, 100)
statsLabel.BackgroundTransparency = 1
statsLabel.TextColor3        = Color3.fromRGB(200, 200, 200)
statsLabel.Font              = Enum.Font.Gotham
statsLabel.TextScaled        = true
statsLabel.TextWrapped       = true
statsLabel.Text              = ""
statsLabel.Parent            = resultFrame

local dismissBtn = Instance.new("TextButton")
dismissBtn.Size              = UDim2.new(0.6, 0, 0, 40)
dismissBtn.Position          = UDim2.new(0.2, 0, 1, -50)
dismissBtn.BackgroundColor3  = MulletConfig.Colors.Primary
dismissBtn.BorderSizePixel   = 0
dismissBtn.Text              = "Awesome!"
dismissBtn.TextColor3        = MulletConfig.Colors.Text
dismissBtn.Font              = Enum.Font.GothamBold
dismissBtn.TextScaled        = true
dismissBtn.Parent            = resultFrame

local dismissCorner = Instance.new("UICorner")
dismissCorner.CornerRadius = UDim.new(0, 8)
dismissCorner.Parent = dismissBtn

---------------------------------------------------------------------------
-- EGG CARD BUILDER
---------------------------------------------------------------------------

local eggCards: { [string]: Frame } = {}

local function buildEggCard(eggId: string, eggDef: table, index: number): Frame
    local card = Instance.new("Frame")
    card.Name             = eggId
    card.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    card.BorderSizePixel  = 0
    card.LayoutOrder      = index
    card.Parent           = eggScroll

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 10)
    cardCorner.Parent = card

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size               = UDim2.new(1, -8, 0, 28)
    nameLabel.Position           = UDim2.new(0, 4, 0, 4)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3         = MulletConfig.Colors.Secondary
    nameLabel.Font               = Enum.Font.GothamBold
    nameLabel.TextScaled         = true
    nameLabel.Text               = eggDef.name
    nameLabel.Parent             = card

    local countLabel = Instance.new("TextLabel")
    countLabel.Name              = "CountLabel"
    countLabel.Size              = UDim2.new(1, -8, 0, 22)
    countLabel.Position          = UDim2.new(0, 4, 0, 36)
    countLabel.BackgroundTransparency = 1
    countLabel.TextColor3        = Color3.fromRGB(180, 180, 180)
    countLabel.Font              = Enum.Font.Gotham
    countLabel.TextScaled        = true
    countLabel.Text              = "×" .. (eggCounts[eggId] or 0)
    countLabel.Parent            = card

    local hatchBtn = Instance.new("TextButton")
    hatchBtn.Size              = UDim2.new(1, -12, 0, 34)
    hatchBtn.Position          = UDim2.new(0, 6, 1, -40)
    hatchBtn.BackgroundColor3  = MulletConfig.Colors.Primary
    hatchBtn.BorderSizePixel   = 0
    hatchBtn.Text              = "Hatch!"
    hatchBtn.TextColor3        = MulletConfig.Colors.Text
    hatchBtn.Font              = Enum.Font.GothamBold
    hatchBtn.TextScaled        = true
    hatchBtn.Parent            = card

    local hatchCorner = Instance.new("UICorner")
    hatchCorner.CornerRadius = UDim.new(0, 6)
    hatchCorner.Parent = hatchBtn

    hatchBtn.MouseButton1Click:Connect(function()
        if isHatching then return end
        local count = eggCounts[eggId] or 0
        if count < 1 then
            evNotify:FireServer()  -- won't fire; just visual guard
            return
        end

        isHatching = true
        hatchBtn.Text = "Hatching..."
        hatchBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        eggCounts[eggId] = math.max(0, count - 1)
        countLabel.Text = "×" .. eggCounts[eggId]

        evHatchEgg:FireServer(eggId)
    end)

    eggCards[eggId] = card
    return card
end

local function refreshEggCards()
    for _, child in ipairs(eggScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    eggCards = {}

    local i = 1
    for eggId, eggDef in pairs(EggConfig.Eggs) do
        buildEggCard(eggId, eggDef, i)
        i += 1
    end

    local rows = math.ceil(i / 4)
    eggScroll.CanvasSize = UDim2.new(0, 0, 0, rows * 172 + 12)
end

---------------------------------------------------------------------------
-- HATCH RESULT DISPLAY
---------------------------------------------------------------------------

local rarityColors = {
    Common    = Color3.fromRGB(180, 180, 180),
    Uncommon  = Color3.fromRGB(80, 200, 80),
    Rare      = Color3.fromRGB(80, 120, 255),
    Epic      = Color3.fromRGB(160, 60, 220),
    Legendary = Color3.fromRGB(255, 180, 0),
}

local function showHatchResult(data: table)
    local rarityColor = rarityColors[data.rarity] or MulletConfig.Colors.Text
    rarityLabel.Text      = data.rarity:upper()
    rarityLabel.TextColor3 = rarityColor
    resultFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)

    petNameLabel.Text = data.petName or data.petId

    local stats = {}
    if data.coinBonus and data.coinBonus > 0 then
        table.insert(stats, string.format("🪙 +%.0f%% coins", data.coinBonus * 100))
    end
    if data.speedBonus and data.speedBonus > 0 then
        table.insert(stats, string.format("⚡ +%.0f%% speed", data.speedBonus * 100))
    end
    if data.damageBonus and data.damageBonus > 0 then
        table.insert(stats, string.format("⚔ +%.0f%% damage", data.damageBonus * 100))
    end
    statsLabel.Text = #stats > 0 and table.concat(stats, "   ") or "No combat bonuses."

    resultFrame.Visible = true

    -- Pulse animation
    TweenService:Create(resultFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, 420, 0, 280),
        Position = UDim2.new(0.5, -210, 0.5, -140),
    }):Play()
end

dismissBtn.MouseButton1Click:Connect(function()
    resultFrame.Visible = false
    resultFrame.Size     = UDim2.new(0, 400, 0, 260)
    resultFrame.Position = UDim2.new(0.5, -200, 0.5, -130)
    isHatching = false

    -- Refresh count labels
    for eggId, card in pairs(eggCards) do
        local countLabel = card:FindFirstChild("CountLabel") :: TextLabel?
        if countLabel then
            countLabel.Text = "×" .. (eggCounts[eggId] or 0)
        end
        local hatchBtn = card:FindFirstChildOfClass("TextButton") :: TextButton?
        if hatchBtn then
            hatchBtn.Text = "Hatch!"
            hatchBtn.BackgroundColor3 = MulletConfig.Colors.Primary
        end
    end
end)

---------------------------------------------------------------------------
-- OPEN / CLOSE
---------------------------------------------------------------------------

local function openEggUI()
    if eggUiOpen then return end
    eggUiOpen = true
    refreshEggCards()
    screenGui.Enabled = true
end

local function closeEggUI()
    eggUiOpen = false
    screenGui.Enabled = false
end

closeBtn.MouseButton1Click:Connect(closeEggUI)
bg.InputBegan:Connect(function(input: InputObject)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        closeEggUI()
    end
end)

-- Press "E" to toggle egg UI
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.E then
        if eggUiOpen then closeEggUI() else openEggUI() end
    end
end)

---------------------------------------------------------------------------
-- REMOTE EVENT LISTENERS
---------------------------------------------------------------------------

evHatchResult.OnClientEvent:Connect(function(data: table)
    showHatchResult(data)
    -- Update count from server result
    if data.eggId then
        eggCounts[data.eggId] = math.max(0, (eggCounts[data.eggId] or 0))
    end
end)

print("[EggClient] Initialized (press E to open egg UI)")
