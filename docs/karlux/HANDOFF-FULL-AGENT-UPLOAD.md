# Palm Springs Paradise — Full Agent Handoff (Upload This Document)

**Purpose:** Give the next Cursor / Cloud / Manus / SuperbulletAI agent complete context without reading the prior thread.  
**Last verified:** 2026-05-23 · branch `cursor/karlux-foundation-292d` · HEAD `ecda904`  
**Repo:** https://github.com/OBHitting3/Gemini-discovers-Diamonds  
**Draft PR:** #24 (KarLux foundation + Windows toolchain + day-phase + prompt-to-game)

---

## 1. Executive summary

| Item | Value |
|------|--------|
| **Game** | Palm Springs Paradise — Roblox life-sim (MCM desert town) |
| **Entity** | KarLux LLC / Iron Forge Studios |
| **Governance** | **10-80-10** — large changes in `staging/` until Karl/Eddie approve merge to `src/` |
| **Stack** | Rojo 7.4.4, Luau, Wally, StyLua, Selene; Supabase cold path (mock in Studio without secrets); DataStore hot path |
| **Primary user (Karl)** | Windows, **non-technical** — does **not** use PowerShell; uses double-click launcher + Cursor chat |
| **Technical user (Eddie)** | PowerShell scripts, git, audits, merge PRs |
| **Working branch** | `cursor/karlux-foundation-292d` |
| **Last known good state** | Toolchain READY, `rojo serve` on port 34872, Play Solo builds world (~362+ parts), `/help` and `/status` work |

**What was done in the prior session (do not redo blindly):**

- Windows toolchain fixed (Tarmac removed from Rokit, PS5-safe scripts, bootstrap copies toolchain from staging)
- Rojo project fixed (nested `Server` / `Client` under ServerScriptService / StarterPlayerScripts)
- `Types.lua` syntax fix (unblocked server bootstrap)
- **Day-phase vertical slice merged into `src/`** (CoreLoop, HUD, garden/fashion gates)
- **Karl prompt-to-game** (`Start-PalmSprings.cmd`, prompt menu, agent rules)

---

## 2. People and agent lanes

### 2.1 Humans

| Person | Role | How they work |
|--------|------|----------------|
| **Karl** | Creative direction, Studio playtest, merge approval | Double-click `Start-PalmSprings.cmd`, Studio Rojo Connect, Cursor chat only |
| **Eddie** | Technical ops, git, audits, PR review | `staging/scripts/karl-start-day.ps1`, `audit-windows.ps1`, PowerShell |

### 2.2 Agent responsibilities

| Agent | Owns | Must NOT |
|-------|------|----------|
| **Cursor / Cloud** | `src/`, `staging/`, Luau, `default.project.json`, docs, PRs | Ask Karl for terminal; bulk Roblox upload without manifest; secrets in git |
| **Manus** | `vendor-imports/`, `asset-index.yaml`, Supabase migrations + `db push`, Roblox Secrets, n8n | Edit `src/**/*.lua`; change economy/sky in GameConfig |
| **SuperbulletAI** | Checklists, dispatch, reminders (orchestration only — **not in repo as product yet**) | Edit Luau; merge without Karl |
| **Karl/Eddie** | Intent, Experience Settings, publish, approve `staging/` → `src/` | — |

**Machine-readable registry:** `staging/automation/agents.yaml`  
**Human router:** `AGENTS.md` (repo root)  
**Lane discipline:** `docs/karlux/02-agent-lane-discipline.md`  
**Automation map:** `docs/karlux/08-karl-automation-playbook.md`

### 2.3 Handoff files between agents

| File | Producer | Consumer |
|------|----------|----------|
| `vendor-imports/_manifests/asset-index.yaml` | Manus | Cursor → `src/shared/AssetRegistry.lua` |
| `staging/supabase/migrations/` | Manus | Live Supabase |
| `staging/env/.env` | Manus (local only, never commit) | Supabase CLI |
| Roblox Secrets `SUPABASE_URL`, `SUPABASE_ANON_KEY` | Manus / Karl | `SupabaseClient.fromSecrets()` |

**Current manifest state:** `asset-index.yaml` exists but `assets: {}` (empty — placeholders only).

---

## 3. Karl's machine (Windows)

### 3.1 Paths

| Path | Purpose |
|------|---------|
| `C:\Users\karlu\Documents\Roblox\PalmSprings\` | Git clone (repo root) |
| `C:\Users\karlu\Documents\Roblox\PalmSpringsDev.rbxlx` | Built place file (Desktop path failed — no Desktop folder) |
| `%USERPROFILE%\.rokit\bin\` | Rokit tools (Rojo 7.4.4, Wally, StyLua, Selene, …) |
| `C:\Tools\rojo\rojo.exe` | **Legacy Rojo 7.6.1** — must NOT win PATH over Rokit |

### 3.2 Karl session (no PowerShell)

1. Double-click **`Start-PalmSprings.cmd`** (repo root) — leaves `rojo serve` running  
2. Roblox Studio → open place → **Plugins → Rojo → Connect**  
3. **Play Solo** — test chat: `/help`, `/coins 5000`, `/status`  
4. **Cursor chat** — ideas from `docs/karlux/karl-prompt-menu.md`

**Agent rule file:** `.cursor/rules/karl-prompt-builder.mdc` (always apply — do not ask Karl for terminal)

### 3.3 Eddie session (PowerShell)

```powershell
cd C:\Users\karlu\Documents\Roblox\PalmSprings
$env:Path = "$env:USERPROFILE\.rokit\bin;" + $env:Path
git checkout cursor/karlux-foundation-292d
git pull
Copy-Item staging\toolchain\rokit.toml . -Force
Copy-Item staging\toolchain\wally.toml . -Force
rokit install
wally install
powershell -ExecutionPolicy Bypass -File staging\scripts\karl-start-day.ps1
```

After `git pull`, **always** refresh root `rokit.toml` / `wally.toml` from `staging/toolchain/` (bootstrap also does this).

### 3.4 Permanent PATH fix (recommended, not done)

Move `%USERPROFILE%\.rokit\bin` **above** `C:\Tools\rojo` in Windows **User** environment variables so Karl never gets wrong Rojo version.

---

## 4. Toolchain

### 4.1 Pinned versions (`staging/toolchain/rokit.toml`)

| Tool | Version | Notes |
|------|---------|--------|
| Rojo | 7.4.4 | **Required** for this `default.project.json` |
| Wally | 0.3.2 | Packages under `Packages/` |
| StyLua | 2.0.2 | Format |
| Selene | 0.28.0 | Lint |
| Darklua | 0.13.0 | Release transform (optional) |
| Remodel | 0.11.0 | Optional publish |
| **Tarmac** | **Omitted** | `Roblox/Tarmac@1.0.0` had no Rokit release; blocked `rokit install` |

Root copies: `rokit.toml`, `wally.toml` (symlink or copy from staging).

### 4.3 Scripts

| Script | User |
|--------|------|
| `Start-PalmSprings.cmd` | Karl — starts `rojo serve` |
| `staging/scripts/karl-start-day.ps1` | Eddie — full morning checklist |
| `staging/scripts/krlx-workspace-bootstrap.ps1` | Eddie — links/copies toolchain |
| `staging/scripts/toolchain/verify.ps1` | Eddie — toolchain smoke test |
| `staging/scripts/toolchain/audit-windows.ps1` | Eddie — install audit |

**PowerShell 5 rule:** No UTF-8 em dashes (`—`) in `.ps1` files — use ASCII `-` only.

---

## 5. Rojo and Studio sync

### 5.1 `default.project.json` (critical)

Rojo 7 cannot map `src/server` directly onto `ServerScriptService` when `init.server.lua` exists. Structure:

```
ServerScriptService.Server  →  src/server
StarterPlayer.StarterPlayerScripts.Client  →  src/client
ReplicatedStorage  →  src/shared
StarterGui  →  src/gui
```

**Studio Explorer when connected:** `ServerScriptService.Server`, not scripts at root of ServerScriptService.

### 5.2 Serve and connect

- One `rojo serve` only — port **34872** default  
- Error **10048** = second instance; kill other terminal or reuse existing window  
- Cloud agents **cannot** run Studio on Karl's PC — push code; Karl Connects in Studio

### 5.3 Studio settings (Karl/Eddie)

After **File → Save to Roblox** (or publish once):

- **File → Experience Settings** (not legacy “Game Settings”)
- Enable **Allow HTTP Requests**
- Enable **Enable Studio Access to API Services** (DataStore in Play Solo)

Without API access: DataStore warnings in Output (expected).

### 5.4 Supabase in Studio

Without Roblox Secrets: **Supabase MOCK** — expected. Live path needs Manus + secrets.

---

## 6. Production code (`src/`) — current state

### 6.1 Layout (high signal)

```
src/
  server/           init.server.lua, Services/, Commands/
  client/           init.client.lua, Controllers/
  shared/           GameConfig, Types, DayPhaseConfig, AssetRegistry, …
  gui/
```

~40 Luau modules; MCM art lock: `.cursor/rules/roblox-mcm.md`

### 6.2 Day-phase system (**merged to src/** — NOT staging-only)

| Module | Role |
|--------|------|
| `src/shared/DayPhaseConfig.lua` | Morning 6–11, Afternoon 11–17, Evening 17–22 (server local hour) |
| `src/server/Services/CoreLoopService.lua` | Phase loop, garden multiplier, `DayPhaseUpdate` remote |
| `src/client/Controllers/DayPhaseController.lua` | HUD chip, listens to remote |
| `src/shared/AssetRegistry.lua` | slug → asset IDs (needs Manus manifest) |

**Gameplay hooks:**

- `GardenService` — growth multiplier; morning **1.25×** via CoreLoop  
- `FashionService` — auto events **Evening only**  
- Client **N** key — night toggle **Evening only** (`DayPhaseController:isNightAllowed()`)  
- `GameConfig.Remotes.Events` includes `"DayPhaseUpdate"`  
- `/status` shows current phase  

**Warning:** `staging/src/` still contains **duplicate** copies of day-phase files. Do **not** wire both — `src/` is canonical. Staging copies are historical; avoid double `require` paths.

### 6.3 Critical bug already fixed

**File:** `src/shared/Types.lua` line ~42  

**Was:** invalid `Types.DefaultPlayerData: PlayerData = {`  
**Now:** table literal + `} :: PlayerData`  

This blocked `PersistenceService` and entire server bootstrap (empty world).

### 6.4 Test chat commands

```
/help
/coins 5000
/status          ← includes day phase
/claimplot 1
/buildhouse kaufmann
/partcount
```

---

## 7. Staging vs production

| Area | Path | Status |
|------|------|--------|
| Production Luau | `src/` | Day-phase **live** here |
| Gated experiments | `staging/src/` | Duplicates — do not re-merge day-phase |
| Toolchain | `staging/toolchain/` | Source of truth for `rokit.toml` |
| Supabase | `staging/supabase/migrations/` | Pending live `db push` (Manus) |
| CI | `.github/workflows/palm-springs-pr-checks.yml` | StyLua, Selene, Rojo build on PRs |

**Merge guide (historical):** `docs/karlux/03-vertical-slice-merge-guide.md` — day-phase step **already done**.

---

## 8. Errors encountered and fixes (troubleshooting)

| Symptom | Cause | Fix |
|---------|--------|-----|
| `git` in `C:\Windows\system32` | Wrong cwd | `cd` to `Documents\Roblox\PalmSprings` |
| `rokit install` fails / no wally | Tarmac in old `rokit.toml` | Use staging copy without Tarmac; `Copy-Item` after pull |
| bootstrap.ps1 parse error | Em dash `—` in strings | ASCII only in `.ps1` |
| Rojo “class conflict” ServerScriptService | Flat map of `src/server` | Nested `Server` / `Client` in `default.project.json` |
| Empty ServerScriptService in Studio | Not connected / wrong place | Rojo Connect OR open `PalmSpringsDev.rbxlx` |
| Server never starts, Types error | Bad `Types.lua` syntax | `} :: PlayerData` |
| Port 10048 on serve | Two `rojo serve` | One window only |
| Wrong Rojo behavior | `C:\Tools\rojo` first in PATH | Prepend `%USERPROFILE%\.rokit\bin` |
| “Game Settings” missing | Unpublished experience | Save to Roblox → **Experience Settings** |
| Supabase MOCK | No secrets | Expected until Manus configures |
| Placeholder sound warnings | rbxassetid 0 in registry | Manus uploads + manifest |
| HANDOFF says day-phase not merged | **Stale doc** | Use this file; `src/` has CoreLoop |

---

## 9. Prompt-to-game workflow (Karl)

| Asset | Path |
|-------|------|
| Launcher | `Start-PalmSprings.cmd` |
| Karl guide | `docs/karlux/10-karl-prompt-to-game.md` |
| Copy-paste prompts | `docs/karlux/karl-prompt-menu.md` |
| Agent behavior | `.cursor/rules/karl-prompt-builder.mdc` |

**Receiving agent workflow:**

1. Read Karl's prompt in natural language  
2. Implement in `src/` (small) or `staging/` (large / experimental)  
3. Commit + push (cloud agent)  
4. Reply to Karl with **only:** Start-PalmSprings.cmd → Connect → Play + test command  
5. Never assign PowerShell unless Eddie is named  

**SuperbulletAI:** Documented as orchestration lane in `08-karl-automation-playbook.md` — **no Superbullet product binary in repo**; role is runbooks + dispatch.

---

## 10. CI and PR

| Item | Detail |
|------|--------|
| **PR** | #24 (draft) — KarLux foundation branch |
| **CI** | `palm-springs-pr-checks.yml` on `cursor/**` and PRs to `main` |
| **Merge target** | `main` after Karl/Eddie approval |

**Next PR actions:** Update description to reflect day-phase merged + prompt-to-game; mark ready for review when Karl approves.

---

## 11. Remaining work (prioritized)

### P0 — Documentation hygiene (quick)

- [x] This file (`HANDOFF-FULL-AGENT-UPLOAD.md`)  
- [x] Update `HANDOFF-condensed.md` day-phase section (was stale)  
- [x] Update `staging/automation/agents.yaml` — `day_phase_merge: completed`  

### P1 — Karl UX

- [ ] Pin desktop shortcut to `Start-PalmSprings.cmd` (manual on Karl's PC)  
- [x] Optional: open `PalmSpringsDev.rbxlx` on launcher start (`Start-PalmSprings.cmd`)  
- [ ] Permanent User PATH: `.rokit\bin` above `C:\Tools\rojo`  

### P2 — Manus lane

- [ ] `supabase db push` from `staging/supabase/migrations/`  
- [ ] Roblox Secrets for `SUPABASE_*`  
- [ ] Populate `vendor-imports/_manifests/asset-index.yaml` with real rbxassetids  
- [ ] Cursor syncs IDs into `AssetRegistry.lua`  

### P3 — Product / governance

- [ ] Review and merge PR #24 to `main`  
- [ ] Wire SuperbulletAI to real product if Karl adopts it  
- [ ] Replace placeholder sounds (Output warnings)  

### P4 — Do NOT redo

- [ ] Re-merge day-phase from `staging/src/` to `src/`  
- [ ] Re-add Tarmac to `rokit.toml`  
- [ ] Flatten `default.project.json` server path  

---

## 12. Doc index (read order for new agent)

| Order | File |
|-------|------|
| 1 | **This file** — `HANDOFF-FULL-AGENT-UPLOAD.md` |
| 2 | `AGENTS.md` |
| 3 | `docs/karlux/10-karl-prompt-to-game.md` |
| 4 | `docs/karlux/02-agent-lane-discipline.md` |
| 5 | `docs/karlux/07-step-by-step-install-windows.md` |
| 6 | `docs/karlux/08-karl-automation-playbook.md` |
| 7 | `docs/karlux/HANDOFF-condensed.md` (short reference) |
| 8 | `docs/karlux/karl-prompt-menu.md` |

Architecture deep dives: `01`–`06` in `docs/karlux/README.md`.

---

## 13. Recent commits (reference)

```
ecda904 Karl prompt-to-game: double-click launcher, prompt menu, zero-CLI agent rules
d77b3aa Add day phase to /status; karl-start-day shows CoreLoop merged
3b1b895 Merge day-phase vertical slice into src (CoreLoop, HUD, garden/fashion gates)
68bca08 Fix audit-windows.ps1 em dashes for Windows PowerShell 5
8d78fe9 Fix Windows PS5: ASCII-only karl-start-day.ps1 and audit-windows.ps1
48b8590 Fix Types.lua syntax error blocking server bootstrap in Studio
c762a6e Fix Rojo 7 serve: nest server/client paths under Server and Client nodes
1f98765 Fix Windows toolchain: drop Tarmac from rokit.toml, fix bootstrap.ps1 encoding
```

---

## 14. Instructions for the receiving agent (copy-paste checklist)

```
[ ] Read this file end-to-end
[ ] Checkout branch: cursor/karlux-foundation-292d
[ ] git pull
[ ] Confirm day-phase in src/ (CoreLoopService, DayPhaseConfig) — do not re-merge from staging/src
[ ] Follow .cursor/rules/karl-prompt-builder.mdc for Karl-facing replies
[ ] Implement requested work; commit + push
[ ] Tell Karl: Start-PalmSprings.cmd → Studio Rojo Connect → Play Solo → /command
[ ] Route assets/DB to Manus; never ask Karl for PowerShell
[ ] Update PR #24 when merging significant slices
[ ] Cloud agent: cannot run Studio locally — rely on Karl/Eddie for playtest confirmation
```

---

## 15. Upload instructions for Karl

1. Save or download this file: `docs/karlux/HANDOFF-FULL-AGENT-UPLOAD.md`  
2. Start a **new Cursor chat** (or Cloud Agent task)  
3. Attach/upload this file and say: *“Continue Palm Springs from this handoff. Branch `cursor/karlux-foundation-292d`. I am Karl — use prompt-to-game rules.”*  
4. Double-click **`Start-PalmSprings.cmd`** before playtesting any code changes  

---

*End of handoff document.*
