# Toolchain verify — Windows
# Cursor → PowerShell: powershell -ExecutionPolicy Bypass -File staging\scripts\toolchain\verify.ps1

$Root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$rokitBin = Join-Path $env:USERPROFILE ".rokit\bin"
if (Test-Path $rokitBin) { $env:Path = "$rokitBin;$env:Path" }

Write-Host "=== Palm Springs Paradise — toolchain verify (Windows) ==="

$required = @("rojo", "wally", "stylua", "selene", "git")
$missing = @()

foreach ($tool in $required) {
    $cmd = Get-Command $tool -ErrorAction SilentlyContinue
    if ($cmd) {
        $ver = & $tool --version 2>&1 | Select-Object -First 1
        Write-Host "  OK  $tool — $ver"
    } else {
        Write-Host "  MISS $tool"
        $missing += $tool
    }
}

foreach ($tool in @("darklua", "remodel")) {
    $cmd = Get-Command $tool -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host "  OK  $tool (optional)"
    } else {
        Write-Host "  OPT $tool"
    }
}

Write-Host "  OPT tarmac — use Studio Import 3D"

if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "Install: rokit install (see docs/karlux/07-step-by-step-install-windows.md)"
    exit 1
}

Write-Host "=== All required tools found ==="
exit 0
