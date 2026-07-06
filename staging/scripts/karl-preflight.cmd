@echo off
setlocal
title Palm Springs - Preflight
cd /d "%~dp0..\.."

set "ROKIT=%USERPROFILE%\.rokit\bin"
set "PATH=%ROKIT%;%PATH%"

echo.
echo  Palm Springs Paradise - Preflight
echo  ================================
echo.

set "FAIL=0"

where rokit >nul 2>&1
if errorlevel 1 (
    echo  [FAIL] Rokit not installed. Eddie: see docs\karlux\07-step-by-step-install-windows.md
    set "FAIL=1"
) else (
    echo  [OK]   Rokit found
)

where rojo >nul 2>&1
if errorlevel 1 (
    echo  [FAIL] Rojo not on PATH. Run: rokit install
    set "FAIL=1"
) else (
    for /f "delims=" %%V in ('rojo --version 2^>nul') do echo  [OK]   %%V
)

if not exist "staging\toolchain\rokit.toml" (
    echo  [FAIL] Missing staging\toolchain\rokit.toml
    set "FAIL=1"
)

if not exist "rokit.toml" (
    echo  [INFO] Copying toolchain manifests to repo root...
    copy /Y "staging\toolchain\rokit.toml" "rokit.toml" >nul
    copy /Y "staging\toolchain\wally.toml" "wally.toml" >nul
)

if not exist "src\server\init.server.lua" (
    echo  [FAIL] Not in Palm Springs repo root
    set "FAIL=1"
) else (
    echo  [OK]   Game source present
)

if not exist "src\server\Builders\PropBuilder.lua" (
    echo  [WARN] PropBuilder missing - pull latest cursor/karlux-foundation-292d
) else (
    echo  [OK]   Prompt-to-3D PropBuilder present
)

netstat -ano 2>nul | findstr ":34872" >nul 2>&1
if not errorlevel 1 (
    echo  [WARN] Port 34872 in use - close other Rojo window or reuse it
)

echo.
if "%FAIL%"=="1" (
    echo  Preflight FAILED - fix items above before Play Solo.
    echo.
    endlocal
    exit /b 1
)

echo  Preflight PASSED - starting Rojo...
echo.
endlocal
exit /b 0
