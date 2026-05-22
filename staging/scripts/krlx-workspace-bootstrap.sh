#!/usr/bin/env bash
# One-shot KRLX workstation bootstrap (run after cloning repo)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

echo "=== KarLux KRLX workspace bootstrap ==="

# Rokit
if ! command -v rokit &>/dev/null; then
  echo "Installing Rokit..."
  curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash
fi

if [[ -f staging/toolchain/rokit.toml ]] && [[ ! -f rokit.toml ]]; then
  echo "Linking rokit.toml from staging (temporary until merge)..."
  ln -sf staging/toolchain/rokit.toml rokit.toml
fi

if [[ -f staging/toolchain/wally.toml ]] && [[ ! -f wally.toml ]]; then
  ln -sf staging/toolchain/wally.toml wally.toml
fi

# First install may prompt to trust each tool — approve in terminal
rokit install || rokit install --no-trust-check 2>/dev/null || true
export PATH="$ROOT/.rokit/bin:$PATH"

wally install 2>/dev/null || echo "WARN: wally install skipped (check wally.toml)"

# Editor config
if [[ ! -d .vscode ]] && [[ -d staging/editor/.vscode ]]; then
  echo "Installing VS Code / Cursor workspace settings..."
  cp -r staging/editor/.vscode .vscode
fi

# Env template
if [[ ! -f .env ]] && [[ -f staging/env/.env.example ]]; then
  cp staging/env/.env.example .env
  echo "Created .env from template — fill Supabase keys"
fi

# Git hooks
if [[ -f staging/scripts/git/pre-commit ]]; then
  mkdir -p .git/hooks
  cp staging/scripts/git/pre-commit .git/hooks/pre-commit
  chmod +x .git/hooks/pre-commit
  echo "Installed git pre-commit hook"
fi

# Supabase CLI hint
if command -v supabase &>/dev/null; then
  echo "Supabase CLI: $(supabase --version)"
else
  echo "Optional: brew install supabase/tap/supabase"
fi

bash staging/scripts/toolchain/verify.sh

echo ""
echo "Next steps:"
echo "  1. Open folder in Cursor or VS Code (install recommended extensions)"
echo "  2. Fill .env with Supabase credentials (Manus can help)"
echo "  3. Terminal: rojo serve → Roblox Studio → Rojo Connect"
echo "  4. Read docs/karlux/05-unified-dev-stack.md"
