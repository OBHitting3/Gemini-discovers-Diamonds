--[[
    ZoneClient.client.lua
    Client-side zone selection and wave HUD controller.

    Responsibilities:
      - Display a zone map/selector UI (press M to open)
      - Show zone name, unlock cost, current wave, and coin drop multiplier
      - Fire EnterZone remote event when the player picks a zone
      - Listen for WaveStarted, WaveCompleted, BossSpawned, BossDefeated events
        and update the wave HUD accordingly
      - Show a boss health bar during boss waves
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

local ZoneConfig   = require(ReplicatedStorage:WaitForChild("ZoneConfig"))
local MulletConfig = require(ReplicatedStorage:WaitForChild("MulletConfig"))

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local Remotes     = ReplicatedStorage:WaitForChild("Remotes", 15)

local evEnterZone     = Remotes:WaitForChild("EnterZone",     15) :: RemoteEvent
local evWaveStarted   = Remotes:WaitForChild("WaveStarted",   15) :: RemoteEvent
local evWaveCompleted = Remotes:WaitForChild("WaveCompleted",  15) :: RemoteEvent
local evBossSpawned   = Remotes:WaitForChild("BossSpawned",   15) :: RemoteEvent
local evBossDefeated  = Remotes:WaitForChild("BossDefeated",  15) :: RemoteEvent
local evZoneUnlocked  = Remotes:WaitForChild("ZoneUnlocked",  15) :: RemoteEvent
local evNotify        = Remotes:WaitForChild("NotifyPlayer",  15) :: RemoteEvent
local fnGetZoneData   = Remotes:WaitForChild("GetZoneData",   15) :: RemoteFunction

---------------------------------------------------------------------------
-- STATE
---------------------------------------------------------------------------
local zoneMapOpen   = false
local currentZoneId = "zone_barbershop"
local localCoins    = 0      -- synced from UpdateCoins event (shared listener)

---------------------------------------------------------------------------
-- WAVE HUD
---------------------------------------------------------------------------

local waveGui = Instance.new("ScreenGui")
waveGui.Name           = "ZoneWaveHUD"
waveGui.ResetOnSpawn   = false
waveGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
waveGui.Parent         = PlayerGui

-- Zone name (top-centre)
local zoneLabel = Instance.new("TextLabel")
zoneLabel.Name               = "ZoneLabel"
zoneLabel.Size               = UDim2.new(0, 280, 0, 30)
zoneLabel.Position           = UDim2.new(0.5, -140, 0, 8)
zoneLabel.BackgroundTransparency = 1
zoneLabel.TextColor3         = MulletConfig.Colors.Secondary
zoneLabel.Font               = Enum.Font.GothamBold
zoneLabel.TextScaled         = true
zoneLabel.Text               = "Zone: The Old Barbershop"
zoneLabel.Parent             = waveGui

-- Wave indicator (below zone label)
local waveLabel = Instance.new("TextLabel")
waveLabel.Name               = "WaveLabel"
waveLabel.Size               = UDim2.new(0, 240, 0, 26)
waveLabel.Position           = UDim2.new(0.5, -120, 0, 40)
waveLabel.BackgroundTransparency = 1
waveLabel.TextColor3         = MulletConfig.Colors.Text
waveLabel.Font               = Enum.Font.Gotham
waveLabel.TextScaled         = true
waveLabel.Text               = "Wave: — / —"
waveLabel.Parent             = waveGui

-- Boss health bar (hidden by default)
local bossBarFrame = Instance.new("Frame")
bossBarFrame.Name              = "BossBarFrame"
bossBarFrame.Size              = UDim2.new(0, 440, 0, 34)
bossBarFrame.Position          = UDim2.new(0.5, -220, 0, 74)
bossBarFrame.BackgroundColor3  = Color3.fromRGB(60, 0, 0)
bossBarFrame.BackgroundTransparency = 0.2
bossBarFrame.BorderSizePixel   = 0
bossBarFrame.Visible           = false
bossBarFrame.Parent            = waveGui

local bossBarCorner = Instance.new("UICorner")
bossBarCorner.CornerRadius = UDim.new(0, 6)
bossBarCorner.Parent = bossBarFrame

local bossHealthFill = Instance.new("Frame")
bossHealthFill.Name             = "HealthFill"
bossHealthFill.Size             = UDim2.new(1, 0, 1, 0)
bossHealthFill.BackgroundColor3 = MulletConfig.Colors.Danger
bossHealthFill.BorderSizePixel  = 0
bossHealthFill.Parent           = bossBarFrame

local bossHealthCorner = Instance.new("UICorner")
bossHealthCorner.CornerRadius = UDim.new(0, 6)
bossHealthCorner.Parent = bossHealthFill

local bossNameLabel = Instance.new("TextLabel")
bossNameLabel.Size               = UDim2.new(1, -8, 1, 0)
bossNameLabel.Position           = UDim2.new(0, 4, 0, 0)
bossNameLabel.BackgroundTransparency = 1
bossNameLabel.TextColor3         = Color3.fromRGB(255, 255, 255)
bossNameLabel.Font               = Enum.Font.GothamBold
bossNameLabel.TextScaled         = true
bossNameLabel.Text               = "BOSS"
bossNameLabel.ZIndex             = 2
bossNameLabel.Parent             = bossBarFrame

---------------------------------------------------------------------------
-- ZONE MAP UI
---------------------------------------------------------------------------

local zoneGui = Instance.new("ScreenGui")
zoneGui.Name           = "ZoneMapGui"
zoneGui.ResetOnSpawn   = false
zoneGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
zoneGui.Enabled        = false
zoneGui.Parent         = PlayerGui

local mapBg = Instance.new("Frame")
mapBg.Name              = "MapBackground"
mapBg.Size              = UDim2.new(1, 0, 1, 0)
mapBg.BackgroundColor3  = Color3.fromRGB(0, 0, 0)
mapBg.BackgroundTransparency = 0.45
mapBg.BorderSizePixel   = 0
mapBg.Parent            = zoneGui

local mapPanel = Instance.new("Frame")
mapPanel.Name              = "MapPanel"
mapPanel.Size              = UDim2.new(0, 680, 0, 500)
mapPanel.Position          = UDim2.new(0.5, -340, 0.5, -250)
mapPanel.BackgroundColor3  = MulletConfig.Colors.Background
mapPanel.BackgroundTransparency = 0.05
mapPanel.BorderSizePixel   = 0
mapPanel.Parent            = zoneGui

local mapCorner = Instance.new("UICorner")
mapCorner.CornerRadius = UDim.new(0, 14)
mapCorner.Parent = mapPanel

-- Title
local mapTitle = Instance.new("Frame")
mapTitle.Size             = UDim2.new(1, 0, 0, 50)
mapTitle.BackgroundColor3 = MulletConfig.Colors.Accent
mapTitle.BorderSizePixel  = 0
mapTitle.Parent           = mapPanel

local mapTitleCorner = Instance.new("UICorner")
mapTitleCorner.CornerRadius = UDim.new(0, 14)
mapTitleCorner.Parent = mapTitle

local mapTitlePatch = Instance.new("Frame")
mapTitlePatch.Size             = UDim2.new(1, 0, 0.5, 0)
mapTitlePatch.Position         = UDim2.new(0, 0, 0.5, 0)
mapTitlePatch.BackgroundColor3 = MulletConfig.Colors.Accent
mapTitlePatch.BorderSizePixel  = 0
mapTitlePatch.Parent           = mapTitle

local mapTitleLabel = Instance.new("TextLabel")
mapTitleLabel.Size               = UDim2.new(0.8, 0, 1, 0)
mapTitleLabel.Position           = UDim2.new(0, 16, 0, 0)
mapTitleLabel.BackgroundTransparency = 1
mapTitleLabel.TextColor3         = MulletConfig.Colors.Text
mapTitleLabel.Font               = Enum.Font.GothamBlack
mapTitleLabel.TextScaled         = true
mapTitleLabel.Text               = "🗺  ZONE SELECT"
mapTitleLabel.Parent             = mapTitle

local mapClose = Instance.new("TextButton")
mapClose.Size               = UDim2.new(0, 36, 0, 36)
mapClose.Position           = UDim2.new(1, -44, 0, 7)
mapClose.BackgroundColor3   = Color3.fromRGB(180, 50, 50)
mapClose.BorderSizePixel    = 0
mapClose.Text               = "✕"
mapClose.TextColor3         = Color3.fromRGB(255, 255, 255)
mapClose.Font               = Enum.Font.GothamBold
mapClose.TextScaled         = true
mapClose.Parent             = mapTitle

local mapCloseCorner = Instance.new("UICorner")
mapCloseCorner.CornerRadius = UDim.new(0, 6)
mapCloseCorner.Parent = mapClose

-- Zone list scroll
local zoneScroll = Instance.new("ScrollingFrame")
zoneScroll.Name              = "ZoneScroll"
zoneScroll.Size              = UDim2.new(1, -20, 1, -62)
zoneScroll.Position          = UDim2.new(0, 10, 0, 58)
zoneScroll.BackgroundTransparency = 1
zoneScroll.ScrollBarThickness = 6
zoneScroll.BorderSizePixel   = 0
zoneScroll.CanvasSize        = UDim2.new(0, 0, 0, 0)
zoneScroll.Parent            = mapPanel

local zoneListLayout = Instance.new("UIListLayout")
zoneListLayout.SortOrder = Enum.SortOrder.LayoutOrder
zoneListLayout.Padding   = UDim.new(0, 8)
zoneListLayout.Parent    = zoneScroll

---------------------------------------------------------------------------
-- ZONE CARD BUILDER
---------------------------------------------------------------------------

local function buildZoneCard(zoneData: table, index: number): Frame
    local isUnlocked = zoneData.isUnlocked
    local isCurrent  = zoneData.isCurrent

    local card = Instance.new("Frame")
    card.Name             = zoneData.id
    card.Size             = UDim2.new(1, -10, 0, 80)
    card.BackgroundColor3 = isCurrent
        and Color3.fromRGB(40, 60, 40)
        or  Color3.fromRGB(35, 35, 35)
    card.BorderSizePixel  = 0
    card.LayoutOrder      = index
    card.Parent           = zoneScroll

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card

    -- Zone name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size               = UDim2.new(0.55, 0, 0, 28)
    nameLabel.Position           = UDim2.new(0, 10, 0, 8)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3         = isUnlocked
        and MulletConfig.Colors.Text
        or  Color3.fromRGB(120, 120, 120)
    nameLabel.Font               = Enum.Font.GothamBold
    nameLabel.TextScaled         = true
    nameLabel.TextXAlignment     = Enum.TextXAlignment.Left
    nameLabel.Text               = zoneData.name
    nameLabel.Parent             = card

    -- Description
    local descLabel = Instance.new("TextLabel")
    descLabel.Size               = UDim2.new(0.55, 0, 0, 34)
    descLabel.Position           = UDim2.new(0, 10, 0, 38)
    descLabel.BackgroundTransparency = 1
    descLabel.TextColor3         = Color3.fromRGB(160, 160, 160)
    descLabel.Font               = Enum.Font.Gotham
    descLabel.TextScaled         = true
    descLabel.TextXAlignment     = Enum.TextXAlignment.Left
    descLabel.TextWrapped        = true
    descLabel.Text               = zoneData.description or ""
    descLabel.Parent             = card

    -- Coin drop mult label
    local multLabel = Instance.new("TextLabel")
    multLabel.Size               = UDim2.new(0.2, 0, 0, 24)
    multLabel.Position           = UDim2.new(0.56, 0, 0, 10)
    multLabel.BackgroundTransparency = 1
    multLabel.TextColor3         = MulletConfig.Colors.Coin
    multLabel.Font               = Enum.Font.GothamBold
    multLabel.TextScaled         = true
    multLabel.Text               = "×" .. (zoneData.coinDropMult or 1)
    multLabel.Parent             = card

    local multSub = Instance.new("TextLabel")
    multSub.Size               = UDim2.new(0.2, 0, 0, 18)
    multSub.Position           = UDim2.new(0.56, 0, 0, 34)
    multSub.BackgroundTransparency = 1
    multSub.TextColor3         = Color3.fromRGB(150, 150, 150)
    multSub.Font               = Enum.Font.Gotham
    multSub.TextScaled         = true
    multSub.Text               = "coin mult"
    multSub.Parent             = card

    -- Wave label
    local waveInfo = Instance.new("TextLabel")
    waveInfo.Size               = UDim2.new(0.2, 0, 0, 24)
    waveInfo.Position           = UDim2.new(0.56, 0, 0, 52)
    waveInfo.BackgroundTransparency = 1
    waveInfo.TextColor3         = Color3.fromRGB(160, 160, 200)
    waveInfo.Font               = Enum.Font.Gotham
    waveInfo.TextScaled         = true
    waveInfo.Text               = "Wave " .. (zoneData.waveNumber or 0)
    waveInfo.Parent             = card

    -- Enter / Unlock button
    local actionBtn = Instance.new("TextButton")
    actionBtn.Size              = UDim2.new(0.19, 0, 0, 46)
    actionBtn.Position          = UDim2.new(0.8, 0, 0.5, -23)
    actionBtn.BorderSizePixel   = 0
    actionBtn.Font              = Enum.Font.GothamBold
    actionBtn.TextScaled        = true
    actionBtn.TextColor3        = MulletConfig.Colors.Text
    actionBtn.Parent            = card

    local actionCorner = Instance.new("UICorner")
    actionCorner.CornerRadius = UDim.new(0, 8)
    actionCorner.Parent = actionBtn

    if isCurrent then
        actionBtn.Text            = "Current"
        actionBtn.BackgroundColor3 = Color3.fromRGB(60, 130, 60)
        actionBtn.Active          = false
    elseif isUnlocked then
        actionBtn.Text            = "Enter"
        actionBtn.BackgroundColor3 = MulletConfig.Colors.Primary
    else
        actionBtn.Text            = "🪙 " .. (zoneData.unlockCoins or 0)
        actionBtn.BackgroundColor3 = MulletConfig.Colors.Accent
    end

    actionBtn.MouseButton1Click:Connect(function()
        evEnterZone:FireServer(zoneData.id)
        currentZoneId = zoneData.id
        local zoneDef = ZoneConfig.getZone(zoneData.id)
        if zoneDef then
            zoneLabel.Text = "Zone: " .. zoneDef.name
        end
        -- Close map after entering
        zoneGui.Enabled = false
        zoneMapOpen = false
    end)

    return card
end

---------------------------------------------------------------------------
-- POPULATE MAP
---------------------------------------------------------------------------

local function openZoneMap()
    if zoneMapOpen then return end
    zoneMapOpen = true
    zoneGui.Enabled = true

    -- Clear
    for _, child in ipairs(zoneScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    -- Fetch zone data
    local ok, zones = pcall(function()
        return fnGetZoneData:InvokeServer()
    end)

    local zoneList = (ok and zones) or {}

    -- Fall back to config if RPC fails
    if #zoneList == 0 then
        for i, zone in ipairs(ZoneConfig.Zones) do
            zoneList[i] = {
                id          = zone.id,
                name        = zone.name,
                description = zone.description,
                unlockCoins = zone.unlockCoins,
                isUnlocked  = zone.unlockCoins == 0,
                isCurrent   = zone.id == currentZoneId,
                waveNumber  = 0,
                coinDropMult = zone.coinDropMult,
            }
        end
    end

    for i, zoneData in ipairs(zoneList) do
        buildZoneCard(zoneData, i)
    end

    local totalHeight = #zoneList * 88
    zoneScroll.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
end

local function closeZoneMap()
    zoneMapOpen = false
    zoneGui.Enabled = false
end

mapClose.MouseButton1Click:Connect(closeZoneMap)
mapBg.InputBegan:Connect(function(input: InputObject)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        closeZoneMap()
    end
end)

-- Press "M" to toggle zone map
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.M then
        if zoneMapOpen then closeZoneMap() else openZoneMap() end
    end
end)

---------------------------------------------------------------------------
-- WAVE EVENT LISTENERS
---------------------------------------------------------------------------

evWaveStarted.OnClientEvent:Connect(function(data: table)
    waveLabel.Text = ("Wave: %d / %d%s"):format(
        data.waveNumber or 0,
        MulletConfig.Waves.MaxWaves,
        data.isBoss and "  [BOSS!]" or ""
    )
    if data.isBoss then
        waveLabel.TextColor3 = MulletConfig.Colors.Danger
    else
        waveLabel.TextColor3 = MulletConfig.Colors.Text
    end
end)

evWaveCompleted.OnClientEvent:Connect(function(data: table)
    waveLabel.TextColor3 = MulletConfig.Colors.Accent
    waveLabel.Text = ("Wave %d Complete! 🪙+%d"):format(
        data.waveNumber or 0,
        MulletConfig.Economy.CoinPerWave
    )
    task.delay(3, function()
        waveLabel.TextColor3 = MulletConfig.Colors.Text
    end)
end)

evBossSpawned.OnClientEvent:Connect(function(data: table)
    bossNameLabel.Text = "⚠ " .. (data.bossName or "BOSS") .. " ⚠"
    bossHealthFill.Size = UDim2.new(1, 0, 1, 0)
    bossBarFrame.Visible = true
end)

evBossDefeated.OnClientEvent:Connect(function(_data: table)
    TweenService:Create(bossHealthFill, TweenInfo.new(0.5), {
        Size = UDim2.new(0, 0, 1, 0),
    }):Play()
    task.delay(1.2, function()
        bossBarFrame.Visible = false
    end)
end)

evZoneUnlocked.OnClientEvent:Connect(function(data: table)
    -- Refresh map if open
    if zoneMapOpen then
        closeZoneMap()
        task.wait(0.1)
        openZoneMap()
    end
end)

---------------------------------------------------------------------------
-- SYNC COIN BALANCE (reuse UpdateCoins event)
---------------------------------------------------------------------------
local evCoinsUpdate = Remotes:WaitForChild("UpdateCoins", 15) :: RemoteEvent
evCoinsUpdate.OnClientEvent:Connect(function(newBalance: number)
    localCoins = newBalance
end)

print("[ZoneClient] Initialized (press M to open zone map)")
