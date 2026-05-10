#!/usr/bin/env bash
# One-time setup. Double-click this from Finder.
# Installs: Homebrew (if missing), Ollama, Llama 3.2 model, Python, Open WebUI.
set -euo pipefail
cd "$(dirname "$0")"

say() { printf "\n==> %s\n" "$1"; }

say "Local LLM setup starting"

# 1. Homebrew
if ! command -v brew >/dev/null 2>&1; then
  say "Installing Homebrew (you may be asked for your password)"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# 2. Ollama (the LLM runner)
if ! command -v ollama >/dev/null 2>&1; then
  say "Installing Ollama"
  brew install ollama
fi

# 3. Start Ollama as a background service
if ! pgrep -x ollama >/dev/null 2>&1; then
  say "Starting Ollama"
  brew services start ollama >/dev/null 2>&1 || nohup ollama serve >/dev/null 2>&1 &
  sleep 3
fi

# 4. Pull the model (~2 GB, one time, runs on basically any modern Mac)
say "Pulling model llama3.2:3b (one-time download, ~2 GB)"
ollama pull llama3.2:3b

# 5. Python (Open WebUI needs 3.11+)
if ! command -v python3.11 >/dev/null 2>&1 && ! python3 -c 'import sys; sys.exit(0 if sys.version_info>=(3,11) else 1)' 2>/dev/null; then
  say "Installing Python 3.11"
  brew install python@3.11
fi

# 6. pipx (clean way to install Open WebUI)
if ! command -v pipx >/dev/null 2>&1; then
  say "Installing pipx"
  brew install pipx
  pipx ensurepath >/dev/null 2>&1 || true
fi

# 7. Open WebUI (the chat interface with persistent memory)
if ! command -v open-webui >/dev/null 2>&1; then
  say "Installing Open WebUI (this takes a few minutes)"
  pipx install open-webui
fi

say "Setup complete."
echo
echo "Next: double-click start.command"
echo
read -n 1 -s -r -p "Press any key to close this window..."
echo
