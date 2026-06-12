# karl-twin

Sovereign digital twin for Karl. Voice-driven, multi-agent, sandboxed, approval-gated, with persistent memory.

## Architecture (one-line)

`LISTEN → TRANSCRIBE → PARSE_INTENT → RETRIEVE_MEMORY → INTERPRET (confidence) → CLARIFY (if conf<0.7) → SCORE_CAC → PLAN → PROPOSE (Action Envelope) → APPROVAL_GATE (LangGraph interrupt + PostgresSaver) → EXECUTE (worker; E2B for risky, local for safe) → VERIFY → STORE_MEMORY → RESPOND`

## Non-negotiable invariants

1. The LLM never invokes tools. It only emits Action Envelopes.
2. Every action is wrapped (action_id, timestamp, action_type, risk_level, cac_score, reason, tool, payload_preview, requires_approval, expires_in_sec, executed_at).
3. The worker refuses to dispatch any envelope whose `executed_at` is non-null. Crash-replay safe.
4. Append-only SQLite event log with `PRAGMA journal_mode=WAL` on init.
5. INTERPRET returns a confidence score; below 0.7 routes to CLARIFY.
6. Kill switch: `python -m karl_twin.admin pause`.
7. No master credentials in LLM context, ever. Secrets are JIT-injected by the worker into the E2B sandbox by name only.

## Stack (locked)

| Layer | Tech |
|---|---|
| Orchestration | LangGraph 1.x |
| Reasoning | Claude Agent SDK + `anthropic` |
| Vector memory | Qdrant 1.12 (Docker, API-key-required) |
| Persistence | PostgreSQL 16 (Docker) for LangGraph PostgresSaver |
| Approval API | FastAPI bound to `0.0.0.0:8000` |
| STT | faster-whisper, GPU-accelerated on RTX 5090 |
| Code sandbox | E2B Code Interpreter |
| Network | Tailscale mesh + ACLs (default-deny) |
| Event log | SQLite WAL, append-only |
| Secrets | `.env` (gitignored), JIT rotation later |

## First run on Windows 11

> All commands assume PowerShell as Administrator.

```powershell
# 1. Install host prerequisites (winget): Docker Desktop + WSL2, Python 3.11,
#    git, ffmpeg, Tailscale, NVIDIA Container Toolkit verification.
Set-ExecutionPolicy -Scope Process Bypass
.\infra\scripts\bootstrap.ps1

# 2. Create venv, install Python deps, generate .env, start docker stack.
.\infra\scripts\install.ps1

# 3. Open .env and fill in:
#       ANTHROPIC_API_KEY = sk-ant-...
#       E2B_API_KEY       = e2b_...
#    (QDRANT_API_KEY and POSTGRES_PASSWORD were auto-generated.)

# 4. Start API + worker.
.\infra\scripts\start.ps1
```

The API prints its LAN URL on startup (e.g. `http://192.168.1.42:8000/`).

## Pixel setup

1. Install the Tailscale Android app, sign in to your tailnet.
2. Apply `infra/tailscale-acl.hujson` in the Tailscale admin console (replace any existing ACL or merge with your existing one).
3. Tag your Pixel as `tag:owner` and the karl-twin host as `tag:karl-twin`.
4. Open the LAN URL on the Pixel (Chrome). The approval UI is mobile-first and polls every 2 seconds.

## Kill switch

```powershell
python -m karl_twin.admin pause      # halts worker, leaves API running
python -m karl_twin.admin resume     # resumes worker
python -m karl_twin.admin status     # queue depth, last events
```

The pause flag is `data\.secrets\worker.paused`. Remove it manually if a process exits while paused.

## Smoke test

```powershell
python -m karl_twin "write a file that says hello world"
```

Expected sequence (also see `tests/test_smoke.py`):
1. Whisper passes through (text mode), or transcribes if `--audio` is provided.
2. Interpret returns confidence (≥ 0.7 expected for this prompt).
3. CAC scorer returns tier 1 (file.write inside `data\outputs\`).
4. Action Envelope POSTed to `/actions/propose`.
5. Pixel UI shows envelope with CAC tier badge.
6. Approve on Pixel.
7. Worker writes file to `data\outputs\`.
8. Event log records the full chain (`python -m karl_twin.admin status`).
9. Memory record logged (Qdrant write requires an embedder; v0.1 logs the would-be record).
10. CLI prints `Done.`

## Free local LLM mode

Karl can use Ollama instead of paid API keys for natural-language planning.
Install Ollama on the host, pull a local model, and set:

```bash
KARL_TWIN_PROVIDER=ollama
OLLAMA_BASE_URL=http://127.0.0.1:11434
OLLAMA_MODEL=qwen2.5:3b
```

Then start the API and worker as usual. The local model only proposes Action
Envelopes; execution still goes through the approval UI and worker.

## Voice mode

```powershell
python -m karl_twin --audio C:\path\to\note.wav
```

faster-whisper picks `large-v3` on `cuda:float16` by default. Override with env vars `WHISPER_MODEL`, `WHISPER_DEVICE`, `WHISPER_COMPUTE_TYPE`.

## Layout

```
karl-twin\
├── karl_twin\              # the Python package
│   ├── api\                # FastAPI service + static UI
│   ├── worker\             # async worker + tool handlers
│   ├── admin\              # kill switch CLI
│   ├── agents\             # ReasoningProvider abstraction
│   ├── actions\            # Action Envelope + CAC types
│   ├── cac\                # NIST-ALFUS-derived CAC tier scorer
│   ├── memory\             # Qdrant wrapper
│   ├── orchestration\      # LangGraph orchestrator + Whisper + E2B
│   └── identity\           # secrets loader / env generator
├── infra\
│   ├── docker\             # docker-compose.yml (Qdrant + Postgres)
│   ├── scripts\            # bootstrap / install / start (PowerShell)
│   └── tailscale-acl.hujson
├── data\                   # gitignored: outputs, qdrant, postgres, events.db, .secrets
├── tests\
├── .env.example
├── .gitignore
├── pyproject.toml
├── requirements.txt
└── README.md
```

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `QDRANT_API_KEY missing; refusing to connect` | `.env` not generated or empty | `python -m karl_twin.admin generate_env` then re-run |
| Docker Desktop won't start GPU container | NVIDIA Container Toolkit not enabled | Settings → Resources → WSL Integration → enable GPU; `wsl --shutdown`; restart Docker Desktop |
| Pixel can't reach LAN URL | Wi-Fi only | Connect Pixel to Tailscale; ensure ACL grants `tag:owner` → `tag:karl-twin:8000` |
| `executed_at not None` error in worker | Replay attempt after crash (invariant #3 working as designed) | Worker correctly skipped a duplicate; no action needed |
| `faster-whisper` import fails on 3.12 | Python version | Reinstall venv with Python 3.11 |
| Approval card shows `TIER 0 / TIER 1` even for a tiny task | CAC heuristics conservative by default | Edit `karl_twin/cac/scorer.py` baselines or swap in a learned scorer |
| LangGraph `interrupt()` doesn't pause | Compiled without checkpointer | Ensure Postgres is up; otherwise the code falls back to MemorySaver and logs `graph.postgres_unavailable` |

## What this Cloud Agent could not do

This codebase was generated by a Linux Cloud Agent. The agent could not:
- Install Docker Desktop / NVIDIA Container Toolkit / Tailscale on your Windows host.
- Pop interactive prompts for `ANTHROPIC_API_KEY` / `E2B_API_KEY`.
- Run the live smoke test against your RTX 5090.

`infra/scripts/bootstrap.ps1` + `install.ps1` + `start.ps1` are how you complete steps 1, 5, and 20 on your Windows machine.

## CAC tier reference

Adapted from NIST ALFUS SP 1011-I-2.0 (Autonomy Levels for Unmanned Systems, Framework Volume I).

| Tier | HI band | Behaviour |
|---|---|---|
| 0 | < 2 | Human in the loop on every step |
| 1 | 2–4 | Mandatory per-action human approval |
| 2 | 4–6 | Batch / policy approval, periodic review |
| 3 | 6–8 | Supervised autonomy with sampled review |
| 4 | 8–10 | Full autonomy in a proven narrow domain |
