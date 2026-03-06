--[[
    MainHUD.lua  (StarterGui)
    Creates the ScreenGui container that hosts all Palm Springs
    Paradise UI.  Placed in StarterGui so it automatically clones
    to each player's PlayerGui on spawn.

    The actual HUD content is built by HUDTemplate.lua via the
    client bootstrap (init.client.lua).
]]

-- This module is required by Rojo's StarterGui mapping.
-- It creates a bare ScreenGui; the client bootstrap populates it.

local MainHUD = {}

function MainHUD:init()
    -- No-op: the ScreenGui is created by init.client.lua
    -- This file exists to satisfy the Rojo folder structure
    -- and provide a StarterGui entry point.
end

return MainHUD
