-- Remodel: GATED publish script — Karl/Eddie only
-- Requires ROBLOX_API_KEY with place write scope
-- DO NOT run from Cursor cloud agent

local remodel = require("./remodel")

local PLACE_FILE = os.getenv("PSP_PLACE_FILE") or "PalmSpringsParadise.rbxlx"
local UNIVERSE_ID = os.getenv("PSP_UNIVERSE_ID")
local PLACE_ID = os.getenv("PSP_PLACE_ID")

if not UNIVERSE_ID or not PLACE_ID then
    error("[Remodel] Set PSP_UNIVERSE_ID and PSP_PLACE_ID before publish")
end

print("[Remodel] Publish staging — universe", UNIVERSE_ID, "place", PLACE_ID)
print("[Remodel] Reading", PLACE_FILE)

local game = remodel.readPlaceFile(PLACE_FILE)

-- remodel.writeExistingPlaceAsset(placeId, game) — enable after API review
warn("[Remodel] Publish stub only — uncomment writeExistingPlaceAsset after approval")
