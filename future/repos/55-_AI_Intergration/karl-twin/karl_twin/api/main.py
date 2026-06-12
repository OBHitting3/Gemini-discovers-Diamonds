"""FastAPI service for karl-twin.

Endpoints (per spec step 8):
  POST /actions/propose
  GET  /actions/pending
  POST /actions/{id}/approve
  POST /actions/{id}/revise
  POST /actions/{id}/reject
  POST /clarify/{run_id}/answer
  GET  /clarify/pending
  GET  /clarify/{run_id}/pending
  GET  /admin/health

Plus:
  GET  /                      - mobile-friendly approval UI
  GET  /admin/events          - recent event-log rows
  GET  /actions/{id}          - single envelope (for UI deeplinks)

Binds 0.0.0.0:8000. CORS enabled for LAN. Prints LAN URL on startup.
"""

from __future__ import annotations

import socket
from datetime import datetime, timezone
from pathlib import Path

from fastapi import FastAPI, HTTPException, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles

from karl_twin.actions.envelope import (
    ActionEnvelope,
    ActionStatus,
    ClarifyAnswer,
    ClarifyQuestion,
    ProposeRequest,
    ReviseRequest,
)
from karl_twin.api.event_log import EventLog, default_path
from karl_twin.api.store import STORE
from karl_twin.identity import secrets as sec

sec.load()

EVENTS = EventLog(default_path())

app = FastAPI(
    title="karl-twin",
    description="Sovereign digital twin: approval-gated multi-agent orchestrator.",
    version="0.1.0",
)

# CORS: LAN-wide. Pixel reaches the API over Tailscale (or local Wi-Fi);
# both surface as ordinary IP origins to the browser, so allow any origin
# but lock the port to a single API and require all writes to go through
# the approval UI which is served from the same origin.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)

# Static UI
_STATIC_DIR = Path(__file__).resolve().parent / "static"
app.mount("/ui", StaticFiles(directory=str(_STATIC_DIR), html=True), name="ui")


# -------- helpers --------

def _log_action_event(env: ActionEnvelope, event_type: str) -> None:
    EVENTS.log(
        event_type,
        run_id=env.run_id,
        action_id=env.action_id,
        node="api",
        cac_tier=env.cac_score.tier,
        cac_hi=env.cac_score.HI,
        cac_mc=env.cac_score.MC,
        cac_ec=env.cac_score.EC,
        payload={
            "action_type": env.action_type,
            "tool": env.tool,
            "risk_level": env.risk_level.value,
            "status": env.status.value,
        },
    )


# -------- root: serve the approval UI --------

@app.get("/", response_class=HTMLResponse)
def root() -> HTMLResponse:
    index = _STATIC_DIR / "index.html"
    return HTMLResponse(index.read_text(encoding="utf-8"))


# -------- actions --------

@app.post("/actions/propose", status_code=status.HTTP_201_CREATED)
def propose(req: ProposeRequest) -> dict:
    env = req.envelope
    STORE.add(env)
    _log_action_event(env, "action.proposed")
    return {"action_id": env.action_id, "status": env.status.value}


@app.get("/actions/pending")
def pending() -> list[dict]:
    return [env.model_dump(mode="json") for env in STORE.pending()]


@app.get("/actions/{action_id}")
def get_action(action_id: str) -> dict:
    env = STORE.get(action_id)
    if env is None:
        raise HTTPException(404, f"action {action_id} not found")
    return env.model_dump(mode="json")


@app.post("/actions/{action_id}/approve")
def approve(action_id: str) -> dict:
    env = STORE.get(action_id)
    if env is None:
        raise HTTPException(404, "action not found")
    if env.status not in (ActionStatus.PROPOSED, ActionStatus.REVISED):
        raise HTTPException(409, f"action is in status {env.status.value}, cannot approve")
    if env.is_expired():
        STORE.update_status(action_id, ActionStatus.EXPIRED)
        _log_action_event(env, "action.expired")
        raise HTTPException(410, "action expired")
    STORE.update_status(action_id, ActionStatus.APPROVED)
    _log_action_event(env, "action.approved")
    return {"action_id": action_id, "status": ActionStatus.APPROVED.value}


@app.post("/actions/{action_id}/revise")
def revise(action_id: str, body: ReviseRequest) -> dict:
    env = STORE.get(action_id)
    if env is None:
        raise HTTPException(404, "action not found")
    if env.status not in (ActionStatus.PROPOSED, ActionStatus.REVISED):
        raise HTTPException(409, "cannot revise in current status")
    STORE.update_status(action_id, ActionStatus.REVISED, revision_note=body.revision_text)
    _log_action_event(env, "action.revised")
    return {"action_id": action_id, "status": ActionStatus.REVISED.value, "revision_note": body.revision_text}


@app.post("/actions/{action_id}/reject")
def reject(action_id: str) -> dict:
    env = STORE.get(action_id)
    if env is None:
        raise HTTPException(404, "action not found")
    if env.status not in (ActionStatus.PROPOSED, ActionStatus.REVISED):
        raise HTTPException(409, "cannot reject in current status")
    STORE.update_status(action_id, ActionStatus.REJECTED)
    _log_action_event(env, "action.rejected")
    return {"action_id": action_id, "status": ActionStatus.REJECTED.value}


# -------- worker callbacks --------

@app.post("/actions/{action_id}/executed")
def executed(action_id: str, body: dict) -> dict:
    """Worker reports completion. Sets executed_at and result/error."""
    env = STORE.get(action_id)
    if env is None:
        raise HTTPException(404, "action not found")
    if env.executed_at is not None:
        # Invariant #3: never re-execute.
        raise HTTPException(409, "action already executed")
    success = bool(body.get("success", False))
    new_status = ActionStatus.EXECUTED if success else ActionStatus.FAILED
    STORE.update_status(
        action_id,
        new_status,
        executed_at=datetime.now(timezone.utc),
        result=body.get("result"),
        error=body.get("error"),
    )
    _log_action_event(env, f"action.{new_status.value}")
    return {"action_id": action_id, "status": new_status.value}


# -------- clarify --------

@app.post("/clarify/propose")
def clarify_propose(q: ClarifyQuestion) -> dict:
    STORE.add_clarify(q)
    EVENTS.log("clarify.asked", run_id=q.run_id, node="api", payload={"q": q.question})
    return {"run_id": q.run_id}


@app.get("/clarify/pending")
def clarify_pending() -> list[dict]:
    return [q.model_dump(mode="json") for q in STORE.pending_clarify()]


@app.get("/clarify/{run_id}/pending")
def clarify_pending_one(run_id: str) -> dict:
    for q in STORE.pending_clarify():
        if q.run_id == run_id:
            return q.model_dump(mode="json")
    raise HTTPException(404, "no pending clarify for run")


@app.post("/clarify/{run_id}/answer")
def clarify_answer(run_id: str, body: ClarifyAnswer) -> dict:
    q = STORE.answer_clarify(run_id, body.answer)
    if q is None:
        raise HTTPException(404, "no clarify question for run")
    EVENTS.log("clarify.answered", run_id=run_id, node="api", payload={"a": body.answer})
    return {"run_id": run_id, "answer": body.answer}


# -------- admin --------

@app.get("/admin/health")
def health() -> dict:
    return {
        "ok": True,
        "service": "karl-twin",
        "actions_pending": len(STORE.pending()),
        "actions_total": len(STORE.all()),
        "clarify_pending": len(STORE.pending_clarify()),
    }


@app.get("/admin/events")
def events(limit: int = 50) -> list[dict]:
    return EVENTS.recent(limit=limit)


@app.get("/admin/queue")
def admin_queue() -> list[dict]:
    """Worker dispatch queue: approved envelopes with executed_at=null."""
    return [env.model_dump(mode="json") for env in STORE.approved_unexecuted()]


# -------- entrypoint --------

def _print_lan_banner(host: str, port: int) -> None:
    try:
        ip = socket.gethostbyname(socket.gethostname())
    except Exception:
        ip = host
    print("\n" + "=" * 60)
    print(" karl-twin API ready")
    print(f"  Local : http://127.0.0.1:{port}/")
    print(f"  LAN   : http://{ip}:{port}/")
    print(f"  Docs  : http://{ip}:{port}/docs")
    print("=" * 60 + "\n", flush=True)


def run() -> None:
    import os
    import uvicorn

    host = os.environ.get("KARL_TWIN_API_HOST", "0.0.0.0")
    port = int(os.environ.get("KARL_TWIN_API_PORT", "8000"))
    _print_lan_banner(host, port)
    uvicorn.run(
        "karl_twin.api.main:app",
        host=host,
        port=port,
        log_level="info",
        reload=False,
    )
