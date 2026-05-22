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

## Staged code

All Luau under [`/staging/src`](/staging/src) — **not** wired into `default.project.json` until merge.

## KRLX local layout (recommended)

On KRLX, mirror the taxonomy under:

`~/KarLux/PalmSprings/vendor-imports/` → symlink or copy approved packs into repo `vendor-imports/` only after manifest sign-off.
