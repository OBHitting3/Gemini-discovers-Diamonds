# AGENTS.md

## Cursor Cloud specific instructions

This repository contains two main components:

1. **Content Shield** (`/content-shield/`) — Python AI content validation framework (the primary testable product)
2. **Express test server** (root `server.js`) — Trivial Node.js HTTP server with `/hello` and `/add` endpoints
3. **Palm Springs Paradise** (root `src/`) — Roblox Luau game; **cannot be run/tested in a cloud VM** (requires Roblox Studio on Windows/macOS)

### Content Shield (Python)

- **Working directory**: `/workspace/content-shield/`
- **Python requirement**: `>=3.10` (system Python 3.12 works)
- **Build backend caveat**: `pyproject.toml` declares `setuptools.backends._legacy:_Backend` which does not exist in any setuptools version. `pip install -e .` will fail. Instead, install dependencies directly with: `pip install --user "pydantic>=2.0" "httpx>=0.25" "tenacity>=8.0" "structlog>=23.0" "pytest>=7.0" "pytest-asyncio>=0.21" "pytest-cov>=4.0" "ruff>=0.1" "mypy>=1.0"` and then use `PYTHONPATH=/workspace/content-shield/src:$PYTHONPATH` when running tests or scripts.
- **Commands** (all from `/workspace/content-shield/`, with `PYTHONPATH` set as above):
  - Lint: `ruff check src/ tests/` (pre-existing warnings; exits 1)
  - Tests: `pytest --cov=content_shield --cov-report=term-missing` (129 tests, all pass)
  - Type check: `mypy src/content_shield/` (pre-existing errors; exits 1)
  - Format: `ruff format src/ tests/`

### Express Server (Node.js)

- **Working directory**: `/workspace/`
- Run: `node server.js` (port 3000)
- Test endpoints: `curl http://localhost:3000/hello?name=World` and `curl "http://localhost:3000/add?a=3&b=5"`

### Key gotchas

- The `make dev` / `make install` targets in `content-shield/Makefile` fail due to the invalid build backend. Use direct `pip install` of deps instead.
- Always set `PYTHONPATH=/workspace/content-shield/src:$PYTHONPATH` before running pytest, ruff, or mypy from the content-shield directory to ensure the package is importable.
- Upgraded pip/setuptools are installed to `~/.local/` — ensure `$HOME/.local/bin` is on `PATH`.
