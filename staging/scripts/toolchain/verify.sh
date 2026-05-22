#!/usr/bin/env bash
# Verify Roblox toolchain on KRLX / dev machine
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$ROOT"

export PATH="$ROOT/.rokit/bin:$HOME/.aftman/bin:$HOME/.cargo/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

echo "=== Palm Springs Paradise — toolchain verify ==="

check() {
  if command -v "$1" &>/dev/null; then
    echo "  OK  $1 — $("$1" --version 2>&1 | head -1 || "$1" -V 2>&1 | head -1 || echo "installed")"
  else
    echo "  MISS $1"
    MISSING=1
  fi
}

MISSING=0
check rojo
check wally
check stylua
check darklua
check remodel
check tarmac
check git

if [[ -f "$ROOT/rokit.toml" ]] || [[ -f "$ROOT/staging/toolchain/rokit.toml" ]]; then
  echo "  OK  rokit.toml present"
else
  echo "  WARN rokit.toml not at repo root (still in staging?)"
fi

if [[ -d "$ROOT/Packages" ]]; then
  echo "  OK  Packages/ (wally install done)"
else
  echo "  INFO Packages/ missing — run: wally install"
fi

if [[ -n "${MISSING:-}" && "$MISSING" == "1" ]]; then
  echo ""
  echo "Install: rokit install  (from repo root with rokit.toml)"
  exit 1
fi

echo "=== All required tools found ==="
