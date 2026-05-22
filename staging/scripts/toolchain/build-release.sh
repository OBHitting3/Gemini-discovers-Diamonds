#!/usr/bin/env bash
# Release build: format check → darklua (release) → rojo build
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$ROOT"

export PATH="$ROOT/.rokit/bin:$HOME/.aftman/bin:$PATH"

OUT="${PSP_BUILD_OUTPUT:-$HOME/Desktop/PalmSpringsParadise.rbxlx}"
STYLUA_CFG="${PSP_STYLUA_CONFIG:-staging/toolchain/stylua.toml}"
DARKLUA_CFG="${PSP_DARKLUA_CONFIG:-staging/toolchain/darklua.json}"
ROJO_PROJECT="${PSP_ROJO_PROJECT:-default.project.json}"

echo "[build-release] Root: $ROOT"
echo "[build-release] Output: $OUT"

if command -v stylua &>/dev/null; then
  echo "[build-release] StyLua check..."
  stylua --check --config-path "$STYLUA_CFG" src/
else
  echo "[build-release] WARN stylua not installed — skipping format check"
fi

if command -v selene &>/dev/null; then
  echo "[build-release] Selene lint..."
  selene --config staging/toolchain/selene.toml src/
else
  echo "[build-release] WARN selene not installed — skipping lint"
fi

BUILD_SRC="src"
if command -v darklua &>/dev/null; then
  echo "[build-release] Darklua process (release rules)..."
  rm -rf .darklua/release-build
  mkdir -p .darklua/release-build
  darklua process "$DARKLUA_CFG" src/ .darklua/release-build/
  BUILD_SRC=".darklua/release-build"
  # Temporary rojo override could point here — for now document manual merge
  echo "[build-release] NOTE: darklua output in .darklua/release-build — wire rojo path when ready"
fi

echo "[build-release] Rojo build..."
rojo build "$ROJO_PROJECT" -o "$OUT"
echo "[build-release] Done: $OUT"
