--[[
    JobsService.server.lua
    Manages the 5 silly hair-collecting mini-games (Jobs).

    Jobs:
      1. Shave the Sleeping Giant — succeed: hair; fail: get SWATTED across map
      2. Unclog the Toilet       — succeed: hair; fail: flushed into sewer obby
      3. Chase the Hairy Chicken — succeed: hair; fail: chicken drops a random egg
      4. Shampoo Surf            — succeed: hair; fail: wipe out and bump players
      5. Tornado Vacuum          — succeed: hair; fail: get launched into maze
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MulletConfig = require(ReplicatedStorage:WaitForChild("MulletConfig"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)

local function getOrCreateEvent(name)
    local e = Remotes:FindFirstChild(name)
    if e and e:IsA("RemoteEvent") then return e end
    local ev = Instance.new("RemoteEvent")
    ev.Name = name ; ev.Parent = Remotes
    return ev
end

local evJobStarted   = getOrCreateEvent("JobStarted")
local evJobCompleted = getOrCreateEvent("JobCompleted")
local evJobFailed    = getOrCreateEvent("JobFailed")
local evNotify       = getOrCreateEvent("NotifyPlayer")
local evStartJob     = getOrCreateEvent("StartJob")

---------------------------------------------------------------------------
-- SERVICE REFERENCES
---------------------------------------------------------------------------
local _mulletService = nil
local _hairService   = nil

local JobsService = {}

function JobsService:init(mulletService, hairService)
    _mulletService = mulletService
    _hairService   = hairService
end

---------------------------------------------------------------------------
-- ACTIVE JOB TRACKING
---------------------------------------------------------------------------
-- activeJobs[userId] = { jobId, startTime, timeLimit }
local activeJobs = {}

---------------------------------------------------------------------------
-- FAIL PENALTIES
---------------------------------------------------------------------------

local function penaltySwat(player)
    -- Launch player across the map
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local bv = Instance.new("BodyVelocity")
    bv.Velocity  = Vector3.new(math.random(-80, 80), 60, math.random(-80, 80))
    bv.MaxForce  = Vector3.new(1e5, 1e5, 1e5)
    bv.P         = 1e5
    bv.Parent    = root
    game:GetService("Debris"):AddItem(bv, 0.3)

    evNotify:FireClient(player, "💥 THE GIANT SWATTED YOU!")
    print("[JobsService] " .. player.Name .. " got swatted!")
end

local function penaltyFlush(player)
    -- Teleport player to sewer obby location
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Sewer obby is below the map
    root.CFrame = CFrame.new(0, -50, 0)
    evNotify:FireClient(player, "🚽 YOU GOT FLUSHED! Complete the sewer obby to escape!")
    print("[JobsService] " .. player.Name .. " got flushed!")

    -- Simple sewer obby: spawn platforms, give them 30s to jump back
    task.spawn(function()
        -- Build simple sewer platforms
        local sewerFolder = Instance.new("Folder")
        sewerFolder.Name = "SewerObby_" .. player.UserId
        sewerFolder.Parent = workspace

        local platforms = {}
        for i = 1, 8 do
            local plat = Instance.new("Part")
            plat.Anchored = true
            plat.Size     = Vector3.new(4, 1, 4)
            plat.Color    = Color3.fromRGB(60, 80, 60)
            plat.CFrame   = CFrame.new(
                math.random(-10, 10),
                -50 + i * 8,
                math.random(-10, 10)
            )
            plat.Parent = sewerFolder
            table.insert(platforms, plat)
        end

        -- Final exit platform brings them back to surface
        local exit = Instance.new("Part")
        exit.Anchored = true
        exit.Size     = Vector3.new(6, 1, 6)
        exit.Color    = Color3.fromRGB(255, 215, 0)
        exit.CFrame   = CFrame.new(0, -50 + 9 * 8, 0)
        exit.Parent   = sewerFolder

        -- Check if player reaches the exit
        local escaped = false
        local timer   = 0
        while timer < 30 and not escaped do
            task.wait(0.5)
            timer += 0.5
            if char and char.Parent then
                local rp = char:FindFirstChild("HumanoidRootPart")
                if rp then
                    local dist = (rp.Position - exit.Position).Magnitude
                    if dist < 5 then
                        escaped = true
                    end
                end
            else
                break
            end
        end

        -- Clean up sewer and return player to surface
        sewerFolder:Destroy()
        if char and char.Parent then
            local rp = char:FindFirstChild("HumanoidRootPart")
            if rp then
                rp.CFrame = CFrame.new(math.random(-20, 20), 5, math.random(-20, 20))
                if escaped then
                    evNotify:FireClient(player, "🎉 You escaped the sewer!")
                    -- Reward a little hair for escaping
                    if _mulletService then
                        _mulletService:addHair(player, 2)
                    end
                else
                    evNotify:FireClient(player, "⏱ Time's up! Sewer spat you out.")
                end
            end
        end
    end)
end

local function penaltyLaunch(player)
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local bv = Instance.new("BodyVelocity")
    bv.Velocity  = Vector3.new(math.random(-50, 50), 80, math.random(-50, 50))
    bv.MaxForce  = Vector3.new(1e5, 1e5, 1e5)
    bv.P         = 1e5
    bv.Parent    = root
    game:GetService("Debris"):AddItem(bv, 0.4)

    evNotify:FireClient(player, "🌪 THE TORNADO LAUNCHED YOU!")
end

local function penaltySlide(player)
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local bv = Instance.new("BodyVelocity")
    bv.Velocity  = Vector3.new(math.random(-40, 40), 10, math.random(-40, 40))
    bv.MaxForce  = Vector3.new(1e5, 1e5, 1e5)
    bv.P         = 1e5
    bv.Parent    = root
    game:GetService("Debris"):AddItem(bv, 0.3)

    evNotify:FireClient(player, "🧴 You wiped out on the shampoo!")
end

local function penaltyEgg(player)
    -- Chicken lays a hair clump somewhere random — no direct penalty to player
    evNotify:FireClient(player, "🐔 The chicken got away and laid a hair egg somewhere!")
    -- Drop some bonus hair randomly on the map (other players might get it)
    local bonusPart = Instance.new("Part")
    bonusPart.Name   = "ChickenEgg"
    bonusPart.Size   = Vector3.new(2, 2, 2)
    bonusPart.Shape  = Enum.PartType.Ball
    bonusPart.Color  = Color3.fromRGB(255, 240, 200)
    bonusPart.CFrame = CFrame.new(math.random(-30, 30), 5, math.random(-30, 30))
    bonusPart.Parent = workspace
    game:GetService("Debris"):AddItem(bonusPart, 20)
end

local PENALTIES = {
    swat   = penaltySwat,
    flush  = penaltyFlush,
    launch = penaltyLaunch,
    slide  = penaltySlide,
    egg    = penaltyEgg,
}

---------------------------------------------------------------------------
-- JOB LOGIC
---------------------------------------------------------------------------

local function getJobDef(jobId)
    for _, job in ipairs(MulletConfig.Jobs) do
        if job.id == jobId then return job end
    end
    return nil
end

local JOB_TIME_LIMITS = {
    sleeping_giant = 15,
    toilet         = 20,
    chicken        = 20,
    shampoo_surf   = 12,
    tornado        = 18,
}

function JobsService:startJob(player, jobId)
    local userId = player.UserId
    if activeJobs[userId] then
        evNotify:FireClient(player, "Finish your current job first!")
        return false
    end

    local jobDef = getJobDef(jobId)
    if not jobDef then return false end

    local timeLimit = JOB_TIME_LIMITS[jobId] or 15
    activeJobs[userId] = { jobId = jobId, startTime = os.clock(), timeLimit = timeLimit }

    evJobStarted:FireClient(player, {
        jobId     = jobId,
        jobName   = jobDef.name,
        timeLimit = timeLimit,
    })
    evNotify:FireClient(player, "🎯 Job started: " .. jobDef.name)

    -- Auto-fail if time runs out
    task.delay(timeLimit, function()
        if activeJobs[userId] and activeJobs[userId].jobId == jobId then
            JobsService:failJob(player, jobId)
        end
    end)

    print("[JobsService] " .. player.Name .. " started job: " .. jobId)
    return true
end

function JobsService:completeJob(player, jobId)
    local userId = player.UserId
    if not activeJobs[userId] or activeJobs[userId].jobId ~= jobId then return end

    local jobDef = getJobDef(jobId)
    if not jobDef then return end

    activeJobs[userId] = nil

    -- Award hair
    if _mulletService then
        _mulletService:addHair(player, jobDef.hairReward)
    end

    evJobCompleted:FireClient(player, {
        jobId      = jobId,
        hairReward = jobDef.hairReward,
    })
    evNotify:FireClient(player, "✅ Job done! +" .. jobDef.hairReward .. " hair!")
    print("[JobsService] " .. player.Name .. " completed job: " .. jobId)
end

function JobsService:failJob(player, jobId)
    local userId = player.UserId
    activeJobs[userId] = nil

    local jobDef = getJobDef(jobId)
    if not jobDef then return end

    evJobFailed:FireClient(player, { jobId = jobId })

    -- Apply penalty
    local penaltyFn = PENALTIES[jobDef.failPenalty]
    if penaltyFn then
        penaltyFn(player)
    end

    print("[JobsService] " .. player.Name .. " failed job: " .. jobId)
end

---------------------------------------------------------------------------
-- REMOTE HANDLER — client requests to start a job
---------------------------------------------------------------------------
evStartJob.OnServerEvent:Connect(function(player, jobId)
    if type(jobId) ~= "string" then return end
    JobsService:startJob(player, jobId)
end)

-- Client fires when they complete a job interaction
local evCompleteJob = getOrCreateEvent("JobCompleted")
-- Note: using a separate internal complete trigger
local evClientComplete = getOrCreateEvent("ClientJobComplete")
evClientComplete.OnServerEvent:Connect(function(player, jobId)
    if type(jobId) ~= "string" then return end
    JobsService:completeJob(player, jobId)
end)

---------------------------------------------------------------------------
-- CLEANUP ON PLAYER LEAVE
---------------------------------------------------------------------------
Players.PlayerRemoving:Connect(function(player)
    activeJobs[player.UserId] = nil
end)

print("[JobsService] Initialized — 5 jobs ready!")

return JobsService
