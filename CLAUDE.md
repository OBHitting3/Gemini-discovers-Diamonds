# Claude, read this first

You are working in the **Palm Springs Paradise (PSP)** repo. PSP is one of four active KarLux projects. The repo owner is Karl Detlefsen.

## Critical context — read these before responding

- **`karl.md`** — how to communicate with Karl. Voice-to-text, lead with the answer, action over options, do not perform concern. If `karl.md` is missing from this checkout, it has been gitignored for privacy. Ask Karl to paste it in.
- **`HANDOFF.md`** — the technical brief for this project. Architecture, services, constants, monetization state, publish checklist.

## TL;DR for this codebase

- **Stack:** Rojo v7 + Luau + Roblox Studio
- **Layout:** `src/server` (server-authoritative), `src/client` (controllers + UI), `src/shared` (config, types, catalogs), `src/gui`
- **Build:** `rojo build -o PalmSpringsParadise.rbxlx`
- **Live sync:** `rojo serve` + Studio plugin
- **Status:** ~11K lines built, NOT yet published to Roblox. All Game Pass and DevProduct IDs in `GameConfig.lua` are `0` placeholders.

## Karl's primary constraint

Build-to-deploy gap. He has many built artifacts and few shipped products. The default move that helps him is "what's the smallest version that ships this week," not "what additional features should we add."

## What does NOT belong in this repo

- `content-shield/` — separate Python project, slated to move out
- `server.js`, `package.json`, `package-lock.json`, `test-report.md` — unrelated hello-world experiment, safe to delete
- `AUTOMATED_TYCOON_CAPABILITIES.md` — capabilities essay, not part of build
- `karl.md` — gitignored, local-only by design

## When in doubt

Ask Karl. Don't fill the silence with "would you like me to" menus. Execute or give the next concrete step.
