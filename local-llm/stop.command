#!/usr/bin/env bash
# Stop the local LLM + chat UI. Double-click to shut down.
set -euo pipefail

if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

pkill -f "open-webui serve" 2>/dev/null || true
brew services stop ollama 2>/dev/null || pkill -x ollama 2>/dev/null || true

echo "Stopped."
echo
read -n 1 -s -r -p "Press any key to close this window..."
echo
