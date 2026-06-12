#!/usr/bin/env bash
# ================================================================
#  Palm Springs Paradise — QUICK UPDATE
#  Double-click this file to pull the latest code and rebuild.
#  Run this after the initial setup.command has been run once.
# ================================================================

set -e

echo ""
echo "==========================================="
echo "  Palm Springs Paradise — Updating...      "
echo "==========================================="
echo ""

# ----------------------------------------------------------
# Paths
# ----------------------------------------------------------
BRANCH="cursor/art-direction-prototype-6c9e"
PROJECT_DIR="$HOME/Desktop/Roblox/PalmSprings"
OUTPUT="$HOME/Desktop/PalmSpringsParadise.rbxlx"

export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.aftman/bin:$HOME/.cargo/bin:$HOME/.foreman/bin:$PATH"

# ----------------------------------------------------------
# 1. Check project exists
# ----------------------------------------------------------
if [ ! -d "$PROJECT_DIR/.git" ]; then
    echo "ERROR: Project not found at $PROJECT_DIR"
    echo "Please run setup.command first!"
    echo ""
    osascript -e 'display dialog "Project not found!\n\nPlease run setup.command first to do the initial setup." with title "Palm Springs Paradise" buttons {"OK"} default button "OK" with icon stop' 2>/dev/null || true
    read -n 1 -s -r -p "Press any key to close..."
    exit 1
fi

cd "$PROJECT_DIR"

# ----------------------------------------------------------
# 2. Pull latest changes
# ----------------------------------------------------------
echo "[update] Pulling latest changes..."
git fetch origin
git checkout "$BRANCH" 2>/dev/null || true
git pull origin "$BRANCH"
echo "[update] Code updated."

# ----------------------------------------------------------
# 3. Check for Rojo
# ----------------------------------------------------------
if ! command -v rojo &> /dev/null; then
    echo "ERROR: Rojo not found. Please run setup.command to reinstall."
    osascript -e 'display dialog "Rojo not found!\n\nPlease run setup.command again to reinstall dependencies." with title "Palm Springs Paradise" buttons {"OK"} default button "OK" with icon stop' 2>/dev/null || true
    read -n 1 -s -r -p "Press any key to close..."
    exit 1
fi

echo "[update] Using: $(rojo --version 2>&1)"

# ----------------------------------------------------------
# 4. Rebuild place file
# ----------------------------------------------------------
echo "[update] Building place file..."
rojo build -o "$OUTPUT"

echo ""
echo "==========================================="
echo "  UPDATE COMPLETE!"
echo "==========================================="
echo ""
echo "  Place file: $OUTPUT"
echo ""
echo "  Open PalmSpringsParadise.rbxlx on your Desktop"
echo "  and press Play Solo in Roblox Studio."
echo ""
echo "==========================================="
echo ""

# ----------------------------------------------------------
# 5. Success dialog
# ----------------------------------------------------------
osascript -e 'display notification "Build updated on your Desktop!" with title "Palm Springs Paradise" subtitle "Update Complete ✅"' 2>/dev/null || true

osascript -e 'display dialog "Update complete! ✅\n\nPalmSpringsParadise.rbxlx has been rebuilt on your Desktop.\n\nOpen it in Roblox Studio and press Play Solo." with title "Palm Springs Paradise" buttons {"Open Desktop", "Done"} default button "Open Desktop"' 2>/dev/null && open "$HOME/Desktop" || true

read -n 1 -s -r -p "Press any key to close this window..."
