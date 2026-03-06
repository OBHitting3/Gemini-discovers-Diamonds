--[[
    FashionController.lua
    Client-side fashion/runway interactions: event join, outfit
    selection, runway walk animation, voting, results display.
]]

local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig    = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteManager = require(ReplicatedStorage:WaitForChild("RemoteManager"))

local FashionController = {}
FashionController._uiController = nil
FashionController._currentEvent = nil
FashionController._isWalking = false

---------------------------------------------------------------------------
-- INITIALIZATION
---------------------------------------------------------------------------

function FashionController:init(uiController)
    self._uiController = uiController

    -- Listen for fashion event updates
    local fashionEvent = RemoteManager:getEvent("FashionEventUpdate")
    if fashionEvent then
        fashionEvent.OnClientEvent:Connect(function(data)
            self:_onFashionUpdate(data)
        end)
    end

    print("[FashionController] Initialized")
end

---------------------------------------------------------------------------
-- EVENT HANDLING
---------------------------------------------------------------------------

function FashionController:_onFashionUpdate(data: table)
    local action = data.action

    if action == "started" then
        self._currentEvent = {
            theme = data.theme,
            endsAt = data.endsAt,
            eventId = data.eventId,
            participants = {},
        }
        self._uiController:showNotification(
            "Fashion Event: " .. data.theme .. "! Head to the runway!")
    elseif action == "ended" then
        self._currentEvent = nil
        if data.results and #data.results > 0 then
            local winner = data.results[1]
            self._uiController:showNotification(
                "Fashion Winner: " .. winner.displayName ..
                " with " .. winner.votes .. " votes!")
        end
    elseif action == "playerJoined" then
        self._uiController:showNotification(
            data.playerName .. " joined the fashion event! (" ..
            data.participantCount .. " contestants)")
    elseif action == "runwayWalk" then
        self:_animateRunwayWalk(data.userId)
    end
end

---------------------------------------------------------------------------
-- PLAYER ACTIONS
---------------------------------------------------------------------------

function FashionController:joinEvent()
    RemoteManager:fireServer("JoinFashionEvent")
end

function FashionController:submitOutfit(outfitData: table?)
    RemoteManager:fireServer("SubmitOutfit", outfitData or {
        name = "Default Look",
        category = "resort",
        items = {},
    })
end

function FashionController:walkRunway()
    -- Request server to initiate walk
    -- Server broadcasts to all clients, animation plays locally
    RemoteManager:fireServer("SubmitOutfit", {
        name = "Runway Look",
        category = "poolside",
        items = {},
    })

    -- Trigger walk animation locally
    local player = Players.LocalPlayer
    self:_animateRunwayWalk(player.UserId)
end

function FashionController:voteFor(targetUserId: number)
    RemoteManager:fireServer("VoteOutfit", targetUserId)
end

---------------------------------------------------------------------------
-- RUNWAY WALK ANIMATION
---------------------------------------------------------------------------

function FashionController:_animateRunwayWalk(userId: number)
    if self._isWalking then return end

    local player = Players:GetPlayerByUserId(userId)
    if not player or not player.Character then return end

    local character = player.Character
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return end

    -- Get runway parameters from the RunwayBuilder folder
    local runwayFolder = workspace:FindFirstChild("FashionRunway")
    if not runwayFolder then return end

    local startZ = runwayFolder:GetAttribute("WalkStartZ")
    local endZ = runwayFolder:GetAttribute("WalkEndZ")
    local centerX = runwayFolder:GetAttribute("RunwayCenterX")
    local runwayY = runwayFolder:GetAttribute("RunwayY")

    if not startZ or not endZ then return end

    self._isWalking = true

    -- Teleport to start position
    local startPos = Vector3.new(centerX or 0, (runwayY or 1) + 3, startZ)
    rootPart.CFrame = CFrame.new(startPos) * CFrame.Angles(0, math.rad(180), 0)

    -- Walk to end of runway
    task.spawn(function()
        -- Walk forward
        local endPos = Vector3.new(centerX or 0, (runwayY or 1) + 3, endZ)
        local distance = (endPos - startPos).Magnitude
        local walkSpeed = 8  -- studs/sec

        -- Use Humanoid:MoveTo for natural walking
        humanoid:MoveTo(endPos)
        humanoid.MoveToFinished:Wait()

        -- Pause at end for pose
        task.wait(2)

        -- Turn and walk back
        local returnPos = startPos
        humanoid:MoveTo(returnPos)
        humanoid.MoveToFinished:Wait()

        self._isWalking = false

        if userId == Players.LocalPlayer.UserId then
            self._uiController:showNotification("Runway walk complete! Awaiting votes...")
        end
    end)
end

---------------------------------------------------------------------------
-- STATE ACCESS
---------------------------------------------------------------------------

function FashionController:getCurrentEvent(): table?
    return self._currentEvent
end

function FashionController:isEventActive(): boolean
    return self._currentEvent ~= nil
end

function FashionController:isWalking(): boolean
    return self._isWalking
end

return FashionController
