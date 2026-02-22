#!/usr/bin/env bash
# ================================================================
#  Palm Springs Paradise — FULL SETUP (Zero to Playable)
#  Double-click this file on macOS. No terminal knowledge needed.
#
#  What this does:
#   1. Installs Homebrew (if missing)
#   2. Installs git (if missing)
#   3. Clones (or updates) the repo to ~/Desktop/Roblox/PalmSprings
#   4. Checks out the correct branch
#   5. Installs Rojo (if missing)
#   6. Builds PalmSpringsParadise.rbxlx to your Desktop
#   7. Shows a success dialog
# ================================================================

set -e

echo ""
echo "==========================================="
echo "  Palm Springs Paradise — Full Setup       "
echo "  Sit back — this is fully automatic!      "
echo "==========================================="
echo ""

# ----------------------------------------------------------
# Paths
# ----------------------------------------------------------
REPO_URL="https://github.com/OBHitting3/Gemini-discovers-Diamonds.git"
BRANCH="cursor/art-direction-prototype-6c9e"
PROJECT_DIR="$HOME/Desktop/Roblox/PalmSprings"
OUTPUT="$HOME/Desktop/PalmSpringsParadise.rbxlx"

export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.aftman/bin:$HOME/.cargo/bin:$HOME/.foreman/bin:$PATH"

# ----------------------------------------------------------
# 1. Install Homebrew if missing
# ----------------------------------------------------------
if ! command -v brew &> /dev/null; then
    echo "[setup] Homebrew not found. Installing Homebrew..."
    echo "[setup] (You may be asked for your Mac password once)"
    echo ""
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon and Intel Macs
    if [ -f /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -f /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
    echo "[setup] Homebrew installed."
else
    echo "[setup] Homebrew found: $(brew --version | head -1)"
fi

# ----------------------------------------------------------
# 2. Install git if missing
# ----------------------------------------------------------
if ! command -v git &> /dev/null; then
    echo "[setup] git not found. Installing via Homebrew..."
    brew install git
    echo "[setup] git installed."
else
    echo "[setup] git found: $(git --version)"
fi

# ----------------------------------------------------------
# 3. Clone or update the repo
# ----------------------------------------------------------
mkdir -p "$HOME/Desktop/Roblox"

if [ -d "$PROJECT_DIR/.git" ]; then
    echo "[setup] Project already exists. Pulling latest changes..."
    cd "$PROJECT_DIR"
    git fetch origin
    git checkout "$BRANCH" 2>/dev/null || git checkout -b "$BRANCH" "origin/$BRANCH"
    git pull origin "$BRANCH"
    echo "[setup] Updated to latest."
else
    echo "[setup] Cloning repository..."
    git clone "$REPO_URL" "$PROJECT_DIR"
    cd "$PROJECT_DIR"
    git checkout "$BRANCH" 2>/dev/null || git checkout -b "$BRANCH" "origin/$BRANCH"
    echo "[setup] Repository cloned."
fi

echo "[setup] Project location: $PROJECT_DIR"

# ----------------------------------------------------------
# 4. Install Rojo if missing
# ----------------------------------------------------------
install_rojo() {
    echo "[setup] Rojo not found. Installing..."

    # Try aftman first
    if command -v aftman &> /dev/null; then
        echo "[setup] Installing Rojo via aftman..."
        aftman add rojo-rbx/rojo@7 2>/dev/null || true
        aftman install 2>/dev/null || true
        if command -v rojo &> /dev/null; then
            echo "[setup] Rojo installed via aftman."
            return 0
        fi
    fi

    # Try foreman
    if command -v foreman &> /dev/null; then
        echo "[setup] Installing Rojo via foreman..."
        foreman install 2>/dev/null || true
        if command -v rojo &> /dev/null; then
            echo "[setup] Rojo installed via foreman."
            return 0
        fi
    fi

    # Install Rust + cargo if needed, then install Rojo
    if ! command -v cargo &> /dev/null; then
        echo "[setup] Installing Rust toolchain (needed for Rojo)..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
        export PATH="$HOME/.cargo/bin:$PATH"
    fi

    if command -v cargo &> /dev/null; then
        echo "[setup] Installing Rojo via cargo (this may take 2-3 minutes)..."
        cargo install rojo
        if command -v rojo &> /dev/null; then
            echo "[setup] Rojo installed via cargo."
            return 0
        fi
    fi

    echo ""
    echo "ERROR: Could not install Rojo automatically."
    echo "Please visit https://rojo.space/ for manual installation."
    osascript -e 'display dialog "Could not install Rojo automatically.\n\nPlease visit https://rojo.space/ for manual installation instructions." with title "Palm Springs Paradise" buttons {"OK"} default button "OK" with icon stop' 2>/dev/null || true
    read -n 1 -s -r -p "Press any key to close..."
    exit 1
}

if ! command -v rojo &> /dev/null; then
    install_rojo
fi

echo "[setup] Using: $(rojo --version 2>&1)"

# ----------------------------------------------------------
# 5. Build the .rbxlx place file
# ----------------------------------------------------------
echo "[setup] Building place file..."
cd "$PROJECT_DIR"
rojo build -o "$OUTPUT"

echo ""
echo "==========================================="
echo "  SETUP COMPLETE!"
echo "==========================================="
echo ""
echo "  Place file: $OUTPUT"
echo ""
echo "  To play:"
echo "  1. Open PalmSpringsParadise.rbxlx on your Desktop"
echo "  2. Press Play Solo in Roblox Studio"
echo "  3. Type /help in chat for test commands"
echo ""
echo "  For future updates, double-click update.command"
echo "  in ~/Desktop/Roblox/PalmSprings"
echo ""
echo "==========================================="
echo ""

# ----------------------------------------------------------
# 6. Success dialog + notification
# ----------------------------------------------------------
osascript -e 'display notification "PalmSpringsParadise.rbxlx is on your Desktop!" with title "Palm Springs Paradise" subtitle "Setup Complete ✅"' 2>/dev/null || true

osascript -e 'display dialog "Setup complete! ✅\n\nPalmSpringsParadise.rbxlx is on your Desktop.\n\nOpen it in Roblox Studio and press Play Solo.\nType /help in chat for test commands.\n\nFor future updates, double-click update.command\nin Desktop → Roblox → PalmSprings." with title "Palm Springs Paradise" buttons {"Open Desktop", "Done"} default button "Open Desktop"' 2>/dev/null && open "$HOME/Desktop" || true

read -n 1 -s -r -p "Press any key to close this window..."
