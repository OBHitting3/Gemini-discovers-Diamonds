"""Offline LangGraph wiring test.

Uses a stub ReasoningProvider so we don't depend on Anthropic. Validates:
  - INTERPRET below threshold routes to CLARIFY (invariant #5)
  - score_cac populates state with valid CACScore
  - PROPOSE_ACTION posts an envelope
  - APPROVAL_GATE blocks via interrupt() until decision is supplied
"""

import os
import pytest

# Skip cleanly if langgraph isn't installed in this env (CI offline guard).
langgraph = pytest.importorskip("langgraph")
from langgraph.checkpoint.memory import MemorySaver
from langgraph.types import Command

from karl_twin.agents.providers import ReasoningProvider, ReasoningRequest, ReasoningResult
from karl_twin.orchestration.graph import build_graph


class StubProvider(ReasoningProvider):
    def __init__(self, plan_action="file.write"):
        self.plan_action = plan_action
        self.calls = 0

    def reason(self, req: ReasoningRequest) -> ReasoningResult:
        self.calls += 1
        sys = req.system or ""
        if "parse a user's natural-language request" in sys:
            parsed = {"action_hint": self.plan_action, "summary": req.user, "confidence": 0.9}
        elif "interpret the user's request" in sys:
            parsed = {"goal": req.user, "needed_clarification": None, "confidence": 0.9}
        elif "planner" in sys:
            parsed = {
                "action_type": "file.write",
                "tool": "file.write",
                "payload": {"path": "hello.txt", "content": "hello world"},
                "reason": "user asked to write hello world",
                "risk_level": "low",
                "confidence": 0.95,
            }
        else:
            parsed = {"confidence": 0.9}
        return ReasoningResult(
            text="{}",
            parsed=parsed,
            confidence=parsed.get("confidence", 0.9),
            model="stub",
            tokens_in=10,
            tokens_out=10,
        )


def test_graph_pauses_at_approval_gate(tmp_path, monkeypatch):
    monkeypatch.setenv("OUTPUT_DIR", str(tmp_path))
    monkeypatch.setenv("CONFIDENCE_THRESHOLD", "0.7")
    # Avoid posting to a real API; we only care that the graph reaches the gate.
    import httpx
    real_post = httpx.Client.post

    def fake_post(self, url, *a, **kw):
        class R:
            status_code = 200
            def json(self): return {}
            def raise_for_status(self): pass
        return R()
    monkeypatch.setattr(httpx.Client, "post", fake_post)

    g = build_graph(provider=StubProvider()).compile(checkpointer=MemorySaver())
    cfg = {"configurable": {"thread_id": "t-1"}}
    g.invoke({"run_id": "t-1", "input_text": "write a file that says hello world"}, config=cfg)
    state = g.get_state(cfg)
    # Must be paused at approval_gate (or clarify, but interpret confidence is 0.9)
    assert state.next, "graph should have paused at an interrupt"
    interrupts = getattr(state, "interrupts", []) or []
    assert interrupts, "expected at least one pending interrupt"
    payload = interrupts[0].value
    assert isinstance(payload, dict)
    assert payload.get("kind") == "approval_required"
    env = payload["envelope"]
    assert env["action_type"] == "file.write"
    assert env["cac_score"]["tier"] in (0, 1)


def test_graph_routes_clarify_below_threshold(tmp_path, monkeypatch):
    monkeypatch.setenv("OUTPUT_DIR", str(tmp_path))
    monkeypatch.setenv("CONFIDENCE_THRESHOLD", "0.7")

    class LowConfProvider(StubProvider):
        def reason(self, req):
            res = super().reason(req)
            if "interpret the user's request" in (req.system or ""):
                res.parsed = {"goal": req.user, "needed_clarification": "What file?", "confidence": 0.3}
                res.confidence = 0.3
            return res

    import httpx
    monkeypatch.setattr(httpx.Client, "post", lambda *a, **kw: type("R", (), {
        "status_code": 200, "json": lambda self: {}, "raise_for_status": lambda self: None
    })())

    g = build_graph(provider=LowConfProvider()).compile(checkpointer=MemorySaver())
    cfg = {"configurable": {"thread_id": "t-2"}}
    g.invoke({"run_id": "t-2", "input_text": "do the thing"}, config=cfg)
    state = g.get_state(cfg)
    interrupts = getattr(state, "interrupts", []) or []
    assert interrupts, "low-confidence interpret should route to clarify and interrupt"
    payload = interrupts[0].value
    assert "clarify_q" in payload
