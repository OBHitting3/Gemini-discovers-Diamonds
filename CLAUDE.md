# Context for any AI session in this repo

> **Read this before doing anything.** The user has eidetic recall and is exhausted from re-explaining context to fresh AI sessions. Do not pretend you remember prior conversations — read this file. That's why it exists.

## Who this repo belongs to

- **OBHitting3 / Iron Forge Studios.** One human user. Solo operator, not a team.
- Works on a Mac. Prefers double-clickable `.command` scripts over CLI flags.
- Speaks directly. No hedging, no emojis, no four-option enumerations.

## What this repo IS NOT

This is not one project. It is **five different experiments** in one repo, accumulated since Feb 2026. Treat them as separate. Do not cross-pollinate context between them.

| Folder / file | What it is | Status |
|---|---|---|
| `AUTOMATED_TYCOON_CAPABILITIES.md` | Roblox tycoon capabilities doc (Feb 2026) | Archived reference. Do not extend. |
| `src/`, `default.project.json`, `*.command` (root) | Palm Springs Paradise — Roblox MCM tycoon prototype | Stalled. Do not extend without explicit ask. |
| `server.js`, `package.json`, `test-report.md` | Strict-execution compliance test (Express) | **5 bugs are INTENTIONAL. Do NOT "fix" them.** |
| `content-shield/` | 228-file Python AI-content-validation framework | Scaffolded by Claude on a "review" branch (drift). Never run. Do not extend. |
| `docs/` | Birch Lake adventure plan + Thursday demo scope | Creative brief only. Pipeline does not exist yet. |
| `local-llm/` | **Active work.** Private local LLM (Ollama + llama3.2:3b + Open WebUI). | This is what matters now. |

## Active work: `local-llm/`

The user is building a private, local LLM with persistent memory so cloud-AI amnesia stops happening. Stack:

- **Ollama** runs the model on the Mac.
- **llama3.2:3b** is the default model.
- **Open WebUI** is the chat interface at `http://localhost:8080`.
- **`local-llm/intake/`** is the vetting station for any old files the user wants the model to know about. The user is the bouncer; nothing auto-imports.
- **`local-llm/intake/memory.md`** = curated facts.
- **`local-llm/intake/voice.md`** = sample writing for tone-matching.
- **`local-llm/intake/build-system-prompt.command`** = combines both into a clipboard-ready system prompt.

## Operating rules for any AI in this repo

1. **Read this file first.** Every session.
2. **Do not extend scope.** When asked to review, review. When asked to fix one thing, fix one thing. The canonical drift example is `claude/review-content-shield-spec-B8kt2` — Claude was asked to review a spec and shipped 8431 lines of code instead. Do not repeat that.
3. **Do not "improve" code marked INTENTIONAL.** See `server.js` and `test-report.md`.
4. **For multi-step actions:** do them, validate, report done. Don't ask for confirmation between steps unless the action is destructive (force-push, rm -rf, etc.).
5. **Match the user's register:** short sentences, direct verbs, no apologies, no fluff.
6. **If unsure, ask one short question.** Not four options. One question.
7. **Do not import outside knowledge about this user.** Only what's in this file or in this conversation.

## What "done" means for `local-llm/`

- `setup.command` runs cleanly on the user's Mac (one-time).
- `start.command` opens Open WebUI in the browser.
- `voice.md` and `memory.md` hold the user's profile.
- `build-system-prompt.command` produces a clipboard-ready prompt for Open WebUI.

## What is OUT of scope right now

Unless the user explicitly says otherwise:
- YouTube publish pipelines
- Extending `content-shield/`
- Roblox / Palm Springs work
- Adding new top-level projects to this repo

If the user asks for one of these, ask whether to spin up a new repo first.
