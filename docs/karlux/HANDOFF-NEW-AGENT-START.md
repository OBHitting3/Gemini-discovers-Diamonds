# Palm Springs Paradise — Start New Agent (Upload This File)

**Use this as the only attachment** when opening a new Cursor or Cloud Agent chat.  
**Principal:** Karl (creative direction, no PowerShell) · **Technical:** Eddie (git, merge, audits)  
**Last updated:** 2026-05-24 · **Branch:** `cursor/karlux-foundation-292d`  
**Thread drop (new chat at ~76%):** [HANDOFF-THREAD-DROP.md](./HANDOFF-THREAD-DROP.md)  
**Karl’s goal:** build the **automation machine** — Palm Springs is the proof track, not Roblox revenue.  
**Repo:** https://github.com/OBHitting3/Gemini-discovers-Diamonds  
**Draft PR:** #24 — CI **passing** (StyLua, Selene, Rojo build)

---

## Copy-paste to start the agent

```
Continue Palm Springs Paradise from this handoff.
Branch: cursor/karlux-foundation-292d
I am Karl — use prompt-to-game rules (no PowerShell).
Read docs/karlux/HANDOFF-NEW-AGENT-START.md fully before changing code.
Follow .cursor/rules/karl-prompt-builder.mdc for all replies to Karl.
```

---

## What this game is

Roblox life-sim **Palm Springs Paradise** — mid-century modern desert town (KarLux LLC / Iron Forge Studios).  
**Stack:** Rojo 7.4.4, Luau, Wally, StyLua, Selene · **Governance:** KarLux **10-80-10** (big changes in `staging/` until Karl/Eddie approve merge to `src/`).  
**Art lock:** `.cursor/rules/roblox-mcm.md` — do not change sky/palette without approval.

---

## Karl’s workflow (mandatory for agents)

| Step | Karl does | Karl never does |
|------|-----------|-----------------|
| 1 | **Windows:** `Start-PalmSprings.cmd` · **Mac:** `setup.command` or `rojo serve` (see `07-step-by-step-install.md`) | PowerShell, `git pull`, `rojo serve` typing |
| 2 | Studio → **Plugins → Rojo → Connect** | Bulk mesh upload without manifest |
| 3 | **Play Solo** — test chat commands | `supabase` CLI |
| 4 | **Cursor chat** — plain English ideas | Merge `staging/` → `src/` without noting approval |

**After every code change, tell Karl only:**

1. `Start-PalmSprings.cmd` (leave window open)  
2. Studio → Rojo → **Connect**  
3. **Play Solo** + suggest a test command (`/health`, `/spawnprop flamingo_lawn`, etc.)

**Prompt menus:** `docs/karlux/karl-prompt-menu.md` · **3D:** `docs/karlux/11-karl-prompt-to-3d.md`

---

## What is already done (do not redo)

| Area | Status |
|------|--------|
| Windows toolchain | Rokit 7.4.4, Tarmac **omitted**, PS5-safe `.ps1` (ASCII only, no em dashes) |
| Rojo project | Nested `ServerScriptService.Server` / `StarterPlayerScripts.Client` |
| `Types.lua` | Fixed `} :: PlayerData` — server bootstrap works |
| Day-phase | **Merged in `src/`** — CoreLoop, DayPhaseController, garden/fashion gates |
| Prompt-to-game | `Start-PalmSprings.cmd`, `karl-prompt-menu.md`, `karl-prompt-builder.mdc` |
| Prompt-to-3D | `PropBuilder.lua`, `ProceduralAssetCatalog.lua`, `/spawnprop`, `/listprops` |
| Session commands | `/dailybonus`, `/poolparty`, `/vip`, `/runwayinfo`, `/stockshop`, Desert Rose plant, 200 starting coins |
| Cross-repo hardening | `Resilience.lua`, webhook/Supabase retries, `BootstrapHealth`, `/health`, `karl-preflight.cmd` |
| CI | Green on `cursor/**` — symlink-safe toolchain copy, `rokit install --no-trust-check` |

**Do NOT:** re-merge day-phase from `staging/src/` · re-add Tarmac · flatten `default.project.json` server paths.

---

## Key paths

| Path | Purpose |
|------|---------|
| `src/` | Production Luau (Rojo) |
| `staging/` | Gated experiments, toolchain source of truth |
| `staging/toolchain/rokit.toml` | Copy to root if `rokit install` fails |
| `vendor-imports/_manifests/asset-index.yaml` | Manus — currently `assets: {}` |
| `docs/karlux/` | All architecture + Karl guides |
| `AGENTS.md` | Agent router |
| `.cursor/rules/karl-prompt-builder.mdc` | Always-on Karl behavior |

---

## Test commands (Play Solo)

```
/help
/health          ← bootstrap OK/FAIL per service
/status          ← includes day phase
/coins 5000
/claimplot 1
/buildhouse kaufmann
/spawnprop flamingo_lawn
/listprops
/placefurniture eames_lounge
/dailybonus
```

---

## Agent lanes

| Agent | Owns |
|-------|------|
| **Cursor / Cloud** | Luau, Rojo, docs, PRs, **Tier 1 procedural 3D** (`PropBuilder`) |
| **Manus** | `vendor-imports/`, `asset-index.yaml`, Supabase `db push`, Roblox Secrets |
| **SuperbulletAI** | **Not a product in repo yet** — orchestration/checklists only (see `08-karl-automation-playbook.md`) |
| **Karl / Eddie** | Approve merges, Studio publish, Experience Settings (HTTP + API access) |

Registry: `staging/automation/agents.yaml`

---

## Suggestions for the receiving agent (prioritized)

### P0 — Do first when Karl asks for “make it work”

1. **Read** `.cursor/rules/karl-prompt-builder.mdc` and obey **no PowerShell** for Karl.  
2. **Checkout** `cursor/karlux-foundation-292d` and `git pull`.  
3. If Karl reports empty world or errors → check **`/health`** and Server Output; fix **minimal** change in `src/`.  
4. **Never** ask Karl to run terminal; offer to interpret pasted logs.

### P1 — High-value product (safe in `src/`)

1. **New procedural 3D** — add builder in `PropBuilder.lua` + entry in `ProceduralAssetCatalog.lua`; Karl tests `/spawnprop [slug]`.  
2. **New chat perks** — extend `TestCommands.lua` + `/help` (session flags pattern already exists).  
3. **Wire `placefurniture`** to procedural models (already: AssetRegistry → PropBuilder → box fallback).  
4. **UI polish** — DayPhase chip, notifications via existing `NotifyPlayer` remote.

### P2 — Needs Manus (write handoff only for Karl)

1. Populate **`asset-index.yaml`** with real `rbxassetid` values after Roblox upload.  
2. **`supabase db push`** from `staging/supabase/migrations/` + Roblox Secrets `SUPABASE_*`.  
3. Tier 2 meshes — handoff note in `staging/manus-handoffs/YYYY-MM-DD_slug-handoff.md` (template in `staging/manus-handoffs/README.md`).

### P3 — Governance / Eddie

1. **Review PR #24** with Karl — merge to `main` when approved.  
2. Permanent Windows PATH: `%USERPROFILE%\.rokit\bin` **above** `C:\Tools\rojo`.  
3. Pin desktop shortcut to `Start-PalmSprings.cmd`.  
4. Wire **SuperbulletAI** only if Karl adopts it (external product).

### P4 — Cross-repo context (optional research)

| Repo | Use when |
|------|----------|
| `content-shield/` (in repo) | Resilience/retry patterns — already in `Resilience.lua` |
| `OBHitting3/55-_AI_Intergration` | `game/PalmLuxeTycoon` parallel, `karl-twin` approval gates |
| `docs/karlux/12-cross-repo-success-hardening.md` | Full hardening map |

---

## Known gotchas

| Symptom | Fix |
|---------|-----|
| CI failed `cp: same file` | Root `rokit.toml` is symlink — workflow uses `rm` + `cp` (already fixed) |
| `rokit: command not found` in CI | PATH must include `$HOME/.rokit/bin` before `rokit install` |
| Port **10048** | Second `rojo serve` — close extra window |
| Wrong Rojo on Windows | `C:\Tools\rojo` before `.rokit\bin` in PATH |
| Supabase **MOCK** in Studio | Expected until Manus + Secrets |
| Empty `asset-index.yaml` | Expected — procedural 3D works without it |
| SuperbulletAI | **Not required** for Play Solo today |

---

## Doc index (read order)

| # | File |
|---|------|
| 1 | **This file** — `HANDOFF-NEW-AGENT-START.md` |
| 2 | `AGENTS.md` |
| 3 | `docs/karlux/10-karl-prompt-to-game.md` |
| 4 | `docs/karlux/11-karl-prompt-to-3d.md` |
| 5 | `docs/karlux/12-cross-repo-success-hardening.md` |
| 6 | `docs/karlux/karl-prompt-menu.md` |
| 7 | `docs/karlux/HANDOFF-FULL-AGENT-UPLOAD.md` (deep reference) |
| 8 | `docs/karlux/HANDOFF-condensed.md` (short) |

---

## Receiving agent checklist

```
[ ] Read this file and karl-prompt-builder.mdc
[ ] Branch: cursor/karlux-foundation-292d
[ ] Do not re-merge day-phase from staging/src
[ ] Implement Karl requests in src/ (small) or staging/ (large)
[ ] Commit + push; CI must stay green
[ ] Reply to Karl: Start-PalmSprings.cmd → Connect → Play → /command
[ ] Route FBX/uploads/DB to Manus handoff — never Karl terminal
[ ] Update PR #24 description if large slice lands
```

---

## For Karl — save this file

1. Download or keep: **`docs/karlux/HANDOFF-NEW-AGENT-START.md`**  
2. New chat → attach this file → paste the **Copy-paste to start the agent** block above.  
3. Double-click **`Start-PalmSprings.cmd`** before playtesting.

---

*End of new-agent handoff.*
