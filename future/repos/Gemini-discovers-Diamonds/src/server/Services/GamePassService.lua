--[[
    GamePassService.lua
    Cosmetic game pass management for Palm Springs Paradise.
    Handles VIP, Double Coins, and Auto-Water passes.
    Checks ownership on join, grants perks server-side.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local GameConfig    = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteManager = require(ReplicatedStorage:WaitForChild("RemoteManager"))

local GamePassService = {}

GamePassService._playerPasses = {}   -- userId → { passName → boolean }
GamePassService._economyService = nil
GamePassService._gardenService = nil

---------------------------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------------------------

function GamePassService:init(economyService, gardenService)
    self._economyService = economyService
    self._gardenService = gardenService

    -- Listen for in-game pass purchases
    MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
        if purchased then
            self:_onPassPurchased(player, passId)
        end
    end)

    print("[GamePassService] Initialized — " ..
          "VIP=" .. GameConfig.Economy.GamePasses.VIP ..
          " DoubleSC=" .. GameConfig.Economy.GamePasses.DoubleCoins ..
          " AutoWater=" .. GameConfig.Economy.GamePasses.AutoWater)
end

---------------------------------------------------------------------------
-- PLAYER SETUP (call from bootstrap on PlayerAdded)
---------------------------------------------------------------------------

--- Check which passes a player owns. Call on join.
function GamePassService:loadPlayerPasses(player: Player)
    local passes = {}
    local passConfig = GameConfig.Economy.GamePasses

    for passName, passId in pairs(passConfig) do
        if passId > 0 then
            local ok, owns = pcall(function()
                return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
            end)
            passes[passName] = (ok and owns) or false
        else
            -- ID=0 means not yet configured — treat as not owned
            passes[passName] = false
        end
    end

    self._playerPasses[player.UserId] = passes

    -- Apply immediate perks
    if passes.VIP then
        RemoteManager:fireClient("NotifyPlayer", player,
            "VIP Pass active! You get a gold name tag and priority event access.")
    end

    print("[GamePassService] " .. player.Name .. " passes: " ..
          (passes.VIP and "VIP " or "") ..
          (passes.DoubleCoins and "2xSC " or "") ..
          (passes.AutoWater and "AutoWater " or ""))
end

--- Cleanup on leave.
function GamePassService:removePlayer(player: Player)
    self._playerPasses[player.UserId] = nil
end

---------------------------------------------------------------------------
-- PASS PURCHASE HANDLER
---------------------------------------------------------------------------

function GamePassService:_onPassPurchased(player: Player, passId: number)
    local passConfig = GameConfig.Economy.GamePasses

    for passName, configId in pairs(passConfig) do
        if configId == passId then
            if not self._playerPasses[player.UserId] then
                self._playerPasses[player.UserId] = {}
            end
            self._playerPasses[player.UserId][passName] = true

            RemoteManager:fireClient("NotifyPlayer", player,
                "Thank you! " .. passName .. " pass activated!")
            print("[GamePassService] " .. player.Name .. " purchased " .. passName)
            return
        end
    end
end

---------------------------------------------------------------------------
-- PERK QUERIES (called by other services)
---------------------------------------------------------------------------

--- Does the player have the VIP pass?
function GamePassService:isVIP(player: Player): boolean
    local passes = self._playerPasses[player.UserId]
    return passes and passes.VIP or false
end

--- Does the player have Double Coins pass?
function GamePassService:hasDoubleCoins(player: Player): boolean
    local passes = self._playerPasses[player.UserId]
    return passes and passes.DoubleCoins or false
end

--- Does the player have Auto-Water pass?
function GamePassService:hasAutoWater(player: Player): boolean
    local passes = self._playerPasses[player.UserId]
    return passes and passes.AutoWater or false
end

--- Get the coin multiplier for a player (1x normal, 2x with pass).
function GamePassService:getCoinMultiplier(player: Player): number
    return self:hasDoubleCoins(player) and 2 or 1
end

---------------------------------------------------------------------------
-- AUTO-WATER LOOP
-- Players with AutoWater pass get their garden plots watered
-- automatically every 90 seconds.
---------------------------------------------------------------------------

function GamePassService:startAutoWaterLoop()
    task.spawn(function()
        while true do
            task.wait(90)
            for _, player in ipairs(Players:GetPlayers()) do
                if self:hasAutoWater(player) and self._gardenService then
                    -- Water all plots that the player planted
                    local state = self._gardenService:getFullState()
                    for i, plot in pairs(state) do
                        if plot.plantedBy == player.UserId and
                           plot.growthStage ~= "empty" and
                           plot.growthStage ~= "dead" and
                           plot.growthStage ~= "mature" then
                            self._gardenService:waterPlant(player, i)
                        end
                    end
                end
            end
        end
    end)
end

return GamePassService
