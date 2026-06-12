"""TypedDict state for the LangGraph orchestrator."""

from __future__ import annotations

from typing import Any, Optional, TypedDict


class TwinState(TypedDict, total=False):
    run_id: str
    input_text: str  # transcribed or direct
    audio_path: Optional[str]

    intent: dict[str, Any]
    memory: list[dict[str, Any]]
    interpretation: dict[str, Any]
    confidence: float
    clarify_q: Optional[str]
    clarify_answer: Optional[str]

    plan: dict[str, Any]

    proposed_envelope: dict[str, Any]
    cac_score: dict[str, Any]
    approval_status: str  # 'pending'|'approved'|'rejected'|'revised'

    execution_result: dict[str, Any]
    verification: dict[str, Any]
    response: str
