--[[
    MulletGodService.server.lua
    When the Giant Jar fills up, The Mullet God arrives.
    He dances above the map and rains coins on every player for 30 seconds.
    Then the jar resets and the round continues.
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local MulletConfig = require(ReplicatedStorage:WaitForChild("MulletConfig"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)

local function getOrCreateEvent(name)
    local e = Remotes:FindFirstChild(name)
    if e and e:IsA("RemoteEvent") then return e end
    local ev = Instance.new("RemoteEvent")
    ev.Name = name ; ev.Parent = Remotes
    return ev
end

local evArrived  = getOrCreateEvent("MulletGodArrived")
local evLeft     = getOrCreateEvent("MulletGodLeft")
local evRain     = getOrCreateEvent("MoneyRain")
local evNotify   = getOrCreateEvent("NotifyPlayer")

---------------------------------------------------------------------------
-- SERVICE REFERENCES
---------------------------------------------------------------------------
local _mulletService = nil
local _hairService   = nil

local MulletGodService = {}

function MulletGodService:init(mulletService, hairService)
    _mulletService = mulletService
    _hairService   = hairService
    print("[MulletGodService] Ready — The Mullet God awaits!")
end

---------------------------------------------------------------------------
-- COIN DROP PICKUP (physical coins that fall)
---------------------------------------------------------------------------

local function spawnCoinPickup(position)
    local coin = Instance.new("Part")
    coin.Name        = "CoinPickup"
    coin.Size        = Vector3.new(1, 0.2, 1)
    coin.Shape       = Enum.PartType.Cylinder
    coin.Color       = MulletConfig.Colors.Coin
    coin.Material    = Enum.Material.SmoothPlastic
    coin.CastShadow  = false
    coin.CFrame      = CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2)
    coin.Parent      = workspace

    -- Give it a random toss
    local bv = Instance.new("BodyVelocity")
    bv.Velocity  = Vector3.new(math.random(-15, 15), math.random(20, 35), math.random(-15, 15))
    bv.MaxForce  = Vector3.new(1e4, 1e4, 1e4)
    bv.P         = 1e4
    bv.Parent    = coin

    -- Auto-collect check
    task.spawn(function()
        task.wait(0.5)  -- let it fly first
        local lifeTime = 0
        while coin and coin.Parent and lifeTime < 10 do
            task.wait(0.1)
            lifeTime += 0.1
            for _, player in ipairs(Players:GetPlayers()) do
                local char = player.Character
                if char then
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if root and (root.Position - coin.Position).Magnitude < 5 then
                        -- Player collects this coin
                        if _mulletService then
                            _mulletService:addCoins(player, 5, "money_rain")
                        end
                        local ls = player:FindFirstChild("leaderstats")
                        if ls then
                            local c = ls:FindFirstChild("Coins")
                            if c then c.Value += 5 end
                        end
                        coin:Destroy()
                        return
                    end
                end
            end
        end
        if coin and coin.Parent then coin:Destroy() end
    end)
end

---------------------------------------------------------------------------
-- THE MULLET GOD ACTIVATION
---------------------------------------------------------------------------

local isActive = false

function MulletGodService:activate()
    if isActive then return end
    isActive = true

    print("[MulletGodService] THE MULLET GOD HAS ARRIVED!")

    -- Notify all players
    for _, player in ipairs(Players:GetPlayers()) do
        evNotify:FireClient(player, "🪙 THE MULLET GOD HAS ARRIVED! Money rain for 30 seconds! 🪙")
        evArrived:FireClient(player, { name = MulletConfig.MulletGodName })
    end

    -- Build the Mullet God NPC above the map center
    local godModel = Instance.new("Model")
    godModel.Name = "MulletGod"

    local body = Instance.new("Part")
    body.Name    = "HumanoidRootPart"
    body.Size    = Vector3.new(4, 6, 2)
    body.Color   = Color3.fromRGB(255, 200, 150)
    body.Anchored = true
    body.CFrame  = CFrame.new(0, MulletConfig.MulletGod.AppearanceHeight, 0)
    body.Parent  = godModel

    -- Giant mullet (represented as a big part flowing behind)
    local mullet = Instance.new("Part")
    mullet.Name     = "Mullet"
    mullet.Size     = Vector3.new(4, 8, 0.5)
    mullet.Color    = Color3.fromRGB(255, 215, 0)  -- legendary gold mullet
    mullet.Material = Enum.Material.Neon
    mullet.Anchored = true
    mullet.CFrame   = CFrame.new(0, MulletConfig.MulletGod.AppearanceHeight - 2, -1.5)
    mullet.Parent   = godModel

    -- Oakleys (two dark rectangles across the face)
    local oakleys = Instance.new("Part")
    oakleys.Name     = "Oakleys"
    oakleys.Size     = Vector3.new(3, 0.6, 0.2)
    oakleys.Color    = Color3.fromRGB(10, 10, 10)
    oakleys.Material = Enum.Material.SmoothPlastic
    oakleys.Anchored = true
    oakleys.CFrame   = CFrame.new(0, MulletConfig.MulletGod.AppearanceHeight + 1, 1.1)
    oakleys.Parent   = godModel

    godModel.PrimaryPart = body
    godModel.Parent = workspace

    -- Dance: bob up and down
    local danceTween = TweenService:Create(body, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        CFrame = body.CFrame * CFrame.new(0, 3, 0)
    })
    danceTween:Play()

    -- Money rain loop for 30 seconds
    local rainDuration = MulletConfig.MulletGod.RainDuration
    local elapsed = 0
    local rainInterval = 0.3  -- spawn coins every 0.3s

    -- Notify clients to show money rain effect
    for _, player in ipairs(Players:GetPlayers()) do
        evRain:FireClient(player, { duration = rainDuration, active = true })
    end

    -- Award base coins per second to all players + spawn physical coins
    task.spawn(function()
        while elapsed < rainDuration do
            task.wait(rainInterval)
            elapsed += rainInterval

            -- Award coins to all players
            for _, player in ipairs(Players:GetPlayers()) do
                local coinsThisTick = math.floor(MulletConfig.MulletGod.CoinsPerSecond * rainInterval)
                if _mulletService then
                    _mulletService:addCoins(player, coinsThisTick, "rain")
                end
                local ls = player:FindFirstChild("leaderstats")
                if ls then
                    local c = ls:FindFirstChild("Coins")
                    if c then c.Value += coinsThisTick end
                end
            end

            -- Spawn physical coin pickups from the sky
            for _ = 1, 3 do
                local x = math.random(-40, 40)
                local z = math.random(-40, 40)
                spawnCoinPickup(Vector3.new(x, 40, z))
            end
        end

        -- Rain over — give bonus to top hair collector
        local topPlayer = nil
        local topHair   = 0
        for _, player in ipairs(Players:GetPlayers()) do
            local data = _mulletService and _mulletService:getData(player)
            if data and data.hairCollected > topHair then
                topHair   = data.hairCollected
                topPlayer = player
            end
        end

        if topPlayer then
            if _mulletService then
                _mulletService:addCoins(topPlayer, MulletConfig.MulletGod.BonusForTopCollector, "top_collector")
            end
            for _, player in ipairs(Players:GetPlayers()) do
                evNotify:FireClient(player, "👑 " .. topPlayer.Name .. " collected the most hair and got a bonus!")
            end
        end

        -- End event
        danceTween:Cancel()
        godModel:Destroy()
        isActive = false

        for _, player in ipairs(Players:GetPlayers()) do
            evRain:FireClient(player, { active = false })
            evLeft:FireClient(player)
            evNotify:FireClient(player, "The Mullet God has left. Fill the jar again!")
        end

        -- Reset jar
        if _hairService then
            _hairService:resetJar()
        end

        print("[MulletGodService] Money rain ended. Jar reset.")
    end)
end

print("[MulletGodService] Initialized")

return MulletGodService
