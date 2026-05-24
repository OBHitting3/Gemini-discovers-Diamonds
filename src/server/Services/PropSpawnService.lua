--[[
    PropSpawnService.lua
    Spawns procedural (or imported) props for Play Solo testing and future gameplay.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local AssetRegistry = require(ReplicatedStorage:WaitForChild("AssetRegistry"))
local ProceduralAssetCatalog = require(ReplicatedStorage:WaitForChild("ProceduralAssetCatalog"))
local RemoteManager = require(ReplicatedStorage:WaitForChild("RemoteManager"))

local PropBuilder = require(script.Parent.Parent.Builders.PropBuilder)

local PropSpawnService = {}

function PropSpawnService:init()
    local folder = Workspace:FindFirstChild("DynamicProps")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "DynamicProps"
        folder.Parent = Workspace
    end
    self._propsFolder = folder
    print("[PropSpawnService] Ready — procedural 3D via PropBuilder")
end

function PropSpawnService:getSpawnPosition(player: Player): Vector3?
    local char = player.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    return hrp.Position + hrp.CFrame.LookVector * 10 + Vector3.new(0, 1, 0)
end

function PropSpawnService:spawnProp(player: Player, slugOrItemId: string): (boolean, string)
    local position = self:getSpawnPosition(player)
    if not position then
        return false, "Character not loaded."
    end

    local slug = slugOrItemId
    local def = ProceduralAssetCatalog.getBySlug(slugOrItemId)
        or ProceduralAssetCatalog.getByItemCatalogId(slugOrItemId)
    if def then
        slug = def.slug
    end

    local model: Model? = nil
    local partCount = 0

    local imported = AssetRegistry:getTemplate(slugOrItemId)
        or (def and def.itemCatalogId and AssetRegistry:getTemplate(def.itemCatalogId))
    if imported then
        model = imported :: Model
        if not model.PrimaryPart then
            local first = model:FindFirstChildWhichIsA("BasePart", true)
            if first then
                model.PrimaryPart = first
            end
        end
        model:PivotTo(CFrame.new(position))
        model.Parent = self._propsFolder
        for _, desc in ipairs(model:GetDescendants()) do
            if desc:IsA("BasePart") then
                partCount += 1
            end
        end
    else
        local built, parts = PropBuilder:build(slugOrItemId, self._propsFolder, CFrame.new(position))
        model = built
        partCount = parts
    end

    if not model then
        local available = table.concat(PropBuilder:listBuildableSlugs(), ", ")
        return false, "Unknown prop. Try: " .. available
    end

    model:SetAttribute("SpawnedBy", player.UserId)
    model:SetAttribute("SpawnedAt", os.time())

    local label = def and def.displayName or slugOrItemId
    return true, "Spawned " .. label .. " (" .. partCount .. " parts)"
end

function PropSpawnService:notifySpawn(player: Player, slugOrItemId: string)
    local ok, message = self:spawnProp(player, slugOrItemId)
    RemoteManager:fireClient("NotifyPlayer", player, message)
    return ok
end

function PropSpawnService:listPropsForPlayer(player: Player)
    RemoteManager:fireClient("NotifyPlayer", player, "=== Procedural 3D props (prompt-built) ===")
    for _, def in ipairs(ProceduralAssetCatalog.Assets) do
        RemoteManager:fireClient("NotifyPlayer", player,
            "  " .. def.slug .. " — " .. def.displayName)
    end
    RemoteManager:fireClient("NotifyPlayer", player,
        "Spawn: /spawnprop [slug]  |  Place on plot: /placefurniture [itemId]")
end

return PropSpawnService
