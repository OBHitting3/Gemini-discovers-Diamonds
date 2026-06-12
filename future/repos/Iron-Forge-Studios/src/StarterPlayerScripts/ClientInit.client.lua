--[[
    ClientInit.client.lua
    Main client bootstrap. Initializes controllers and UI in order.
    Place in StarterPlayerScripts.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Wait for essential modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Shared = Modules:WaitForChild("Shared")

print("[Client] Initializing Palm Springs Paradise...")

-- Initialize controllers in order
local Controllers = {
    { Name = "DataController",     Module = require(script.Parent.Controllers.DataController) },
    { Name = "EggController",      Module = require(script.Parent.Controllers.EggController) },
    { Name = "HeistController",    Module = require(script.Parent.Controllers.HeistController) },
    { Name = "PlotController",     Module = require(script.Parent.Controllers.PlotController) },
    { Name = "TradeController",    Module = require(script.Parent.Controllers.TradeController) },
    { Name = "UIController",       Module = require(script.Parent.Controllers.UIController) },
}

for _, controller in Controllers do
    local success, err = pcall(controller.Module.Init, player)
    if success then
        print(string.format("  [Client] ✓ %s ready", controller.Name))
    else
        warn(string.format("  [Client] ✗ %s failed: %s", controller.Name, tostring(err)))
    end
end

print("[Client] All systems ready!")
