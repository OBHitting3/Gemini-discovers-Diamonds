# Palm Springs Paradise — Windows workspace bootstrap
# Run in: Cursor → Terminal (PowerShell)
#   powershell -ExecutionPolicy Bypass -File staging\scripts\krlx-workspace-bootstrap.ps1

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $Root

Write-Host "=== KarLux Windows workspace bootstrap ===" -ForegroundColor Cyan

# Ensure rokit tools on PATH (user + project bins)
foreach ($bin in @(
        (Join-Path $Root ".rokit\bin"),
        (Join-Path $env:USERPROFILE ".rokit\bin")
    )) {
    if (Test-Path $bin) { $env:Path = "$bin;$env:Path" }
}

# Always refresh toolchain manifests from staging (Windows copies go stale after git pull)
$rokitSrc = Join-Path $Root "staging\toolchain\rokit.toml"
$wallySrc = Join-Path $Root "staging\toolchain\wally.toml"
Copy-Item $rokitSrc "rokit.toml" -Force
Copy-Item $wallySrc "wally.toml" -Force
Write-Host "Synced rokit.toml and wally.toml from staging\toolchain"

if (Get-Command rokit -ErrorAction SilentlyContinue) {
    Write-Host "Installing Rokit tools..."
    rokit install
} else {
    Write-Host "WARN: rokit not found. Run Step 2 in 07-step-by-step-install-windows.md" -ForegroundColor Yellow
}

if (Get-Command wally -ErrorAction SilentlyContinue) {
    wally install
}

# Editor config
if (-not (Test-Path ".vscode") -and (Test-Path "staging\editor\.vscode")) {
    Copy-Item -Recurse "staging\editor\.vscode" ".vscode"
    Write-Host "Installed .vscode from staging"
}

# Env template
if (-not (Test-Path ".env") -and (Test-Path "staging\env\.env.example")) {
    Copy-Item "staging\env\.env.example" ".env"
    Write-Host "Created .env - fill Supabase keys locally"
}

if (Test-Path "staging\scripts\toolchain\verify.ps1") {
    & "$Root\staging\scripts\toolchain\verify.ps1"
}

Write-Host ""
Write-Host "Next: Cursor -> Tasks: Run Task -> Rojo: Serve -> Roblox Studio -> Connect" -ForegroundColor Green
