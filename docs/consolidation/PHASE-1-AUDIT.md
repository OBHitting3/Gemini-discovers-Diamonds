# Phase 1: Deep Audit and Summarization

**Date:** 2026-07-06  
**Auditor:** Consolidation agent  
**Scope:** All 8 OBHitting3 repositories targeted for SSO consolidation

---

## Executive Summary

The workspace currently contains **one live Git repository** (`gemini-discovers-diamonds`) with three logical projects at the root. A prior commit (`4658b4d`) captured a **full snapshot of all 8 source repositories** under `future/repos/` with a machine-readable manifest. That snapshot is the authoritative inventory for this audit.

| # | Repository | Status | Keep? |
|---|------------|--------|-------|
| 1 | `55-_AI_Intergration` | 94 files — Next.js + karl-twin + PalmLuxeTycoon | **Yes** (split into apps) |
| 2 | `Content_Shield` | 84 files — Joshua 7 MVP validators | **Merge** into content-shield |
| 3 | `Faceless_Shorts` | 37 files — YouTube Shorts pipeline | **Yes** |
| 4 | `FreeLance` | Empty (no default branch) | **Discard** |
| 5 | `Gemini-discovers-Diamonds` | 206 files — Palm Springs Paradise + content-shield | **Yes** (primary live repo) |
| 6 | `Iron-Forge-Studios` | 29 files — Roblox "Steal the Oasis" prototype | **Yes** (merge Roblox code) |
| 7 | `joshua7` | 33 files — Joshua 7 CLI/API standalone | **Merge** into content-shield |
| 8 | `yt-autopilot` | 5 files — YouTube video generator stub | **Merge** with Faceless_Shorts |

**Key finding:** Consolidation is primarily **organizational** plus **deduplicating three content-validation codebases** (Content_Shield, joshua7, content-shield) and **two video pipelines** (Faceless_Shorts, yt-autopilot), plus **three Roblox games** (Palm Springs Paradise, Palm Luxe Tycoon, Iron-Forge-Studios).

---

## How to Open All Repos in Cursor

The agent can only audit folders present in the workspace. To work with live clones of all 8 repos:

1. **Multi-root workspace:** File → Add Folder to Workspace for each cloned repo; save as `sso-consolidation.code-workspace`.
2. **Parent folder:** Clone all repos into one directory and open it in Cursor.
3. **Cloud Agent:** Add all repo folders to the same Cloud workspace before starting a run.
4. **Existing snapshot:** The `future/` snapshot (commit `4658b4d`) already contains tracked-file copies of all 8 repos — restore with `git checkout 4658b4d -- future/` if needed.

---

## Repository Summaries

### 1. Gemini-discovers-Diamonds (Live Workspace Root)

| Attribute | Details |
|-----------|---------|
| **GitHub** | https://github.com/OBHitting3/Gemini-discovers-Diamonds |
| **Purpose** | Palm Springs Paradise — social life-simulation Roblox game (MCM desert town) |
| **Stack** | Luau, Rojo v7, Roblox DataStore, Supabase REST (mock), n8n webhooks (placeholder) |
| **Scale** | ~40 Luau files, ~11,000 lines |
| **Entry points** | `src/server/init.server.lua`, `src/client/init.client.lua`, `default.project.json` |

**Also embedded in this repo:**

- **`content-shield/`** — Full Python AI content validation framework (228 files, Apache 2.0, merged via PR #10)
- **`server.js`** — Intentionally buggy Express test harness (`execution-test`) — **do not migrate**
- **`docs/`** — YouTube pipeline demo scope, Birch Lake adventure content plan
- **`AUTOMATED_TYCOON_CAPABILITIES.md`** — Reference doc (~900 lines), not executable code

**Core dependencies:** Roblox engine only; Python deps in `content-shield/pyproject.toml`; Express 4.18.2 for test harness.

---

### 2. 55-_AI_Intergration

| Attribute | Details |
|-----------|---------|
| **GitHub** | https://github.com/OBHitting3/55-_AI_Intergration |
| **Default branch** | `claude/upgrade-ai-bridge-sync-JqMHc` |
| **Files** | 94 |
| **Purpose** | Three independent products in one tree |

**Sub-projects:**

| Product | Path | Stack | Purpose |
|---------|------|-------|---------|
| **AI Bridge Sync** | repo root | Next.js 14, React 18, TypeScript, Tailwind | MCP context sync dashboard; `/api/health`, `/api/sync` |
| **karl-twin** | `karl-twin/` | Python 3.12, FastAPI, LangGraph, Qdrant, Postgres, E2B | Sovereign digital twin — voice-driven, approval-gated agent |
| **Palm Luxe Tycoon** | `game/PalmLuxeTycoon/` | Roblox Luau | Unified economy tycoon — PricingEngine, AntiExploit, AssetBridge, MonteCarloSim (~950 lines) |

**Core dependencies:**

- Next.js: `next@14.2.35`, `react@^18.3.1`, custom `eslint-plugin-no-sdk`
- karl-twin: LangGraph 1.x, Claude Agent SDK, FastAPI, faster-whisper, E2B, Qdrant, PostgreSQL 16
- PalmLuxeTycoon: Roblox Studio only

---

### 3. Content_Shield (OBHitting3 fork)

| Attribute | Details |
|-----------|---------|
| **GitHub** | https://github.com/OBHitting3/Content_Shield |
| **Files** | 84 |
| **Purpose** | Joshua 7 MVP — pre-publication AI content validation (Iron Forge Studios product) |
| **Stack** | Python 3.10+, FastAPI, Pydantic v2, Typer CLI, Docker |
| **Entry point** | `joshua7` CLI, FastAPI at `joshua7/api/main.py` |

**MVP validators (5):**

1. Forbidden Phrase Detector
2. PII Validator (redacted output)
3. Brand Voice Scorer
4. Prompt Injection Detector (10 pattern families)
5. Readability Scorer (Flesch-Kincaid)

**Core dependencies:** `fastapi`, `uvicorn`, `pydantic`, `typer`, `pyyaml`, `textstat`

---

### 4. joshua7 (Standalone)

| Attribute | Details |
|-----------|---------|
| **GitHub** | https://github.com/OBHitting3/joshua7 |
| **Files** | 33 |
| **Purpose** | Same Joshua 7 product as Content_Shield — standalone CLI/API package |
| **Stack** | Python 3.10+, FastAPI, Typer, Render deploy (`render.yaml`) |
| **Entry point** | `j7` / `joshua7` CLI |

**Overlap:** Near-duplicate of `Content_Shield/joshua7/` module. Same validators, same company branding. **Consolidate into one package.**

---

### 5. content-shield (Embedded in Gemini-discovers-Diamonds)

| Attribute | Details |
|-----------|---------|
| **Upstream** | https://github.com/content-shield/content-shield (Apache 2.0) |
| **Path (live)** | `/workspace/content-shield` |
| **Purpose** | Enterprise-grade AI content validation framework |
| **Stack** | Python 3.10+, Pydantic v2, httpx, tenacity, structlog |
| **Scale** | 59 source files, 31 test files, full infra (Terraform, Docker, Grafana) |

**Capabilities beyond Joshua 7:**

- 8 pluggable shields (brand voice, factual, legal, toxicity, hallucination, sentiment, competitor, contact)
- Multi-provider AI agents (Gemini, Claude, OpenAI)
- Resilience layer (retry, circuit breaker, DLQ)
- CMS integrations (WordPress, HubSpot, Mailchimp, Shopify)
- Event emitters (console, webhook, Pub/Sub, Slack)
- Grafana dashboards with Pain Line tracking

**Core dependencies:** `pydantic>=2.0`, `httpx>=0.25`, `tenacity>=8.0`, `structlog>=23.0`

---

### 6. Faceless_Shorts

| Attribute | Details |
|-----------|---------|
| **GitHub** | https://github.com/OBHitting3/Faceless_Shorts |
| **Files** | 37 (mostly docs + 5 Python scripts) |
| **Purpose** | 95% automated faceless YouTube Shorts pipeline — topic → script → voice → video → upload |
| **Stack** | Python, Gemini, ElevenLabs, YouTube OAuth, MoviePy, Pillow |
| **Entry point** | `scripts/run_pipeline.py "topic"` |

**Pipeline steps:**

1. Gemini writes Shorts script
2. ElevenLabs (or gTTS fallback) generates voiceover
3. MoviePy builds 9:16 video from image + audio
4. YouTube API uploads

**Core dependencies:** `google-generativeai`, `elevenlabs`, `moviepy`, `Pillow`, Google OAuth libs

**Status:** Marked `FINISHED` in repo; extensive Gumroad/marketing docs included.

---

### 7. yt-autopilot

| Attribute | Details |
|-----------|---------|
| **GitHub** | https://github.com/OBHitting3/yt-autopilot |
| **Files** | 5 |
| **Purpose** | Automated YouTube video generation — topic to upload in one command |
| **Stack** | Python, OpenAI GPT-4o, ElevenLabs, MoviePy, YouTube API |
| **Entry point** | `main.py` |

**Overlap with Faceless_Shorts:** Same pipeline pattern (script → TTS → video → YouTube). Uses OpenAI instead of Gemini. Code quality issues (indentation corruption in snapshot). **Merge into unified video-pipeline app; keep Faceless_Shorts as canonical.**

---

### 8. Iron-Forge-Studios

| Attribute | Details |
|-----------|---------|
| **GitHub** | https://github.com/OBHitting3/Iron-Forge-Studios |
| **Files** | 29 |
| **Purpose** | "Palm Springs Paradise: Steal the Oasis" — Roblox game prototype with heist/egg/trade mechanics |
| **Stack** | Roblox Luau, Rojo |
| **Entry point** | `src/ServerScriptService/GameInit.server.lua` |

**Services:** DataService, WorldService, EggService, HeistService, PlotService, TradeService, MonetizationService, LeaderboardService

**Data modules:** 50 collectible icons, 52 MCM furniture items, PlayerDataTemplate

**Overlap with Palm Springs Paradise:** Both are MCM Palm Springs Roblox games with PlotService, LeaderboardService, furniture catalogs. Different game loops (heist/eggs vs garden/fashion). **Merge shared modules; keep as separate apps or unified game with feature flags.**

---

### 9. FreeLance (Discard)

| Attribute | Details |
|-----------|---------|
| **GitHub** | https://github.com/OBHitting3/FreeLance |
| **Files** | 1 (import note only) |
| **Status** | No default branch, no tracked files |
| **Recommendation** | **Leave behind** — archive or delete on GitHub |

---

## Cross-Repository Overlap Analysis

### Content Validation (HIGH overlap — must deduplicate)

| Feature | Joshua 7 (Content_Shield + joshua7) | content-shield (embedded) |
|---------|-------------------------------------|---------------------------|
| Brand voice | `validators/brand_voice.py` | `shields/brand_voice.py` + BrandProfile |
| PII detection | `validators/pii.py` | `analyzers/email_validator.py`, `phone_validator.py` |
| Forbidden phrases | `validators/forbidden_phrases.py` | BrandProfile banned_words |
| Readability | `validators/readability.py` | `analyzers/readability.py` |
| Prompt injection | `validators/prompt_injection.py` | Not present |
| AI agents | None | Full multi-provider router |
| Resilience | None | Retry, CB, DLQ |
| Infra | Docker, Render | Terraform, GCP, Grafana |

**Recommendation:** Use `content-shield` as the canonical package. Port Joshua 7's prompt-injection validator and CLI (`j7` command) into it. Deprecate standalone `Content_Shield` and `joshua7` repos.

### Video Pipeline (MEDIUM overlap — merge)

| Feature | Faceless_Shorts | yt-autopilot |
|---------|-----------------|--------------|
| Script gen | Gemini | OpenAI GPT-4o |
| TTS | ElevenLabs + gTTS fallback | ElevenLabs |
| Video | MoviePy + Pillow | MoviePy + Pillow |
| Upload | YouTube OAuth | YouTube OAuth |
| Maturity | Full scripts, docs, FINISHED marker | 5-file stub, broken formatting |

**Recommendation:** Unified `apps/video-pipeline` with provider abstraction (Gemini/OpenAI for scripts, ElevenLabs for TTS).

### Roblox Games (MEDIUM overlap — shared packages)

| Feature | Palm Springs Paradise | Iron-Forge-Studios | Palm Luxe Tycoon |
|---------|----------------------|--------------------|------------------|
| Plot system | PlotService | PlotService | N/A |
| Economy | EconomyService | MonetizationService | PricingEngine |
| Leaderboard | LeaderboardService | LeaderboardService | N/A |
| Furniture | ItemCatalog | FurnitureDatabase (52 items) | N/A |
| Persistence | ProfileServiceWrapper + Supabase | DataService | AssetBridge |
| Unique | Garden, Fashion, Runway | Heist, Eggs, Trade | Cross-mode economy sim |

**Shared patterns:** RemoteManager/Remotes, Util/Utilities, GameConfig/Constants, DataStore wrappers, procedural builders.

**Recommendation:** Extract `packages/roblox-shared` (Remotes, Util, DataStore patterns, MCM part builders). Keep three games as separate `apps/` with distinct `default.project.json` files.

### Web / Agent Infrastructure (LOW overlap)

| Product | Stack | Overlap |
|---------|-------|---------|
| AI Bridge Sync | Next.js 14 | Unique — MCP sync dashboard |
| karl-twin | LangGraph + FastAPI | Unique — approval-gated agent |
| execution-test | Express (buggy) | Discard |

---

## Dead, Placeholder, and Deprecated Code

| Location | Status | Action |
|----------|--------|--------|
| `WebhookClient.lua` | Placeholder mode | Keep — wire to n8n in SSO |
| `SupabaseClient.lua` | Mock mode in Play Solo | Keep — dev pattern |
| `SoundController.lua` | Placeholder asset IDs | Keep — replace later |
| `server.js` / `execution-test` | Intentionally buggy | **Discard** or isolate in `tools/agent-tests/` |
| `content-shield/.venv/` | Generated | Never migrate |
| `node_modules/` | Generated | Never migrate |
| `FreeLance` repo | Empty | **Discard** |
| `yt-autopilot/main.py` | Corrupted indentation | Rewrite during merge |
| `joshua7/__pycache__/` in snapshot | Generated | Never migrate |
| Video pipeline in `docs/thursday-demo-scope.md` | Spec only | Implement in Phase 3 |

---

## Git History Context

The live repo (`bea516e`) is behind newer commits on remote `main` that include:

- Day-phase vertical slice, Karl prompt-to-game tooling, 3D furniture, drivable car, music commands
- Cross-repo success hardening (resilience, preflight, `/health`)
- `future/` monorepo snapshot (commit `4658b4d`) with all 8 repos

Partial consolidation already started:

- PR #10 merged `content-shield` scaffold (228 files)
- PR #6 added execution-test harness
- PR #2 added Palm Springs art-direction prototype

---

## Phase 1 Conclusions

1. **All 8 repos identified** via `future/manifest.json` snapshot (commit `4658b4d`).
2. **7 repos have keep-worthy code**; FreeLance is empty and should be discarded.
3. **Three-way content validation overlap** (Content_Shield, joshua7, content-shield) is the highest-priority deduplication target.
4. **Two video pipelines** (Faceless_Shorts, yt-autopilot) should merge into one app.
5. **Three Roblox games** share MCM theme and module patterns — extract shared package.
6. **No direct code duplication** between Luau and Python; consolidation is organizational plus targeted merges.
7. **Live workspace** is a proto-monorepo; the `future/` snapshot should be restored or repos cloned fresh for Phase 3 migration.

---

## Next Step

Proceed to **Phase 2: Evaluation and Extraction Strategy** — see [`PHASE-2-ARCHITECTURE.md`](PHASE-2-ARCHITECTURE.md).
