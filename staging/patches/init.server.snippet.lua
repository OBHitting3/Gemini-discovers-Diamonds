--[[
    MERGE PATCH — init.server.lua
    Insert after EventService:init(webhooks) block (~line 141)
    Requires DayPhaseConfig + AssetRegistry in ReplicatedStorage (copy from staging/src/shared)
]]

-- Copy shared staging modules into src/shared before this patch:
--   DayPhaseConfig.lua, AssetRegistry.lua

local CoreLoopService = require(script.Services.CoreLoopService)
local coreOk, coreErr = pcall(function()
    CoreLoopService:init({
        garden = GardenService,
        fashion = FashionService,
        event = EventService,
    })
end)
if not coreOk then
    warn("[Bootstrap] CoreLoopService init failed: " .. tostring(coreErr))
end

-- Optional: gate FashionService auto-start (add to FashionService after merge):
-- if not CoreLoopService:canStartFashionEvent() then return end
