# KarLux / Iron Forge Studios — Architecture Staging

**Entity:** KarLux LLC · **Studio:** Iron Forge Studios  
**Project:** Palm Springs Paradise (enterprise Roblox / Rojo v7)  
**Governance:** KarLux **10-80-10** — intent from principals (10%), agent implementation staged for review (80%), explicit merge by Karl or Eddie (10%).

## Documents in this folder

| Doc | Purpose |
|-----|---------|
| [01-asset-taxonomy-tree.md](./01-asset-taxonomy-tree.md) | Canonical folder hierarchy for downloaded assets **before** any file moves |
| [02-agent-lane-discipline.md](./02-agent-lane-discipline.md) | Cursor vs Manus ownership — zero overlap |
| [03-vertical-slice-merge-guide.md](./03-vertical-slice-merge-guide.md) | How to promote `staging/` into `src/` after approval |
| [04-roblox-toolchain.md](./04-roblox-toolchain.md) | Rokit, Wally, StyLua, Darklua, Rojo, Remodel, Tarmac, Git |
| [05-unified-dev-stack.md](./05-unified-dev-stack.md) | **Cursor, VS Code, Studio, Blender, Supabase** — how they connect |
| [06-friction-reduction-additions.md](./06-friction-reduction-additions.md) | Selene, LSP, LFS, CI, pre-commit, extras |
| [07-step-by-step-install.md](./07-step-by-step-install.md) | **Start here** — macOS install walkthrough |
| [07-step-by-step-install-windows.md](./07-step-by-step-install-windows.md) | **Start here** — Windows + Cursor (PowerShell) |
| [08-karl-automation-playbook.md](./08-karl-automation-playbook.md) | **Karl automation** — Cursor + Manus + SuperbulletAI + Supabase phases |
| [10-karl-prompt-to-game.md](./10-karl-prompt-to-game.md) | **Karl: no PowerShell** — prompt → AI → Studio |
| [11-karl-prompt-to-3d.md](./11-karl-prompt-to-3d.md) | **Karl: prompt → 3D** — procedural props + Manus path |
| [karl-prompt-menu.md](./karl-prompt-menu.md) | Copy-paste prompts for Cursor chat |
| [HANDOFF-FULL-AGENT-UPLOAD.md](./HANDOFF-FULL-AGENT-UPLOAD.md) | **Upload to new agent** — full session handoff |
| [HANDOFF-condensed.md](./HANDOFF-condensed.md) | Short session handoff |
| [../AGENTS.md](../AGENTS.md) | Agent router (repo root) |
| [../Start-PalmSprings.cmd](../Start-PalmSprings.cmd) | Double-click Rojo server (Windows) |

## Staged code

Day-phase slice is **merged** in `src/`. Remaining `staging/src/` files are duplicates/history — see [HANDOFF-FULL-AGENT-UPLOAD.md](./HANDOFF-FULL-AGENT-UPLOAD.md).

## KRLX local layout (recommended)

On KRLX, mirror the taxonomy under:

`~/KarLux/PalmSprings/vendor-imports/` → symlink or copy approved packs into repo `vendor-imports/` only after manifest sign-off.
