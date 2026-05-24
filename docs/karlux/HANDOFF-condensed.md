# Palm Springs Paradise — Thread Handoff (condensed)

**Entity:** KarLux LLC / Iron Forge Studios  
**Repo:** `https://github.com/OBHitting3/Gemini-discovers-Diamonds`  
**Branch:** `cursor/karlux-foundation-292d` · **PR:** #24 (draft)  
**Rule:** KarLux **10-80-10** — staged work only; merge `staging/` → `src/` after Karl/Eddie approval.

---

## What this project is

- **Roblox** life-sim: Palm Springs Paradise (MCM desert town)
- **Rojo v7** + **Luau** in `src/` (~40 modules): plots, garden, fashion, shops, DataStore + Supabase cold path
- **Locked art:** `.cursor/rules/roblox-mcm.md` (bright blue sky, single-story MCM, &lt;5k parts)

---

## User environment

- **OS:** Windows (not Mac — ignore Homebrew / `setup.command`)
- **IDE:** **Cursor** (PowerShell terminal) + **Roblox Studio**
- Also use: **VS Code** (same `.vscode/`), **Blender**, **Supabase**, **Git**

---

## Toolchain (pinned in `staging/toolchain/rokit.toml`)

| Tool | Role |
|------|------|
| Rokit | CLI version manager |
| Rojo 7.4 | File sync → Studio |
| Wally | Luau packages (`karlux/palm-springs-paradise`) |
| StyLua / Selene | Format + lint |
| Darklua | Release transform (optional) |
| Tarmac | **Skipped** in Rokit (use Studio Import 3D) |
| Remodel | Optional publish scripts |
| Supabase CLI | Migrations in `staging/supabase/` |

**Symlinks at root (Windows may copy instead):** `rokit.toml`, `wally.toml` → `staging/toolchain/`

---

## Windows install (Cursor only — quick)

1. **Cursor** → Open Folder → clone path e.g. `Documents\Roblox\PalmSprings`
2. **Cursor PowerShell:** `irm https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | iex`
3. Add `%USERPROFILE%\.rokit\bin` to PATH; restart Cursor
4. `Copy-Item staging\toolchain\rokit.toml . -Force` (+ wally.toml)
5. `rokit install` → `wally install`
6. `powershell -ExecutionPolicy Bypass -File staging\scripts\krlx-workspace-bootstrap.ps1`
7. **Cursor:** Install recommended extensions → **Task: Rojo: Serve**
8. **Roblox Studio** → Rojo Connect → Allow HTTP → Play Solo → `/coins 5000` `/status`

**Full doc:** `docs/karlux/07-step-by-step-install-windows.md`

---

## Repo layout (high signal)

```
src/                    # PRODUCTION Luau (Rojo) — do not bulk-edit without approval
staging/                # GATED: CoreLoop, AssetRegistry, toolchain, patches
vendor-imports/         # Raw assets (_incoming, _manifests/asset-index.yaml)
docs/karlux/            # Architecture + install docs
.cursor/rules/          # roblox-mcm.md + karlux-unified-stack.mdc
.vscode/                # Tasks: Rojo Serve, stylua, selene, verify
```

---

## Day-phase vertical slice (**merged to `src/`** — May 2026)

| Module | Path |
|--------|------|
| `DayPhaseConfig` | `src/shared/DayPhaseConfig.lua` |
| `CoreLoopService` | `src/server/Services/CoreLoopService.lua` |
| `DayPhaseController` | `src/client/Controllers/DayPhaseController.lua` |
| `AssetRegistry` | `src/shared/AssetRegistry.lua` (needs Manus manifest IDs) |

**Do not re-merge** from `staging/src/` (duplicate copies remain for history).  
**Full handoff:** [HANDOFF-FULL-AGENT-UPLOAD.md](./HANDOFF-FULL-AGENT-UPLOAD.md)

---

## Agent lanes

| Agent | Owns |
|-------|------|
| **Cursor** | `src/`, `staging/`, Luau, Rojo, Wally, PRs, `.vscode` |
| **Manus** | `vendor-imports/`, uploads, Supabase `db push`, secrets, n8n |
| **SuperbulletAI** | Daily checklists, `karl-start-day.ps1`, dispatch Manus/Cursor |
| **Karl/Eddie** | Intent, Studio publish, merge PRs |

**Unified automation:** [08-karl-automation-playbook.md](./08-karl-automation-playbook.md) · [AGENTS.md](../../AGENTS.md) · `staging/automation/agents.yaml`

**Karl (no terminal):** double-click **`Start-PalmSprings.cmd`** → Studio Connect → Cursor prompts in `docs/karlux/karl-prompt-menu.md`

**Eddie (audit):** `powershell -ExecutionPolicy Bypass -File staging\scripts\karl-start-day.ps1`

---

## Doc index (`docs/karlux/`)

| File | Topic |
|------|--------|
| `01-asset-taxonomy-tree.md` | Folder hierarchy for assets |
| `02-agent-lane-discipline.md` | Cursor vs Manus |
| `03-vertical-slice-merge-guide.md` | Promote day-phase code |
| `04-roblox-toolchain.md` | Rokit/Wally/etc. |
| `05-unified-dev-stack.md` | Studio/Blender/Supabase map |
| `06-friction-reduction-additions.md` | Selene, LFS, CI, pre-commit |
| `07-step-by-step-install-windows.md` | **Windows start here** |
| `08-karl-automation-playbook.md` | Karl + all agents unified automation |
| `HANDOFF-condensed.md` | This file (short) |
| `HANDOFF-FULL-AGENT-UPLOAD.md` | **Upload to new agent** (complete) |
| `AGENTS.md` (repo root) | Agent router for Cursor / cloud |

---

## Known issues / notes

- `default.project.json` nests `src/server` under `ServerScriptService.Server` (and client under `Client`) so Rojo 7 does not class-conflict on `init.server.lua`
- Supabase **mock** in Play Solo without Roblox Secrets
- Cloud agent cannot open local Cursor — user runs commands on Windows machine
- `.env` never commit; copy from `staging/env/.env.example`

---

## Test commands (Studio chat)

```
/coins 5000
/claimplot 1
/buildhouse kaufmann
/status
/partcount
```

---

## Next actions for new thread

**Karl:** Upload [HANDOFF-FULL-AGENT-UPLOAD.md](./HANDOFF-FULL-AGENT-UPLOAD.md) to the new agent. Use `Start-PalmSprings.cmd` + Studio Connect — no PowerShell.

**Eddie:** `karl-start-day.ps1` or full commands in HANDOFF-FULL §3.3.

1. Confirm toolchain (`verify.ps1` or `karl-start-day.ps1`)
2. Review / merge **PR #24** when Karl/Eddie approve
3. **Manus:** `asset-index.yaml` + Supabase live + Roblox Secrets
4. **Do not** re-wire day-phase (already in `src/`); avoid duplicate `staging/src/` wiring
