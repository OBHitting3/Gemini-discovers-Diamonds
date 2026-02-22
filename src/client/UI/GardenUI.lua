--[[
    GardenUI.lua
    Garden interaction interface: seed selection, garden overview
    (4x4 grid), plant detail, harvest confirmation.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig    = require(ReplicatedStorage:WaitForChild("GameConfig"))
local ItemCatalog   = require(ReplicatedStorage:WaitForChild("ItemCatalog"))

local GardenUI = {}
local C = GameConfig.Colors

function GardenUI:build(screenGui: ScreenGui, uiController, gardenController)
    local panel = Instance.new("Frame")
    panel.Name = "GardenPanel"
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
    stroke.Color = C.CactusGreen
    stroke.Thickness = 2
    stroke.Parent = panel

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = C.CactusGreen
    title.BackgroundTransparency = 0.1
    title.BorderSizePixel = 0
    title.Text = "DESERT GARDEN"
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
        uiController:hidePanel("garden")
    end)

    -- Garden overview grid (4x4)
    local gridLabel = Instance.new("TextLabel")
    gridLabel.Size = UDim2.new(1, -20, 0, 20)
    gridLabel.Position = UDim2.new(0, 10, 0, 48)
    gridLabel.BackgroundTransparency = 1
    gridLabel.Text = "Garden Plots:"
    gridLabel.TextColor3 = C.UIText
    gridLabel.TextScaled = true
    gridLabel.Font = Enum.Font.GothamBold
    gridLabel.TextXAlignment = Enum.TextXAlignment.Left
    gridLabel.Parent = panel

    local gridFrame = Instance.new("Frame")
    gridFrame.Size = UDim2.new(0, 200, 0, 200)
    gridFrame.Position = UDim2.new(0.5, -100, 0, 72)
    gridFrame.BackgroundTransparency = 1
    gridFrame.Parent = panel

    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0, 45, 0, 45)
    grid.CellPadding = UDim2.new(0, 4, 0, 4)
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    grid.Parent = gridFrame

    local plotButtons = {}
    for i = 1, 16 do
        local plotBtn = Instance.new("TextButton")
        plotBtn.Name = "Plot_" .. i
        plotBtn.Text = tostring(i)
        plotBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        plotBtn.TextScaled = true
        plotBtn.Font = Enum.Font.GothamBold
        plotBtn.BackgroundColor3 = Color3.fromRGB(120, 90, 60)  -- empty soil color
        plotBtn.LayoutOrder = i
        plotBtn.Parent = gridFrame

        local plotCorner = Instance.new("UICorner")
        plotCorner.CornerRadius = UDim.new(0, 4)
        plotCorner.Parent = plotBtn

        plotButtons[i] = plotBtn

        plotBtn.MouseButton1Click:Connect(function()
            local state = gardenController:getPlotState(i)
            if not state or state.growthStage == "empty" then
                -- Show seed selection below
                -- For prototype: use first available seed type
            elseif state.growthStage == "mature" then
                gardenController:harvestPlant(i)
            else
                gardenController:waterPlant(i)
            end
        end)
    end

    -- Seed selection section
    local seedLabel = Instance.new("TextLabel")
    seedLabel.Size = UDim2.new(1, -20, 0, 20)
    seedLabel.Position = UDim2.new(0, 10, 0, 280)
    seedLabel.BackgroundTransparency = 1
    seedLabel.Text = "Plant Seeds (tap plot first, then seed):"
    seedLabel.TextColor3 = C.UIText
    seedLabel.TextScaled = true
    seedLabel.Font = Enum.Font.GothamBold
    seedLabel.TextXAlignment = Enum.TextXAlignment.Left
    seedLabel.Parent = panel

    local seedScroll = Instance.new("ScrollingFrame")
    seedScroll.Size = UDim2.new(1, -20, 0, 100)
    seedScroll.Position = UDim2.new(0, 10, 0, 305)
    seedScroll.BackgroundTransparency = 1
    seedScroll.BorderSizePixel = 0
    seedScroll.ScrollBarThickness = 4
    seedScroll.ScrollingDirection = Enum.ScrollingDirection.X
    seedScroll.CanvasSize = UDim2.new(0, #ItemCatalog.Plants * 85, 0, 0)
    seedScroll.Parent = panel

    local seedListLayout = Instance.new("UIListLayout")
    seedListLayout.FillDirection = Enum.FillDirection.Horizontal
    seedListLayout.Padding = UDim.new(0, 6)
    seedListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    seedListLayout.Parent = seedScroll

    self._selectedPlotIndex = 1

    for i, plant in ipairs(ItemCatalog.Plants) do
        local seedBtn = Instance.new("TextButton")
        seedBtn.Size = UDim2.new(0, 78, 0, 90)
        seedBtn.BackgroundColor3 = Color3.fromRGB(240, 238, 230)
        seedBtn.Text = plant.name .. "\n" .. plant.seedPrice .. " SC"
        seedBtn.TextColor3 = C.UIText
        seedBtn.TextScaled = true
        seedBtn.TextWrapped = true
        seedBtn.Font = Enum.Font.Gotham
        seedBtn.LayoutOrder = i
        seedBtn.Parent = seedScroll

        local seedCorner = Instance.new("UICorner")
        seedCorner.CornerRadius = UDim.new(0, 6)
        seedCorner.Parent = seedBtn

        seedBtn.MouseButton1Click:Connect(function()
            gardenController:plantSeed(self._selectedPlotIndex, plant.id)
        end)
    end

    -- Update grid colors based on garden state
    task.spawn(function()
        while true do
            task.wait(2)
            local state = gardenController:getGardenState()
            for i = 1, 16 do
                local plotState = state[i]
                local btn = plotButtons[i]
                if btn then
                    if not plotState or plotState.growthStage == "empty" then
                        btn.BackgroundColor3 = Color3.fromRGB(120, 90, 60)
                        btn.Text = tostring(i)
                    elseif plotState.growthStage == "seed" then
                        btn.BackgroundColor3 = Color3.fromRGB(139, 90, 43)
                        btn.Text = "Seed"
                    elseif plotState.growthStage == "sprout" then
                        btn.BackgroundColor3 = Color3.fromRGB(100, 160, 80)
                        btn.Text = "Sprout"
                    elseif plotState.growthStage == "growing" then
                        btn.BackgroundColor3 = Color3.fromRGB(60, 140, 60)
                        btn.Text = "Grow"
                    elseif plotState.growthStage == "mature" then
                        btn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
                        btn.Text = "PICK"
                    elseif plotState.growthStage == "wilting" then
                        btn.BackgroundColor3 = Color3.fromRGB(200, 180, 50)
                        btn.Text = "WILT!"
                    elseif plotState.growthStage == "dead" then
                        btn.BackgroundColor3 = Color3.fromRGB(100, 80, 60)
                        btn.Text = "Dead"
                    end

                    -- Track selected plot
                    self._selectedPlotIndex = i
                end
            end
        end
    end)

    uiController:registerPanel("garden", panel)
    print("[GardenUI] Built")
end

return GardenUI
