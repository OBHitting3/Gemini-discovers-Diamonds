--[[
    Remotes.lua
    Central registry of all RemoteEvents and RemoteFunctions.
    Accessed from both client and server to ensure consistent naming.

    Usage:
        Server: Remotes.GetEvent("EggHatch").OnServerEvent:Connect(...)
        Client: Remotes.GetEvent("EggHatch"):FireServer(...)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

-- Folder that holds all remotes
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
    remotesFolder = Instance.new("Folder")
    remotesFolder.Name = "Remotes"
    remotesFolder.Parent = ReplicatedStorage
end

-- All remote definitions: Name -> Type
local REMOTE_DEFINITIONS = {
    -- ═══════════ DATA ═══════════
    PlayerDataLoaded     = "RemoteEvent",
    PlayerDataUpdate     = "RemoteEvent",

    -- ═══════════ EGGS / COLLECTIBLES ═══════════
    EggHatchRequest      = "RemoteEvent",
    EggHatchResult       = "RemoteEvent",
    EvolveIconRequest    = "RemoteEvent",
    EvolveIconResult     = "RemoteEvent",

    -- ═══════════ HEIST ═══════════
    HeistStartRequest    = "RemoteEvent",
    HeistCountdown       = "RemoteEvent",
    HeistLockpickStart   = "RemoteEvent",
    HeistLockpickInput   = "RemoteEvent",
    HeistResult          = "RemoteEvent",
    HeistStealCam        = "RemoteEvent",
    HeistNotification    = "RemoteEvent",

    -- ═══════════ BUILDING ═══════════
    PlotPlaceFurniture   = "RemoteEvent",
    PlotRemoveFurniture  = "RemoteEvent",
    PlotMoveFurniture    = "RemoteEvent",
    PlotDisplayIcon      = "RemoteEvent",
    PlotRemoveDisplay    = "RemoteEvent",
    PlotVisit            = "RemoteEvent",
    PlotRate             = "RemoteEvent",
    PlotDataSync         = "RemoteEvent",

    -- ═══════════ TRADING ═══════════
    TradeRequest         = "RemoteEvent",
    TradeResponse        = "RemoteEvent",
    TradeUpdateOffer     = "RemoteEvent",
    TradeConfirm         = "RemoteEvent",
    TradeCancel          = "RemoteEvent",
    TradeComplete        = "RemoteEvent",
    MarketplaceList      = "RemoteFunction",
    MarketplaceSearch    = "RemoteFunction",

    -- ═══════════ MONETIZATION ═══════════
    PurchasePassRequest  = "RemoteEvent",
    PurchasePassResult   = "RemoteEvent",
    PurchaseProductRequest = "RemoteEvent",

    -- ═══════════ UI / MISC ═══════════
    NotificationPush     = "RemoteEvent",
    LeaderboardData      = "RemoteFunction",
    GetPlayerData        = "RemoteFunction",
    ZoneEntered          = "RemoteEvent",
    SettingsUpdate       = "RemoteEvent",
}

-- Create all remotes on first require
for name, remoteType in REMOTE_DEFINITIONS do
    if not remotesFolder:FindFirstChild(name) then
        local remote = Instance.new(remoteType)
        remote.Name = name
        remote.Parent = remotesFolder
    end
end

function Remotes.GetEvent(name: string): RemoteEvent
    local remote = remotesFolder:FindFirstChild(name)
    assert(remote, "[Remotes] RemoteEvent not found: " .. name)
    return remote
end

function Remotes.GetFunction(name: string): RemoteFunction
    local remote = remotesFolder:FindFirstChild(name)
    assert(remote, "[Remotes] RemoteFunction not found: " .. name)
    return remote
end

function Remotes.GetFolder(): Folder
    return remotesFolder
end

return Remotes
