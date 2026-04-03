# AGENTS.md

## Cursor Cloud specific instructions

### Repository overview

This repo contains two independent products:

1. **Express test server** (root `/workspace/`) — A trivial Express.js server (`server.js`) on port 3000 with intentionally buggy endpoints. Node.js deps are in `package.json` with `package-lock.json`.
2. **Content Shield** (`/workspace/content-shield/`) — A Python AI content quality validation framework. Source is in `content-shield/src/content_shield/`, tests in `content-shield/tests/`. Config is in `content-shield/pyproject.toml`.

There is also a Roblox Luau game (Palm Springs Paradise) under `src/`, which requires Roblox Studio and cannot be run in a headless cloud VM.

### Running services

- **Express server:** `node server.js` from repo root (port 3000). Test with `curl http://localhost:3000/hello?name=Test`.
- **Content Shield:** Python package, no long-running server. Used as a library / via tests.

### Python environment (content-shield)

The `pyproject.toml` has an **invalid build-backend** (`setuptools.backends._legacy:_Backend`). This means `pip install -e .` and `pip install .` will both fail. Instead, install dependencies manually and use `PYTHONPATH`:

```bash
cd /workspace/content-shield
source .venv/bin/activate
export PYTHONPATH=/workspace/content-shield/src:$PYTHONPATH
```

The venv is at `/workspace/content-shield/.venv`. All commands below assume it is activated.

### Key commands

| Task | Command | Working directory |
|------|---------|-------------------|
| Install Node deps | `npm install` | `/workspace` |
| Install Python deps | `pip install "pydantic>=2.0" "httpx>=0.25" "tenacity>=8.0" "structlog>=23.0" "pytest>=7.0" "pytest-asyncio>=0.21" "pytest-cov>=4.0" "ruff>=0.1" "mypy>=1.0"` | (with venv active) |
| Run Python tests | `PYTHONPATH=src:$PYTHONPATH pytest --cov=content_shield --cov-report=term-missing` | `/workspace/content-shield` |
| Run Python lint | `ruff check src/ tests/` | `/workspace/content-shield` |
| Run type check | `PYTHONPATH=src:$PYTHONPATH mypy src/content_shield/` | `/workspace/content-shield` |
| Start Express server | `node server.js` | `/workspace` |

### Pre-existing issues

- **Ruff lint:** 98 pre-existing lint errors (mostly F401 unused imports). These are in the existing code, not introduced by setup.
- **Mypy:** 59 pre-existing type errors. These are in the existing code.
- **Build backend:** `pyproject.toml` specifies `setuptools.backends._legacy:_Backend` which does not exist in any setuptools version. Workaround is manual dep install + PYTHONPATH.
