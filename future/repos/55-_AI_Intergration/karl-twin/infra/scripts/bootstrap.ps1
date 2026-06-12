# karl-twin Windows 11 bootstrap. Run as Administrator in PowerShell.
# Installs all host prerequisites required by the karl-twin stack.
# Verifies: Docker Desktop + WSL2 backend, Python 3.11, git, ffmpeg,
# NVIDIA Container Toolkit (via Docker Desktop GPU support), Tailscale.
#
# Usage:
#   Set-ExecutionPolicy -Scope Process Bypass
#   .\bootstrap.ps1

$ErrorActionPreference = 'Stop'

function Test-Cmd($name) {
    return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

function Install-IfMissing($probeCmd, $wingetId, $label) {
    if (Test-Cmd $probeCmd) {
        Write-Host "[OK] $label already installed: $(& $probeCmd --version 2>$null | Select-Object -First 1)"
        return
    }
    Write-Host "[INSTALL] $label via winget ($wingetId)..."
    winget install --id $wingetId --silent --accept-source-agreements --accept-package-agreements
}

Write-Host "==> karl-twin bootstrap starting"

# 1. WSL2
Write-Host "==> Verifying WSL2"
try {
    $wslStatus = wsl --status 2>&1 | Out-String
    if ($wslStatus -notmatch '2') {
        Write-Host "[ACTION] WSL2 not default. Running 'wsl --set-default-version 2'."
        wsl --set-default-version 2
    } else {
        Write-Host "[OK] WSL2 is default."
    }
} catch {
    Write-Host "[INSTALL] WSL not found. Running 'wsl --install --no-launch'."
    wsl --install --no-launch
    Write-Host "[ACTION] Reboot Windows after first WSL install, then re-run this script."
}

# 2. winget probe
if (-not (Test-Cmd winget)) {
    Write-Error "winget is not available. Install 'App Installer' from Microsoft Store, then re-run."
}

# 3. Core tools
Install-IfMissing 'git'    'Git.Git'                 'git'
Install-IfMissing 'python' 'Python.Python.3.11'      'Python 3.11'
Install-IfMissing 'ffmpeg' 'Gyan.FFmpeg'             'ffmpeg'
Install-IfMissing 'docker' 'Docker.DockerDesktop'    'Docker Desktop'
Install-IfMissing 'tailscale' 'Tailscale.Tailscale'  'Tailscale'

# 4. Verify Python 3.11 is the active "python" (not 3.12+)
$pyVer = & python --version 2>&1
if ($pyVer -notmatch '3\.11') {
    Write-Warning "Active python is '$pyVer'. faster-whisper requires 3.11. Install py launcher or pin 3.11 on PATH."
}

# 5. Docker Desktop GPU / NVIDIA Container Toolkit check
Write-Host "==> Verifying Docker GPU runtime"
try {
    docker info 2>&1 | Out-Null
    $gpuTest = docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi 2>&1 | Out-String
    if ($gpuTest -match 'NVIDIA-SMI' -and $gpuTest -match 'RTX') {
        Write-Host "[OK] Docker GPU passthrough functional."
    } else {
        Write-Warning "Docker GPU passthrough did not show NVIDIA-SMI output. Open Docker Desktop > Settings > Resources > WSL Integration and ensure GPU support is enabled, then 'wsl --shutdown' + restart Docker Desktop."
    }
} catch {
    Write-Warning "Docker daemon not running. Start Docker Desktop, wait for the whale icon, then re-run."
}

# 6. Tailscale state
Write-Host "==> Verifying Tailscale"
try {
    $tsStatus = & 'C:\Program Files\Tailscale\tailscale.exe' status 2>&1 | Out-String
    if ($tsStatus -match 'Logged out') {
        Write-Host "[ACTION] Tailscale installed but logged out. Run: tailscale up --advertise-tags=tag:karl-twin"
    } else {
        Write-Host "[OK] Tailscale running."
    }
} catch {
    Write-Warning "Tailscale not on PATH. Open Tailscale tray app and sign in."
}

Write-Host "==> Bootstrap complete. Next: copy karl-twin\ to C:\karl-twin\, then run install.ps1"
