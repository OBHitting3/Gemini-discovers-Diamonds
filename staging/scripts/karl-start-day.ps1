# Karl - automated start of dev day (Windows)
#   powershell -ExecutionPolicy Bypass -File staging\scripts\karl-start-day.ps1

$ErrorActionPreference = "Continue"
$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $Root

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Palm Springs - Karl start dev day" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$rokitBin = Join-Path $env:USERPROFILE ".rokit\bin"
$env:Path = "$rokitBin;$env:Path"

# 1. Toolchain manifests (symlink-safe — same as CI)
$rokitSrc = Join-Path $Root "staging\toolchain\rokit.toml"
$wallySrc = Join-Path $Root "staging\toolchain\wally.toml"
Remove-Item (Join-Path $Root "rokit.toml") -Force -ErrorAction SilentlyContinue
Remove-Item (Join-Path $Root "wally.toml") -Force -ErrorAction SilentlyContinue
Copy-Item $rokitSrc (Join-Path $Root "rokit.toml") -Force
Copy-Item $wallySrc (Join-Path $Root "wally.toml") -Force
Write-Host "[1/5] Synced rokit.toml + wally.toml from staging" -ForegroundColor Green

# 2. Install CLI tools
if (Get-Command rokit -ErrorAction SilentlyContinue) {
    rokit install --no-trust-check 2>&1 | Out-Null
    Write-Host "[2/5] rokit install - done" -ForegroundColor Green
} else {
    Write-Host "[2/5] MISS rokit - install from 07-step-by-step-install-windows.md" -ForegroundColor Red
}

if (Get-Command wally -ErrorAction SilentlyContinue) {
    wally install 2>&1 | Out-Null
    Write-Host "       wally install - done" -ForegroundColor Green
}

# 3. Verify + audit
$verify = Join-Path $Root "staging\scripts\toolchain\verify.ps1"
$audit = Join-Path $Root "staging\scripts\toolchain\audit-windows.ps1"
if (Test-Path $verify) {
    Write-Host "[3/5] Toolchain verify..." -ForegroundColor Yellow
    & powershell -ExecutionPolicy Bypass -File $verify
}
if (Test-Path $audit) {
    Write-Host "[4/5] Windows audit..." -ForegroundColor Yellow
    & powershell -ExecutionPolicy Bypass -File $audit
}

# 5. Agent handoff status (SuperbulletAI / Karl checklist)
Write-Host ""
Write-Host "[5/5] Agent handoff status" -ForegroundColor Yellow

$manifest = Join-Path $Root "vendor-imports\_manifests\asset-index.yaml"
if (Test-Path $manifest) {
    Write-Host "  [OK]   Manus: asset-index.yaml present" -ForegroundColor Green
} else {
    Write-Host "  [TODO] Manus: populate vendor-imports\_manifests\asset-index.yaml" -ForegroundColor Yellow
}

$srcCore = Join-Path $Root "src\server\Services\CoreLoopService.lua"
$propBuilder = Join-Path $Root "src\server\Builders\PropBuilder.lua"
if (Test-Path $srcCore) {
    Write-Host "  [OK]   Day-phase CoreLoop in src/" -ForegroundColor Green
} else {
    Write-Host "  [TODO] CoreLoop missing in src/" -ForegroundColor Yellow
}
if (Test-Path $propBuilder) {
    Write-Host "  [OK]   Prompt-to-3D PropBuilder in src/" -ForegroundColor Green
} else {
    Write-Host "  [TODO] Pull latest for PropBuilder (Karl /spawnprop)" -ForegroundColor Yellow
}

if (Test-Path (Join-Path $Root "staging\supabase\migrations")) {
    Write-Host "  [INFO] Manus: run supabase db push when project linked" -ForegroundColor DarkYellow
}

Write-Host "  [INFO] Supabase in Studio: mock until Roblox Secrets set" -ForegroundColor DarkYellow
Write-Host "  [INFO] SuperbulletAI: see docs\karlux\08-karl-automation-playbook.md" -ForegroundColor DarkGray

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " NEXT (Karl)" -ForegroundColor Green
Write-Host "   1. Double-click Start-PalmSprings.cmd (Karl)" -ForegroundColor Green
Write-Host "   2. Studio -> Rojo Connect -> Play Solo" -ForegroundColor Green
Write-Host "   3. Chat: /help  /health  /spawnprop flamingo_lawn" -ForegroundColor Green
Write-Host " Doc: docs\karlux\08-karl-automation-playbook.md" -ForegroundColor DarkGray
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
