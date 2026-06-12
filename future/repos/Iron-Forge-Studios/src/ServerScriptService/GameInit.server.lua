--[[
    GameInit.server.lua
    Main server bootstrap script. Initializes all services in dependency order.
    Place in ServerScriptService.
]]

print("═══════════════════════════════════════════════════")
print("  Palm Springs Paradise: Steal the Oasis")
print("  Server Initializing...")
print("═══════════════════════════════════════════════════")

-- Initialize services in dependency order
local Services = {
    { Name = "DataService",         Module = require(script.Parent.Services.DataService) },
    { Name = "WorldService",        Module = require(script.Parent.Services.WorldService) },
    { Name = "EggService",          Module = require(script.Parent.Services.EggService) },
    { Name = "HeistService",        Module = require(script.Parent.Services.HeistService) },
    { Name = "PlotService",         Module = require(script.Parent.Services.PlotService) },
    { Name = "TradeService",        Module = require(script.Parent.Services.TradeService) },
    { Name = "MonetizationService", Module = require(script.Parent.Services.MonetizationService) },
    { Name = "LeaderboardService",  Module = require(script.Parent.Services.LeaderboardService) },
}

for _, service in Services do
    local startTime = os.clock()
    local success, err = pcall(service.Module.Init)
    local elapsed = math.floor((os.clock() - startTime) * 1000)

    if success then
        print(string.format("  ✓ %s initialized (%dms)", service.Name, elapsed))
    else
        warn(string.format("  ✗ %s FAILED: %s", service.Name, tostring(err)))
    end
end

print("═══════════════════════════════════════════════════")
print("  Server Ready!")
print("═══════════════════════════════════════════════════")
