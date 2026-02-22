--[[
    FashionService.lua
    Manages poolside fashion runway events: themed competitions,
    player registration, outfit submission, runway walks, voting,
    winner announcement, and prize distribution.

    Events run every 10 minutes (configurable), last 2 minutes,
    and support up to 5 participants per event.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local GameConfig    = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteManager = require(ReplicatedStorage:WaitForChild("RemoteManager"))
local Utilities     = require(ReplicatedStorage:WaitForChild("Utilities"))

local FashionService = {}

-- Internal state
FashionService._currentEvent = nil
FashionService._eventLoop = false
FashionService._economyService = nil
FashionService._themeIndex = 0

---------------------------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------------------------

function FashionService:init(economyService)
    self._economyService = economyService

    -- Connect remote events
    local joinEvent = RemoteManager:getEvent("JoinFashionEvent")
    if joinEvent then
        joinEvent.OnServerEvent:Connect(function(player)
            self:joinEvent(player)
        end)
    end

    local submitEvent = RemoteManager:getEvent("SubmitOutfit")
    if submitEvent then
        submitEvent.OnServerEvent:Connect(function(player, outfitData)
            self:submitOutfit(player, outfitData)
        end)
    end

    local voteEvent = RemoteManager:getEvent("VoteOutfit")
    if voteEvent then
        voteEvent.OnServerEvent:Connect(function(voter, targetUserId)
            self:voteForOutfit(voter, targetUserId)
        end)
    end

    -- Start the event loop
    self:_startEventLoop()

    print("[FashionService] Initialized — events every " ..
          GameConfig.Timing.FashionEventInterval .. "s")
end

---------------------------------------------------------------------------
-- EVENT LIFECYCLE
---------------------------------------------------------------------------

function FashionService:_startEventLoop()
    if self._eventLoop then return end
    self._eventLoop = true

    task.spawn(function()
        -- Wait a bit before first event so players can join
        task.wait(60)

        while self._eventLoop do
            -- Start a new event
            self:startEvent()

            -- Wait for event duration
            task.wait(GameConfig.Timing.FashionEventDuration)

            -- End the event
            self:endEvent()

            -- Wait for cooldown until next event
            task.wait(GameConfig.Timing.FashionEventInterval - GameConfig.Timing.FashionEventDuration)
        end
    end)
end

function FashionService:startEvent(theme: string?)
    -- Rotate themes
    self._themeIndex += 1
    if self._themeIndex > #GameConfig.FashionThemes then
        self._themeIndex = 1
    end

    local eventTheme = theme or GameConfig.FashionThemes[self._themeIndex]

    self._currentEvent = {
        eventId = Utilities.generateId(),
        theme = eventTheme,
        isActive = true,
        startedAt = os.time(),
        endsAt = os.time() + GameConfig.Timing.FashionEventDuration,
        participants = {},
        votes = {},
        winnerId = nil,
    }

    -- Broadcast to all players
    RemoteManager:fireAllClients("FashionEventUpdate", {
        action = "started",
        theme = eventTheme,
        endsAt = self._currentEvent.endsAt,
        eventId = self._currentEvent.eventId,
    })

    RemoteManager:fireAllClients("NotifyPlayer",
        "Fashion Event: " .. eventTheme .. "! Head to the runway to compete!")

    print("[FashionService] Event started: " .. eventTheme)
end

function FashionService:endEvent()
    if not self._currentEvent or not self._currentEvent.isActive then return end

    self._currentEvent.isActive = false

    -- Tally votes and determine winners
    local results = self:_tallyVotes()

    -- Distribute prizes
    for _, result in ipairs(results) do
        local prize = GameConfig.Economy.FashionPrizes[result.place]
        if prize then
            local player = Players:GetPlayerByUserId(result.userId)
            if player then
                self._economyService:addCoins(player, prize.coins,
                    "Fashion #" .. result.place .. ": " .. self._currentEvent.theme)
                self._economyService:addPrestige(player, prize.prestige)

                if result.place == 1 then
                    local data = self._economyService:getPlayerData(player)
                    if data then
                        data.stats.fashionWins += 1
                    end
                end

                RemoteManager:fireClient("NotifyPlayer", player,
                    "Fashion Event Results: #" .. result.place .. "! +" ..
                    prize.coins .. " SC, +" .. prize.prestige .. " Prestige")
            end
        end
    end

    -- Broadcast results
    RemoteManager:fireAllClients("FashionEventUpdate", {
        action = "ended",
        theme = self._currentEvent.theme,
        results = results,
    })

    local winnerName = "Nobody"
    if #results > 0 then
        local winner = Players:GetPlayerByUserId(results[1].userId)
        winnerName = winner and winner.Name or "Unknown"
    end

    RemoteManager:fireAllClients("NotifyPlayer",
        "Fashion Event ended! Winner: " .. winnerName)

    print("[FashionService] Event ended: " .. self._currentEvent.theme ..
          " | Winner: " .. winnerName)

    self._currentEvent = nil
end

---------------------------------------------------------------------------
-- PLAYER ACTIONS
---------------------------------------------------------------------------

function FashionService:joinEvent(player: Player): boolean
    if not self._currentEvent or not self._currentEvent.isActive then
        RemoteManager:fireClient("NotifyPlayer", player,
            "No fashion event is currently active!")
        return false
    end

    -- Check max participants
    if #self._currentEvent.participants >= GameConfig.Timing.FashionMaxParticipants then
        RemoteManager:fireClient("NotifyPlayer", player,
            "This event is full! (" .. GameConfig.Timing.FashionMaxParticipants .. " max)")
        return false
    end

    -- Check not already joined
    for _, p in ipairs(self._currentEvent.participants) do
        if p.userId == player.UserId then
            RemoteManager:fireClient("NotifyPlayer", player,
                "You're already in this event!")
            return false
        end
    end

    table.insert(self._currentEvent.participants, {
        userId = player.UserId,
        displayName = player.DisplayName,
        outfit = { name = "Default", category = "resort", items = {} },
        hasWalked = false,
        voteCount = 0,
    })

    RemoteManager:fireClient("NotifyPlayer", player,
        "Joined fashion event: " .. self._currentEvent.theme .. "!")

    -- Broadcast updated participant list
    RemoteManager:fireAllClients("FashionEventUpdate", {
        action = "playerJoined",
        playerName = player.Name,
        participantCount = #self._currentEvent.participants,
    })

    return true
end

function FashionService:submitOutfit(player: Player, outfitData: table): boolean
    if not self._currentEvent or not self._currentEvent.isActive then return false end

    -- Find participant
    for _, p in ipairs(self._currentEvent.participants) do
        if p.userId == player.UserId then
            p.outfit = outfitData or p.outfit
            RemoteManager:fireClient("NotifyPlayer", player,
                "Outfit submitted! Walk the runway when ready.")
            return true
        end
    end

    RemoteManager:fireClient("NotifyPlayer", player,
        "Join the event first!")
    return false
end

function FashionService:walkRunway(player: Player): boolean
    if not self._currentEvent or not self._currentEvent.isActive then return false end

    -- Find participant
    for _, p in ipairs(self._currentEvent.participants) do
        if p.userId == player.UserId then
            if p.hasWalked then
                RemoteManager:fireClient("NotifyPlayer", player,
                    "You've already walked the runway!")
                return false
            end

            p.hasWalked = true

            -- Broadcast walk event (client handles animation)
            RemoteManager:fireAllClients("FashionEventUpdate", {
                action = "runwayWalk",
                userId = player.UserId,
                displayName = player.DisplayName,
            })

            return true
        end
    end

    return false
end

function FashionService:voteForOutfit(voter: Player, targetUserId: number): boolean
    if not self._currentEvent or not self._currentEvent.isActive then return false end

    -- Can't vote for yourself
    if voter.UserId == targetUserId then
        RemoteManager:fireClient("NotifyPlayer", voter,
            "You can't vote for yourself!")
        return false
    end

    -- Check not already voted
    if self._currentEvent.votes[voter.UserId] then
        RemoteManager:fireClient("NotifyPlayer", voter,
            "You've already voted in this event!")
        return false
    end

    -- Check target is a participant
    local found = false
    for _, p in ipairs(self._currentEvent.participants) do
        if p.userId == targetUserId then
            p.voteCount += 1
            found = true
            break
        end
    end

    if not found then
        RemoteManager:fireClient("NotifyPlayer", voter,
            "That player isn't in this event!")
        return false
    end

    self._currentEvent.votes[voter.UserId] = targetUserId

    RemoteManager:fireClient("NotifyPlayer", voter, "Vote cast!")
    return true
end

---------------------------------------------------------------------------
-- VOTE TALLYING
---------------------------------------------------------------------------

function FashionService:_tallyVotes(): { { userId: number, place: number, votes: number, displayName: string } }
    if not self._currentEvent then return {} end

    -- Sort participants by vote count (descending)
    local sorted = {}
    for _, p in ipairs(self._currentEvent.participants) do
        table.insert(sorted, {
            userId = p.userId,
            displayName = p.displayName,
            votes = p.voteCount,
        })
    end

    table.sort(sorted, function(a, b) return a.votes > b.votes end)

    -- Assign places
    local results = {}
    for i, entry in ipairs(sorted) do
        table.insert(results, {
            userId = entry.userId,
            displayName = entry.displayName,
            place = i,
            votes = entry.votes,
        })
    end

    if #results > 0 then
        self._currentEvent.winnerId = results[1].userId
    end

    return results
end

---------------------------------------------------------------------------
-- STATE ACCESS
---------------------------------------------------------------------------

function FashionService:getCurrentEvent(): table?
    return self._currentEvent
end

function FashionService:isEventActive(): boolean
    return self._currentEvent ~= nil and self._currentEvent.isActive
end

return FashionService
