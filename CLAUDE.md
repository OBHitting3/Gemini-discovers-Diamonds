# Context for any AI session in this repo

> **Read this before doing anything.** The user has eidetic recall and is exhausted from re-explaining context to fresh AI sessions. Do not pretend you remember prior conversations — read this file. That's why it exists.

## Who this repo belongs to

- **OBHitting3 / Iron Forge Studios.** One human user. Solo operator, not a team.
- Uses both a **Mac** (for chat with cloud AIs) and a **CyberPower PC named KRLX** (RTX 5090, 32 GB VRAM, Windows 11 + WSL, WSL username `karlux`). KRLX is also the name of the digital twin LLM being built on that PC.
- Speaks directly. Short clauses. Profanity for emphasis. **No hedging, no emojis, no four-option enumerations.**
- Uses metaphors: "Groundhog Day" (re-explaining to amnesiac AIs), "black widow spider" (hard-earned authority), "big dog" (confidence).

## What this repo IS NOT

This is not one project. It is **five different experiments** in one repo, accumulated since Feb 2026. Treat them as separate. Do not cross-pollinate context between them.

| Folder / file | What it is | Status |
|---|---|---|
| `AUTOMATED_TYCOON_CAPABILITIES.md` | Roblox tycoon capabilities doc (Feb 2026) | Archived reference. Do not extend. |
| `src/`, `default.project.json`, `*.command` (root) | Palm Springs Paradise — Roblox MCM tycoon prototype | Stalled. Do not extend without explicit ask. |
| `server.js`, `package.json`, `test-report.md` | Strict-execution compliance test (Express) | **5 bugs are INTENTIONAL. Do NOT "fix" them.** |
| `content-shield/` | 228-file Python AI-content-validation framework | Scaffolded by Claude on a "review" branch (drift). Never run. Do not extend. |
| `docs/` | Birch Lake adventure plan + Thursday demo scope | Creative brief only. Pipeline does not exist yet. |
| `local-llm/` | **Active work.** KRLX — private local LLM digital twin on the Windows PC. | This is what matters now. |

## Active work: KRLX (`local-llm/windows/`)

The user is building **KRLX** — a private local LLM "digital twin" that runs on a CyberPower PC also named KRLX. Stack:

- **LM Studio** (Windows native app) runs the model. No terminal, no Docker, no GitHub on the PC.
- **Llama 3.3 70B Instruct** (Q4_K_M or Q3_K_M depending on LM Studio's recommendation for the 5090's 32 GB VRAM).
- **System prompt** is KRLX's identity + behavior — single text field inside LM Studio. The pre-drafted prompt lives at `local-llm/windows/system-prompt.txt`.
- **Persistent chat history** = LM Studio's built-in local storage. Nothing leaves the box.
- **Sunshine + Moonlight** (planned, not yet installed) for streaming the PC's screen to the user's phone over Wi-Fi.
- **`local-llm/intake/`** is the vetting station for vetting any old files before they cross into KRLX's knowledge. The user is the bouncer; nothing auto-imports.

### Key files in `local-llm/windows/`

- `TONIGHT.md` — 5-checkpoint walkthrough (power on → internet → Sunshine/Moonlight → LM Studio + model → system prompt + test)
- `MORNING.md` — one-click launch instructions for daily use
- `system-prompt.txt` — pre-drafted KRLX brain. User edits anything that doesn't sound like them before pasting into LM Studio.
- `FIRST-CHAT.md` — 3-message validation script the user runs the very first time to prove KRLX loaded the brain correctly
- `README.md` — overview / index

### Current status (as of May 18, 2026, end of session)

- ✅ PC powered on, Windows desktop reached, internet works (proven via WSL `nvidia-smi`)
- ✅ Hardware confirmed: NVIDIA GeForce RTX 5090, 32 GB VRAM, driver 596.36, CUDA 13.2
- ✅ LM Studio installed and opened (user clicked through onboarding)
- 🟡 **Llama 3.3 70B Instruct downloading** (30–40 GB, in progress when session ended; user stepped away to Mac)
- ⏳ Not yet done: paste `system-prompt.txt` into LM Studio's System Prompt field, run `FIRST-CHAT.md` 3-message validation
- ⏳ Sunshine + Moonlight: skipped tonight; do later when there's time
- ❓ User mentioned a "6 AM deadline" for tomorrow. Specifics not given. Ask if relevant.

### What "done" means for KRLX

KRLX is operational when this test passes:
1. User opens LM Studio on the PC (or via Moonlight on phone, if Sunshine is set up).
2. Llama 3.3 70B is selected and loaded.
3. User types: "What do you remember about me?"
4. KRLX replies in the user's register, citing facts from the system prompt's "Who I'm talking to" section.

Full validation script: `local-llm/windows/FIRST-CHAT.md`.

## Operating rules for any AI in this repo

1. **Read this file first.** Every session.
2. **Do not extend scope.** When asked to review, review. When asked to fix one thing, fix one thing. The canonical drift example is `claude/review-content-shield-spec-B8kt2` — Claude was asked to review a spec and shipped 8431 lines of code instead. Do not repeat that.
3. **Do not "improve" code marked INTENTIONAL.** See `server.js` and `test-report.md`.
4. **For multi-step actions:** do them, validate, report done. Don't ask for confirmation between steps unless the action is destructive (force-push, rm -rf, etc.).
5. **Match the user's register:** short sentences, direct verbs, no apologies, no fluff. No emojis. No four-option enumerations — make the call, commit, course-correct on the next turn if wrong.
6. **If unsure, ask one short question.** Not four options. One question.
7. **Do not import outside knowledge about this user.** Only what's in this file or in this conversation.
8. **The user is the bouncer.** Do not auto-import any old files into KRLX. They vet every byte that crosses.

## What is OUT of scope right now

Unless the user explicitly says otherwise:
- YouTube publish pipelines
- Extending `content-shield/`
- Roblox / Palm Springs work
- Adding new top-level projects to this repo
- Setting up the "Vibe Coding Stack" (90-tool spreadsheet of services) — the user explicitly rejected this; it is the disease, not the cure.

If the user asks for one of these, ask whether to spin up a new repo first.
