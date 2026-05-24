--[[
    AssetRegistry.lua
    Maps ItemCatalog slugs → Roblox asset IDs and optional ReplicatedStorage paths.

    IMPORT HOOKUP:
      1. Manus runs Tarmac (staging/toolchain/tarmac.toml) → GeneratedAssets.lua
      2. Manus uploads meshes → vendor-imports/_manifests/asset-index.yaml
      3. Karl approves → merge GeneratedAssets + AssetRegistry._entries
      4. Services call AssetRegistry:getSoundId / getTemplate / hasImportedAsset

    local GeneratedAssets = nil -- after merge: require(script.Parent.GeneratedAssets)

    Until IDs exist, builders keep using procedural Parts (HomeBuilder, etc.)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetRegistry = {}

export type AssetKind = "MeshPart" | "Model" | "Sound" | "Decal" | "Animation"

export type AssetEntry = {
    kind: AssetKind,
    rbxassetid: string?, -- rbxassetid://...
    replicatedPath: string?, -- e.g. "Assets.Furniture.eames_lounge"
    tags: { string }?,
    partEstimate: number?,
    sourcePack: string?,
}

-- Populated from Manus manifest; 0 = placeholder (use procedural fallback)
AssetRegistry._entries = {
    -- Furniture (ItemCatalog.Furniture ids)
    eames_lounge = {
        kind = "MeshPart",
        rbxassetid = nil,
        replicatedPath = "Assets.Furniture.eames_lounge",
        tags = { "PSP_Furniture", "PSP_ImportedMesh" },
        partEstimate = 8,
        sourcePack = "procedural-fallback",
    },
    kidney_table = {
        kind = "MeshPart",
        rbxassetid = nil,
        replicatedPath = "Assets.Furniture.kidney_table",
        tags = { "PSP_Furniture" },
        partEstimate = 4,
    },

    -- Plants (ItemCatalog.Plants)
    saguaro_cactus = {
        kind = "Model",
        rbxassetid = nil,
        replicatedPath = "Assets.Plants.saguaro_cactus",
        tags = { "PSP_Plant" },
        partEstimate = 6,
    },

    -- Audio (SoundController keys)
    ambience_wind = {
        kind = "Sound",
        rbxassetid = "rbxassetid://9112854440",
        tags = { "PSP_Audio" },
    },
    garden_water = {
        kind = "Sound",
        rbxassetid = "rbxassetid://6677463651",
        tags = { "PSP_Audio" },
    },
    ui_click = {
        kind = "Sound",
        rbxassetid = "rbxassetid://6895079853",
        tags = { "PSP_Audio" },
    },
}

---------------------------------------------------------------------------
-- Lookup API
---------------------------------------------------------------------------
function AssetRegistry:getEntry(slug: string): AssetEntry?
    return self._entries[slug]
end

function AssetRegistry:hasImportedAsset(slug: string): boolean
    local entry = self._entries[slug]
    if not entry then
        return false
    end
    if entry.rbxassetid and entry.rbxassetid ~= "" and not string.find(entry.rbxassetid, "//0") then
        return true
    end
    if entry.replicatedPath then
        local inst = self:_resolvePath(entry.replicatedPath)
        return inst ~= nil
    end
    return false
end

function AssetRegistry:getSoundId(soundKey: string): string
    local entry = self._entries[soundKey]
    if entry and entry.kind == "Sound" and entry.rbxassetid then
        return entry.rbxassetid
    end
    return "rbxassetid://6895079853" -- safe UI fallback
end

--- Clone a template Model/MeshPart from ReplicatedStorage if present.
function AssetRegistry:getTemplate(slug: string): Instance?
    local entry = self._entries[slug]
    if not entry or not entry.replicatedPath then
        return nil
    end
    local source = self:_resolvePath(entry.replicatedPath)
    if source then
        return source:Clone()
    end
    return nil
end

function AssetRegistry:applyCollectionTags(instance: Instance, slug: string)
    local entry = self._entries[slug]
    if not entry or not entry.tags then
        return
    end
    local CollectionService = game:GetService("CollectionService")
    for _, tag in ipairs(entry.tags) do
        CollectionService:AddTag(instance, tag)
    end
end

---------------------------------------------------------------------------
-- Merge helper — load rows from Manus YAML (future: parse at build time)
---------------------------------------------------------------------------
function AssetRegistry:registerManifestEntry(slug: string, data: AssetEntry)
    self._entries[slug] = data
end

---------------------------------------------------------------------------
-- Internal
---------------------------------------------------------------------------
function AssetRegistry:_resolvePath(dotPath: string): Instance?
    local root = ReplicatedStorage:FindFirstChild("Assets")
    if not root then
        return nil
    end
    local current: Instance = root
    for segment in string.gmatch(dotPath, "[^%.]+") do
        if segment ~= "Assets" then
            local child = current:FindFirstChild(segment)
            if not child then
                return nil
            end
            current = child
        end
    end
    return current
end

return AssetRegistry
