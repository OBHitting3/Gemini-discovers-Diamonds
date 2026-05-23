# Palm Springs Paradise — Windows workspace bootstrap
# Run in: Cursor → Terminal (PowerShell)
#   powershell -ExecutionPolicy Bypass -File staging\scripts\krlx-workspace-bootstrap.ps1

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $Root

Write-Host "=== KarLux Windows workspace bootstrap ===" -ForegroundColor Cyan

# Ensure rokit on PATH
$rokitBin = Join-Path $env:USERPROFILE ".rokit\bin"
if (Test-Path $rokitBin) {
    $env:Path = "$rokitBin;$env:Path"
}

# Link or copy toolchain manifests
$rokitSrc = Join-Path $Root "staging\toolchain\rokit.toml"
$wallySrc = Join-Path $Root "staging\toolchain\wally.toml"
if (-not (Test-Path "rokit.toml")) {
    try {
        cmd /c "mklink rokit.toml staging\toolchain\rokit.toml" 2>$null
    } catch {
        Copy-Item $rokitSrc "rokit.toml" -Force
    }
}
if (-not (Test-Path "wally.toml")) {
    try {
        cmd /c "mklink wally.toml staging\toolchain\wally.toml" 2>$null
    } catch {
        Copy-Item $wallySrc "wally.toml" -Force
    }
}

if (Get-Command rokit -ErrorAction SilentlyContinue) {
    Write-Host "Installing Rokit tools (approve trust prompts if shown)..."
    rokit install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "If install failed on trust, run: rokit trust JohnnyMorganz/StyLua rojo-rbx/rojo UpliftGames/wally seaofvoices/darklua rojo-rbx/remodel Kampfkarren/selene" -ForegroundColor Yellow
        rokit install
    }
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
    Write-Host "Created .env — fill Supabase keys locally"
}

if (Test-Path "staging\scripts\toolchain\verify.ps1") {
    & "$Root\staging\scripts\toolchain\verify.ps1"
}

Write-Host ""
Write-Host "Next: Cursor -> Tasks: Run Task -> Rojo: Serve -> Roblox Studio -> Connect" -ForegroundColor Green
