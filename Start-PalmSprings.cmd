@echo off
title Palm Springs Paradise - Rojo Server
cd /d "%~dp0"

call "%~dp0staging\scripts\karl-preflight.cmd"
if errorlevel 1 (
    pause
    exit /b 1
)

set "ROKIT=%USERPROFILE%\.rokit\bin"
set "PATH=%ROKIT%;%PATH%"

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

if exist "%USERPROFILE%\Documents\Roblox\PalmSpringsDev.rbxlx" (
    echo  Opening PalmSpringsDev.rbxlx in Studio...
    start "" "%USERPROFILE%\Documents\Roblox\PalmSpringsDev.rbxlx"
) else if exist "%USERPROFILE%\Desktop\PalmSpringsParadise.rbxlx" (
    echo  Opening PalmSpringsParadise.rbxlx on Desktop...
    start "" "%USERPROFILE%\Desktop\PalmSpringsParadise.rbxlx"
)
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
