--[[
    MazeService.server.lua
    Generates a new random maze each round using recursive backtracking.
    Builds the maze walls as Parts in the workspace.
    Three difficulty levels: Easy (fewer walls), Medium, Hard (more walls).
]]

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

local evRoundStarted = getOrCreateEvent("RoundStarted")
local evRoundEnded   = getOrCreateEvent("RoundEnded")

---------------------------------------------------------------------------
-- MAZE GENERATION (Recursive Backtracker)
---------------------------------------------------------------------------

local GRID   = MulletConfig.Maze.GridSize
local CELL   = MulletConfig.Maze.CellSize
local WALL_H = MulletConfig.Maze.WallHeight
local WALL_T = MulletConfig.Maze.WallThickness
local ORIGIN = MulletConfig.Maze.Origin

-- Directions: N, S, E, W
local DIRS = {
    { dr = -1, dc = 0,  wall = "N", opp = "S" },
    { dr = 1,  dc = 0,  wall = "S", opp = "N" },
    { dr = 0,  dc = 1,  wall = "E", opp = "W" },
    { dr = 0,  dc = -1, wall = "W", opp = "E" },
}

local function initGrid()
    local grid = {}
    for r = 1, GRID do
        grid[r] = {}
        for c = 1, GRID do
            grid[r][c] = { N = true, S = true, E = true, W = true, visited = false }
        end
    end
    return grid
end

local function shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(1, i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

local function carve(grid, r, c)
    grid[r][c].visited = true
    local dirs = shuffle({ table.unpack(DIRS) })
    for _, d in ipairs(dirs) do
        local nr, nc = r + d.dr, c + d.dc
        if nr >= 1 and nr <= GRID and nc >= 1 and nc <= GRID and not grid[nr][nc].visited then
            grid[r][c][d.wall]   = false
            grid[nr][nc][d.opp]  = false
            carve(grid, nr, nc)
        end
    end
end

local function generateMaze(seed)
    math.randomseed(seed or os.time())
    local grid = initGrid()
    carve(grid, 1, 1)
    return grid
end

---------------------------------------------------------------------------
-- MAZE BUILDER
---------------------------------------------------------------------------

local mazeFolder = nil

local wallColors = {
    Easy   = Color3.fromRGB(140, 60, 220),    -- bright purple
    Medium = Color3.fromRGB(180, 40, 255),    -- deeper purple
    Hard   = Color3.fromRGB(220, 0, 180),     -- purple-pink
}

local wallMaterials = {
    Easy   = Enum.Material.Neon,
    Medium = Enum.Material.SmoothPlastic,
    Hard   = Enum.Material.Neon,
}

local function buildMaze(grid, difficulty)
    -- Remove old maze
    if mazeFolder then mazeFolder:Destroy() end
    mazeFolder = Instance.new("Folder")
    mazeFolder.Name = "MazeWalls"
    mazeFolder.Parent = workspace

    local wallColor = wallColors[difficulty] or wallColors.Easy
    local wallMat   = wallMaterials[difficulty] or Enum.Material.Neon

    -- For Easy, randomly remove extra walls to open up the maze
    local extraOpenings = 0
    if difficulty == "Easy" then
        extraOpenings = math.floor(GRID * GRID * 0.2)
    elseif difficulty == "Medium" then
        extraOpenings = math.floor(GRID * GRID * 0.05)
    end

    local function makeWall(pos, size)
        local part = Instance.new("Part")
        part.Anchored  = true
        part.Size      = size
        part.CFrame    = CFrame.new(pos)
        part.Color     = wallColor
        part.Material  = wallMat
        part.TopSurface = Enum.SurfaceType.Smooth
        part.BottomSurface = Enum.SurfaceType.Smooth
        part.Parent    = mazeFolder
        return part
    end

    -- Floor
    local floorSize = Vector3.new(GRID * CELL, 1, GRID * CELL)
    local floorPos  = Vector3.new(
        ORIGIN.X + (GRID * CELL) / 2,
        ORIGIN.Y - 0.5,
        ORIGIN.Z + (GRID * CELL) / 2
    )
    local floor = Instance.new("Part")
    floor.Anchored = true
    floor.Size     = floorSize
    floor.CFrame   = CFrame.new(floorPos)
    floor.Color    = Color3.fromRGB(60, 180, 80)   -- bright green floor inside maze
    floor.Material = Enum.Material.SmoothPlastic
    floor.TopSurface = Enum.SurfaceType.Smooth
    floor.Parent   = mazeFolder

    -- Draw walls
    for r = 1, GRID do
        for c = 1, GRID do
            local cell = grid[r][c]
            local baseX = ORIGIN.X + (c - 1) * CELL
            local baseZ = ORIGIN.Z + (r - 1) * CELL
            local midY  = ORIGIN.Y + WALL_H / 2

            -- North wall (top edge of cell)
            if cell.N then
                makeWall(
                    Vector3.new(baseX + CELL / 2, midY, baseZ),
                    Vector3.new(CELL + WALL_T, WALL_H, WALL_T)
                )
            end

            -- West wall (left edge of cell)
            if cell.W then
                makeWall(
                    Vector3.new(baseX, midY, baseZ + CELL / 2),
                    Vector3.new(WALL_T, WALL_H, CELL + WALL_T)
                )
            end
        end
    end

    -- Always draw outer south and east borders
    for c = 1, GRID do
        local baseX = ORIGIN.X + (c - 1) * CELL
        local baseZ = ORIGIN.Z + GRID * CELL
        makeWall(
            Vector3.new(baseX + CELL / 2, ORIGIN.Y + WALL_H / 2, baseZ),
            Vector3.new(CELL + WALL_T, WALL_H, WALL_T)
        )
    end
    for r = 1, GRID do
        local baseZ = ORIGIN.Z + (r - 1) * CELL
        local baseX = ORIGIN.X + GRID * CELL
        makeWall(
            Vector3.new(baseX, ORIGIN.Y + WALL_H / 2, baseZ + CELL / 2),
            Vector3.new(WALL_T, WALL_H, CELL + WALL_T)
        )
    end

    print("[MazeService] Maze built — difficulty: " .. difficulty)
end

---------------------------------------------------------------------------
-- PUBLIC API
---------------------------------------------------------------------------

local MazeService = {}
local currentDifficulty = MulletConfig.Round.DefaultDifficulty

function MazeService:newRound(difficulty)
    difficulty = difficulty or currentDifficulty
    currentDifficulty = difficulty

    local seed = os.time() + math.random(1, 10000)
    local grid = generateMaze(seed)
    buildMaze(grid, difficulty)

    print("[MazeService] New " .. difficulty .. " maze generated (seed: " .. seed .. ")")
    return difficulty
end

function MazeService:getDifficulty()
    return currentDifficulty
end

function MazeService:clearMaze()
    if mazeFolder then
        mazeFolder:Destroy()
        mazeFolder = nil
    end
end

-- Build initial maze on startup
task.spawn(function()
    task.wait(2)  -- wait for other services to init
    MazeService:newRound(MulletConfig.Round.DefaultDifficulty)
end)

print("[MazeService] Ready")

return MazeService
