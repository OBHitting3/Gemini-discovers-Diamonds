# Joshua 7

Pre-publication AI content validation. **Content Shield** — the gate between AI output and the public.

## Run locally

```bash
# Setup
cd /path/to/joshua7
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -e .

# CLI
j7 "Your content here."
# PASS

j7 "guaranteed results, contact us at test@example.com"
# FAIL
#   [forbidden_phrases] Found forbidden phrase: "guaranteed results"
#   [pii_scanner] Detected email address: test@example.com
```

## Run with Docker

```bash
# Build
docker build -t joshua7 .

# CLI
docker run --rm joshua7 j7 "Your content here"

# API server (local)
docker run -p 8000:8000 joshua7
# Then: curl -X POST http://localhost:8000/validate -H "Content-Type: application/json" -d '{"text":"your content"}'
```

## Deploy

**Render (free tier):** Push the repo to GitHub, then in [Render Dashboard](https://dashboard.render.com) create **New > Blueprint**, connect the repo, and deploy. The `render.yaml` defines a Docker web service with `/health` and `/validate` endpoints. Free tier spins down after inactivity.

**Railway:** Push the repo to GitHub, create a new project at [Railway](https://railway.app), add a GitHub service, point it at this repo. Railway auto-detects the Dockerfile. Set no extra config needed for the API; it listens on `PORT` automatically.

## Structure (MVP)

- `src/joshua7/core.py` — ValidationResult, run_validation
- `src/joshua7/cli.py` — `j7` CLI entry point
- `src/joshua7/api.py` — Flask API for deployment
- `src/joshua7/validators/` — forbidden_phrases, pii_scanner
- More validators (competitor, brand_voice, fact_claims) stack on next.
