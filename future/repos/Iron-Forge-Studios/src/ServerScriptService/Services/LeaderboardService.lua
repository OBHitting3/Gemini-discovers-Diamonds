--[[
    LeaderboardService.lua (Server)
    Manages OrderedDataStore leaderboards and in-game display boards.
    Leaderboards: Top Collectors, Richest Players, Best Heists, Top Oasis Ratings
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Constants = require(game.ReplicatedStorage.Modules.Shared.Constants)
local Remotes = require(game.ReplicatedStorage.Modules.Shared.Remotes)
local DataService = require(game.ServerScriptService.Services.DataService)

local LeaderboardService = {}

-- ═══════════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════════
local BOARDS = {
    {
        Name = "TopCollectors",
        DisplayName = "Top Collectors",
        Store = DataStoreService:GetOrderedDataStore("LB_TopCollectors_v1"),
        StatKey = "CollectionCount",
        GetValue = function(data)
            local count = 0
            for _ in data.CollectionBook do
                count += 1
            end
            return count
        end,
    },
    {
        Name = "Richest",
        DisplayName = "Richest Players",
        Store = DataStoreService:GetOrderedDataStore("LB_Richest_v1"),
        StatKey = "Currency",
        GetValue = function(data)
            return data.Currency
        end,
    },
    {
        Name = "BestHeists",
        DisplayName = "Best Heist Masters",
        Store = DataStoreService:GetOrderedDataStore("LB_BestHeists_v1"),
        StatKey = "HeistsSucceeded",
        GetValue = function(data)
            return data.HeistsSucceeded or 0
        end,
    },
    {
        Name = "TopOasis",
        DisplayName = "Top Oasis Ratings",
        Store = DataStoreService:GetOrderedDataStore("LB_TopOasis_v1"),
        StatKey = "PlotRating",
        GetValue = function(data)
            -- Store as integer (rating * 100) for OrderedDataStore
            return math.floor((data.PlotRating or 0) * 100)
        end,
    },
}

local cachedLeaderboards = {} -- { [boardName] = { entries, lastUpdate } }
local UPDATE_INTERVAL = 120 -- refresh every 2 minutes

-- ═══════════════════════════════════════════════════════════════
-- UPLOAD STATS
-- ═══════════════════════════════════════════════════════════════

local function uploadPlayerStats(player: Player)
    local data = DataService.GetData(player)
    if not data then return end

    for _, board in BOARDS do
        local value = board.GetValue(data)
        if value > 0 then
            local success, err = pcall(function()
                board.Store:SetAsync(tostring(player.UserId), value)
            end)
            if not success then
                warn("[LeaderboardService] Upload failed for", board.Name, err)
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- FETCH LEADERBOARDS
-- ═══════════════════════════════════════════════════════════════

local function fetchBoard(board): { table }
    local success, pages = pcall(function()
        return board.Store:GetSortedAsync(false, 50) -- top 50, descending
    end)

    if not success or not pages then
        return cachedLeaderboards[board.Name] and cachedLeaderboards[board.Name].entries or {}
    end

    local entries = {}
    local page = pages:GetCurrentPage()

    for rank, entry in page do
        local userId = tonumber(entry.key)
        local playerName = "[Unknown]"

        local nameSuccess, name = pcall(function()
            return Players:GetNameFromUserIdAsync(userId)
        end)
        if nameSuccess then
            playerName = name
        end

        table.insert(entries, {
            Rank = rank,
            UserId = userId,
            Name = playerName,
            Value = entry.value,
        })
    end

    cachedLeaderboards[board.Name] = {
        entries = entries,
        lastUpdate = os.time(),
    }

    return entries
end

-- ═══════════════════════════════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════════════════════════════

function LeaderboardService.GetLeaderboard(boardName: string): { table }
    local cached = cachedLeaderboards[boardName]
    if cached and (os.time() - cached.lastUpdate) < UPDATE_INTERVAL then
        return cached.entries
    end

    for _, board in BOARDS do
        if board.Name == boardName then
            return fetchBoard(board)
        end
    end

    return {}
end

function LeaderboardService.GetAllBoards(): { table }
    local result = {}
    for _, board in BOARDS do
        result[board.Name] = {
            DisplayName = board.DisplayName,
            Entries = LeaderboardService.GetLeaderboard(board.Name),
        }
    end
    return result
end

-- ═══════════════════════════════════════════════════════════════
-- PHYSICAL LEADERBOARD DISPLAYS
-- ═══════════════════════════════════════════════════════════════

local function createPhysicalBoards()
    local zonesFolder = game.Workspace:FindFirstChild("Zones")
    local downtown = zonesFolder and zonesFolder:FindFirstChild(Constants.Zones.DOWNTOWN)
    if not downtown then return end

    for i, board in BOARDS do
        local pedestal = downtown:FindFirstChild("LeaderboardPedestal_" .. i)
        if not pedestal then continue end

        local surfaceGui = Instance.new("SurfaceGui")
        surfaceGui.Name = "LB_" .. board.Name
        surfaceGui.Face = Enum.NormalId.Front
        surfaceGui.CanvasSize = Vector2.new(400, 600)
        surfaceGui.Parent = pedestal

        -- Title
        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, 0, 0, 60)
        title.Position = UDim2.new(0, 0, 0, 0)
        title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        title.BorderSizePixel = 0
        title.Text = board.DisplayName
        title.TextColor3 = Color3.fromRGB(255, 220, 150)
        title.TextScaled = true
        title.Font = Enum.Font.GothamBold
        title.Parent = surfaceGui

        -- Entries container
        local entriesFrame = Instance.new("Frame")
        entriesFrame.Name = "Entries"
        entriesFrame.Size = UDim2.new(1, 0, 1, -60)
        entriesFrame.Position = UDim2.new(0, 0, 0, 60)
        entriesFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        entriesFrame.BackgroundTransparency = 0.2
        entriesFrame.BorderSizePixel = 0
        entriesFrame.Parent = surfaceGui

        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 2)
        layout.Parent = entriesFrame
    end
end

local function updatePhysicalBoards()
    local zonesFolder = game.Workspace:FindFirstChild("Zones")
    local downtown = zonesFolder and zonesFolder:FindFirstChild(Constants.Zones.DOWNTOWN)
    if not downtown then return end

    for i, board in BOARDS do
        local pedestal = downtown:FindFirstChild("LeaderboardPedestal_" .. i)
        if not pedestal then continue end

        local surfaceGui = pedestal:FindFirstChild("LB_" .. board.Name)
        if not surfaceGui then continue end

        local entriesFrame = surfaceGui:FindFirstChild("Entries")
        if not entriesFrame then continue end

        -- Clear old entries
        for _, child in entriesFrame:GetChildren() do
            if child:IsA("TextLabel") then
                child:Destroy()
            end
        end

        -- Add new entries
        local entries = LeaderboardService.GetLeaderboard(board.Name)
        for rank, entry in entries do
            if rank > 10 then break end -- show top 10 on physical boards

            local label = Instance.new("TextLabel")
            label.Name = "Entry_" .. rank
            label.Size = UDim2.new(1, -10, 0, 45)
            label.LayoutOrder = rank
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.GothamMedium
            label.TextScaled = true

            local displayValue = entry.Value
            if board.Name == "TopOasis" then
                displayValue = string.format("%.1f★", entry.Value / 100)
            end

            label.Text = string.format("#%d  %s  -  %s", rank, entry.Name, tostring(displayValue))
            label.TextColor3 = rank <= 3 and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(200, 200, 200)
            label.Parent = entriesFrame
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- REMOTE HANDLER
-- ═══════════════════════════════════════════════════════════════

local function handleLeaderboardRequest(player: Player, boardName: string)
    if type(boardName) == "string" then
        return LeaderboardService.GetLeaderboard(boardName)
    else
        return LeaderboardService.GetAllBoards()
    end
end

-- ═══════════════════════════════════════════════════════════════
-- INIT
-- ═══════════════════════════════════════════════════════════════

function LeaderboardService.Init()
    Remotes.GetFunction("LeaderboardData").OnServerInvoke = handleLeaderboardRequest

    -- Create physical boards after world loads
    task.delay(2, createPhysicalBoards)

    -- Periodic update loop
    task.spawn(function()
        while true do
            task.wait(UPDATE_INTERVAL)

            -- Upload all online player stats
            for _, player in Players:GetPlayers() do
                if DataService.IsLoaded(player) then
                    task.spawn(uploadPlayerStats, player)
                end
            end

            -- Refresh physical boards
            updatePhysicalBoards()
        end
    end)

    -- Upload stats on player leave
    Players.PlayerRemoving:Connect(function(player)
        task.spawn(uploadPlayerStats, player)
    end)

    print("[LeaderboardService] Initialized")
end

return LeaderboardService
