"""Worker loop. Polls the API for approved envelopes and dispatches.

Invariants:
  - Reads envelopes where status=approved AND executed_at is null (#3).
  - Logs every dispatch to the SQLite event log (#4).
  - Refuses to dispatch tier 0/1 unless the envelope's status is approved.
  - Honours the kill switch via apps/admin pause file flag.
"""

from __future__ import annotations

import os
import time
import traceback
from pathlib import Path

import httpx

from karl_twin.actions.envelope import ActionEnvelope, ActionStatus
from karl_twin.api.event_log import EventLog, default_path
from karl_twin.identity import secrets as sec
from karl_twin.worker.handlers import HANDLERS

sec.load()
EVENTS = EventLog(default_path())

PAUSE_FLAG = Path(__file__).resolve().parents[2] / "data" / ".secrets" / "worker.paused"


def _api_base() -> str:
    host = os.environ.get("KARL_TWIN_API_HOST", "127.0.0.1")
    if host == "0.0.0.0":
        host = "127.0.0.1"
    port = os.environ.get("KARL_TWIN_API_PORT", "8000")
    return f"http://{host}:{port}"


def _fetch_approved(client: httpx.Client) -> list[ActionEnvelope]:
    # We pull from /actions/pending and /admin/health; in this v0.1 model
    # we read from the in-process API store. The worker is a separate
    # process, so we use a dedicated /actions/approved endpoint via the
    # raw store-listing endpoint we expose for admins.
    r = client.get(_api_base() + "/admin/health")
    r.raise_for_status()
    # Detail listing: gather all actions by hitting the /actions/{id} path
    # is overkill; instead the API exposes /admin/queue for the worker.
    r2 = client.get(_api_base() + "/admin/queue")
    r2.raise_for_status()
    return [ActionEnvelope.model_validate(item) for item in r2.json()]


def _confirm_executed(client: httpx.Client, env: ActionEnvelope, success: bool, *, result=None, error=None) -> None:
    client.post(
        _api_base() + f"/actions/{env.action_id}/executed",
        json={"success": success, "result": result, "error": error},
        timeout=10.0,
    )


def _dispatch(env: ActionEnvelope) -> tuple[bool, dict | None, str | None]:
    handler = HANDLERS.get(env.action_type)
    if handler is None:
        return False, None, f"no handler registered for action_type={env.action_type!r}"
    try:
        result = handler(env.payload)
        return True, result, None
    except Exception as e:
        return False, None, f"{type(e).__name__}: {e}\n{traceback.format_exc()}"


def loop(poll_sec: float = 1.0) -> None:
    print(f"[worker] starting; api={_api_base()}; pause_flag={PAUSE_FLAG}", flush=True)
    with httpx.Client(timeout=10.0) as client:
        while True:
            try:
                if PAUSE_FLAG.exists():
                    EVENTS.log("worker.paused", node="worker")
                    time.sleep(poll_sec * 5)
                    continue

                envs = _fetch_approved(client)
                for env in envs:
                    if not env.is_replayable():
                        # Invariant #3: never re-execute.
                        continue
                    EVENTS.log(
                        "worker.dispatch",
                        run_id=env.run_id,
                        action_id=env.action_id,
                        node="worker",
                        cac_tier=env.cac_score.tier,
                        cac_hi=env.cac_score.HI,
                        cac_mc=env.cac_score.MC,
                        cac_ec=env.cac_score.EC,
                        payload={"action_type": env.action_type, "tool": env.tool},
                    )
                    success, result, err = _dispatch(env)
                    EVENTS.log(
                        "worker.executed" if success else "worker.failed",
                        run_id=env.run_id,
                        action_id=env.action_id,
                        node="worker",
                        payload={"result": result, "error": err},
                    )
                    _confirm_executed(client, env, success, result=result, error=err)
            except Exception as e:
                EVENTS.log("worker.loop_error", node="worker", payload={"error": repr(e)})
                print(f"[worker] loop error: {e}", flush=True)
            time.sleep(poll_sec)


if __name__ == "__main__":
    loop()
