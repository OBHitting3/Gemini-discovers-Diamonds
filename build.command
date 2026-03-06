#!/usr/bin/env bash
# ============================================================
#  Palm Springs Paradise — One-Click Build
#  Double-click this file on macOS to build the Roblox place.
#  The .rbxlx file will appear on your Desktop.
# ============================================================

set -e

# Move to the directory this script lives in (the repo root)
cd "$(dirname "$0")"

echo ""
echo "==========================================="
echo "  Palm Springs Paradise — Building...      "
echo "==========================================="
echo ""

# ----------------------------------------------------------
# 1. Check for Rojo and install if missing
# ----------------------------------------------------------
install_rojo() {
    echo "[build] Rojo not found. Attempting to install..."

    # Try aftman first (Roblox community tool manager)
    if command -v aftman &> /dev/null; then
        echo "[build] Installing Rojo via aftman..."
        aftman add rojo-rbx/rojo@7
        aftman install
        if command -v rojo &> /dev/null; then
            echo "[build] Rojo installed via aftman."
            return 0
        fi
    fi

    # Try foreman (older Roblox tool manager)
    if command -v foreman &> /dev/null; then
        echo "[build] Installing Rojo via foreman..."
        foreman install
        if command -v rojo &> /dev/null; then
            echo "[build] Rojo installed via foreman."
            return 0
        fi
    fi

    # Try cargo (Rust package manager)
    if command -v cargo &> /dev/null; then
        echo "[build] Installing Rojo via cargo (this may take a few minutes)..."
        cargo install rojo
        if command -v rojo &> /dev/null; then
            echo "[build] Rojo installed via cargo."
            return 0
        fi
    fi

    # Try Homebrew
    if command -v brew &> /dev/null; then
        echo "[build] Attempting Rojo install via Homebrew..."
        brew install rojo || true
        if command -v rojo &> /dev/null; then
            echo "[build] Rojo installed via Homebrew."
            return 0
        fi
    fi

    # Nothing worked
    echo ""
    echo "ERROR: Could not install Rojo automatically."
    echo ""
    echo "Please install Rojo manually:"
    echo "  Option A: Install aftman (https://github.com/LPGhatguy/aftman) then run this script again"
    echo "  Option B: Install Rust (https://rustup.rs) then run: cargo install rojo"
    echo "  Option C: Download from https://github.com/rojo-rbx/rojo/releases"
    echo ""
    read -n 1 -s -r -p "Press any key to close..."
    exit 1
}

# Check PATH additions for aftman/cargo
export PATH="$HOME/.aftman/bin:$HOME/.cargo/bin:$HOME/.foreman/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

if ! command -v rojo &> /dev/null; then
    install_rojo
fi

ROJO_VERSION=$(rojo --version 2>&1 || echo "unknown")
echo "[build] Using: $ROJO_VERSION"

# ----------------------------------------------------------
# 2. Build the .rbxlx place file to the Desktop
# ----------------------------------------------------------
OUTPUT="$HOME/Desktop/PalmSpringsParadise.rbxlx"

echo "[build] Building project..."
rojo build -o "$OUTPUT"

echo ""
echo "==========================================="
echo "  BUILD SUCCESSFUL!"
echo "==========================================="
echo ""
echo "  Your place file is ready:"
echo "  $OUTPUT"
echo ""
echo "  Next steps:"
echo "  1. Open PalmSpringsParadise.rbxlx on your Desktop"
echo "     (double-click it, or open via Roblox Studio)"
echo "  2. Press Play Solo to test"
echo "  3. Type /help in chat for test commands"
echo ""
echo "==========================================="
echo ""

# ----------------------------------------------------------
# 3. Show a macOS notification + dialog
# ----------------------------------------------------------
osascript -e 'display notification "PalmSpringsParadise.rbxlx is on your Desktop. Open it in Roblox Studio!" with title "Palm Springs Paradise" subtitle "Build Complete ✅"' 2>/dev/null || true

osascript -e 'display dialog "Build complete! ✅\n\nPalmSpringsParadise.rbxlx has been saved to your Desktop.\n\nOpen it in Roblox Studio and press Play Solo to test.\nType /help in chat for test commands." with title "Palm Springs Paradise" buttons {"Open Desktop", "Done"} default button "Open Desktop"' 2>/dev/null && open "$HOME/Desktop" || true

read -n 1 -s -r -p "Press any key to close this window..."
