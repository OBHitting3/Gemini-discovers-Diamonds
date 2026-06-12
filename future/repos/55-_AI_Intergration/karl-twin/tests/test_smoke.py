"""Live smoke test runner. Skipped unless KARL_TWIN_SMOKE=1.

Reproduces spec step 20: posts a file.write envelope to a running API,
auto-approves it via the API, and verifies the worker writes the file.

Requires:
  - API and worker running (.\\infra\\scripts\\start.ps1 on Windows)
  - .env populated with QDRANT/POSTGRES/ANTHROPIC/E2B values
  - OUTPUT_DIR set
"""

import os
import time
from datetime import datetime, timezone
from pathlib import Path

import httpx
import pytest

if os.environ.get("KARL_TWIN_SMOKE") != "1":
    pytest.skip("set KARL_TWIN_SMOKE=1 to run live smoke", allow_module_level=True)

from karl_twin.actions.envelope import ActionEnvelope, ActionStatus, CACScore, RiskLevel


def _api():
    host = os.environ.get("KARL_TWIN_API_HOST", "127.0.0.1")
    if host == "0.0.0.0":
        host = "127.0.0.1"
    return f"http://{host}:{os.environ.get('KARL_TWIN_API_PORT', '8000')}"


def test_full_chain():
    api = _api()

    env = ActionEnvelope(
        action_type="file.write",
        risk_level=RiskLevel.LOW,
        cac_score=CACScore(HI=3.0, MC=2.0, EC=2.0, tier=1),
        reason="smoke: hello world",
        tool="file.write",
        payload_preview="WRITE smoke.txt",
        payload={"path": "smoke.txt", "content": "hello world"},
    )
    r = httpx.post(f"{api}/actions/propose", json={"envelope": env.model_dump(mode="json")}, timeout=10)
    assert r.status_code == 201, r.text

    r = httpx.post(f"{api}/actions/{env.action_id}/approve", timeout=10)
    assert r.status_code == 200, r.text

    deadline = time.time() + 60
    final = None
    while time.time() < deadline:
        d = httpx.get(f"{api}/actions/{env.action_id}", timeout=5).json()
        if d["executed_at"] is not None:
            final = d
            break
        time.sleep(1)
    assert final is not None, "worker did not execute envelope within 60s"
    assert final["status"] == ActionStatus.EXECUTED.value
    out_path = Path(os.environ["OUTPUT_DIR"]) / "smoke.txt"
    assert out_path.exists()
    assert out_path.read_text(encoding="utf-8") == "hello world"

    events = httpx.get(f"{api}/admin/events?limit=200", timeout=5).json()
    types = [e["event_type"] for e in events if e.get("action_id") == env.action_id]
    assert "action.proposed" in types
    assert "action.approved" in types
    assert "worker.dispatch" in types
    assert "worker.executed" in types
    assert "action.executed" in types
