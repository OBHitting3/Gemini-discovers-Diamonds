"""LangGraph orchestrator for karl-twin.

Loop (per spec):
  parse_intent -> retrieve_memory -> interpret -> [clarify if conf<0.7] ->
  score_cac -> plan -> propose_action -> approval_gate(interrupt) ->
  execute -> verify -> store_memory -> respond

Persistence: PostgresSaver checkpoints state across the interrupt() pauses
so an approval that lands minutes later resumes exactly where the run
suspended. Postgres URL is read from env (POSTGRES_URL).
"""

from __future__ import annotations

import os
import time
import uuid
from typing import Any

import httpx
from langgraph.graph import END, START, StateGraph
from langgraph.types import interrupt

from karl_twin.actions.envelope import (
    ActionEnvelope,
    ActionStatus,
    CACScore,
    ClarifyQuestion,
    RiskLevel,
)
from karl_twin.agents.providers import (
    ReasoningProvider,
    ReasoningRequest,
    create_reasoning_provider,
)
from karl_twin.api.event_log import EventLog, default_path
from karl_twin.cac.scorer import score_action
from karl_twin.identity import secrets as sec
from karl_twin.orchestration.state import TwinState

sec.load()
EVENTS = EventLog(default_path())


def _api_base() -> str:
    host = os.environ.get("KARL_TWIN_API_HOST", "127.0.0.1")
    if host == "0.0.0.0":
        host = "127.0.0.1"
    port = os.environ.get("KARL_TWIN_API_PORT", "8000")
    return f"http://{host}:{port}"


# -------- nodes --------

def parse_intent(state: TwinState, *, provider: ReasoningProvider) -> TwinState:
    t0 = time.time()
    state.setdefault("run_id", str(uuid.uuid4()))
    text = state.get("input_text", "")
    EVENTS.log("node.start", run_id=state["run_id"], node="parse_intent")
    res = provider.reason(ReasoningRequest(
        system="You parse a user's natural-language request into a structured intent. Be concise and literal.",
        user=text,
        context={},
        json_schema={
            "type": "object",
            "required": ["action_hint", "summary", "confidence"],
            "properties": {
                "action_hint": {"type": "string", "description": "best-guess action_type, e.g. file.write"},
                "summary": {"type": "string"},
                "confidence": {"type": "number"},
            },
        },
    ))
    state["intent"] = res.parsed or {"action_hint": "respond", "summary": text, "confidence": 0.5}
    EVENTS.log(
        "node.end",
        run_id=state["run_id"],
        node="parse_intent",
        latency_ms=int((time.time() - t0) * 1000),
        model=res.model,
        tokens_in=res.tokens_in,
        tokens_out=res.tokens_out,
        confidence=res.confidence,
    )
    return state


def retrieve_memory(state: TwinState) -> TwinState:
    t0 = time.time()
    EVENTS.log("node.start", run_id=state["run_id"], node="retrieve_memory")
    # In v0.1 we keep memory retrieval no-op-safe (Qdrant may be unreachable
    # during initial smoke tests). The hook is wired so the planner will pick
    # up real memories once an embedder is configured.
    state["memory"] = []
    EVENTS.log(
        "node.end",
        run_id=state["run_id"],
        node="retrieve_memory",
        latency_ms=int((time.time() - t0) * 1000),
    )
    return state


def interpret(state: TwinState, *, provider: ReasoningProvider) -> TwinState:
    t0 = time.time()
    EVENTS.log("node.start", run_id=state["run_id"], node="interpret")
    res = provider.reason(ReasoningRequest(
        system=(
            "You interpret the user's request given the parsed intent and any retrieved memory. "
            "Return a structured interpretation and a calibrated confidence in [0,1]. "
            "Confidence below 0.7 will trigger a clarifying question loop."
        ),
        user=state.get("input_text", ""),
        context={"intent": state.get("intent"), "memory": state.get("memory", [])},
        json_schema={
            "type": "object",
            "required": ["goal", "needed_clarification", "confidence"],
            "properties": {
                "goal": {"type": "string"},
                "needed_clarification": {"type": ["string", "null"]},
                "confidence": {"type": "number"},
            },
        },
    ))
    parsed = res.parsed or {"goal": state.get("input_text", ""), "needed_clarification": None, "confidence": 0.5}
    state["interpretation"] = parsed
    state["confidence"] = float(parsed.get("confidence", res.confidence or 0.5))
    if parsed.get("needed_clarification"):
        state["clarify_q"] = str(parsed["needed_clarification"])
    EVENTS.log(
        "node.end",
        run_id=state["run_id"],
        node="interpret",
        latency_ms=int((time.time() - t0) * 1000),
        model=res.model,
        tokens_in=res.tokens_in,
        tokens_out=res.tokens_out,
        confidence=state["confidence"],
    )
    return state


def clarify(state: TwinState) -> TwinState:
    """Surface a clarifying question via the API and pause via interrupt()."""
    EVENTS.log("node.start", run_id=state["run_id"], node="clarify")
    q = ClarifyQuestion(
        run_id=state["run_id"],
        question=state.get("clarify_q") or "Could you clarify what you'd like me to do?",
    )
    try:
        with httpx.Client(timeout=5.0) as c:
            c.post(_api_base() + "/clarify/propose", json=q.model_dump(mode="json"))
    except Exception as e:
        EVENTS.log("clarify.api_error", run_id=state["run_id"], node="clarify", payload={"err": repr(e)})
    # interrupt() suspends the graph; resume payload becomes clarify_answer.
    answer = interrupt({"clarify_q": q.question, "run_id": state["run_id"]})
    state["clarify_answer"] = str(answer or "")
    state["input_text"] = (state.get("input_text", "") + "\n\nClarification: " + state["clarify_answer"]).strip()
    EVENTS.log("node.end", run_id=state["run_id"], node="clarify", payload={"answer": state["clarify_answer"]})
    return state


def score_cac(state: TwinState) -> TwinState:
    t0 = time.time()
    EVENTS.log("node.start", run_id=state["run_id"], node="score_cac")
    intent = state.get("intent", {})
    action_type = intent.get("action_hint", "respond")
    payload = state.get("plan", {}).get("payload", {}) if state.get("plan") else {}
    score = score_action(action_type, payload)
    state["cac_score"] = score.model_dump(mode="json")
    EVENTS.log(
        "node.end",
        run_id=state["run_id"],
        node="score_cac",
        latency_ms=int((time.time() - t0) * 1000),
        cac_tier=score.tier,
        cac_hi=score.HI,
        cac_mc=score.MC,
        cac_ec=score.EC,
    )
    return state


def plan(state: TwinState, *, provider: ReasoningProvider) -> TwinState:
    t0 = time.time()
    EVENTS.log("node.start", run_id=state["run_id"], node="plan")
    res = provider.reason(ReasoningRequest(
        system=(
            "You are the planner. Translate the interpretation into a concrete tool action. "
            "DO NOT execute anything. Emit only the tool name, action_type, payload, and a short reason. "
            "Allowed action_types: file.write, code.execute, respond. "
            "For file.write payload schema: {path: <relative under data/outputs>, content: <text>}. "
            "For code.execute payload schema: {code: <python>, language: 'python', timeout_sec: int}."
        ),
        user=state.get("input_text", ""),
        context={"interpretation": state.get("interpretation")},
        json_schema={
            "type": "object",
            "required": ["action_type", "tool", "payload", "reason", "risk_level", "confidence"],
            "properties": {
                "action_type": {"type": "string"},
                "tool": {"type": "string"},
                "payload": {"type": "object"},
                "reason": {"type": "string"},
                "risk_level": {"type": "string", "enum": ["low", "medium", "high", "critical"]},
                "confidence": {"type": "number"},
            },
        },
    ))
    p = res.parsed or {
        "action_type": "respond",
        "tool": "respond",
        "payload": {"text": state.get("input_text", "")},
        "reason": "fallback respond plan",
        "risk_level": "low",
        "confidence": 0.4,
    }
    state["plan"] = p
    EVENTS.log(
        "node.end",
        run_id=state["run_id"],
        node="plan",
        latency_ms=int((time.time() - t0) * 1000),
        model=res.model,
        tokens_in=res.tokens_in,
        tokens_out=res.tokens_out,
        confidence=res.confidence,
    )
    # Re-score CAC now that we have a real payload.
    cac = score_action(p["action_type"], p.get("payload", {}), context={"risk_level": p.get("risk_level")})
    state["cac_score"] = cac.model_dump(mode="json")
    return state


def propose_action(state: TwinState) -> TwinState:
    t0 = time.time()
    EVENTS.log("node.start", run_id=state["run_id"], node="propose_action")
    p = state["plan"]
    cac = CACScore.model_validate(state["cac_score"])
    payload = p.get("payload", {})
    preview = _make_preview(p["action_type"], payload)
    env = ActionEnvelope(
        action_type=p["action_type"],
        risk_level=RiskLevel(p.get("risk_level", "low")),
        cac_score=cac,
        reason=p.get("reason", ""),
        tool=p.get("tool", p["action_type"]),
        payload_preview=preview,
        payload=payload,
        run_id=state["run_id"],
    )
    try:
        with httpx.Client(timeout=5.0) as c:
            c.post(
                _api_base() + "/actions/propose",
                json={"envelope": env.model_dump(mode="json")},
            )
    except Exception as e:
        EVENTS.log("propose.api_error", run_id=state["run_id"], node="propose_action", payload={"err": repr(e)})
    state["proposed_envelope"] = env.model_dump(mode="json")
    EVENTS.log(
        "node.end",
        run_id=state["run_id"],
        node="propose_action",
        action_id=env.action_id,
        latency_ms=int((time.time() - t0) * 1000),
        cac_tier=cac.tier,
        cac_hi=cac.HI, cac_mc=cac.MC, cac_ec=cac.EC,
    )
    return state


def approval_gate(state: TwinState) -> TwinState:
    """Suspend the graph until the API marks the envelope approved/rejected."""
    EVENTS.log("node.start", run_id=state["run_id"], node="approval_gate",
               action_id=state["proposed_envelope"]["action_id"])
    decision = interrupt({
        "kind": "approval_required",
        "envelope": state["proposed_envelope"],
    })
    # decision is whatever the resume() call passes; expected: dict(status=...)
    if isinstance(decision, dict):
        state["approval_status"] = str(decision.get("status", "rejected"))
    else:
        state["approval_status"] = str(decision or "rejected")
    EVENTS.log("node.end", run_id=state["run_id"], node="approval_gate",
               payload={"approval_status": state["approval_status"]})
    return state


def execute(state: TwinState) -> TwinState:
    """Wait for the worker to confirm executed_at on the action."""
    t0 = time.time()
    EVENTS.log("node.start", run_id=state["run_id"], node="execute")
    action_id = state["proposed_envelope"]["action_id"]
    deadline = time.time() + 120.0
    last: dict[str, Any] = {}
    while time.time() < deadline:
        try:
            with httpx.Client(timeout=5.0) as c:
                r = c.get(_api_base() + f"/actions/{action_id}")
                r.raise_for_status()
                last = r.json()
                if last.get("executed_at") is not None:
                    break
        except Exception:
            pass
        time.sleep(1.0)
    state["execution_result"] = last
    EVENTS.log(
        "node.end",
        run_id=state["run_id"],
        node="execute",
        action_id=action_id,
        latency_ms=int((time.time() - t0) * 1000),
        payload={"status": last.get("status"), "error": last.get("error")},
    )
    return state


def verify(state: TwinState) -> TwinState:
    EVENTS.log("node.start", run_id=state["run_id"], node="verify")
    res = state.get("execution_result") or {}
    ok = res.get("status") == ActionStatus.EXECUTED.value and res.get("error") is None
    state["verification"] = {"ok": ok, "status": res.get("status"), "error": res.get("error")}
    EVENTS.log("node.end", run_id=state["run_id"], node="verify", payload=state["verification"])
    return state


def store_memory(state: TwinState) -> TwinState:
    t0 = time.time()
    EVENTS.log("node.start", run_id=state["run_id"], node="store_memory")
    # Stub: real Qdrant write requires an embedder; we log the record.
    EVENTS.log(
        "memory.would_write",
        run_id=state["run_id"],
        node="store_memory",
        payload={
            "content": state.get("interpretation", {}).get("goal") or state.get("input_text"),
            "provenance": f"run:{state['run_id']}",
            "approval_status": "approved" if state.get("verification", {}).get("ok") else "rejected",
            "cac_score": state.get("cac_score"),
        },
    )
    EVENTS.log(
        "node.end",
        run_id=state["run_id"],
        node="store_memory",
        latency_ms=int((time.time() - t0) * 1000),
    )
    return state


def respond(state: TwinState) -> TwinState:
    EVENTS.log("node.start", run_id=state["run_id"], node="respond")
    v = state.get("verification") or {}
    if v.get("ok"):
        state["response"] = "Done."
    else:
        state["response"] = f"I couldn't complete that: {v.get('error') or v.get('status')}"
    EVENTS.log("node.end", run_id=state["run_id"], node="respond",
               payload={"response": state["response"]})
    return state


# -------- helpers --------

def _make_preview(action_type: str, payload: dict[str, Any]) -> str:
    if action_type == "file.write":
        path = payload.get("path", "?")
        content = payload.get("content", "")
        return f"WRITE → {path}\n---\n{content[:300]}"
    if action_type == "code.execute":
        return f"RUN python (sandbox)\n---\n{(payload.get('code') or '')[:300]}"
    if action_type == "respond":
        return f"RESPOND\n{(payload.get('text') or '')[:300]}"
    return f"{action_type} :: {str(payload)[:300]}"


# -------- branching --------

def route_after_interpret(state: TwinState) -> str:
    threshold = float(os.environ.get("CONFIDENCE_THRESHOLD", "0.7"))
    return "clarify" if state.get("confidence", 0.0) < threshold else "score_cac"


def route_after_approval(state: TwinState) -> str:
    return "execute" if state.get("approval_status") == ActionStatus.APPROVED.value else "respond"


# -------- builder --------

def build_graph(provider: ReasoningProvider | None = None):
    provider = provider or create_reasoning_provider()

    g: StateGraph = StateGraph(TwinState)
    g.add_node("parse_intent", lambda s: parse_intent(s, provider=provider))
    g.add_node("retrieve_memory", retrieve_memory)
    g.add_node("interpret", lambda s: interpret(s, provider=provider))
    g.add_node("clarify", clarify)
    g.add_node("score_cac", score_cac)
    g.add_node("plan", lambda s: plan(s, provider=provider))
    g.add_node("propose_action", propose_action)
    g.add_node("approval_gate", approval_gate)
    g.add_node("execute", execute)
    g.add_node("verify", verify)
    g.add_node("store_memory", store_memory)
    g.add_node("respond", respond)

    g.add_edge(START, "parse_intent")
    g.add_edge("parse_intent", "retrieve_memory")
    g.add_edge("retrieve_memory", "interpret")
    g.add_conditional_edges("interpret", route_after_interpret,
                            {"clarify": "clarify", "score_cac": "score_cac"})
    g.add_edge("clarify", "interpret")
    g.add_edge("score_cac", "plan")
    g.add_edge("plan", "propose_action")
    g.add_edge("propose_action", "approval_gate")
    g.add_conditional_edges("approval_gate", route_after_approval,
                            {"execute": "execute", "respond": "respond"})
    g.add_edge("execute", "verify")
    g.add_edge("verify", "store_memory")
    g.add_edge("store_memory", "respond")
    g.add_edge("respond", END)

    return g


def compile_with_postgres():
    """Compile the graph with a PostgresSaver checkpointer.

    Falls back to MemorySaver if POSTGRES_URL is unreachable. The fallback
    is logged and is acceptable for first-run smoke tests; production must
    set up Postgres for crash-safe interrupts.
    """
    g = build_graph()
    pg_url = os.environ.get("POSTGRES_URL", "")
    if pg_url:
        try:
            from langgraph.checkpoint.postgres import PostgresSaver
            saver = PostgresSaver.from_conn_string(pg_url)
            saver.setup()
            return g.compile(checkpointer=saver)
        except Exception as e:
            EVENTS.log("graph.postgres_unavailable", node="compile", payload={"err": repr(e)})
    from langgraph.checkpoint.memory import MemorySaver
    return g.compile(checkpointer=MemorySaver())
