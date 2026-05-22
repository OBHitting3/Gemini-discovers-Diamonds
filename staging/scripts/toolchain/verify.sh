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
check git
check selene

# Optional CLI tools (do not fail verify)
if command -v remodel &>/dev/null && remodel --version &>/dev/null 2>&1; then
  echo "  OK  remodel — $(remodel --version 2>&1 | head -1)"
else
  echo "  OPT remodel — optional (headless publish)"
fi
if command -v tarmac &>/dev/null; then
  echo "  OK  tarmac — installed"
else
  echo "  OPT tarmac — use Studio Import 3D or asset-index.yaml"
fi

echo ""
echo "--- Recommended (install if missing) ---"
OPTIONAL=0
if command -v supabase &>/dev/null; then
  echo "  OK  supabase — $(supabase --version 2>&1 | head -1)"
else
  echo "  OPT supabase — brew install supabase/tap/supabase"
  OPTIONAL=1
fi
if command -v blender &>/dev/null; then
  echo "  OK  blender — $(blender --version 2>&1 | head -1)"
else
  echo "  OPT blender — art pipeline (local GUI)"
  OPTIONAL=1
fi

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

if [[ -d "$ROOT/.vscode" ]] || [[ -d "$ROOT/staging/editor/.vscode" ]]; then
  echo "  OK  VS Code / Cursor workspace config present"
else
  echo "  INFO run: bash staging/scripts/krlx-workspace-bootstrap.sh"
fi

if [[ "${MISSING:-}" == "1" ]]; then
  echo ""
  echo "Install: ln -sf staging/toolchain/rokit.toml rokit.toml && rokit install"
  echo "See: docs/karlux/07-step-by-step-install.md"
  exit 1
fi

echo "=== All required tools found ==="
