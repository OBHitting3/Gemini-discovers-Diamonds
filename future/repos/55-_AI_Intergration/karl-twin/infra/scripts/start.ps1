# Starts API and worker in two PowerShell windows. Stack assumed up.
$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path "$PSScriptRoot\..\..").Path
Set-Location $Root

# Warn (don't fail) if user-supplied keys are still blank. The system will
# still start; the LLM planner and E2B sandbox will fail loudly at call time
# until the keys are filled in.
$envFile = Join-Path $Root '.env'
if (Test-Path $envFile) {
    $envText = Get-Content $envFile -Raw
    $missing = @()
    if ($envText -match '(?m)^ANTHROPIC_API_KEY=\s*$') { $missing += 'ANTHROPIC_API_KEY' }
    if ($envText -match '(?m)^E2B_API_KEY=\s*$')      { $missing += 'E2B_API_KEY' }
    if ($missing.Count -gt 0) {
        Write-Host ""
        Write-Host "================================================================" -ForegroundColor Yellow
        Write-Host " REMINDER: missing keys in .env  → $($missing -join ', ')" -ForegroundColor Yellow
        Write-Host "  Anthropic: https://console.anthropic.com/settings/keys"
        Write-Host "  E2B     : https://e2b.dev/dashboard?tab=keys"
        Write-Host "  System will start, but LLM/sandbox calls will fail until set." -ForegroundColor Yellow
        Write-Host "================================================================" -ForegroundColor Yellow
        Write-Host ""
    }
}

# Ensure docker stack is up. --env-file pins to the repo-root .env so
# Compose's ${VAR:?...} interpolation resolves correctly.
docker compose --env-file "$Root\.env" -f "$Root\infra\docker\docker-compose.yml" up -d

# Activate venv and launch API + worker in detached windows
$activate = "$Root\.venv\Scripts\Activate.ps1"

Start-Process powershell -ArgumentList @(
    '-NoExit', '-Command',
    ". `"$activate`"; Set-Location `"$Root`"; python -m karl_twin.api"
) | Out-Null

Start-Process powershell -ArgumentList @(
    '-NoExit', '-Command',
    ". `"$activate`"; Set-Location `"$Root`"; python -m karl_twin.worker"
) | Out-Null

Write-Host "API and worker launched in separate windows."
Write-Host "Approval UI: http://<LAN-IP>:8000/   (LAN-IP printed by API)"
