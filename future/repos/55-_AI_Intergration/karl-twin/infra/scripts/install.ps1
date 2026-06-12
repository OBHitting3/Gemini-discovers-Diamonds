# karl-twin install: creates venv, installs requirements, generates .env,
# starts docker-compose stack. Idempotent. Run from C:\karl-twin\.
#
# Usage:
#   cd C:\karl-twin
#   .\infra\scripts\install.ps1

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path "$PSScriptRoot\..\..").Path
Set-Location $Root

Write-Host "==> Installing karl-twin in $Root"

# 1. Create venv (Python 3.11)
if (-not (Test-Path .venv)) {
    Write-Host "[VENV] Creating .venv with Python 3.11"
    py -3.11 -m venv .venv
}
& .\.venv\Scripts\Activate.ps1

# 2. Install Python deps
python -m pip install --upgrade pip
pip install -r requirements.txt

# 3. Generate .env if missing
if (-not (Test-Path .env)) {
    Write-Host "[ENV] Generating .env from .env.example"
    python -m karl_twin.admin generate_env
    Write-Host "[ACTION] Open .env and fill in ANTHROPIC_API_KEY and E2B_API_KEY before starting."
}

# 4. Start docker stack
# --env-file pins the .env at the repo root; without it, Compose looks for
# .env in the same dir as the -f compose file (infra/docker/) and fails the
# ${QDRANT_API_KEY:?...} interpolation.
Write-Host "[DOCKER] Bringing up Qdrant + Postgres"
docker compose --env-file "$Root\.env" -f "$Root\infra\docker\docker-compose.yml" up -d

Write-Host "==> Install complete."
Write-Host "Next:"
Write-Host "  1. Edit .env and add ANTHROPIC_API_KEY + E2B_API_KEY"
Write-Host "  2. .\infra\scripts\start.ps1   # starts API + worker"
Write-Host "  3. Open the LAN URL printed at startup on your Pixel"
