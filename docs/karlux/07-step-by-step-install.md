# Step-by-Step Install — KRLX / macOS (Karl & Eddie)

Do these **in order**. Each step has a **verify** line so you know it worked before moving on.

**Time:** ~20–30 minutes first time (mostly downloads).

---

## Before you start

| Requirement | Notes |
|-------------|--------|
| **macOS** on KRLX | Steps below use Homebrew; Linux is similar (see Step 1 alt) |
| **Git** | `git --version` |
| **Repo cloned** | e.g. `~/Desktop/Roblox/PalmSprings` |
| **Roblox Studio** | [create.roblox.com](https://create.roblox.com/) |
| **Cursor or VS Code** | Either is fine — same config |

---

## Step 1 — Homebrew (if missing)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"   # Apple Silicon
# OR: eval "$(/usr/local/bin/brew shellenv)"  # Intel
```

**Verify:**

```bash
brew --version
```

---

## Step 2 — Git + clone (if not done)

```bash
brew install git
mkdir -p ~/Desktop/Roblox
cd ~/Desktop/Roblox
git clone https://github.com/OBHitting3/Gemini-discovers-Diamonds.git PalmSprings
cd PalmSprings
git checkout cursor/karlux-foundation-292d   # or main after merge
```

**Verify:**

```bash
git status
ls src/server/init.server.lua
```

---

## Step 3 — Rokit (toolchain manager)

```bash
curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash
```

Add to your shell (put in `~/.zshrc`):

```bash
export PATH="$HOME/.rokit/bin:$PATH"
```

**Verify:**

```bash
rokit --version
```

---

## Step 4 — Install pinned CLI tools (Rojo, Wally, StyLua, Selene, Darklua)

```bash
cd ~/Desktop/Roblox/PalmSprings   # your repo path

# Link toolchain manifest (until promoted to repo root)
ln -sf staging/toolchain/rokit.toml rokit.toml
ln -sf staging/toolchain/wally.toml wally.toml

# Install tools (approve trust prompts when asked — once per tool)
rokit install
```

If `rokit install` errors on **Tarmac**, that is expected — Tarmac is optional (Step 8).

**Verify:**

```bash
export PATH="$HOME/.rokit/bin:$PATH"
rojo --version      # expect 7.4.x
wally --version     # expect 0.3.x
stylua --version
selene --version
darklua --version
```

Or run:

```bash
bash staging/scripts/toolchain/verify.sh
```

---

## Step 5 — Wally packages

```bash
cd ~/Desktop/Roblox/PalmSprings
wally install
```

(Zero packages is OK for now — manifest has no required deps yet.)

**Verify:**

```bash
ls Packages 2>/dev/null || echo "Packages empty — OK for prototype"
```

---

## Step 6 — Editor (Cursor + VS Code)

**Option A — automated:**

```bash
bash staging/scripts/krlx-workspace-bootstrap.sh
```

**Option B — manual:**

```bash
cp -r staging/editor/.vscode .vscode
cp staging/env/.env.example .env
cp staging/scripts/git/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

Open the folder in **Cursor** (or VS Code).

When prompted → **Install Recommended Extensions**:

- Luau LSP  
- Rojo  
- StyLua  
- Selene  

**Verify:** Command Palette → `Tasks: Run Task` → see **Rojo: Serve**.

---

## Step 7 — Roblox Studio + Rojo live sync

**Terminal 1** (leave running):

```bash
cd ~/Desktop/Roblox/PalmSprings
export PATH="$HOME/.rokit/bin:$PATH"
rojo serve
```

**Studio:**

1. Open Roblox Studio (any place or new baseplate).
2. Plugins → **Rojo** → **Connect** (default `localhost:34872`).
3. Your `src/` tree syncs into the place.

**Game Settings → Security:**

- Enable **Allow HTTP Requests** (needed later for Supabase live).

**Verify:** In Studio Explorer, see `ServerScriptService`, `ReplicatedStorage` content from repo. Press **Play Solo** — Output shows `PALM SPRINGS PARADISE — Server Starting`.

---

## Step 8 — Optional tools (do when needed)

### Supabase CLI (cold-path database)

```bash
brew install supabase/tap/supabase
supabase --version
```

Fill `.env` from `staging/env/.env.example` (never commit `.env`).

Link project (Karl/Manus):

```bash
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase db push    # after reviewing staging/supabase/migrations/
```

Roblox live secrets (Studio / Creator Dashboard): `SUPABASE_URL`, `SUPABASE_ANON_KEY`.

### Blender (art)

Install Blender 4.x from [blender.org](https://www.blender.org/).  
Read: `staging/blender/README.md`

### Tarmac (asset upload automation)

Not in Rokit index — use **Studio Import 3D** for now, or:

```bash
# Advanced: community tooling — or Studio Asset Manager
```

Record rbxassetid in `vendor-imports/_manifests/asset-index.yaml`.

### Remodel (headless publish)

Included from Rokit; only needed for CI publish scripts.

---

## Step 9 — Build place file (optional)

```bash
export PATH="$HOME/.rokit/bin:$PATH"
rojo build default.project.json -o ~/Desktop/PalmSpringsParadise.rbxlx
open ~/Desktop/PalmSpringsParadise.rbxlx
```

**Note:** If build errors on `ServerScriptService` class conflict, use **`rojo serve` + Studio** (Step 7) — that is the primary dev loop. Build fix can be a follow-up PR.

**macOS shortcut:** double-click `setup.command` or `update.command` in repo root (installs Rojo via aftman if Rokit not used).

---

## Step 10 — First Play Solo test

In Studio with Rojo connected:

```
/coins 5000
/claimplot 1
/buildhouse kaufmann
/status
/partcount
```

**Verify:** Chat commands work; HUD shows coins.

---

## Quick reference card

| Action | Command |
|--------|---------|
| Start sync | `rojo serve` |
| Format Lua | `stylua src/` |
| Lint | `selene src/` |
| Check tools | `bash staging/scripts/toolchain/verify.sh` |
| Full bootstrap | `bash staging/scripts/krlx-workspace-bootstrap.sh` |

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `rojo: command not found` | `export PATH="$HOME/.rokit/bin:$PATH"` in `~/.zshrc` |
| Rojo won’t connect | Firewall; ensure `rojo serve` running; correct port in plugin |
| Trust prompt loop | Run `rokit add rojo-rbx/rojo@7.4.4` once, approve |
| Supabase mock only | Normal in Play Solo without Secrets |
| Extensions missing | Reload window; install from `.vscode/extensions.json` |

---

## What we do **not** install in Step 1–7

- Manus / cloud agents (separate)  
- n8n webhooks (later)  
- Git LFS (run `git lfs install` when committing large FBX)  

---

**Next:** Read [05-unified-dev-stack.md](./05-unified-dev-stack.md) for daily workflow.
