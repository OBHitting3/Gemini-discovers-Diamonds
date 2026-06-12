--[[
    Util.lua
    Shared utility functions used across client and server.
]]

local Util = {}

--- Deep copy a table (handles nested tables, no metatables)
function Util.DeepCopy(original)
    if type(original) ~= "table" then
        return original
    end
    local copy = {}
    for key, value in original do
        copy[Util.DeepCopy(key)] = Util.DeepCopy(value)
    end
    return copy
end

--- Shallow copy a table
function Util.ShallowCopy(original)
    if type(original) ~= "table" then
        return original
    end
    local copy = {}
    for key, value in original do
        copy[key] = value
    end
    return copy
end

--- Weighted random selection from a table of { item, weight }
function Util.WeightedRandom(items: { { Item: any, Weight: number } }): any
    local totalWeight = 0
    for _, entry in items do
        totalWeight += entry.Weight
    end

    local roll = math.random() * totalWeight
    local cumulative = 0
    for _, entry in items do
        cumulative += entry.Weight
        if roll <= cumulative then
            return entry.Item
        end
    end

    -- Fallback (shouldn't reach here)
    return items[#items].Item
end

--- Generate a short unique ID
function Util.GenerateUID(): string
    return string.format("%s_%s", tostring(os.clock()):gsub("%.", ""), tostring(math.random(10000, 99999)))
end

--- Clamp a number between min and max
function Util.Clamp(value: number, min: number, max: number): number
    return math.max(min, math.min(max, value))
end

--- Round a number to N decimal places
function Util.Round(value: number, decimals: number?): number
    local mult = 10 ^ (decimals or 0)
    return math.floor(value * mult + 0.5) / mult
end

--- Format large numbers with commas: 1234567 -> "1,234,567"
function Util.FormatNumber(n: number): string
    local formatted = tostring(math.floor(n))
    local k
    repeat
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
    until k == 0
    return formatted
end

--- Format time in seconds to MM:SS or HH:MM:SS
function Util.FormatTime(seconds: number): string
    seconds = math.max(0, math.floor(seconds))
    if seconds >= 3600 then
        local h = math.floor(seconds / 3600)
        local m = math.floor((seconds % 3600) / 60)
        local s = seconds % 60
        return string.format("%d:%02d:%02d", h, m, s)
    else
        local m = math.floor(seconds / 60)
        local s = seconds % 60
        return string.format("%d:%02d", m, s)
    end
end

--- Lerp between two values
function Util.Lerp(a: number, b: number, t: number): number
    return a + (b - a) * t
end

--- Check if a table contains a value
function Util.Contains(tbl, value): boolean
    for _, v in tbl do
        if v == value then
            return true
        end
    end
    return false
end

--- Get current day number (for daily resets)
function Util.GetDayNumber(): number
    return math.floor(os.time() / 86400)
end

--- Safe require with error handling
function Util.SafeRequire(moduleScript)
    local success, result = pcall(require, moduleScript)
    if success then
        return result
    else
        warn("[Util.SafeRequire] Failed to require:", moduleScript:GetFullName(), result)
        return nil
    end
end

return Util
