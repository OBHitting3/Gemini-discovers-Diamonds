--[[
    UIController.lua
    Master GUI manager for Palm Springs Paradise client.
    Creates and manages all ScreenGui instances, panel toggling,
    toast notifications, and HUD updates.
]]

local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig    = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteManager = require(ReplicatedStorage:WaitForChild("RemoteManager"))

local UIController = {}

-- References
UIController._screenGui = nil
UIController._panels = {}          -- panelName → Frame
UIController._activePanel = nil
UIController._hudFrame = nil
UIController._notificationQueue = {}
UIController._isProcessingNotifications = false

-- UI state
UIController._coinDisplay = nil
UIController._prestigeDisplay = nil
UIController._levelDisplay = nil

---------------------------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------------------------

function UIController:init(screenGui: ScreenGui)
    self._screenGui = screenGui

    -- Listen for server notifications
    local notifyEvent = RemoteManager:getEvent("NotifyPlayer")
    if notifyEvent then
        notifyEvent.OnClientEvent:Connect(function(message)
            self:showNotification(tostring(message))
        end)
    end

    -- Listen for economy updates
    local econEvent = RemoteManager:getEvent("EconomyUpdate")
    if econEvent then
        econEvent.OnClientEvent:Connect(function(data)
            self:updateHUD(data)
        end)
    end

    print("[UIController] Initialized")
end

---------------------------------------------------------------------------
-- PANEL MANAGEMENT
---------------------------------------------------------------------------

--- Register a panel Frame for toggle management.
function UIController:registerPanel(name: string, frame: Frame)
    self._panels[name] = frame
    frame.Visible = false
end

--- Show a panel (hides the currently active panel first).
function UIController:showPanel(panelName: string)
    -- Hide current panel
    if self._activePanel and self._panels[self._activePanel] then
        self:_animateOut(self._panels[self._activePanel])
    end

    local frame = self._panels[panelName]
    if frame then
        self._activePanel = panelName
        self:_animateIn(frame)
    end
end

--- Hide a specific panel.
function UIController:hidePanel(panelName: string)
    local frame = self._panels[panelName]
    if frame then
        self:_animateOut(frame)
        if self._activePanel == panelName then
            self._activePanel = nil
        end
    end
end

--- Toggle a panel (show if hidden, hide if shown).
function UIController:togglePanel(panelName: string)
    if self._activePanel == panelName then
        self:hidePanel(panelName)
    else
        self:showPanel(panelName)
    end
end

--- Hide all panels.
function UIController:hideAllPanels()
    for name, frame in pairs(self._panels) do
        frame.Visible = false
    end
    self._activePanel = nil
end

---------------------------------------------------------------------------
-- ANIMATIONS
---------------------------------------------------------------------------

function UIController:_animateIn(frame: Frame)
    frame.Visible = true
    frame.Position = UDim2.new(1.1, 0, frame.Position.Y.Scale, frame.Position.Y.Offset)

    local tween = TweenService:Create(
        frame,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Position = UDim2.new(0.5, -frame.AbsoluteSize.X / 2, frame.Position.Y.Scale, frame.Position.Y.Offset) }
    )

    -- Simpler approach: slide from right
    frame.Position = UDim2.new(1, 0, 0.15, 0)
    local targetPos = UDim2.new(0.3, 0, 0.15, 0)

    local slideIn = TweenService:Create(
        frame,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Position = targetPos }
    )
    slideIn:Play()
end

function UIController:_animateOut(frame: Frame)
    local slideOut = TweenService:Create(
        frame,
        TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Position = UDim2.new(1.1, 0, frame.Position.Y.Scale, frame.Position.Y.Offset) }
    )
    slideOut:Play()
    slideOut.Completed:Connect(function()
        frame.Visible = false
    end)
end

---------------------------------------------------------------------------
-- NOTIFICATIONS  (toast style)
---------------------------------------------------------------------------

function UIController:showNotification(message: string, duration: number?)
    table.insert(self._notificationQueue, {
        message = message,
        duration = duration or 3,
    })

    if not self._isProcessingNotifications then
        self:_processNotifications()
    end
end

function UIController:_processNotifications()
    self._isProcessingNotifications = true

    task.spawn(function()
        while #self._notificationQueue > 0 do
            local notif = table.remove(self._notificationQueue, 1)
            self:_displayNotification(notif.message, notif.duration)
            task.wait(0.5)  -- gap between notifications
        end
        self._isProcessingNotifications = false
    end)
end

function UIController:_displayNotification(message: string, duration: number)
    if not self._screenGui then return end

    local C = GameConfig.Colors

    -- Create notification frame
    local frame = Instance.new("Frame")
    frame.Name = "Notification"
    frame.Size = UDim2.new(0.5, 0, 0, 40)
    frame.Position = UDim2.new(0.25, 0, 0, -50)
    frame.BackgroundColor3 = C.UIBackground
    frame.BorderSizePixel = 0
    frame.Parent = self._screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = C.UIPrimary
    stroke.Thickness = 2
    stroke.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -16, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = message
    label.TextColor3 = C.UIText
    label.TextScaled = true
    label.TextWrapped = true
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    -- Slide in from top
    local slideIn = TweenService:Create(
        frame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Position = UDim2.new(0.25, 0, 0, 10) }
    )
    slideIn:Play()

    -- Wait, then slide out
    task.wait(duration)

    local slideOut = TweenService:Create(
        frame,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Position = UDim2.new(0.25, 0, 0, -50) }
    )
    slideOut:Play()
    slideOut.Completed:Connect(function()
        frame:Destroy()
    end)
end

---------------------------------------------------------------------------
-- HUD UPDATES
---------------------------------------------------------------------------

function UIController:updateHUD(data: table)
    if data.sunCoins and self._coinDisplay then
        self._coinDisplay.Text = tostring(math.floor(data.sunCoins)) .. " SC"
    end

    if data.prestige and self._prestigeDisplay then
        self._prestigeDisplay.Text = tostring(math.floor(data.prestige))
    end

    if data.level and self._levelDisplay then
        self._levelDisplay.Text = "Lv." .. tostring(data.level)
    end
end

--- Set references to HUD text labels (called by HUDTemplate).
function UIController:setHUDReferences(coinLabel, prestigeLabel, levelLabel)
    self._coinDisplay = coinLabel
    self._prestigeDisplay = prestigeLabel
    self._levelDisplay = levelLabel
end

return UIController
