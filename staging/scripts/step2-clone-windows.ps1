# Step 2 — Clone Palm Springs repo (Windows)
# Run from ANY PowerShell (Start menu is fine — Cursor not required yet):
#   irm https://raw.githubusercontent.com/OBHitting3/Gemini-discovers-Diamonds/cursor/pc-transfer-audit-0002/staging/scripts/step2-clone-windows.ps1 | iex
#
# Or after you have the repo: powershell -ExecutionPolicy Bypass -File staging\scripts\step2-clone-windows.ps1

$ErrorActionPreference = "Stop"
$Target = Join-Path $env:USERPROFILE "Documents\Roblox\PalmSprings"
$Branch = "cursor/pc-transfer-audit-0002"
$Repo = "https://github.com/OBHitting3/Gemini-discovers-Diamonds.git"

Write-Host "=== Palm Springs — Step 2 Clone ===" -ForegroundColor Cyan
Write-Host "Target: $Target"
Write-Host "Branch: $Branch"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host ""
    Write-Host "Git is not installed." -ForegroundColor Red
    Write-Host "Install: https://git-scm.com/download/win" -ForegroundColor Yellow
    Write-Host "Then run this script again."
    exit 1
}

New-Item -ItemType Directory -Force -Path (Split-Path $Target) | Out-Null

if (Test-Path (Join-Path $Target ".git")) {
    Write-Host "Repo exists — updating..."
    Set-Location $Target
    git fetch origin
    git checkout $Branch 2>$null
    if ($LASTEXITCODE -ne 0) { git checkout -b $Branch "origin/$Branch" }
    git pull origin $Branch
} else {
    if (Test-Path $Target) {
        Write-Host "WARN: Folder exists but is not a git repo: $Target" -ForegroundColor Yellow
        Write-Host "Move or rename it, then run again."
        exit 1
    }
    Write-Host "Cloning..."
    git clone $Repo $Target
    Set-Location $Target
    git checkout $Branch
}

Write-Host ""
Write-Host "Done. Repo root:" -ForegroundColor Green
Write-Host "  $Target"
Write-Host ""
Write-Host "Next (Cursor):" -ForegroundColor Cyan
Write-Host "  1. Open Cursor"
Write-Host "  2. File -> Open Folder"
Write-Host "  3. Choose: $Target"
Write-Host "  4. Terminal -> New Terminal (PowerShell)"
