--[[
    EggService.server.lua
    Server-authoritative egg hatching system.

    Responsibilities:
      - Validate and process egg hatch requests from clients
      - Roll rarity and select a pet using weighted RNG
      - Apply luck boosts (game passes, event modifiers)
      - Grant the pet to the player's data (via MulletService)
      - Persist egg inventory and hatched pet collection
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EggConfig    = require(ReplicatedStorage:WaitForChild("EggConfig"))
local MulletConfig = require(ReplicatedStorage:WaitForChild("MulletConfig"))

-- Remotes (created by MulletService first; we wait for them)
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)

local function getEvent(name: string): RemoteEvent?
    return Remotes and Remotes:FindFirstChild(name) :: RemoteEvent
end

local function getOrCreateEvent(name: string): RemoteEvent
    if Remotes then
        local existing = Remotes:FindFirstChild(name)
        if existing and existing:IsA("RemoteEvent") then return existing end
        local ev = Instance.new("RemoteEvent")
        ev.Name   = name
        ev.Parent = Remotes
        return ev
    end
    error("[EggService] Remotes folder not found")
end

local function getOrCreateFunction(name: string): RemoteFunction
    if Remotes then
        local existing = Remotes:FindFirstChild(name)
        if existing and existing:IsA("RemoteFunction") then return existing end
        local fn = Instance.new("RemoteFunction")
        fn.Name   = name
        fn.Parent = Remotes
        return fn
    end
    error("[EggService] Remotes folder not found")
end

local evNotify    = getOrCreateEvent("NotifyPlayer")
local evHatchResult = getOrCreateEvent("EggHatchResult")

---------------------------------------------------------------------------
-- INTERNAL STATE
-- eggInventory[userId] = { [eggId] = count, ... }
-- petCollection[userId] = { [petId] = count, ... }
---------------------------------------------------------------------------
local eggInventory:  { [number]: { [string]: number } } = {}
local petCollection: { [number]: { [string]: number } } = {}
local luckBoosts:    { [number]: number }               = {}  -- userId → multiplier

---------------------------------------------------------------------------
-- RNG HELPERS
---------------------------------------------------------------------------

--- Build a weighted pool from an egg's rarity table, respecting luck boost.
local function buildRarityPool(eggDef: table, luckMult: number): { string }
    local pool = {}
    for rarity, weight in pairs(eggDef.rarityTable) do
        if weight > 0 then
            -- Luck boost amplifies non-Common weights
            local adjusted = (rarity == "Common")
                and weight
                or math.floor(weight * luckMult)
            for _ = 1, adjusted do
                table.insert(pool, rarity)
            end
        end
    end
    return pool
end

--- Pick a weighted rarity from the pool.
local function rollRarity(pool: { string }): string
    return pool[math.random(1, #pool)]
end

--- Pick a pet of the given rarity from the global Pets table, preferring exclusives.
local function selectPet(eggDef: table, rarity: string): table?
    -- Gather exclusive pets of this rarity first
    local exclusivePets = {}
    for _, petId in ipairs(eggDef.exclusivePets or {}) do
        for _, pet in ipairs(EggConfig.Pets) do
            if pet.id == petId and pet.rarity == rarity then
                table.insert(exclusivePets, pet)
            end
        end
    end

    if #exclusivePets > 0 then
        return exclusivePets[math.random(1, #exclusivePets)]
    end

    -- Fall back to any pet of this rarity
    local rarityPets = {}
    for _, pet in ipairs(EggConfig.Pets) do
        if pet.rarity == rarity then
            table.insert(rarityPets, pet)
        end
    end

    if #rarityPets == 0 then
        -- Edge case: no pets of this rarity exist; fall back to Common
        for _, pet in ipairs(EggConfig.Pets) do
            if pet.rarity == "Common" then
                table.insert(rarityPets, pet)
            end
        end
    end

    return rarityPets[math.random(1, #rarityPets)]
end

---------------------------------------------------------------------------
-- PUBLIC API
---------------------------------------------------------------------------

local EggService = {}

--- Award an egg of the given type to a player.
function EggService:giveEgg(player: Player, eggId: string, count: number?)
    count = count or 1
    local userId = player.UserId
    eggInventory[userId] = eggInventory[userId] or {}
    eggInventory[userId][eggId] = (eggInventory[userId][eggId] or 0) + count
    evNotify:FireClient(player, "Received " .. count .. "× " .. (EggConfig.Eggs[eggId] and EggConfig.Eggs[eggId].name or eggId))
end

--- Set a temporary luck multiplier for this player.
function EggService:setLuckBoost(player: Player, mult: number)
    luckBoosts[player.UserId] = mult
end

--- Return all eggs and pets for a player.
function EggService:getInventory(player: Player): table
    local userId = player.UserId
    return {
        eggs = eggInventory[userId]  or {},
        pets = petCollection[userId] or {},
    }
end

--- Hatch an egg — server-authoritative.
--- Returns { success, petData } where petData is the hatched pet definition.
function EggService:hatchEgg(player: Player, eggId: string): (boolean, table?)
    local userId  = player.UserId
    local inv     = eggInventory[userId]
    if not inv or (inv[eggId] or 0) < 1 then
        evNotify:FireClient(player, "You don't have that egg!")
        return false, nil
    end

    local eggDef = EggConfig.Eggs[eggId]
    if not eggDef then
        warn("[EggService] Unknown egg id: " .. tostring(eggId))
        return false, nil
    end

    -- Deduct egg
    inv[eggId] -= 1
    if inv[eggId] <= 0 then
        inv[eggId] = nil
    end

    -- Roll
    local luckMult = luckBoosts[userId] or EggConfig.LuckBoost.Default
    local pool     = buildRarityPool(eggDef, luckMult)
    if #pool == 0 then
        warn("[EggService] Rarity pool empty for egg: " .. eggId)
        return false, nil
    end

    local rarity = rollRarity(pool)
    local pet    = selectPet(eggDef, rarity)
    if not pet then
        warn("[EggService] No pet found for rarity: " .. rarity)
        return false, nil
    end

    -- Add to collection
    petCollection[userId] = petCollection[userId] or {}
    petCollection[userId][pet.id] = (petCollection[userId][pet.id] or 0) + 1

    -- Notify client with full result
    evHatchResult:FireClient(player, {
        eggId    = eggId,
        petId    = pet.id,
        petName  = pet.name,
        rarity   = rarity,
        coinBonus  = pet.coinBonus,
        speedBonus = pet.speedBonus,
        damageBonus = pet.damageBonus,
    })

    print("[EggService] " .. player.Name .. " hatched " .. pet.name ..
          " (" .. rarity .. ") from " .. eggId)
    return true, pet
end

---------------------------------------------------------------------------
-- REMOTE HANDLER — client requests a hatch
---------------------------------------------------------------------------
local evHatchRequest = getOrCreateEvent("HatchEgg")
evHatchRequest.OnServerEvent:Connect(function(player: Player, eggId: string)
    EggService:hatchEgg(player, eggId)
end)

---------------------------------------------------------------------------
-- PLAYER LIFECYCLE
---------------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player: Player)
    eggInventory[player.UserId]  = {}
    petCollection[player.UserId] = {}
    luckBoosts[player.UserId]    = EggConfig.LuckBoost.Default
end)

Players.PlayerRemoving:Connect(function(player: Player)
    -- Persistence handled by MulletService; here we just clean memory.
    eggInventory[player.UserId]  = nil
    petCollection[player.UserId] = nil
    luckBoosts[player.UserId]    = nil
end)

print("[EggService] Initialized")

return EggService
