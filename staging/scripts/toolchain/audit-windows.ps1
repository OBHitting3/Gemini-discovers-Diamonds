# Full Windows toolchain + repo audit
# Cursor → Terminal (PowerShell):
#   cd <your PalmSprings folder>
#   powershell -ExecutionPolicy Bypass -File staging\scripts\toolchain\audit-windows.ps1

$ErrorActionPreference = "Continue"
$Root = if ($PSScriptRoot) {
    Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
} else { Get-Location }

Set-Location $Root
$rokitBin = Join-Path $env:USERPROFILE ".rokit\bin"
if (Test-Path $rokitBin) { $env:Path = "$rokitBin;$env:Path" }

function Test-Tool($name) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if (-not $cmd) { return @{ ok = $false; detail = "not in PATH" } }
    try {
        $ver = & $name --version 2>&1 | Select-Object -First 1
        return @{ ok = $true; detail = "$ver" }
    } catch {
        return @{ ok = $true; detail = "installed (version unknown)" }
    }
}

function Test-FileExists($rel, $label) {
    $p = Join-Path $Root $rel
    @{ ok = (Test-Path $p); label = $label; path = $rel }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Palm Springs - Windows install audit" -ForegroundColor Cyan
Write-Host " Repo: $Root" -ForegroundColor DarkGray
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`n--- PowerShell ---" -ForegroundColor Yellow
Write-Host "  Version: $($PSVersionTable.PSVersion)"
Write-Host "  Edition: $($PSVersionTable.PSEdition)"

Write-Host "`n--- Required CLI tools ---" -ForegroundColor Yellow
$required = @("git", "rokit", "rojo", "wally", "stylua", "selene")
$missingRequired = @()
foreach ($t in $required) {
    $r = Test-Tool $t
    if ($r.ok) { Write-Host "  [OK]   $t - $($r.detail)" -ForegroundColor Green }
    else { Write-Host "  [MISS] $t - $($r.detail)" -ForegroundColor Red; $missingRequired += $t }
}

Write-Host "`n--- Optional CLI tools ---" -ForegroundColor Yellow
foreach ($t in @("darklua", "remodel", "tarmac", "supabase")) {
    $r = Test-Tool $t
    if ($r.ok) { Write-Host "  [OK]   $t - $($r.detail)" -ForegroundColor Green }
    else { Write-Host "  [OPT]  $t - not installed" -ForegroundColor DarkYellow }
}

Write-Host "`n--- Rokit PATH ---" -ForegroundColor Yellow
if (Test-Path $rokitBin) {
    Write-Host "  [OK]   $rokitBin exists" -ForegroundColor Green
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -like "*\.rokit\bin*") {
        Write-Host "  [OK]   .rokit\bin in User PATH" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] .rokit\bin NOT in User PATH (restart Cursor after adding)" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [MISS] $rokitBin - run Rokit install script" -ForegroundColor Red
    $missingRequired += "rokit(install)"
}

Write-Host "`n--- Repo files ---" -ForegroundColor Yellow
$files = @(
    @("src\server\init.server.lua", "Production server bootstrap"),
    @("default.project.json", "Rojo project"),
    @("rokit.toml", "Toolchain manifest"),
    @("wally.toml", "Wally manifest"),
    @(".vscode\tasks.json", "Cursor/VS Code tasks"),
    @("staging\src\shared\DayPhaseConfig.lua", "Staged day loop (not merged)"),
    @("vendor-imports\_manifests\asset-index.yaml", "Asset manifest")
)
foreach ($f in $files) {
    $check = Test-FileExists $f[0] $f[1]
    if ($check.ok) { Write-Host "  [OK]   $($f[0])" -ForegroundColor Green }
    else { Write-Host "  [MISS] $($f[0])" -ForegroundColor Red }
}

Write-Host "`n--- Wally packages ---" -ForegroundColor Yellow
if (Test-Path (Join-Path $Root "Packages")) {
    Write-Host "  [OK]   Packages\ folder exists" -ForegroundColor Green
} else {
    Write-Host "  [INFO] Packages\ missing - run: wally install" -ForegroundColor DarkYellow
}

Write-Host "`n--- External apps (manual check) ---" -ForegroundColor Yellow
$studioPaths = @(
    "${env:LOCALAPPDATA}\Roblox\Versions",
    "C:\Program Files (x86)\Roblox\Versions"
)
$studioFound = $false
foreach ($sp in $studioPaths) {
    if (Test-Path $sp) { $studioFound = $true; break }
}
if ($studioFound) { Write-Host "  [OK]   Roblox Studio (Versions folder found)" -ForegroundColor Green }
else { Write-Host "  [???]  Roblox Studio - install from create.roblox.com" -ForegroundColor Yellow }

$blender = @(
    "${env:ProgramFiles}\Blender Foundation",
    "${env:ProgramFiles(x86)}\Blender Foundation"
) | Where-Object { Test-Path $_ }
if ($blender) { Write-Host "  [OK]   Blender folder found" -ForegroundColor Green }
else { Write-Host "  [OPT]  Blender - not detected (optional for art)" -ForegroundColor DarkYellow }

Write-Host "`n--- Summary ---" -ForegroundColor Cyan
if ($missingRequired.Count -eq 0) {
    Write-Host "  READY for dev: rojo serve + Studio Connect" -ForegroundColor Green
    Write-Host "  Next: Task 'Rojo: Serve' or: rojo serve" -ForegroundColor Green
} else {
    Write-Host "  INSTALL NEEDED:" -ForegroundColor Red
    foreach ($m in $missingRequired) { Write-Host "    - $m" }
    Write-Host ""
    Write-Host "  Fix steps:" -ForegroundColor Yellow
    Write-Host "    1. irm https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | iex"
    Write-Host "    2. Copy-Item staging\toolchain\rokit.toml . -Force"
    Write-Host "    3. Copy-Item staging\toolchain\wally.toml . -Force"
    Write-Host "    4. rokit install"
    Write-Host "    5. Restart Cursor"
}

Write-Host "`n  Doc: docs\karlux\07-step-by-step-install-windows.md" -ForegroundColor DarkGray
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($missingRequired.Count -gt 0) { exit 1 }
exit 0
