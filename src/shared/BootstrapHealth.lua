--[[
    BootstrapHealth.lua
    Server bootstrap status for /health and Karl troubleshooting.
]]

local BootstrapHealth = {}

BootstrapHealth._services = {} -- name -> { ok: boolean, error: string? }
BootstrapHealth._partCount = 0
BootstrapHealth._startedAt = os.time()

function BootstrapHealth:setService(name: string, ok: boolean, err: string?)
    self._services[name] = {
        ok = ok,
        error = err,
    }
end

function BootstrapHealth:setPartCount(count: number)
    self._partCount = count
end

function BootstrapHealth:getSnapshot(): { [string]: any }
    local failed = 0
    local passed = 0
    for _, entry in pairs(self._services) do
        if entry.ok then
            passed += 1
        else
            failed += 1
        end
    end

    return {
        uptimeSec = os.time() - self._startedAt,
        servicesPassed = passed,
        servicesFailed = failed,
        envParts = self._partCount,
        services = self._services,
        healthy = failed == 0,
    }
end

return BootstrapHealth
