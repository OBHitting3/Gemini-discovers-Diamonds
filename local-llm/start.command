#!/usr/bin/env bash
# Start the local LLM + chat UI. Double-click to launch.
set -euo pipefail
cd "$(dirname "$0")"

# Make sure brew is on PATH (Apple Silicon / Intel)
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# 1. Ollama
if ! pgrep -x ollama >/dev/null 2>&1; then
  echo "Starting Ollama..."
  brew services start ollama >/dev/null 2>&1 || nohup ollama serve >/dev/null 2>&1 &
  sleep 2
fi

# 2. Open WebUI on :8080
if lsof -i :8080 >/dev/null 2>&1; then
  echo "Open WebUI already running."
else
  echo "Starting Open WebUI on http://localhost:8080 ..."
  nohup open-webui serve > "$(dirname "$0")/open-webui.log" 2>&1 &
  # Wait for it to come up (max 30s)
  for i in {1..30}; do
    if lsof -i :8080 >/dev/null 2>&1; then break; fi
    sleep 1
  done
fi

open "http://localhost:8080"
echo
echo "Done. Your local LLM is in your browser."
echo "First time only: pick a username/password — it's local-only, never leaves your Mac."
echo
read -n 1 -s -r -p "Press any key to close this window..."
echo
