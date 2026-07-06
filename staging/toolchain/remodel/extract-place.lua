-- Remodel: extract place metadata for audits (headless)
-- Usage: remodel run staging/toolchain/remodel/extract-place.lua --place PalmSpringsParadise.rbxlx

local remodel = require("./remodel")

local INPUT = os.getenv("PSP_PLACE_FILE") or "PalmSpringsParadise.rbxlx"

print("[Remodel] Loading place: " .. INPUT)
local game = remodel.readPlaceFile(INPUT)

local counts = {
    parts = 0,
    scripts = 0,
    meshParts = 0,
}

for _, desc in ipairs(game:GetDescendants()) do
    if desc:IsA("BasePart") then
        counts.parts += 1
    elseif desc:IsA("LuaSourceContainer") then
        counts.scripts += 1
    elseif desc:IsA("MeshPart") then
        counts.meshParts += 1
    end
end

print("[Remodel] Parts:", counts.parts)
print("[Remodel] Scripts:", counts.scripts)
print("[Remodel] MeshParts:", counts.meshParts)
