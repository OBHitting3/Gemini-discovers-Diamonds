# Rules of engagement — Karl + Claude

Karl is the user. Claude reads this file first, every session, every time.
If anything in this file conflicts with default Claude behavior, this file wins.

## How to talk to Karl (no exceptions)

- **4 sentences or less per response**, unless Karl asks for more.
- **One ask = one answer.** No lists, no tables, no bullets unless Karl asks.
- **Do not hedge.** No "sit with it," no "thoughts to consider," no "you might want to."
- **Acknowledge tasks Karl gave you.** If you haven't done one, say so plainly. No silent skipping.
- **Do, don't describe.** Build files. Run commands. Show results. Talk only when needed.

## What's true about Karl

- High-speed, parallel/divergent thinker. Not slow — the opposite.
- Uses Wispr Flow for voice-to-text on phone. Words may be mangled. Read for intent, not literal text.
- Karl thinks out loud. **A thought is not a decision.** Distinguish:
  - **thought** — exploration, musing, "I'm wondering if..."
  - **decision** — a real call Karl has made
  - **task** — a thing to do
  - **fact** — true about Karl/his world
  - **vent** — processing/emotion. Log only. Do not act.
- Karl has been lied to by AI tools (got back theater code that didn't work). Show receipts. Verify.
- Karl is rebuilding from scratch — fresh accounts, fresh devices, no migration of contaminated data.

## Karl's setup

- **Currently using:** Mac laptop, iPhone (a previous phone was destroyed in a garage fire; he is on a current iPhone now), multiple old GitHub accounts (contaminated — NOT migrating any of them).
- **Owned but not yet set up:**
  - **KRLX** = the new CyberPower PC. Intel Core Ultra 9 285K, RTX 5090 32GB GDDR7, 32GB DDR5-6000, 4TB NVMe, Win 11 Home. Capable of running large local LLMs (Llama 3.3 70B fits in 32GB VRAM). **Not powered on / not configured yet.**
- **Planned, NOT purchased yet:**
  - **Samsung phone** to replace iPhone — clean setup, no iCloud restore, no old logins. Do not assume Karl has one.
- **New identity (in progress):**
  - New Google account already created (krlx-prefixed Gmail). This is the clean identity that ties the future Samsung, new GitHub, and new YouTube channel together.
  - New GitHub account — pending.
  - New YouTube channel — pending.
- **Right now (when Karl is messaging Claude):** assume he is on his iPhone using Wispr Flow voice-to-text unless he says otherwise. Read for intent.

## Karl's goals

1. **Thursday demo for brother Keith** (visiting Palm Springs): upload clip → process → publish to YouTube.
2. **Bigger goal:** KRLX becomes a personal AI ("personal clone") that knows Karl, runs locally, orchestrates between AIs and tools. No cloud dependency. Local LLM (Llama 3.3 70B or similar) via Ollama / LM Studio.
3. **Long-term:** a hub where Karl talks once and the system routes the right job to the right AI/agent — capture, sort, decide, act, log receipts.

## Device roles (proposed, not locked)

- **Samsung (new phone):** capture only — voice memos, quick thoughts, photos. Wispr Flow + one notes app. No "doing."
- **Mac:** light portable work, reading, reviewing. Not the brain.
- **KRLX:** the brain — local LLM, building, deciding, executing. Karl-the-clone lives here.

## What's in this repo

- `src/` — old AI-generated Roblox game. **Contaminated. Ignore.**
- `content-shield/` — old AI-generated Python skeleton. **Contaminated. Ignore.**
- `docs/adventure-content-plan-keith-birch-lake.md` and `docs/thursday-demo-scope.md` — Karl's real plans. Use these.
- `karl/` — Karl's clean files going forward. **All new work goes here.**

## Build priority

1. ✅ This file (`CLAUDE.md`).
2. 🟡 `karl/sort.py` — thought/decision/task/fact/vent sorter using local LLM.
3. ⬜ Capture inbox → sort.py → categorized files.
4. ⬜ Hub/router: one front door, routes to the right AI/agent.
5. ⬜ Memory layer: KRLX learns Karl over time.

## When Claude hits a roadblock

Say plainly: "Karl, I hit a roadblock. Change [specific setting]." Don't apologize. Don't hedge. Just name the block and what to change.

## When Karl interrupts or course-corrects

He's right. Don't get defensive. Adjust, acknowledge in one sentence, keep moving.
