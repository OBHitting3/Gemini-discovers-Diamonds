"""End-to-end API + envelope lifecycle test using FastAPI TestClient.

This exercises the entire approval flow without a running uvicorn:
  propose -> pending -> approve -> admin/queue -> executed -> events
"""

import os
import tempfile
from datetime import datetime, timezone

import pytest
from fastapi.testclient import TestClient

# Direct event DB to a temp file so tests are isolated.
_TMP_DB = tempfile.NamedTemporaryFile(prefix="kt_events_", suffix=".db", delete=False).name
os.environ["EVENT_DB_PATH"] = _TMP_DB

from karl_twin.actions.envelope import ActionEnvelope, ActionStatus, CACScore, RiskLevel
from karl_twin.api.main import app
from karl_twin.api.store import STORE


@pytest.fixture(autouse=True)
def _reset_store():
    STORE._actions.clear()
    STORE._clarify.clear()
    yield


def _envelope_payload():
    env = ActionEnvelope(
        action_type="file.write",
        risk_level=RiskLevel.LOW,
        cac_score=CACScore(HI=4.0, MC=2.0, EC=2.0, tier=1),
        reason="hello world test",
        tool="file.write",
        payload_preview="WRITE hello.txt",
        payload={"path": "hello.txt", "content": "hello world"},
    )
    return env, {"envelope": env.model_dump(mode="json")}


def test_propose_appears_in_pending():
    client = TestClient(app)
    env, body = _envelope_payload()
    r = client.post("/actions/propose", json=body)
    assert r.status_code == 201
    pending = client.get("/actions/pending").json()
    assert any(p["action_id"] == env.action_id for p in pending)


def test_approve_transitions_to_admin_queue():
    client = TestClient(app)
    env, body = _envelope_payload()
    client.post("/actions/propose", json=body)
    r = client.post(f"/actions/{env.action_id}/approve")
    assert r.status_code == 200
    queue = client.get("/admin/queue").json()
    assert any(p["action_id"] == env.action_id for p in queue)


def test_executed_marks_envelope_and_events_log():
    client = TestClient(app)
    env, body = _envelope_payload()
    client.post("/actions/propose", json=body)
    client.post(f"/actions/{env.action_id}/approve")
    r = client.post(f"/actions/{env.action_id}/executed",
                    json={"success": True, "result": {"path": "data/outputs/hello.txt"}})
    assert r.status_code == 200
    fetched = client.get(f"/actions/{env.action_id}").json()
    assert fetched["status"] == ActionStatus.EXECUTED.value
    assert fetched["executed_at"] is not None
    events = client.get("/admin/events").json()
    types = [e["event_type"] for e in events]
    assert "action.proposed" in types
    assert "action.approved" in types
    assert "action.executed" in types


def test_executed_twice_is_rejected():
    """Invariant #3: never re-execute."""
    client = TestClient(app)
    env, body = _envelope_payload()
    client.post("/actions/propose", json=body)
    client.post(f"/actions/{env.action_id}/approve")
    r1 = client.post(f"/actions/{env.action_id}/executed", json={"success": True})
    assert r1.status_code == 200
    r2 = client.post(f"/actions/{env.action_id}/executed", json={"success": True})
    assert r2.status_code == 409


def test_revise_then_approve():
    client = TestClient(app)
    env, body = _envelope_payload()
    client.post("/actions/propose", json=body)
    rv = client.post(f"/actions/{env.action_id}/revise", json={"revision_text": "make it 'goodbye world' instead"})
    assert rv.status_code == 200
    rv_state = client.get(f"/actions/{env.action_id}").json()
    assert rv_state["status"] == ActionStatus.REVISED.value
    assert rv_state["revision_note"] == "make it 'goodbye world' instead"
    ap = client.post(f"/actions/{env.action_id}/approve")
    assert ap.status_code == 200


def test_clarify_round_trip():
    client = TestClient(app)
    q = {
        "run_id": "00000000-0000-0000-0000-000000000001",
        "question": "Which file?",
        "asked_at": datetime.now(timezone.utc).isoformat(),
    }
    r = client.post("/clarify/propose", json=q)
    assert r.status_code == 200
    pending = client.get("/clarify/pending").json()
    assert any(p["run_id"] == q["run_id"] for p in pending)
    a = client.post(f"/clarify/{q['run_id']}/answer", json={"answer": "hello.txt"})
    assert a.status_code == 200
    pending2 = client.get("/clarify/pending").json()
    assert all(p["run_id"] != q["run_id"] for p in pending2)


def test_health():
    client = TestClient(app)
    r = client.get("/admin/health")
    assert r.status_code == 200
    assert r.json()["ok"] is True


def test_root_serves_ui():
    client = TestClient(app)
    r = client.get("/")
    assert r.status_code == 200
    assert "karl-twin" in r.text
    assert "Approve" in r.text
