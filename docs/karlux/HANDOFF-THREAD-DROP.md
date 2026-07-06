# THREAD DROP — Upload This to New Chat (76% handoff)

**Karl · KarLux LLC · building the MACHINE, not shipping Roblox for money**  
**Branch:** `cursor/karlux-foundation-292d` · **PR #24** open, CI green · **Repo:** https://github.com/OBHitting3/Gemini-discovers-Diamonds  
**Mac:** KarLux on Mac — one folder (e.g. `~/KarLux/PalmSprings`), use `setup.command` or `docs/karlux/07-step-by-step-install.md`  
**Full detail:** `docs/karlux/HANDOFF-NEW-AGENT-START.md`

---

## Paste this into the new thread

```
Continue KarLux / Palm Springs from HANDOFF-THREAD-DROP.md.
Branch: cursor/karlux-foundation-292d
I am Karl — building the automation machine, not Roblox revenue.
No PowerShell for me. Read HANDOFF-THREAD-DROP.md + HANDOFF-NEW-AGENT-START.md.
Follow .cursor/rules/karl-prompt-builder.mdc.
```

Attach: **`docs/karlux/HANDOFF-THREAD-DROP.md`** (this file)

---

## North star (what Karl is proving)

**Machine =** describe in Cursor → agent edits Luau → Rojo syncs → Studio Play proves it → handoff doc preserves memory.

| Proof | How |
|-------|-----|
| P1 | Mac/Windows: start Rojo → Studio Connect → Play |
| P2 | Prompt → visible change (`/spawnprop`, new command, UI) |
| P3 | New agent reads handoff, does not redo day-phase merge |
| P4 | `/health` all OK |
| P5 | CI green on branch |

**NOT the goal:** public Roblox launch, monetization, new repo.

**ONE place:** this repo → merge **PR #24** to `main` when ready (single line of truth).

---

## Music (Karl keeps asking — be honest)

| Fact | Detail |
|------|--------|
| **Cursor / Cloud agents cannot play Spotify or audio to you** | No speakers from this chat. Say so plainly; do not pretend. |
| **In-game audio exists** | `SoundController.lua`, `AssetRegistry` sound keys — Play Solo ambient/SFX only |
| **Karl while working** | His own playlist on Mac (Music app, Spotify, etc.) — agent can suggest vibe, not stream |

If Karl wants **more in-game music**: procedural task for Cursor — add ambient zone or `/playsound` test hook in `SoundController` (Tier 1, `src/`).

---

## Session context (this thread ended ~76%)

1. Continued Palm Springs on `cursor/karlux-foundation-292d` — prompt-to-game + prompt-to-3D  
2. Karl UX pack: `/dailybonus`, `/poolparty`, `/spawnprop`, Desert Rose, 200 coins  
3. Cross-repo hardening: `Resilience.lua`, `/health`, `karl-preflight.cmd`, CI fixes  
4. Karl asked: SuperbulletAI (not in repo yet), 3D via prompts (yes — `PropBuilder`)  
5. Karl clarified: **building the machine**, not shipping for money — validated architecture  
6. Workspace often on `main` — **game work is on KarLux branch**, not `main`  
7. Saved this thread drop for new chat  

**Latest commits on branch:** `d87cb1a` (HANDOFF-NEW-AGENT-START), `2c63d99` (hardening), `6f2ad7d` (3D), `6c4c0ac` (prompt menu)

---

## Karl daily (no terminal)

| OS | Start Rojo |
|----|------------|
| **Windows** | Double-click `Start-PalmSprings.cmd` (runs preflight first) |
| **Mac** | Double-click `setup.command` OR `rojo serve` after `rokit install` per `07-step-by-step-install.md` |

Then: Studio → Rojo **Connect** → **Play Solo** → `/health` `/help`

---

## Agent lanes (do not blur)

| Agent | Does |
|-------|------|
| **Karl** | Intent, Cursor chat, Studio playtest, approve merges |
| **Cursor** | `src/`, `staging/`, docs, PropBuilder, PRs |
| **Manus** | `vendor-imports/`, `asset-index.yaml`, Supabase, secrets |
| **SuperbulletAI** | Docs only — **not a shipped product in repo** |

---

## Do not redo

- Day-phase merge (already in `src/`)  
- Tarmac in `rokit.toml`  
- Flatten Rojo `Server`/`Client` paths in `default.project.json`  

---

## Next agent priorities

1. Keep Karl on **one branch** — help Eddie merge PR #24 when Karl says go  
2. Optional: **`Start-PalmSprings.command`** for Mac one-click (parity with `.cmd`)  
3. Optional: in-game music command or more `SoundController` zones if Karl asks again  
4. Manus handoffs only for real meshes / live Supabase  

---

*Drop this file in the new thread. Stay on the machine.*
