--[[
    Utilities.lua
    Shared helper functions used across server and client in
    Palm Springs Paradise.  All functions are pure or side-effect-
    minimal to keep them safe for both runtimes.
]]

local HttpService = game:GetService("HttpService")

local Utilities = {}

---------------------------------------------------------------------------
-- PART / MODEL CREATION
---------------------------------------------------------------------------

--- Create an anchored Part with the given properties table.
--- @param props table — { Size, Position/CFrame, Color, Material, Transparency, Name, Parent, ... }
--- @return Part
function Utilities.createPart(props: { [string]: any }): Part
    local part = Instance.new("Part")
    part.Anchored = true
    part.CanCollide = if props.CanCollide ~= nil then props.CanCollide else true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth

    -- Apply explicit properties
    if props.Name then part.Name = props.Name end
    if props.Size then part.Size = props.Size end
    if props.CFrame then part.CFrame = props.CFrame
    elseif props.Position then part.CFrame = CFrame.new(props.Position) end
    if props.Color then part.Color = props.Color end
    if props.BrickColor then part.BrickColor = props.BrickColor end
    if props.Material then part.Material = props.Material end
    if props.Transparency then part.Transparency = props.Transparency end
    if props.Shape then part.Shape = props.Shape end
    if props.Reflectance then part.Reflectance = props.Reflectance end
    if props.CastShadow ~= nil then part.CastShadow = props.CastShadow end

    -- CollectionService tag
    if props.Tag then
        game:GetService("CollectionService"):AddTag(part, props.Tag)
    end

    -- Parent last to avoid unnecessary property-changed events
    if props.Parent then part.Parent = props.Parent end

    return part
end

--- Create a WedgePart with properties (for roofs, mountains).
function Utilities.createWedge(props: { [string]: any }): WedgePart
    local wedge = Instance.new("WedgePart")
    wedge.Anchored = true
    wedge.TopSurface = Enum.SurfaceType.Smooth
    wedge.BottomSurface = Enum.SurfaceType.Smooth

    if props.Name then wedge.Name = props.Name end
    if props.Size then wedge.Size = props.Size end
    if props.CFrame then wedge.CFrame = props.CFrame
    elseif props.Position then wedge.CFrame = CFrame.new(props.Position) end
    if props.Color then wedge.Color = props.Color end
    if props.Material then wedge.Material = props.Material end
    if props.Transparency then wedge.Transparency = props.Transparency end
    if props.CastShadow ~= nil then wedge.CastShadow = props.CastShadow end

    if props.Tag then
        game:GetService("CollectionService"):AddTag(wedge, props.Tag)
    end

    if props.Parent then wedge.Parent = props.Parent end
    return wedge
end

--- Wrap a list of BaseParts into a Model, setting the first part as PrimaryPart.
--- @param name string
--- @param parts { BasePart }
--- @param parent Instance? — optional parent
--- @return Model
function Utilities.createModel(name: string, parts: { BasePart }, parent: Instance?): Model
    local model = Instance.new("Model")
    model.Name = name
    if #parts > 0 then
        model.PrimaryPart = parts[1]
    end
    for _, part in ipairs(parts) do
        part.Parent = model
    end
    if parent then model.Parent = parent end
    return model
end

--- Create a WeldConstraint between two parts.
function Utilities.weldParts(part0: BasePart, part1: BasePart)
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = part0
    weld.Part1 = part1
    weld.Parent = part0
end

---------------------------------------------------------------------------
-- MATH / GEOMETRY
---------------------------------------------------------------------------

--- Linear interpolation between two numbers.
function Utilities.lerp(a: number, b: number, t: number): number
    return a + (b - a) * t
end

--- Lerp between two Color3 values.
function Utilities.lerpColor(c1: Color3, c2: Color3, t: number): Color3
    return Color3.new(
        Utilities.lerp(c1.R, c2.R, t),
        Utilities.lerp(c1.G, c2.G, t),
        Utilities.lerp(c1.B, c2.B, t)
    )
end

--- Check if two positions are within a given range (2D, ignoring Y).
function Utilities.isWithinRange(pos1: Vector3, pos2: Vector3, range: number): boolean
    local dx = pos1.X - pos2.X
    local dz = pos1.Z - pos2.Z
    return (dx * dx + dz * dz) <= (range * range)
end

--- 3D distance check.
function Utilities.distance(pos1: Vector3, pos2: Vector3): number
    return (pos1 - pos2).Magnitude
end

--- Random float in range [min, max).
function Utilities.randomInRange(min: number, max: number): number
    return min + math.random() * (max - min)
end

--- Check whether a position is inside an axis-aligned box.
function Utilities.isInsideBox(pos: Vector3, center: Vector3, size: Vector3): boolean
    local half = size / 2
    return math.abs(pos.X - center.X) <= half.X
       and math.abs(pos.Y - center.Y) <= half.Y
       and math.abs(pos.Z - center.Z) <= half.Z
end

---------------------------------------------------------------------------
-- TABLE UTILITIES
---------------------------------------------------------------------------

--- Deep-copy a table (handles nested tables, not metatables).
function Utilities.tableDeepCopy(original)
    if type(original) ~= "table" then return original end
    local copy = {}
    for key, value in pairs(original) do
        copy[Utilities.tableDeepCopy(key)] = Utilities.tableDeepCopy(value)
    end
    return copy
end

--- Shallow merge of source into target (mutates target).
function Utilities.tableMerge(target, source)
    for key, value in pairs(source) do
        target[key] = value
    end
    return target
end

--- Count entries in a dictionary-style table.
function Utilities.tableCount(t): number
    local count = 0
    for _ in pairs(t) do count += 1 end
    return count
end

---------------------------------------------------------------------------
-- FORMATTING
---------------------------------------------------------------------------

--- Format SunCoins for display  (e.g. 1234 → "1,234 ☀")
function Utilities.formatCurrency(amount: number): string
    local formatted = tostring(math.floor(amount))
    -- Add thousand separators
    local k
    repeat
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
    until k == 0
    return formatted .. " SC"
end

--- Format time in seconds to MM:SS string.
function Utilities.formatTime(seconds: number): string
    local m = math.floor(seconds / 60)
    local s = math.floor(seconds % 60)
    return string.format("%d:%02d", m, s)
end

---------------------------------------------------------------------------
-- DEBOUNCE
---------------------------------------------------------------------------

--- Returns a debounced version of the given function.
--- The returned function will ignore calls made within `cooldown` seconds
--- of the last successful invocation.
function Utilities.debounce(func: (...any) -> ...any, cooldown: number): (...any) -> ()
    local lastCall = 0
    return function(...)
        local now = tick()
        if now - lastCall >= cooldown then
            lastCall = now
            func(...)
        end
    end
end

---------------------------------------------------------------------------
-- IDENTIFIERS
---------------------------------------------------------------------------

--- Generate a short unique ID (for furniture placements, transactions, etc.)
function Utilities.generateId(): string
    return HttpService:GenerateGUID(false)
end

---------------------------------------------------------------------------
-- SAFE REQUIRE
---------------------------------------------------------------------------

--- pcall-wrapped require that returns (success, module).
function Utilities.safeRequire(moduleScript)
    local ok, result = pcall(require, moduleScript)
    if not ok then
        warn("[Utilities.safeRequire] Failed to require " ..
             tostring(moduleScript) .. ": " .. tostring(result))
        return nil
    end
    return result
end

return Utilities
