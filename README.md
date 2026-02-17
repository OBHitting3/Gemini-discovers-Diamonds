# Gemini-discovers-Diamonds

## Architecture Fixes — Faceless Shorts MCP System

This branch contains **working implementation code** that fixes the 4 critical architecture problems identified by a multi-LLM audit (Grok, Claude Arena, Gemini, Claude Browser).

### The Problem

The Faceless Shorts MCP architecture was a beautifully drawn blueprint with no plumbing:

| Dimension | Audit Score |
|---|---|
| Conceptual Vision | 9/10 |
| Config Hygiene | 7/10 |
| Security | 2/10 |
| Production Readiness | 1/10 |
| Actually Functions End-to-End | 0/10 |

Four specific bugs made the system unable to cold-start or run:

1. **Runtime Bootstrap Paradox** — Supabase Auth is an MCP server, but you need Supabase Auth to access the dashboard that starts MCP servers. Circular dependency. Cannot cold-start.

2. **Cursorrules Enforcement Illusion** — `.cursorrules` is a flat text file with no enforcement. The agent that built the architecture violated it during the build (scaffolded SDK boilerplate before being stopped).

3. **Translation Fidelity Problem** — `bridge-router-mcp.json` claims to translate one config into 4 agent formats, but those formats have incompatible constraints. No actual translation code existed.

4. **Airtable-to-App Ghost** — Make.com was removed from the architecture but never replaced. `backbone-broadcast.json` describes a workflow with no trigger mechanism.

### The Fix

Four Python modules, zero external dependencies beyond stdlib, each solving one problem:

```
architecture/
├── __init__.py
├── bootstrap_resolver.py    ← Fixes #1: Circular auth dependency
├── bridge_router.py         ← Fixes #3: Config translation with fidelity tracking
├── backbone_trigger.py      ← Fixes #4: Airtable polling replaces Make.com
├── cursorrules_enforcer.py  ← Fixes #2: Runtime rule enforcement with pre-commit hook
└── canonical-config.json    ← The single source of truth for all agent configs
```

---

### 1. Bootstrap Resolver (`bootstrap_resolver.py`)

Breaks the circular auth dependency with a 3-phase cold-start:

```bash
# Phase 1: Bootstrap (uses service-role key, bypasses normal auth)
# Phase 2: Handoff (seals credentials, starts services)
# Phase 3: Steady State (normal auth takes over, bootstrap token revoked)

export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_SERVICE_ROLE_KEY="eyJ..."
python3 -m architecture.bootstrap_resolver

# After services are running normally:
python3 -m architecture.bootstrap_resolver --revoke <bootstrap-token>
```

### 2. Bridge Router (`bridge_router.py`)

Translates canonical config into 4 formats with fidelity tracking:

```bash
# Generate all 4 format configs + fidelity report
python3 -m architecture.bridge_router --config architecture/canonical-config.json --report

# Output shows exactly what's preserved, adapted, degraded, or dropped:
#   cursorrules:    83.3% fidelity (retrieval directives degraded)
#   claude_kb:     100.0% fidelity (supports everything)
#   chatgpt_system: 83.3% fidelity (retrieval directives degraded)
#   gemini_system:  83.3% fidelity (retrieval directives degraded)
```

### 3. Backbone Trigger (`backbone_trigger.py`)

Replaces Make.com with Python-native Airtable change detection:

```bash
# Poll Airtable every 30s, forward changes to webhooks
export AIRTABLE_TOKEN="pat..."
export AIRTABLE_BASE_ID="appXXXXXX"
python3 -m architecture.backbone_trigger \
    --tables Configurations Prompts \
    --webhook https://your-api.com/sync \
    --snapshots \
    --interval 30

# Single poll cycle (for testing)
python3 -m architecture.backbone_trigger --tables Configurations --once
```

### 4. Cursorrules Enforcer (`cursorrules_enforcer.py`)

Converts `.cursorrules` from suggestions into a commit gate:

```bash
# Scan the codebase for violations
python3 -m architecture.cursorrules_enforcer --scan ./src

# Scan only staged files (pre-commit mode)
python3 -m architecture.cursorrules_enforcer --pre-commit

# Install as git pre-commit hook (blocks violating commits)
python3 -m architecture.cursorrules_enforcer --install-hook

# JSON output for CI integration
python3 -m architecture.cursorrules_enforcer --scan . --json
```

---

### Linking This Repo in Cursor

If you're having trouble connecting this repository to Cursor:

1. **Open Cursor** on your machine
2. Go to **File > Open Folder** and select the cloned repo
3. For **Background Agents**: Go to `cursor.com/settings` > Cloud Agents and ensure your GitHub account is connected
4. For **MCP servers**: Add server configs in Cursor Settings > MCP (or in `.cursor/mcp.json` in the project root)
5. For **Secrets**: Add API keys at `cursor.com/settings` > Cloud Agents > Secrets (they inject as env vars)

### What Still Needs Human Action

| Item | Time Estimate | Why Only You Can Do It |
|---|---|---|
| List product on Gumroad | 30 min | Requires your Gumroad account |
| Get Supabase service-role key | 5 min | Requires your Supabase dashboard access |
| Get Airtable token | 5 min | Requires your Airtable account |
| Run bootstrap_resolver | 2 min | Needs the keys above |
| Execute marketing plan | Ongoing | 29 platforms documented, needs your voice |

### Repository Structure

This repo (`Gemini-discovers-Diamonds`) contains architecture tools and documentation. The actual Faceless Shorts product code lives in `OBHitting3/Faceless_Shorts`.

| Branch | What It Contains |
|---|---|
| `cursor/all-occurrences-replacement-46f6` (this) | Architecture fixes for the 4 critical issues |
| `cursor/project-outstanding-items-8f2a` | Full project audit, START-HERE.md |
| `cursor/faceless-yt-shorts-project-9e22` | Complete project info document |
| `cursor/iron-forge-cli-executable-*` | Iron Forge CLI tool |
| `cursor/strict-execution-mechanism-*` | Strict execution framework |
