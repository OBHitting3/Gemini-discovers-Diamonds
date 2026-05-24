--[[
    init.server.lua  (ServerScriptService)
    Main server bootstrap for Palm Springs Paradise.
    Initializes all services and builders in correct dependency order,
    builds the world, and sets up player lifecycle handlers.

    Boot order:
    1. RemoteManager (creates all RemoteEvents/Functions)
    2. PersistenceService (DataStore + Supabase)
    3. EconomyService
    4. Environment builders (terrain, sky, roads, etc.)
    5. Gameplay services (Plot, Garden, Fashion, Shop, Event)
    6. Test commands
    7. Player lifecycle handlers
]]

print("===========================================")
print("  PALM SPRINGS PARADISE — Server Starting  ")
print("===========================================")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for shared modules to replicate
ReplicatedStorage:WaitForChild("GameConfig")
ReplicatedStorage:WaitForChild("RemoteManager")

local BootstrapHealth = require(ReplicatedStorage:WaitForChild("BootstrapHealth"))

local function recordBoot(name: string, ok: boolean, err: any?)
    BootstrapHealth:setService(name, ok, if err then tostring(err) else nil)
    if not ok then
        warn("[Bootstrap] " .. name .. " init failed: " .. tostring(err))
    end
end

---------------------------------------------------------------------------
-- 1. REMOTE MANAGER  (must be first — creates all remotes)
---------------------------------------------------------------------------
local RemoteManager = require(ReplicatedStorage.RemoteManager)
RemoteManager:init()
recordBoot("RemoteManager", true, nil)

---------------------------------------------------------------------------
-- 2. PERSISTENCE SERVICE
---------------------------------------------------------------------------
local PersistenceService = require(script.Services.PersistenceService)
local persistOk, persistErr = pcall(function()
    PersistenceService:init()
end)
recordBoot("PersistenceService", persistOk, persistErr)

---------------------------------------------------------------------------
-- 3. ECONOMY SERVICE
---------------------------------------------------------------------------
local EconomyService = require(script.Services.EconomyService)
local econOk, econErr = pcall(function()
    EconomyService:init(PersistenceService)
end)
recordBoot("EconomyService", econOk, econErr)

---------------------------------------------------------------------------
-- 4. ENVIRONMENT BUILDERS
---------------------------------------------------------------------------
local EnvironmentBuilder = require(script.Builders.EnvironmentBuilder)
local GardenBuilder = require(script.Builders.GardenBuilder)
local HomeBuilder = require(script.Builders.HomeBuilder)
local RunwayBuilder = require(script.Builders.RunwayBuilder)
local StorefrontBuilder = require(script.Builders.StorefrontBuilder)

local totalEnvParts = 0

local envOk, envErr = pcall(function()
    totalEnvParts += EnvironmentBuilder:buildAll()
end)
recordBoot("EnvironmentBuilder", envOk, envErr)

local sfOk, sfErr = pcall(function()
    totalEnvParts += StorefrontBuilder:buildBoulevard()
end)
recordBoot("StorefrontBuilder", sfOk, sfErr)

local gardenOk, gardenErr = pcall(function()
    totalEnvParts += GardenBuilder:buildGarden()
end)
recordBoot("GardenBuilder", gardenOk, gardenErr)

local runwayOk, runwayErr = pcall(function()
    totalEnvParts += RunwayBuilder:buildRunway()
end)
recordBoot("RunwayBuilder", runwayOk, runwayErr)

print("[Bootstrap] Environment built — " .. totalEnvParts .. " base parts")

---------------------------------------------------------------------------
-- 5. GAMEPLAY SERVICES
---------------------------------------------------------------------------
local PlotService = require(script.Services.PlotService)
local plotOk, plotErr = pcall(function()
    PlotService:init(EconomyService, HomeBuilder, PersistenceService)
end)
recordBoot("PlotService", plotOk, plotErr)

local GardenService = require(script.Services.GardenService)
local gardenSvcOk, gardenSvcErr = pcall(function()
    GardenService:init(
        EconomyService,
        GardenBuilder,
        PersistenceService and PersistenceService:getSupabaseClient()
    )
end)
recordBoot("GardenService", gardenSvcOk, gardenSvcErr)

local WebhookClient = require(ReplicatedStorage.WebhookClient)
local webhooks = WebhookClient.new() -- placeholder mode

local ShopService = require(script.Services.ShopService)
local shopOk, shopErr = pcall(function()
    ShopService:init(EconomyService, webhooks, PersistenceService)
end)
recordBoot("ShopService", shopOk, shopErr)

local PropSpawnService = require(script.Services.PropSpawnService)
local propSpawnOk, propSpawnErr = pcall(function()
    PropSpawnService:init()
end)
recordBoot("PropSpawnService", propSpawnOk, propSpawnErr)

local FashionService = require(script.Services.FashionService)
local fashionOk, fashionErr = pcall(function()
    FashionService:init(EconomyService)
end)
recordBoot("FashionService", fashionOk, fashionErr)

local EventService = require(script.Services.EventService)
local eventOk, eventErr = pcall(function()
    EventService:init(webhooks)
end)
recordBoot("EventService", eventOk, eventErr)

---------------------------------------------------------------------------
-- 5a. CORE LOOP (day phases: Morning / Afternoon / Evening)
---------------------------------------------------------------------------
local CoreLoopService = require(script.Services.CoreLoopService)
local coreOk, coreErr = pcall(function()
    CoreLoopService:init({
        garden = GardenService,
        fashion = FashionService,
        event = EventService,
    })
end)
recordBoot("CoreLoopService", coreOk, coreErr)

---------------------------------------------------------------------------
-- 5b. LEADERBOARD SERVICE
---------------------------------------------------------------------------
local LeaderboardService = require(script.Services.LeaderboardService)
local lbOk, lbErr = pcall(function()
    LeaderboardService:init(EconomyService, PlotService)
end)
recordBoot("LeaderboardService", lbOk, lbErr)

---------------------------------------------------------------------------
-- 5c. GAME PASS SERVICE
---------------------------------------------------------------------------
local GamePassService = require(script.Services.GamePassService)
local gpOk, gpErr = pcall(function()
    GamePassService:init(EconomyService, GardenService)
    GamePassService:startAutoWaterLoop()
end)
recordBoot("GamePassService", gpOk, gpErr)

---------------------------------------------------------------------------
-- 6. TEST COMMANDS
---------------------------------------------------------------------------
local TestCommands = require(script.Commands.TestCommands)
local testOk, testErr = pcall(function()
    TestCommands:init({
        economy = EconomyService,
        plot = PlotService,
        garden = GardenService,
        fashion = FashionService,
        shop = ShopService,
        event = EventService,
        persistence = PersistenceService,
        propSpawn = PropSpawnService,
        homeBuilder = HomeBuilder,
        gardenBuilder = GardenBuilder,
        environmentBuilder = EnvironmentBuilder,
        storefrontBuilder = StorefrontBuilder,
        runwayBuilder = RunwayBuilder,
    })
end)
recordBoot("TestCommands", testOk, testErr)

---------------------------------------------------------------------------
-- 7. PLAYER LIFECYCLE
---------------------------------------------------------------------------

local function onPlayerAdded(player: Player)
    print("[Bootstrap] Player joined: " .. player.Name)

    -- Load player data
    local data = nil
    local loadOk, loadErr = pcall(function()
        data = PersistenceService:loadPlayer(player)
    end)

    if not loadOk or not data then
        warn("[Bootstrap] Failed to load data for " .. player.Name .. ": " .. tostring(loadErr))
        -- Create minimal data so player can still play
        data = {
            userId = player.UserId,
            displayName = player.DisplayName,
            sunCoins = 200,
            prestige = 0,
            level = 1,
            plotId = nil,
            shopId = nil,
            homeStyle = nil,
            inventory = {},
            outfits = {},
            stats = {
                totalCoinsEarned = 0,
                totalPrestigeEarned = 0,
                plantsHarvested = 0,
                fashionWins = 0,
                itemsSold = 0,
                itemsBought = 0,
                homeTourVisits = 0,
            },
            lastLogin = os.time(),
            firstJoin = os.time(),
        }
    end

    -- Create leaderstats
    EconomyService:createLeaderstats(player, data)

    -- Load game pass ownership
    pcall(function()
        GamePassService:loadPlayerPasses(player)
    end)

    -- Send welcome notification
    task.delay(2, function()
        if player.Parent then -- still in game
            local DayPhaseConfig = require(ReplicatedStorage:WaitForChild("DayPhaseConfig"))
            local welcome = "Welcome to Palm Springs Paradise! Head to El Paseo to explore."
            if DayPhaseConfig.getCurrentPhase() == "Evening" then
                welcome = "Evening soirée — head to the runway!"
            end
            RemoteManager:fireClient("NotifyPlayer", player, welcome)

            -- Send initial economy update
            RemoteManager:fireClient("EconomyUpdate", player, {
                sunCoins = data.sunCoins,
                prestige = data.prestige,
                level = data.level,
            })

            -- If first-time player, send signup webhook
            if data.firstJoin == data.lastLogin then
                webhooks:sendSignup(data)
            end
        end
    end)
end

local function onPlayerRemoving(player: Player)
    print("[Bootstrap] Player leaving: " .. player.Name)

    local saveOk, saveErr = pcall(function()
        PersistenceService:releasePlayer(player)
    end)

    if not saveOk then
        warn("[Bootstrap] Save failed for " .. player.Name .. ": " .. tostring(saveErr))
    end

    EconomyService:removePlayer(player)
    GamePassService:removePlayer(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Handle players who joined before this script ran
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(onPlayerAdded, player)
end

---------------------------------------------------------------------------
-- GAME CLOSE  (save all before shutdown)
---------------------------------------------------------------------------
game:BindToClose(function()
    print("[Bootstrap] Game closing — saving all players...")
    PersistenceService:saveAll()
    print("[Bootstrap] All players saved. Goodbye!")
end)

---------------------------------------------------------------------------
-- STARTUP COMPLETE
---------------------------------------------------------------------------
BootstrapHealth:setPartCount(totalEnvParts)
local health = BootstrapHealth:getSnapshot()
print("===========================================")
print("  PALM SPRINGS PARADISE — Server Ready!    ")
print("  Total base parts: " .. totalEnvParts)
print("  Players: " .. #Players:GetPlayers())
print("  Bootstrap: " .. health.servicesPassed .. " ok, " .. health.servicesFailed .. " failed")
print("===========================================")
