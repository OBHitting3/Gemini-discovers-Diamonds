# AGENTS.md

## Cursor Cloud specific instructions

### Repository layout

This workspace is **not** a single npm/pnpm monorepo. Three independent products share the tree:

| Product | Path | Stack |
|---------|------|--------|
| **AI Bridge Sync** (primary web app) | `/workspace` | Next.js 14, npm |
| **karl-twin** | `/workspace/karl-twin` | Python 3.12, FastAPI, LangGraph |
| **Palm Luxe Tycoon** | `/workspace/game/PalmLuxeTycoon` | Roblox Luau (Studio only) |

### AI Bridge Sync (default dev target)

- **Install:** `npm install` (from repo root).
- **Env:** Copy `.env.local.example` → `.env.local`. Omit `DASHBOARD_PASSWORD` to disable the login gate locally.
- **Dev server:** `npm run dev` → http://localhost:3000
- **Quality:** `npm run lint`, `npm run type-check`, `npm run build`
- **Core E2E (no external MCP):** `GET /api/health` (empty `MCP_SERVERS_JSON` returns healthy), then `POST /api/sync` with `globalContext` + `targets[]` (see `src/types/bridge-context.ts`). Sync history and audit log persist under `src/data/`.
- **MCP health checks** only run when `MCP_SERVERS_JSON` lists servers; each must be reachable separately.

### karl-twin

- **System deps:** `python3.12-venv` (Debian/Ubuntu) is required once per VM to create `.venv`.
- **Install:** `cd karl-twin && python3 -m venv .venv && .venv/bin/pip install -r requirements.txt`
- **Env:** Copy `.env.example` → `.env` and set Linux paths (e.g. `OUTPUT_DIR=/workspace/karl-twin/data/outputs`, `EVENT_DB_PATH=.../data/events.db`). Tier-A keyless flow does **not** need `ANTHROPIC_API_KEY`, E2B, or Docker.
- **Run (keyless Tier A):** Two processes — `.venv/bin/python -m karl_twin.api` (port **8000**) and `.venv/bin/python -m karl_twin.worker` (loads `.env` in both shells). Approval UI: http://127.0.0.1:8000/
- **Tests:** `cd karl-twin && .venv/bin/pytest tests/ -q --ignore=tests/test_smoke.py` (no Docker). Live smoke: `tests/test_smoke.py` with API + worker up and `KARL_TWIN_SMOKE=1`.
- **Docker (optional):** `docker compose --env-file .env -f infra/docker/docker-compose.yml up -d` for Qdrant (**6333**) and Postgres (**5432**); needed for full LLM/graph paths, not keyless file.write.

### Palm Luxe Tycoon

No Node/Python services in-repo; validate in Roblox Studio per `game/PalmLuxeTycoon/README.md`.

### Long-running processes

Use **tmux** (`tmux -f /exec-daemon/tmux.portal.conf`) for `npm run dev`, karl-twin API, and worker so sessions survive backgrounding.
