# Karl — Prompt to Game (No PowerShell)

**You describe ideas in plain English. AI writes the code. The game updates in Studio.**

You do **not** need PowerShell, git commands, or terminal skills.

---

## Your only 3 clicks (every session)

| Step | What you do |
|------|-------------|
| **1** | Double-click **`Start-PalmSprings.cmd`** in the PalmSprings folder (leave the black window open) |
| **2** | Open **Roblox Studio** → your Palm Springs place → **Plugins** → **Rojo** → **Connect** |
| **3** | Press **Play** and test in chat (`/help`, `/coins 5000`, `/status`) |

That is the entire technical setup.

---

## Where you type ideas (pick one)

| Tool | Best for |
|------|----------|
| **Cursor** (chat on the right) | “Add a new plant”, “Make shops cheaper”, “Fix the HUD” |
| **SuperbulletAI** (if configured) | Daily “build my list” from a checklist |
| **Cloud Agent** (GitHub / Cursor cloud) | Big features while you are away — Eddie reviews the PR |

**Copy-paste starters:** [karl-prompt-menu.md](./karl-prompt-menu.md)

---

## What the AI does for you (automatic)

When you send a prompt in **Cursor**:

1. AI edits the game files (`src/` or `staging/`).
2. AI commits to GitHub (cloud agent) or tells Eddie to merge.
3. **Rojo** copies changes into Studio (while `Start-PalmSprings.cmd` is running).
4. You press **Play** again to see the update.

You never run `git pull` or `rojo serve` yourself if you use **`Start-PalmSprings.cmd`**.

---

## What to say in a good prompt

Include:

1. **What** you want (new item, new command, UI text, event rule).
2. **Where** in the game (garden, El Paseo shop, fashion runway, home plot).
3. **How to test** (`/something` in chat, or “see it on the HUD”).

**Example:**

> Add a chat command `/poolparty` that gives the player 200 SunCoins and shows a notification “Pool party bonus!” Only works once per play session.

---

## What still needs other lanes (not Cursor chat)

| Need | Who |
|------|-----|
| 3D meshes, sounds, rbxassetid | **Manus** (or Studio Import 3D) |
| Database / live saves in cloud | **Manus** + Supabase |
| Approve big merges to production | **Karl / Eddie** (10-80-10) |
| Publish game to Roblox players | **Karl / Eddie** in Studio |

Tell Cursor: *“Queue this for Manus: upload cactus mesh to vendor-imports.”*

---

## Day phases (already in the game)

Morning / Afternoon / Evening run automatically. Check with **`/status`** in Play.

- **Morning** — garden boost  
- **Evening** — fashion + night toggle (**N** key)

---

## If something does not show up in Studio

1. Is **`Start-PalmSprings.cmd`** still open? (not an error window)  
2. Studio → Rojo → **Connect** again  
3. **Stop** play → **Play** again  
4. Paste a screenshot of **Output (Server)** into Cursor chat: *“It didn’t work — here’s the log.”*

---

## Eddie / agents reference

- Full automation map: [08-karl-automation-playbook.md](./08-karl-automation-playbook.md)  
- Agent roles: [02-agent-lane-discipline.md](./02-agent-lane-discipline.md)  
- Repo router: [AGENTS.md](../../AGENTS.md)
