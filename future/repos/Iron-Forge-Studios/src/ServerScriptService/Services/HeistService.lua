--[[
    HeistService.lua (Server)
    Manages the steal-the-icon heist system.
    - 10s countdown, 15s lockpicking minigame
    - Anti-grief: target cooldowns, newbie shield, daily limits, server-hop lockout
    - Vault system (protected icons)
    - Steal Cam replay notification
    All validation is server-authoritative.
]]

local Players = game:GetService("Players")

local Constants = require(game.ReplicatedStorage.Modules.Shared.Constants)
local Util = require(game.ReplicatedStorage.Modules.Shared.Util)
local Remotes = require(game.ReplicatedStorage.Modules.Shared.Remotes)
local DataService = require(game.ServerScriptService.Services.DataService)
local RateLimiter = require(game.ServerScriptService.Modules.RateLimiter)

local HeistService = {}

-- ═══════════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════════
local activeHeists = {} -- { [attackerUserId] = heistData }
local heistLimiter = RateLimiter.new({
    MaxCalls = 1,
    WindowSeconds = Constants.RateLimit.HEIST_START_COOLDOWN,
})

-- Lockpick minigame: server generates a sequence, client must match it
local LOCKPICK_SEQUENCE_LENGTH = 6
local LOCKPICK_DIRECTIONS = { "Up", "Down", "Left", "Right" }

-- ═══════════════════════════════════════════════════════════════
-- VALIDATION HELPERS
-- ═══════════════════════════════════════════════════════════════

local function canStartHeist(attacker: Player): (boolean, string?)
    local data = DataService.GetData(attacker)
    if not data then return false, "DataNotLoaded" end

    local now = os.time()

    -- Server-hop lockout
    local timeSinceJoin = now - (data.HeistServerJoinTime or 0)
    if timeSinceJoin < Constants.Heist.SERVER_HOP_LOCKOUT_SECONDS then
        local remaining = Constants.Heist.SERVER_HOP_LOCKOUT_SECONDS - timeSinceJoin
        return false, "ServerHopLockout:" .. tostring(math.ceil(remaining))
    end

    -- Cooldown from failed heist
    if data.HeistCooldownUntil > now then
        local remaining = data.HeistCooldownUntil - now
        return false, "OnCooldown:" .. tostring(math.ceil(remaining))
    end

    -- Daily attempts
    local today = Util.GetDayNumber()
    if data.HeistLastResetDay ~= today then
        data.HeistLastResetDay = today
        data.HeistAttemptsToday = 0
    end

    local maxAttempts = Constants.Heist.DAILY_ATTEMPTS
    if DataService.HasPass(attacker, "HeistMaster") then
        maxAttempts = maxAttempts + 3
    end

    if data.HeistAttemptsToday >= maxAttempts then
        return false, "DailyLimitReached"
    end

    -- Already in a heist
    if activeHeists[attacker.UserId] then
        return false, "AlreadyInHeist"
    end

    return true
end

local function canTargetPlayer(attacker: Player, target: Player): (boolean, string?)
    if attacker.UserId == target.UserId then
        return false, "CannotTargetSelf"
    end

    local targetData = DataService.GetData(target)
    if not targetData then return false, "TargetDataNotLoaded" end

    local now = os.time()

    -- Newbie shield
    if targetData.NewbieShieldUntil > now then
        return false, "NewbieShield"
    end

    -- Purchased shield boost
    for _, boost in targetData.ActiveBoosts do
        if boost.BoostType == "Shield" and boost.ExpiresAt > now then
            return false, "ShieldActive"
        end
    end

    -- Target cooldown (attacker can't hit same target within 30min)
    local attackerData = DataService.GetData(attacker)
    if attackerData then
        local cooldownUntil = attackerData.HeistTargetCooldowns[tostring(target.UserId)]
        if cooldownUntil and cooldownUntil > now then
            return false, "TargetCooldown"
        end
    end

    return true
end

local function findStealableIcon(target: Player): table?
    local targetData = DataService.GetData(target)
    if not targetData then return nil end

    -- Find displayed, non-vaulted icons
    local stealable = {}
    for _, icon in targetData.Icons do
        if icon.Displayed and icon.VaultSlot == nil then
            table.insert(stealable, icon)
        end
    end

    if #stealable == 0 then return nil end

    -- Pick random stealable icon
    return stealable[math.random(1, #stealable)]
end

local function generateLockpickSequence(): { string }
    local sequence = {}
    for _ = 1, LOCKPICK_SEQUENCE_LENGTH do
        table.insert(sequence, LOCKPICK_DIRECTIONS[math.random(1, #LOCKPICK_DIRECTIONS)])
    end
    return sequence
end

-- ═══════════════════════════════════════════════════════════════
-- HEIST FLOW
-- ═══════════════════════════════════════════════════════════════

local function handleHeistStart(attacker: Player, targetUserId: number)
    if type(targetUserId) ~= "number" then return end

    -- Rate limit
    if not heistLimiter:Check(attacker) then return end

    -- Validate attacker
    local canStart, reason = canStartHeist(attacker)
    if not canStart then
        Remotes.GetEvent("HeistResult"):FireClient(attacker, {
            Success = false,
            Phase = "Start",
            Reason = reason,
        })
        return
    end

    -- Find target player
    local target = Players:GetPlayerByUserId(targetUserId)
    if not target then
        Remotes.GetEvent("HeistResult"):FireClient(attacker, {
            Success = false,
            Phase = "Start",
            Reason = "TargetNotInServer",
        })
        return
    end

    -- Validate target
    local canTarget, targetReason = canTargetPlayer(attacker, target)
    if not canTarget then
        Remotes.GetEvent("HeistResult"):FireClient(attacker, {
            Success = false,
            Phase = "Start",
            Reason = targetReason,
        })
        return
    end

    -- Find stealable icon
    local stealableIcon = findStealableIcon(target)
    if not stealableIcon then
        Remotes.GetEvent("HeistResult"):FireClient(attacker, {
            Success = false,
            Phase = "Start",
            Reason = "NoStealableIcons",
        })
        return
    end

    -- Generate lockpick sequence
    local sequence = generateLockpickSequence()

    -- Create heist session
    local heistData = {
        AttackerId = attacker.UserId,
        TargetId = target.UserId,
        TargetIconUID = stealableIcon.UID,
        TargetIconId = stealableIcon.IconId,
        Sequence = sequence,
        InputIndex = 0,
        StartedAt = os.time(),
        Phase = "Countdown",
    }
    activeHeists[attacker.UserId] = heistData

    -- Increment daily attempts
    local attackerData = DataService.GetData(attacker)
    if attackerData then
        attackerData.HeistAttemptsToday += 1
    end

    -- Notify attacker: start countdown
    Remotes.GetEvent("HeistCountdown"):FireClient(attacker, {
        TargetName = target.Name,
        TargetUserId = target.UserId,
        CountdownSeconds = Constants.Heist.COUNTDOWN_SECONDS,
    })

    -- Notify target: someone is attempting a heist
    Remotes.GetEvent("HeistNotification"):FireClient(target, {
        Type = "HeistIncoming",
        AttackerName = attacker.Name,
    })

    -- After countdown, start lockpick phase
    task.delay(Constants.Heist.COUNTDOWN_SECONDS, function()
        local heist = activeHeists[attacker.UserId]
        if not heist or heist.StartedAt ~= heistData.StartedAt then return end

        heist.Phase = "Lockpick"
        heist.LockpickStartedAt = os.time()

        -- Send lockpick start to attacker (sequence hints, not the answer)
        Remotes.GetEvent("HeistLockpickStart"):FireClient(attacker, {
            SequenceLength = LOCKPICK_SEQUENCE_LENGTH,
            TimeLimit = Constants.Heist.LOCKPICK_SECONDS,
        })

        -- Auto-fail after time limit
        task.delay(Constants.Heist.LOCKPICK_SECONDS + 1, function()
            local h = activeHeists[attacker.UserId]
            if h and h.StartedAt == heistData.StartedAt and h.Phase == "Lockpick" then
                HeistService._resolveHeist(attacker, false, "TimeExpired")
            end
        end)
    end)
end

local function handleLockpickInput(attacker: Player, direction: string)
    if type(direction) ~= "string" then return end
    if not Util.Contains(LOCKPICK_DIRECTIONS, direction) then return end

    local heist = activeHeists[attacker.UserId]
    if not heist or heist.Phase ~= "Lockpick" then return end

    -- Check if lockpick time expired
    local elapsed = os.time() - heist.LockpickStartedAt
    if elapsed > Constants.Heist.LOCKPICK_SECONDS then
        HeistService._resolveHeist(attacker, false, "TimeExpired")
        return
    end

    heist.InputIndex += 1
    local expectedDirection = heist.Sequence[heist.InputIndex]

    if direction ~= expectedDirection then
        -- Wrong input = fail
        HeistService._resolveHeist(attacker, false, "WrongInput")
        return
    end

    -- Correct input
    if heist.InputIndex >= LOCKPICK_SEQUENCE_LENGTH then
        -- All correct = success!
        HeistService._resolveHeist(attacker, true)
    else
        -- Notify progress
        Remotes.GetEvent("HeistLockpickInput"):FireClient(attacker, {
            Progress = heist.InputIndex,
            Total = LOCKPICK_SEQUENCE_LENGTH,
            Correct = true,
        })
    end
end

function HeistService._resolveHeist(attacker: Player, success: boolean, failReason: string?)
    local heist = activeHeists[attacker.UserId]
    if not heist then return end

    activeHeists[attacker.UserId] = nil

    local target = Players:GetPlayerByUserId(heist.TargetId)
    local attackerData = DataService.GetData(attacker)

    if success then
        -- Transfer icon from target to attacker
        local targetData = target and DataService.GetData(target)
        local stolenIcon = nil

        if targetData then
            for i, icon in targetData.Icons do
                if icon.UID == heist.TargetIconUID then
                    stolenIcon = Util.DeepCopy(icon)
                    table.remove(targetData.Icons, i)
                    break
                end
            end
        end

        if stolenIcon then
            -- Add to attacker's inventory with new UID
            local newIcon = DataService.AddIcon(attacker, stolenIcon.IconId, stolenIcon.Evolution)

            -- Update attacker stats
            if attackerData then
                attackerData.HeistsSucceeded = (attackerData.HeistsSucceeded or 0) + 1
            end

            -- Notify attacker
            Remotes.GetEvent("HeistResult"):FireClient(attacker, {
                Success = true,
                Phase = "Complete",
                StolenIconId = stolenIcon.IconId,
                StolenIconName = stolenIcon.IconId, -- Client resolves name
                TargetName = target and target.Name or "Unknown",
            })

            -- Notify target with Steal Cam data
            if target then
                Remotes.GetEvent("HeistStealCam"):FireClient(target, {
                    AttackerName = attacker.Name,
                    StolenIconId = stolenIcon.IconId,
                })

                -- Update target data on client
                Remotes.GetEvent("PlayerDataUpdate"):FireClient(target, "Icons", targetData.Icons)
            end
        else
            -- Icon was removed/vaulted between start and finish
            Remotes.GetEvent("HeistResult"):FireClient(attacker, {
                Success = false,
                Phase = "Complete",
                Reason = "IconNoLongerAvailable",
            })
        end

        -- Set target cooldown for this attacker
        if attackerData then
            attackerData.HeistTargetCooldowns[tostring(heist.TargetId)] =
                os.time() + Constants.Heist.TARGET_COOLDOWN_SECONDS
        end
    else
        -- Failed heist
        if attackerData then
            attackerData.HeistCooldownUntil = os.time() + Constants.Heist.FAIL_COOLDOWN_SECONDS
            attackerData.HeistsFailed = (attackerData.HeistsFailed or 0) + 1
        end

        Remotes.GetEvent("HeistResult"):FireClient(attacker, {
            Success = false,
            Phase = "Complete",
            Reason = failReason or "Failed",
        })

        -- Notify target that heist failed
        if target then
            Remotes.GetEvent("HeistNotification"):FireClient(target, {
                Type = "HeistFailed",
                AttackerName = attacker.Name,
            })
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- VAULT MANAGEMENT
-- ═══════════════════════════════════════════════════════════════

function HeistService.VaultIcon(player: Player, iconUID: number): boolean
    local data = DataService.GetData(player)
    if not data then return false end

    local icon = DataService.GetIcon(player, iconUID)
    if not icon then return false end
    if icon.VaultSlot ~= nil then return false end -- already vaulted

    -- Count current vault usage
    local vaultCount = 0
    for _, ic in data.Icons do
        if ic.VaultSlot ~= nil then
            vaultCount += 1
        end
    end

    if vaultCount >= data.VaultSlots then
        return false -- vault full
    end

    icon.VaultSlot = vaultCount + 1
    icon.Displayed = false -- can't display vaulted icons
    Remotes.GetEvent("PlayerDataUpdate"):FireClient(player, "Icons", data.Icons)
    return true
end

function HeistService.UnvaultIcon(player: Player, iconUID: number): boolean
    local icon = DataService.GetIcon(player, iconUID)
    if not icon or icon.VaultSlot == nil then return false end

    icon.VaultSlot = nil
    local data = DataService.GetData(player)
    if data then
        Remotes.GetEvent("PlayerDataUpdate"):FireClient(player, "Icons", data.Icons)
    end
    return true
end

-- ═══════════════════════════════════════════════════════════════
-- INIT
-- ═══════════════════════════════════════════════════════════════

function HeistService.Init()
    Remotes.GetEvent("HeistStartRequest").OnServerEvent:Connect(handleHeistStart)
    Remotes.GetEvent("HeistLockpickInput").OnServerEvent:Connect(handleLockpickInput)

    Players.PlayerRemoving:Connect(function(player)
        activeHeists[player.UserId] = nil
        heistLimiter:CleanupPlayer(player)
    end)

    print("[HeistService] Initialized")
end

return HeistService
