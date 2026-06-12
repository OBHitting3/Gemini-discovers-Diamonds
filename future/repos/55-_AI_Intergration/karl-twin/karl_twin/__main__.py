"""CLI entrypoint.

  python -m karl_twin "<text>"
  python -m karl_twin --audio path/to/audio.wav
"""

from __future__ import annotations

import argparse
import sys
import time
import uuid
from typing import Optional

import httpx

from karl_twin.actions.envelope import ActionStatus
from karl_twin.api.event_log import EventLog, default_path
from karl_twin.identity import secrets as sec
from karl_twin.orchestration.graph import compile_with_postgres

sec.load()
EVENTS = EventLog(default_path())


def _run(text: str) -> int:
    run_id = str(uuid.uuid4())
    print(f"[run {run_id}] input: {text!r}", flush=True)

    graph = compile_with_postgres()
    config = {"configurable": {"thread_id": run_id}}

    state = {"run_id": run_id, "input_text": text}

    # Drive the graph through interrupts. Each invoke() returns when the
    # graph either completes or hits an interrupt(); we then resume by
    # supplying the interrupt's resume value.
    while True:
        out = graph.invoke(state, config=config)
        snapshot = graph.get_state(config)
        if not snapshot.next:
            # Graph completed.
            print(f"[run {run_id}] response: {out.get('response')}", flush=True)
            return 0

        # We're paused at an interrupt; figure out which one.
        interrupts = getattr(snapshot, "interrupts", None) or []
        if interrupts:
            kind_payload = interrupts[0].value
        else:
            kind_payload = {}
        kind = kind_payload.get("kind") if isinstance(kind_payload, dict) else None

        if kind == "approval_required":
            action_id = kind_payload["envelope"]["action_id"]
            print(f"[run {run_id}] awaiting approval for action {action_id}", flush=True)
            print(f"  Open the approval UI on your Pixel: http://<LAN-IP>:8000/", flush=True)
            status = _poll_action_status(action_id)
            from langgraph.types import Command
            graph.invoke(Command(resume={"status": status}), config=config)
            state = {}  # subsequent invokes resume from checkpoint
            continue

        # Default: clarify
        if "clarify_q" in kind_payload:
            answer = _poll_clarify_answer(run_id)
            from langgraph.types import Command
            graph.invoke(Command(resume=answer), config=config)
            state = {}
            continue

        # Unknown interrupt: bail.
        print(f"[run {run_id}] unknown interrupt: {kind_payload}", flush=True)
        return 2


def _poll_action_status(action_id: str, timeout_sec: int = 600) -> str:
    """Poll the API until the action moves out of 'proposed'/'revised'."""
    base = _api_base()
    deadline = time.time() + timeout_sec
    last = None
    while time.time() < deadline:
        try:
            r = httpx.get(f"{base}/actions/{action_id}", timeout=5.0)
            r.raise_for_status()
            j = r.json()
            last = j["status"]
            if last not in (ActionStatus.PROPOSED.value, ActionStatus.REVISED.value):
                return last
        except Exception:
            pass
        time.sleep(2.0)
    return last or "expired"


def _poll_clarify_answer(run_id: str, timeout_sec: int = 600) -> str:
    base = _api_base()
    deadline = time.time() + timeout_sec
    while time.time() < deadline:
        try:
            r = httpx.get(f"{base}/clarify/{run_id}/pending", timeout=5.0)
            if r.status_code == 200:
                j = r.json()
                if j.get("answered") and j.get("answer") is not None:
                    return j["answer"]
        except Exception:
            pass
        time.sleep(2.0)
    return ""


def _api_base() -> str:
    import os
    host = os.environ.get("KARL_TWIN_API_HOST", "127.0.0.1")
    if host == "0.0.0.0":
        host = "127.0.0.1"
    port = os.environ.get("KARL_TWIN_API_PORT", "8000")
    return f"http://{host}:{port}"


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(prog="karl_twin")
    p.add_argument("text", nargs="?", help="natural-language instruction")
    p.add_argument("--audio", help="path to an audio file to transcribe with faster-whisper")
    args = p.parse_args(argv)

    if not args.text and not args.audio:
        p.error("provide <text> or --audio <path>")

    text = args.text or ""
    if args.audio:
        from karl_twin.orchestration.whisper import WhisperTranscriber
        out = WhisperTranscriber().transcribe(args.audio)
        text = out["text"]
        print(f"[whisper] {out['language']} ({out['language_probability']:.2f}): {text!r}", flush=True)

    return _run(text)


if __name__ == "__main__":
    sys.exit(main())
