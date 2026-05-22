--[[
    DayPhaseController.lua  (STAGING — merge to src/client/Controllers)
    Client-side day phase HUD + input gating (night toggle, fashion hints).

    Listens: RemoteEvent DayPhaseUpdate (created by CoreLoopService)
    Updates: UIController phase chip (if present) or lightweight label
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DayPhaseConfig = require(ReplicatedStorage:WaitForChild("DayPhaseConfig"))

local DayPhaseController = {}

DayPhaseController._uiController = nil
DayPhaseController._phaseLabel = nil
DayPhaseController._currentPayload = nil

---------------------------------------------------------------------------
function DayPhaseController:init(uiController: any)
    self._uiController = uiController
    self:_bindRemote()
    self:_createPhaseLabel()
end

function DayPhaseController:getPhase(): string?
    if self._currentPayload then
        return self._currentPayload.phase
    end
    return DayPhaseConfig.getCurrentPhase()
end

function DayPhaseController:isNightAllowed(): boolean
    if self._currentPayload and self._currentPayload.modifiers then
        return self._currentPayload.modifiers.nightToggleAllowed == true
    end
    local phase = self:getPhase()
    if phase then
        return DayPhaseConfig.getModifiers(phase :: any).nightToggleAllowed
    end
    return false
end

function DayPhaseController:isFashionHighlighted(): boolean
    if self._currentPayload and self._currentPayload.modifiers then
        return self._currentPayload.modifiers.fashionEventsAllowed == true
    end
    return false
end

---------------------------------------------------------------------------
function DayPhaseController:_bindRemote()
    local folder = ReplicatedStorage:WaitForChild("PalmSpringsRemotes", 30)
    if not folder then return end

    local ev = folder:WaitForChild("DayPhaseUpdate", 30)
    if not ev then return end

    ev.OnClientEvent:Connect(function(payload)
        self:_onPhaseUpdate(payload)
    end)
end

function DayPhaseController:_onPhaseUpdate(payload: any)
    self._currentPayload = payload
    self:_updateLabel(payload)

    if self._uiController and self._uiController.setDayPhaseHint then
        self._uiController:setDayPhaseHint(payload.hint)
    end
end

function DayPhaseController:_createPhaseLabel()
    local player = game:GetService("Players").LocalPlayer
    local gui = player:WaitForChild("PlayerGui"):FindFirstChild("MainHUD")
    if not gui then return end

    local existing = gui:FindFirstChild("DayPhaseChip")
    if existing then
        self._phaseLabel = existing
        return
    end

    local chip = Instance.new("TextLabel")
    chip.Name = "DayPhaseChip"
    chip.Size = UDim2.new(0, 200, 0, 28)
    chip.Position = UDim2.new(0, 12, 0, 48)
    chip.BackgroundColor3 = Color3.fromRGB(255, 252, 245)
    chip.BackgroundTransparency = 0.15
    chip.BorderSizePixel = 0
    chip.Font = Enum.Font.GothamMedium
    chip.TextSize = 14
    chip.TextColor3 = Color3.fromRGB(50, 50, 50)
    chip.Text = "…"
    chip.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = chip

    self._phaseLabel = chip

    -- Initial local estimate until server fires
    local phase = DayPhaseConfig.getCurrentPhase()
    local hint = DayPhaseConfig.getHint(phase)
    chip.Text = phase .. " — " .. hint.title
end

function DayPhaseController:_updateLabel(payload: any)
    if not self._phaseLabel then return end
    local hint = payload.hint
    if hint then
        self._phaseLabel.Text = payload.phase .. " — " .. hint.title
    else
        self._phaseLabel.Text = tostring(payload.phase)
    end
end

return DayPhaseController
