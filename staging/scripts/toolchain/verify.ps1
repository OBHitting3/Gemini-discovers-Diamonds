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

Write-Host ""
Write-Host "--- Repo layout ---"
foreach ($rel in @("src", "staging", "default.project.json")) {
    if (Test-Path (Join-Path $Root $rel)) {
        Write-Host "  OK  $rel"
    } else {
        Write-Host "  MISS $rel"
        $missing += "layout:$rel"
    }
}

if ((Test-Path (Join-Path $Root "rokit.toml")) -or (Test-Path (Join-Path $Root "staging\toolchain\rokit.toml"))) {
    Write-Host "  OK  rokit.toml present"
} else {
    Write-Host "  WARN rokit.toml — copy or mklink from staging\toolchain (Step 3)"
}

if (Test-Path (Join-Path $Root "Packages")) {
    Write-Host "  OK  Packages/ (wally install done)"
} else {
    Write-Host "  INFO Packages/ missing — run: wally install"
}

if ((Test-Path (Join-Path $Root ".vscode")) -or (Test-Path (Join-Path $Root "staging\editor\.vscode"))) {
    Write-Host "  OK  VS Code / Cursor workspace config present"
} else {
    Write-Host "  INFO run: staging\scripts\krlx-workspace-bootstrap.ps1"
}

try {
    Push-Location $Root
    $branch = (git rev-parse --abbrev-ref HEAD 2>$null)
    if ($branch -eq "cursor/karlux-foundation-292d") {
        Write-Host "  OK  git branch $branch"
    } elseif ($branch) {
        Write-Host "  WARN git on '$branch' — handoff branch: cursor/karlux-foundation-292d"
        Write-Host "       git checkout cursor/karlux-foundation-292d"
    }
} finally {
    Pop-Location
}

if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "Install: rokit install (see docs/karlux/07-step-by-step-install-windows.md)"
    exit 1
}

Write-Host "=== All required tools found ==="
exit 0
