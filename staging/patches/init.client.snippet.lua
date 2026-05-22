--[[
    MERGE PATCH — init.client.lua
    Insert after NightToggleController:init(UIController)
    Requires DayPhaseConfig in ReplicatedStorage
]]

local DayPhaseController = require(script.Controllers.DayPhaseController)
DayPhaseController:init(UIController)

-- Gate night toggle — wrap or patch NightToggleController:toggle:
-- if not DayPhaseController:isNightAllowed() then
--     UIController:notify("Night mode unlocks this evening.")
--     return
-- end
