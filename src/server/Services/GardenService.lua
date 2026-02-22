--[[
    GardenService.lua
    Manages the shared community desert garden: planting, watering,
    growth cycles, wilting, harvesting, and real-time state broadcast.

    The garden is collaborative — any player can water any plant.
    Growth is server-tick driven (every 5s), and state is broadcast
    to all connected clients for real-time visualization.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig    = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteManager = require(ReplicatedStorage:WaitForChild("RemoteManager"))
local ItemCatalog   = require(ReplicatedStorage:WaitForChild("ItemCatalog"))
local Utilities     = require(ReplicatedStorage:WaitForChild("Utilities"))

local GardenService = {}

-- Internal state
GardenService._plots = {}           -- plotIndex → GardenPlot data
GardenService._economyService = nil
GardenService._gardenBuilder = nil
GardenService._supabaseClient = nil
GardenService._tickRunning = false

---------------------------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------------------------

function GardenService:init(economyService, gardenBuilder, supabaseClient)
    self._economyService = economyService
    self._gardenBuilder = gardenBuilder
    self._supabaseClient = supabaseClient

    -- Initialize all 16 garden plots
    for i = 1, GameConfig.World.GardenPlots do
        self._plots[i] = {
            index = i,
            plantId = nil,
            plantedBy = nil,
            plantedAt = nil,
            growthStage = "empty",
            lastWatered = nil,
            waterCount = 0,
        }
    end

    -- Connect remote events
    local plantEvent = RemoteManager:getEvent("PlantSeed")
    if plantEvent then
        plantEvent.OnServerEvent:Connect(function(player, plotIndex, plantId)
            self:plantSeed(player, plotIndex, plantId)
        end)
    end

    local waterEvent = RemoteManager:getEvent("WaterPlant")
    if waterEvent then
        waterEvent.OnServerEvent:Connect(function(player, plotIndex)
            self:waterPlant(player, plotIndex)
        end)
    end

    local harvestEvent = RemoteManager:getEvent("HarvestPlant")
    if harvestEvent then
        harvestEvent.OnServerEvent:Connect(function(player, plotIndex)
            self:harvestPlant(player, plotIndex)
        end)
    end

    -- Remote function
    local getGardenFunc = RemoteManager:getFunction("GetGardenState")
    if getGardenFunc then
        getGardenFunc.OnServerInvoke = function(_player)
            return self:getFullState()
        end
    end

    -- Start growth tick
    self:_startGrowthTick()

    print("[GardenService] Initialized with " ..
          GameConfig.World.GardenPlots .. " plots")
end

---------------------------------------------------------------------------
-- PLANT SEED
---------------------------------------------------------------------------

function GardenService:plantSeed(player: Player, plotIndex: number, plantId: string): boolean
    -- Validate
    if type(plotIndex) ~= "number" or plotIndex < 1 or plotIndex > GameConfig.World.GardenPlots then
        return false
    end

    local plot = self._plots[plotIndex]
    if plot.growthStage ~= "empty" then
        RemoteManager:fireClient("NotifyPlayer", player,
            "This plot already has something planted!")
        return false
    end

    -- Check plant exists in catalog
    local plant = ItemCatalog.getPlant(plantId)
    if not plant then
        warn("[GardenService] Unknown plant: " .. tostring(plantId))
        return false
    end

    -- Check player has the seed (or can afford it)
    if not self._economyService:hasItem(player, plantId) then
        -- Try to buy the seed directly
        if not self._economyService:removeCoins(player, plant.seedPrice, "Plant: " .. plantId) then
            RemoteManager:fireClient("NotifyPlayer", player,
                "Not enough SunCoins for " .. plant.name .. " seed! Need " .. plant.seedPrice)
            return false
        end
    else
        self._economyService:removeItem(player, plantId)
    end

    -- Plant the seed
    plot.plantId = plantId
    plot.plantedBy = player.UserId
    plot.plantedAt = os.time()
    plot.growthStage = "seed"
    plot.lastWatered = os.time()
    plot.waterCount = 1

    -- Update visual
    self:_updateVisual(plotIndex)
    self:_broadcastState()

    RemoteManager:fireClient("NotifyPlayer", player,
        "Planted " .. plant.name .. " in plot #" .. plotIndex .. "!")
    print("[GardenService] " .. player.Name .. " planted " .. plantId .. " in plot #" .. plotIndex)

    return true
end

---------------------------------------------------------------------------
-- WATER PLANT
---------------------------------------------------------------------------

function GardenService:waterPlant(player: Player, plotIndex: number): boolean
    if type(plotIndex) ~= "number" or plotIndex < 1 or plotIndex > GameConfig.World.GardenPlots then
        return false
    end

    local plot = self._plots[plotIndex]
    if plot.growthStage == "empty" or plot.growthStage == "dead" or plot.growthStage == "mature" then
        RemoteManager:fireClient("NotifyPlayer", player,
            "Nothing to water here!")
        return false
    end

    -- Watering cooldown per player (simplified: check last watered time)
    local now = os.time()
    if plot.lastWatered and (now - plot.lastWatered) < GameConfig.Timing.WateringCooldown then
        RemoteManager:fireClient("NotifyPlayer", player,
            "This plant was just watered! Wait a moment.")
        return false
    end

    -- Water the plant
    plot.lastWatered = now
    plot.waterCount += 1

    -- If wilting, revert to previous growth stage
    if plot.growthStage == "wilting" then
        -- Determine which stage it should be based on age
        local age = now - (plot.plantedAt or now)
        plot.growthStage = self:_getStageForAge(age)
    end

    -- Update visual
    self:_updateVisual(plotIndex)
    self:_broadcastState()

    -- Give small coin reward for collaborative watering
    self._economyService:addCoins(player, 2, "Watered garden plot #" .. plotIndex)

    RemoteManager:fireClient("NotifyPlayer", player,
        "Watered plot #" .. plotIndex .. "! +2 SC")

    return true
end

---------------------------------------------------------------------------
-- HARVEST PLANT
---------------------------------------------------------------------------

function GardenService:harvestPlant(player: Player, plotIndex: number): boolean
    if type(plotIndex) ~= "number" or plotIndex < 1 or plotIndex > GameConfig.World.GardenPlots then
        return false
    end

    local plot = self._plots[plotIndex]
    if plot.growthStage ~= "mature" then
        RemoteManager:fireClient("NotifyPlayer", player,
            "This plant isn't ready to harvest yet!")
        return false
    end

    -- Get plant data for rewards
    local plant = ItemCatalog.getPlant(plot.plantId)
    if not plant then return false end

    -- Award rewards
    self._economyService:addCoins(player, plant.harvestValue,
        "Harvested " .. plant.name)
    self._economyService:addPrestige(player, plant.prestigeReward)

    -- Update player stats
    local data = self._economyService:getPlayerData(player)
    if data then
        data.stats.plantsHarvested += 1
    end

    -- Clear plot
    plot.plantId = nil
    plot.plantedBy = nil
    plot.plantedAt = nil
    plot.growthStage = "empty"
    plot.lastWatered = nil
    plot.waterCount = 0

    self:_updateVisual(plotIndex)
    self:_broadcastState()

    RemoteManager:fireClient("NotifyPlayer", player,
        "Harvested " .. plant.name .. "! +" .. plant.harvestValue ..
        " SC, +" .. plant.prestigeReward .. " Prestige")

    print("[GardenService] " .. player.Name .. " harvested " ..
          plant.name .. " from plot #" .. plotIndex)
    return true
end

---------------------------------------------------------------------------
-- GROWTH TICK
---------------------------------------------------------------------------

function GardenService:_startGrowthTick()
    if self._tickRunning then return end
    self._tickRunning = true

    task.spawn(function()
        while self._tickRunning do
            task.wait(GameConfig.Timing.GardenTickInterval)
            self:_updateGrowthCycle()
        end
    end)
end

function GardenService:_updateGrowthCycle()
    local now = os.time()
    local changed = false

    for i, plot in pairs(self._plots) do
        if plot.growthStage ~= "empty" and plot.growthStage ~= "dead" and plot.growthStage ~= "mature" then
            local age = now - (plot.plantedAt or now)
            local timeSinceWater = now - (plot.lastWatered or now)

            -- Check for wilting
            if plot.growthStage ~= "wilting" and timeSinceWater >= GameConfig.Timing.WiltWarningAfter then
                plot.growthStage = "wilting"
                changed = true
            elseif plot.growthStage == "wilting" then
                -- Check for death
                if timeSinceWater >= GameConfig.Timing.WiltWarningAfter + GameConfig.Timing.WiltToDead then
                    plot.growthStage = "dead"
                    changed = true
                end
            else
                -- Advance growth based on age
                local newStage = self:_getStageForAge(age)
                if newStage ~= plot.growthStage then
                    plot.growthStage = newStage
                    changed = true
                end
            end

            if changed then
                self:_updateVisual(i)
            end
        end

        -- Auto-clear dead plants after 60s
        if plot.growthStage == "dead" then
            local deathTime = (plot.lastWatered or plot.plantedAt or now) +
                              GameConfig.Timing.WiltWarningAfter + GameConfig.Timing.WiltToDead
            if now - deathTime > 60 then
                plot.plantId = nil
                plot.plantedBy = nil
                plot.plantedAt = nil
                plot.growthStage = "empty"
                plot.lastWatered = nil
                plot.waterCount = 0
                self:_updateVisual(i)
                changed = true
            end
        end
    end

    if changed then
        self:_broadcastState()
    end
end

function GardenService:_getStageForAge(age: number): string
    local t = GameConfig.Timing
    if age >= t.SeedToSprout + t.SproutToGrowing + t.GrowingToMature then
        return "mature"
    elseif age >= t.SeedToSprout + t.SproutToGrowing then
        return "growing"
    elseif age >= t.SeedToSprout then
        return "sprout"
    else
        return "seed"
    end
end

---------------------------------------------------------------------------
-- VISUALS & BROADCAST
---------------------------------------------------------------------------

function GardenService:_updateVisual(plotIndex: number)
    if not self._gardenBuilder then return end

    local plot = self._plots[plotIndex]
    local plantColor = nil

    -- Determine color from plant type
    if plot.plantId then
        local plant = ItemCatalog.getPlant(plot.plantId)
        if plant then
            -- Different plants have different colors
            local colorMap = {
                saguaro_cactus = GameConfig.Colors.CactusGreen,
                barrel_cactus = Color3.fromRGB(100, 150, 80),
                agave = Color3.fromRGB(60, 140, 120),
                desert_marigold = Color3.fromRGB(255, 200, 50),
                bougainvillea = Color3.fromRGB(200, 50, 150),
                palm_tree = GameConfig.Colors.PalmCanopy,
                bird_of_paradise = Color3.fromRGB(255, 140, 30),
                prickly_pear = Color3.fromRGB(80, 160, 60),
                ocotillo = Color3.fromRGB(180, 50, 30),
                desert_sage = Color3.fromRGB(150, 170, 140),
            }
            plantColor = colorMap[plot.plantId] or GameConfig.Colors.CactusGreen
        end
    end

    self._gardenBuilder:updatePlantVisual(plotIndex, plot.growthStage, plantColor)
end

function GardenService:_broadcastState()
    RemoteManager:fireAllClients("GardenStateUpdate", self:getFullState())
end

---------------------------------------------------------------------------
-- STATE ACCESS
---------------------------------------------------------------------------

function GardenService:getFullState(): table
    local state = {}
    for i, plot in pairs(self._plots) do
        state[i] = {
            index = plot.index,
            plantId = plot.plantId,
            growthStage = plot.growthStage,
            plantedBy = plot.plantedBy,
            waterCount = plot.waterCount,
            lastWatered = plot.lastWatered,
        }
    end
    return state
end

function GardenService:getPlot(index: number): table?
    return self._plots[index]
end

return GardenService
