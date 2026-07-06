--[[
    Resilience.lua
    Retry helpers (pattern from content-shield resilience layer).
]]

local Resilience = {}

export type RetryOptions = {
    maxAttempts: number?,
    delaySeconds: number?,
    backoffMultiplier: number?,
    label: string?,
}

local function resolveOptions(options: RetryOptions?)
    return {
        maxAttempts = (options and options.maxAttempts) or 3,
        delaySeconds = (options and options.delaySeconds) or 0.5,
        backoffMultiplier = (options and options.backoffMultiplier) or 2,
        label = (options and options.label) or "operation",
    }
end

--- `fn` must return true on success. Retries on false return or pcall error.
function Resilience.retryBool(options: RetryOptions?, fn: () -> boolean): boolean
    local opts = resolveOptions(options)
    local delay = opts.delaySeconds

    for attempt = 1, opts.maxAttempts do
        local ok, result = pcall(fn)
        if ok and result == true then
            return true
        end

        if attempt < opts.maxAttempts then
            warn(
                string.format(
                    "[Resilience] %s attempt %d/%d failed — retrying in %.1fs",
                    opts.label,
                    attempt,
                    opts.maxAttempts,
                    delay
                )
            )
            task.wait(delay)
            delay *= opts.backoffMultiplier
        end
    end

    return false
end

--- `fn` returns (success: boolean, ...). Retries when success is false.
function Resilience.retryResult(options: RetryOptions?, fn: () -> (boolean, any)): (boolean, any)
    local opts = resolveOptions(options)
    local delay = opts.delaySeconds
    local lastErr: any = nil

    for attempt = 1, opts.maxAttempts do
        local callOk, success, detail = pcall(fn)

        if callOk and success == true then
            return true, detail
        end

        lastErr = if callOk then detail else success

        if attempt < opts.maxAttempts then
            warn(
                string.format(
                    "[Resilience] %s attempt %d/%d failed: %s",
                    opts.label,
                    attempt,
                    opts.maxAttempts,
                    tostring(lastErr)
                )
            )
            task.wait(delay)
            delay *= opts.backoffMultiplier
        end
    end

    return false, lastErr
end

return Resilience
