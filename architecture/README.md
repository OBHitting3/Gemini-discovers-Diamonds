# PSP Architecture — Shared Infrastructure

These modules provide the shared infrastructure layer for the Palm Springs Paradise ecosystem (game + content pipeline + external services).

They were built to fix four critical issues identified by a multi-LLM architecture audit.

## Modules

### 1. Bootstrap Resolver (`bootstrap_resolver.py`)

**Problem:** Supabase Auth is an MCP server, but the dashboard that starts MCP servers requires Supabase Auth. Circular dependency -- cannot cold-start.

**Solution:** 3-phase cold-start using the Supabase service-role key.

```bash
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_SERVICE_ROLE_KEY="eyJ..."
python3 -m architecture.bootstrap_resolver

# After steady state:
python3 -m architecture.bootstrap_resolver --revoke <token>
```

### 2. Bridge Router (`bridge_router.py`)

**Problem:** Config translation between .cursorrules, Claude KB, ChatGPT, and Gemini formats silently loses capabilities. No translation code existed.

**Solution:** Format-specific adapters with fidelity tracking.

```bash
python3 -m architecture.bridge_router --config architecture/canonical-config.json --report
```

### 3. Backbone Trigger (`backbone_trigger.py`)

**Problem:** Make.com was removed from the architecture but never replaced. Airtable (source of truth) has no trigger mechanism to propagate changes.

**Solution:** Python-native Airtable polling with content-hash change detection.

```bash
export AIRTABLE_TOKEN="pat..."
export AIRTABLE_BASE_ID="appXXXXXX"
python3 -m architecture.backbone_trigger --tables Configurations Prompts --interval 30
```

### 4. Cursorrules Enforcer (`cursorrules_enforcer.py`)

**Problem:** `.cursorrules` is an honor system. The agent that built the architecture violated it during the build itself.

**Solution:** Runtime scanner + git pre-commit hook that blocks violating commits.

```bash
python3 -m architecture.cursorrules_enforcer --scan ./src
python3 -m architecture.cursorrules_enforcer --install-hook
```

## Canonical Config

`canonical-config.json` defines 12 directives covering architecture, security, reliability, and business rules. The bridge router translates these into format-specific configs for each AI agent platform.
