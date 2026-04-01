--[[
    init.client.lua  (StarterPlayerScripts)
    Main client bootstrap for Palm Springs Paradise.
    Waits for shared modules, initializes all controllers,
    and sets up the client-side UI framework.
]]

print("[Client] Palm Springs Paradise — Client Starting...")

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui       = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Wait for critical shared modules
ReplicatedStorage:WaitForChild("GameConfig", 30)
ReplicatedStorage:WaitForChild("RemoteManager", 30)
ReplicatedStorage:WaitForChild("Utilities", 30)

-- Wait for remotes folder to be created by server
ReplicatedStorage:WaitForChild("PalmSpringsRemotes", 30)

local GameConfig    = require(ReplicatedStorage.GameConfig)
local RemoteManager = require(ReplicatedStorage.RemoteManager)

---------------------------------------------------------------------------
-- CREATE SCREEN GUI
---------------------------------------------------------------------------

-- The MainHUD module in StarterGui creates the ScreenGui,
-- but we also create one here as a fallback
local screenGui = player:WaitForChild("PlayerGui"):FindFirstChild("MainHUD")
if not screenGui then
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MainHUD"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.IgnoreGuiInset = false
    screenGui.Parent = player:WaitForChild("PlayerGui")
end

---------------------------------------------------------------------------
-- INITIALIZE CONTROLLERS
---------------------------------------------------------------------------

local UIController = require(script.Controllers.UIController)
UIController:init(screenGui)

local PlotController = require(script.Controllers.PlotController)
PlotController:init(UIController)

local GardenController = require(script.Controllers.GardenController)
GardenController:init(UIController)

local FashionController = require(script.Controllers.FashionController)
FashionController:init(UIController)

local ShopController = require(script.Controllers.ShopController)
ShopController:init(UIController)

local NightToggleController = require(script.Controllers.NightToggleController)
NightToggleController:init(UIController)

local SoundController = require(script.Controllers.SoundController)
SoundController:init()

---------------------------------------------------------------------------
-- BUILD HUD
---------------------------------------------------------------------------

local HUDTemplate = require(script.UI.HUDTemplate)
HUDTemplate:build(screenGui, UIController)

---------------------------------------------------------------------------
-- BUILD UI PANELS
---------------------------------------------------------------------------

local PlotUI = require(script.UI.PlotUI)
PlotUI:build(screenGui, UIController, PlotController)

local ShopUI = require(script.UI.ShopUI)
ShopUI:build(screenGui, UIController, ShopController)

local GardenUI = require(script.UI.GardenUI)
GardenUI:build(screenGui, UIController, GardenController)

local FashionUI = require(script.UI.FashionUI)
FashionUI:build(screenGui, UIController, FashionController)

local EventUI = require(script.UI.EventUI)
EventUI:build(screenGui, UIController)

local LeaderboardUI = require(script.UI.LeaderboardUI)
LeaderboardUI:build(screenGui, UIController)

---------------------------------------------------------------------------
-- INPUT HANDLING
---------------------------------------------------------------------------

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    -- Keyboard shortcuts
    if input.KeyCode == Enum.KeyCode.R then
        -- Rotate furniture during placement
        if PlotController:isPlacingFurniture() then
            PlotController:rotatePlacement()
        end
    elseif input.KeyCode == Enum.KeyCode.X then
        -- Cancel furniture placement
        if PlotController:isPlacingFurniture() then
            PlotController:cancelPlacement()
        end
    elseif input.KeyCode == Enum.KeyCode.Return then
        -- Confirm furniture placement
        if PlotController:isPlacingFurniture() then
            PlotController:confirmPlacement()
        end
    elseif input.KeyCode == Enum.KeyCode.N then
        -- Night toggle (if enabled)
        NightToggleController:toggle()
    elseif input.KeyCode == Enum.KeyCode.Escape then
        -- Close any open panel
        UIController:hideAllPanels()
    end
end)

-- Mouse click for furniture placement
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if PlotController:isPlacingFurniture() then
            PlotController:confirmPlacement()
        end
    end
end)

---------------------------------------------------------------------------
-- DONE
---------------------------------------------------------------------------

print("[Client] Palm Springs Paradise — Client Ready!")
print("[Client] Controls: N=Night toggle, R=Rotate furniture, X=Cancel, Enter=Confirm")
