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

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for shared modules to replicate
ReplicatedStorage:WaitForChild("GameConfig")
ReplicatedStorage:WaitForChild("RemoteManager")

---------------------------------------------------------------------------
-- 1. REMOTE MANAGER  (must be first — creates all remotes)
---------------------------------------------------------------------------
local RemoteManager = require(ReplicatedStorage.RemoteManager)
RemoteManager:init()

---------------------------------------------------------------------------
-- 2. PERSISTENCE SERVICE
---------------------------------------------------------------------------
local PersistenceService = require(script.Services.PersistenceService)
local persistOk, persistErr = pcall(function()
    PersistenceService:init()
end)
if not persistOk then
    warn("[Bootstrap] PersistenceService init failed: " .. tostring(persistErr))
end

---------------------------------------------------------------------------
-- 3. ECONOMY SERVICE
---------------------------------------------------------------------------
local EconomyService = require(script.Services.EconomyService)
local econOk, econErr = pcall(function()
    EconomyService:init(PersistenceService)
end)
if not econOk then
    warn("[Bootstrap] EconomyService init failed: " .. tostring(econErr))
end

---------------------------------------------------------------------------
-- 4. ENVIRONMENT BUILDERS
---------------------------------------------------------------------------
local EnvironmentBuilder = require(script.Builders.EnvironmentBuilder)
local HomeBuilder        = require(script.Builders.HomeBuilder)
local StorefrontBuilder  = require(script.Builders.StorefrontBuilder)
local GardenBuilder      = require(script.Builders.GardenBuilder)
local RunwayBuilder      = require(script.Builders.RunwayBuilder)

local totalEnvParts = 0

local envOk, envErr = pcall(function()
    totalEnvParts += EnvironmentBuilder:buildAll()
end)
if not envOk then
    warn("[Bootstrap] EnvironmentBuilder failed: " .. tostring(envErr))
end

local sfOk, sfErr = pcall(function()
    totalEnvParts += StorefrontBuilder:buildBoulevard()
end)
if not sfOk then
    warn("[Bootstrap] StorefrontBuilder failed: " .. tostring(sfErr))
end

local gardenOk, gardenErr = pcall(function()
    totalEnvParts += GardenBuilder:buildGarden()
end)
if not gardenOk then
    warn("[Bootstrap] GardenBuilder failed: " .. tostring(gardenErr))
end

local runwayOk, runwayErr = pcall(function()
    totalEnvParts += RunwayBuilder:buildRunway()
end)
if not runwayOk then
    warn("[Bootstrap] RunwayBuilder failed: " .. tostring(runwayErr))
end

print("[Bootstrap] Environment built — " .. totalEnvParts .. " base parts")

---------------------------------------------------------------------------
-- 5. GAMEPLAY SERVICES
---------------------------------------------------------------------------
local PlotService = require(script.Services.PlotService)
local plotOk, plotErr = pcall(function()
    PlotService:init(EconomyService, HomeBuilder, PersistenceService)
end)
if not plotOk then
    warn("[Bootstrap] PlotService init failed: " .. tostring(plotErr))
end

local GardenService = require(script.Services.GardenService)
local gardenSvcOk, gardenSvcErr = pcall(function()
    GardenService:init(EconomyService, GardenBuilder, PersistenceService and PersistenceService:getSupabaseClient())
end)
if not gardenSvcOk then
    warn("[Bootstrap] GardenService init failed: " .. tostring(gardenSvcErr))
end

local WebhookClient = require(ReplicatedStorage.WebhookClient)
local webhooks = WebhookClient.new()  -- placeholder mode

local ShopService = require(script.Services.ShopService)
local shopOk, shopErr = pcall(function()
    ShopService:init(EconomyService, webhooks, PersistenceService)
end)
if not shopOk then
    warn("[Bootstrap] ShopService init failed: " .. tostring(shopErr))
end

local FashionService = require(script.Services.FashionService)
local fashionOk, fashionErr = pcall(function()
    FashionService:init(EconomyService)
end)
if not fashionOk then
    warn("[Bootstrap] FashionService init failed: " .. tostring(fashionErr))
end

local EventService = require(script.Services.EventService)
local eventOk, eventErr = pcall(function()
    EventService:init(webhooks)
end)
if not eventOk then
    warn("[Bootstrap] EventService init failed: " .. tostring(eventErr))
end

---------------------------------------------------------------------------
-- 5b. LEADERBOARD SERVICE
---------------------------------------------------------------------------
local LeaderboardService = require(script.Services.LeaderboardService)
local lbOk, lbErr = pcall(function()
    LeaderboardService:init(EconomyService, PlotService)
end)
if not lbOk then
    warn("[Bootstrap] LeaderboardService init failed: " .. tostring(lbErr))
end

---------------------------------------------------------------------------
-- 5c. GAME PASS SERVICE
---------------------------------------------------------------------------
local GamePassService = require(script.Services.GamePassService)
local gpOk, gpErr = pcall(function()
    GamePassService:init(EconomyService, GardenService)
    GamePassService:startAutoWaterLoop()
end)
if not gpOk then
    warn("[Bootstrap] GamePassService init failed: " .. tostring(gpErr))
end

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
        homeBuilder = HomeBuilder,
        gardenBuilder = GardenBuilder,
        environmentBuilder = EnvironmentBuilder,
        storefrontBuilder = StorefrontBuilder,
        runwayBuilder = RunwayBuilder,
    })
end)
if not testOk then
    warn("[Bootstrap] TestCommands init failed: " .. tostring(testErr))
end

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
        warn("[Bootstrap] Failed to load data for " .. player.Name ..
             ": " .. tostring(loadErr))
        -- Create minimal data so player can still play
        data = {
            userId = player.UserId,
            displayName = player.DisplayName,
            sunCoins = 100,
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
        if player.Parent then  -- still in game
            RemoteManager:fireClient("NotifyPlayer", player,
                "Welcome to Palm Springs Paradise! Head to El Paseo to explore.")

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
print("===========================================")
print("  PALM SPRINGS PARADISE — Server Ready!    ")
print("  Total base parts: " .. totalEnvParts)
print("  Players: " .. #Players:GetPlayers())
print("===========================================")
