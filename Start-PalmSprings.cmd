@echo off
title Palm Springs Paradise - Rojo Server
cd /d "%~dp0"

set "ROKIT=%USERPROFILE%\.rokit\bin"
set "PATH=%ROKIT%;%PATH%"

if not exist "rokit.toml" (
    copy /Y "staging\toolchain\rokit.toml" "rokit.toml" >nul 2>&1
    copy /Y "staging\toolchain\wally.toml" "wally.toml" >nul 2>&1
)

echo.
echo  ========================================
echo   Palm Springs Paradise - Game Server
echo  ========================================
echo.
echo  LEAVE THIS WINDOW OPEN while you work.
echo.
echo  1. Open Roblox Studio (your Palm Springs place)
echo  2. Plugins - Rojo - Connect
echo  3. Press Play to test
echo.
echo  To add ideas: use Cursor chat (see docs\karlux\karl-prompt-menu.md)
echo  Do NOT close this window until you are done for the day.
echo.
echo  Starting Rojo...
echo.

rojo serve

echo.
echo  Rojo stopped. Double-click Start-PalmSprings.cmd to start again.
pause
