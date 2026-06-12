# Key-free smoke test. Proves invariants #1, #2, #3, #4 without using
# Anthropic or E2B. Posts a file.write Action Envelope directly to the
# API, you approve it (Pixel UI or curl), worker writes hello.txt to
# data\outputs\, and the event log records the full chain.
#
# Run from C:\karl-twin\ AFTER `.\infra\scripts\start.ps1` is up.
#
# Usage:
#   .\infra\scripts\smoke_keyless.ps1
#   .\infra\scripts\smoke_keyless.ps1 -AutoApprove   # auto-approve via API

param(
    [switch]$AutoApprove
)

$ErrorActionPreference = 'Stop'

trap {
    Write-Host "[SMOKE] FATAL: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    break
}

Write-Host "[SMOKE] starting smoke_keyless.ps1"
$Root = (Resolve-Path "$PSScriptRoot\..\..").Path
Write-Host "[SMOKE] root=$Root"

$apiHost = '127.0.0.1'
$apiPort = 8000
$base = "http://${apiHost}:${apiPort}"

Write-Host "==> probing API at $base"
try {
    $h = Invoke-RestMethod "$base/admin/health" -TimeoutSec 5
    Write-Host "[OK] API live: pending=$($h.actions_pending) total=$($h.actions_total)"
} catch {
    Write-Error "API not reachable. Start it with .\infra\scripts\start.ps1 in another window first."
}

$actionId = [guid]::NewGuid().ToString()
$envelope = @{
    envelope = @{
        action_id      = $actionId
        timestamp      = (Get-Date).ToUniversalTime().ToString("o")
        action_type    = 'file.write'
        risk_level     = 'low'
        cac_score      = @{ HI = 3.0; MC = 2.0; EC = 2.0; tier = 1; rationale = 'keyless smoke' }
        reason         = 'keyless smoke test bypassing the LLM planner'
        tool           = 'file.write'
        payload_preview= 'WRITE -> hello.txt'
        payload        = @{ path = 'hello.txt'; content = 'hello world (keyless smoke)'; mode = 'w' }
        requires_approval = $true
        expires_in_sec = 600
        status         = 'proposed'
        run_id         = "keyless-$([guid]::NewGuid().ToString().Substring(0,8))"
    }
} | ConvertTo-Json -Depth 6

Write-Host "==> proposing action $actionId"
$null = Invoke-RestMethod "$base/actions/propose" -Method POST -Body $envelope -ContentType 'application/json' -TimeoutSec 5

if ($AutoApprove) {
    Write-Host "==> auto-approving"
    $null = Invoke-RestMethod "$base/actions/$actionId/approve" -Method POST -TimeoutSec 5
} else {
    Write-Host "==> open the approval UI on Pixel/Chrome and tap Approve:"
    try {
        $ip = (Test-NetConnection -ComputerName $apiHost -Port $apiPort -WarningAction SilentlyContinue).RemoteAddress
    } catch {}
    Write-Host "  $base/   (LAN: replace 127.0.0.1 with your machine's LAN IP)"
    Write-Host "==> waiting up to 5 min for approval..."
}

$deadline = (Get-Date).AddMinutes(5)
$last = $null
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 1
    try {
        $last = Invoke-RestMethod "$base/actions/$actionId" -TimeoutSec 5
        if ($last.executed_at) { break }
    } catch {}
}

if (-not $last.executed_at) {
    Write-Error "envelope did not execute within 5 min. Last status: $($last.status)"
}

Write-Host "[OK] executed_at=$($last.executed_at) status=$($last.status)"
$out = Join-Path $Root 'data\outputs\hello.txt'
if (Test-Path $out) {
    Write-Host "[OK] file written: $out"
    Write-Host "  contents: $(Get-Content $out -Raw)"
} else {
    Write-Error "expected file not found: $out"
}

Write-Host "==> last 15 events for this run:"
$events = Invoke-RestMethod "$base/admin/events?limit=200" -TimeoutSec 5
$events | Where-Object { $_.action_id -eq $actionId } | Select-Object -Last 15 ts, event_type, node | Format-Table -AutoSize

Write-Host ""
Write-Host "==> KEYLESS SMOKE PASSED. Invariants #1, #2, #3, #4 verified end-to-end."
Write-Host "    Get ANTHROPIC_API_KEY + E2B_API_KEY (see KEYS_TODO.md) to run the full LLM-driven smoke."
