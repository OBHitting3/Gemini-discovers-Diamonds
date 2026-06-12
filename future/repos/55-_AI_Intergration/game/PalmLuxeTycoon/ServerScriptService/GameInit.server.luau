-- GameInit: Server entry point for Palm Luxe Tycoon
-- Bootstraps all economy modules in correct dependency order.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Load shared config first
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- Initialize modules in dependency order
local PricingEngine = require(ServerScriptService:WaitForChild("PricingEngine"))
PricingEngine:Init()

local AntiExploit = require(ServerScriptService:WaitForChild("AntiExploit"))
AntiExploit:Init(PricingEngine)

local AssetBridge = require(ServerScriptService:WaitForChild("AssetBridge"))
AssetBridge:Init(PricingEngine)

print("[Palm Luxe Tycoon] Economy system initialized.")
print("[Palm Luxe Tycoon] Currency: " .. GameConfig.CURRENCY_NAME)
print("[Palm Luxe Tycoon] Items loaded: " .. tostring(#GameConfig.MODES) .. " modes")

-- Expose modules to other scripts via shared table
_G.PalmLuxe = {
	PricingEngine = PricingEngine,
	AntiExploit = AntiExploit,
	AssetBridge = AssetBridge,
	Config = GameConfig,
}
