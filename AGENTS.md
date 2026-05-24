# Palm Springs Paradise — Agent Router

**Project:** Palm Springs Paradise (KarLux LLC / Iron Forge Studios)  
**Repo:** `Gemini-discovers-Diamonds` · branch `cursor/karlux-foundation-292d`  
**Governance:** KarLux **10-80-10** — Karl/Eddie approve merges from `staging/` → `src/`

Read this file first. Detailed playbooks live in `docs/karlux/`.

---

## Agents at a glance

| Agent | Lane | Automates for Karl |
|-------|------|-------------------|
| **Karl / Eddie** | Intent (10%) | Creative direction, merge PRs, Studio publish |
| **Cursor** | Logic (80% impl) | Luau, Rojo, PRs, `staging/` slices, docs |
| **Manus** | Boundary | Assets, Supabase `db push`, secrets, uploads, n8n |
| **SuperbulletAI** | Orchestration | Daily checklists, agent dispatch, audits, reminders |
| **Cloud Agent** | Remote Cursor | PRs when KRLX/Windows is offline |

Machine-readable registry: `staging/automation/agents.yaml`

---

## Karl — one command (Windows)

```powershell
cd $env:USERPROFILE\Documents\Roblox\PalmSprings
powershell -ExecutionPolicy Bypass -File staging\scripts\karl-start-day.ps1
```

Then: **Tasks → Rojo: Serve** → Studio → Connect → Play Solo → `/help`

---

## Doc map (Palm Springs)

| Doc | Purpose |
|-----|---------|
| [docs/karlux/README.md](docs/karlux/README.md) | Architecture index (01–08) |
| [docs/karlux/HANDOFF-condensed.md](docs/karlux/HANDOFF-condensed.md) | Short session handoff |
| [docs/karlux/02-agent-lane-discipline.md](docs/karlux/02-agent-lane-discipline.md) | Cursor · Manus · SuperbulletAI |
| [docs/karlux/08-karl-automation-playbook.md](docs/karlux/08-karl-automation-playbook.md) | **Full automation timeline for Karl** |
| [docs/karlux/07-step-by-step-install-windows.md](docs/karlux/07-step-by-step-install-windows.md) | Windows + Cursor install |
| [README.md](README.md) | Game design + `src/` layout |

---

## Handoff files (agents must use these, not DMs)

| File | Producer | Consumer |
|------|----------|----------|
| `vendor-imports/_manifests/asset-index.yaml` | Manus | Cursor → `AssetRegistry` |
| `staging/supabase/migrations/` | Manus (`db push`) | Live Supabase |
| `staging/env/.env` | Manus (local only) | Supabase CLI, Open Cloud |
| Roblox Secrets `SUPABASE_*` | Manus / Karl | `SupabaseClient.fromSecrets()` |
| `staging/src/*` | Cursor | Karl merge → `src/` |

---

## What is NOT an agent

- **Rojo / Wally / StyLua** — CLI tools (pinned in `staging/toolchain/rokit.toml`)
- **Roblox Studio** — Karl's playtest surface
- **SuperbulletAI** does not replace Cursor or Manus; it coordinates them

---

## Rules (all agents)

1. Production Luau: `src/` only after Karl/Eddie approval.
2. New features: `staging/` first (10-80-10).
3. No production secrets in git; use `staging/env/.env.example` + Roblox Secrets.
4. MCM art lock: `.cursor/rules/roblox-mcm.md`
