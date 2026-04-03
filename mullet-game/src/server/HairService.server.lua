--[[
    HairService.server.lua
    Spawns hair from the sky. Players walk near it to collect it.
    Collected hair goes to MulletService (player mullet) and fills the Giant Jar.
    When the jar is full → triggers MulletGodService.
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local MulletConfig = require(ReplicatedStorage:WaitForChild("MulletConfig"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)

local function getOrCreateEvent(name)
    local e = Remotes:FindFirstChild(name)
    if e and e:IsA("RemoteEvent") then return e end
    local ev = Instance.new("RemoteEvent")
    ev.Name = name ; ev.Parent = Remotes
    return ev
end

local evJarFill  = getOrCreateEvent("UpdateJarFill")
local evNotify   = getOrCreateEvent("NotifyPlayer")

---------------------------------------------------------------------------
-- STATE
---------------------------------------------------------------------------
local jarFill    = 0   -- current hair in jar (0 to Capacity)
local hairClumps = {}  -- active hair parts in workspace
local mulletGodTriggered = false

-- Service references (injected)
local _mulletService    = nil
local _mulletGodService = nil

local HairService = {}

---------------------------------------------------------------------------
-- JAR
---------------------------------------------------------------------------

function HairService:getJarFill()
    return jarFill, MulletConfig.Jar.Capacity
end

function HairService:resetJar()
    jarFill = 0
    mulletGodTriggered = false
    -- Broadcast reset
    for _, player in ipairs(Players:GetPlayers()) do
        evJarFill:FireClient(player, { fill = 0, capacity = MulletConfig.Jar.Capacity })
    end
end

local function addToJar(amount)
    if mulletGodTriggered then return end

    jarFill = math.min(jarFill + amount, MulletConfig.Jar.Capacity)

    -- Broadcast updated fill to all players
    for _, player in ipairs(Players:GetPlayers()) do
        evJarFill:FireClient(player, {
            fill     = jarFill,
            capacity = MulletConfig.Jar.Capacity,
            percent  = jarFill / MulletConfig.Jar.Capacity,
        })
    end

    -- Trigger Mullet God when full
    if jarFill >= MulletConfig.Jar.Capacity and not mulletGodTriggered then
        mulletGodTriggered = true
        print("[HairService] JAR FULL — Mullet God incoming!")
        if _mulletGodService then
            task.spawn(function()
                _mulletGodService:activate()
            end)
        end
    end
end

---------------------------------------------------------------------------
-- HAIR SPAWNING
---------------------------------------------------------------------------

local hairFolder = workspace:FindFirstChild("HairClumps")
if not hairFolder then
    hairFolder = Instance.new("Folder")
    hairFolder.Name = "HairClumps"
    hairFolder.Parent = workspace
end

local function randomHairColor()
    local colors = MulletConfig.Hair.HairColors
    return colors[math.random(1, #colors)]
end

local function spawnHairClump()
    if #hairClumps >= MulletConfig.Hair.MaxHairOnMap then return end

    -- Random position above the maze area
    local mazeOrigin = MulletConfig.Maze.Origin
    local mazeSize   = MulletConfig.Maze.GridSize * MulletConfig.Maze.CellSize
    local x = mazeOrigin.X + math.random(0, mazeSize)
    local z = mazeOrigin.Z + math.random(0, mazeSize)
    local y = MulletConfig.Hair.SpawnHeight

    local part = Instance.new("Part")
    part.Name            = "HairClump_" .. tostring(math.random(100000, 999999))
    part.Size            = Vector3.new(3, 0.8, 3)   -- flat clump shape, not a ball
    part.Shape           = Enum.PartType.Block
    part.Color           = randomHairColor()
    part.Material        = Enum.Material.Fabric      -- looks fuzzy like hair
    part.CFrame          = CFrame.new(x, y, z)
    part.CanCollide      = true
    part.Anchored        = false
    part.CustomPhysicalProperties = PhysicalProperties.new(0.05, 0.8, 0, 0, 0)
    part.Parent          = hairFolder

    -- Gentle fall with slight drift
    local bv = Instance.new("BodyVelocity")
    bv.Velocity  = Vector3.new(math.random(-5, 5), -18, math.random(-5, 5))
    bv.MaxForce  = Vector3.new(1e4, 1e4, 1e4)
    bv.P         = 1e3
    bv.Parent    = part

    -- Once it lands (velocity near zero) remove the BodyVelocity so it sits still
    task.spawn(function()
        task.wait(1)
        if part and part.Parent then
            -- Check if it has landed by watching Y velocity
            local landWait = 0
            while part and part.Parent and landWait < 8 do
                task.wait(0.2)
                landWait += 0.2
                local vel = part.AssemblyLinearVelocity
                if vel and math.abs(vel.Y) < 1 then
                    -- Landed — remove BodyVelocity and anchor it
                    if part:FindFirstChildOfClass("BodyVelocity") then
                        part:FindFirstChildOfClass("BodyVelocity"):Destroy()
                    end
                    part.Anchored = true
                    break
                end
            end
        end
    end)

    -- Add a subtle glow so hair is easy to see on the ground
    local light = Instance.new("PointLight")
    light.Brightness = 1.5
    light.Range      = 6
    light.Color      = part.Color
    light.Parent     = part

    table.insert(hairClumps, part)

    -- Auto-destroy after 20 seconds if not collected
    task.delay(20, function()
        if part and part.Parent then
            part:Destroy()
            for i, h in ipairs(hairClumps) do
                if h == part then table.remove(hairClumps, i) break end
            end
        end
    end)

    return part
end

---------------------------------------------------------------------------
-- COLLECTION CHECK (runs every heartbeat)
---------------------------------------------------------------------------

local function checkCollection()
    local toRemove = {}

    for i, clump in ipairs(hairClumps) do
        if not clump or not clump.Parent then
            table.insert(toRemove, i)
        else
            local clumpPos = clump.Position

            -- Check if any player is close enough to collect
            for _, player in ipairs(Players:GetPlayers()) do
                local char = player.Character
                if char then
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if root then
                        local dist = (root.Position - clumpPos).Magnitude
                        if dist <= MulletConfig.Hair.PickupRadius then
                            -- Collect!
                            local amount = MulletConfig.Hair.PickupValue
                            if _mulletService then
                                _mulletService:addHair(player, amount)
                            end
                            addToJar(amount)

                            -- Update leaderstat
                            local ls = player:FindFirstChild("leaderstats")
                            if ls then
                                local hairStat = ls:FindFirstChild("Hair")
                                if hairStat then hairStat.Value += amount end
                            end

                            clump:Destroy()
                            table.insert(toRemove, i)
                            break
                        end
                    end
                end
            end
        end
    end

    -- Remove collected/expired clumps (reverse order)
    for j = #toRemove, 1, -1 do
        table.remove(hairClumps, toRemove[j])
    end
end

---------------------------------------------------------------------------
-- HAIR SPAWN LOOP
---------------------------------------------------------------------------

local difficulty = MulletConfig.Round.DefaultDifficulty
local spawnTimer = 0
local collectTimer = 0

function HairService:setDifficulty(diff)
    difficulty = diff
    print("[HairService] Difficulty set to " .. diff)
end

RunService.Heartbeat:Connect(function(dt)
    spawnTimer   += dt
    collectTimer += dt

    -- Spawn hair on interval based on difficulty
    local rate = MulletConfig.Round.HairDropRate[difficulty] or 3
    if spawnTimer >= (1 / rate) then
        spawnTimer = 0
        spawnHairClump()
    end

    -- Check collections every 0.1 seconds
    if collectTimer >= 0.1 then
        collectTimer = 0
        checkCollection()
    end
end)

---------------------------------------------------------------------------
-- INIT
---------------------------------------------------------------------------

function HairService:init(mulletService, mulletGodService)
    _mulletService    = mulletService
    _mulletGodService = mulletGodService
    print("[HairService] Initialized — hair will fall from the sky!")
end

-- Remote function for clients to query jar data
local fnGetJar = Remotes:FindFirstChild("GetJarData")
if not fnGetJar then
    fnGetJar = Instance.new("RemoteFunction")
    fnGetJar.Name = "GetJarData"
    fnGetJar.Parent = Remotes
end
fnGetJar.OnServerInvoke = function()
    return { fill = jarFill, capacity = MulletConfig.Jar.Capacity }
end

print("[HairService] Ready")

return HairService
