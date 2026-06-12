"""Action Envelope: the only object that crosses the LLM -> executor boundary.

Every proposed action is wrapped in an ActionEnvelope. The LLM never invokes
tools directly; it can only emit envelopes which the worker dispatches after
human approval (or batch policy approval for higher CAC tiers).
"""

from __future__ import annotations

import uuid
from datetime import datetime, timezone
from enum import Enum
from typing import Any, Optional

from pydantic import BaseModel, Field, field_validator


class RiskLevel(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class ActionStatus(str, Enum):
    PROPOSED = "proposed"
    APPROVED = "approved"
    REVISED = "revised"
    REJECTED = "rejected"
    EXECUTED = "executed"
    FAILED = "failed"
    EXPIRED = "expired"


class CACScore(BaseModel):
    """Capability and Autonomy Classification (CAC) score for a single action.

    Three axes per Alpha's adaptation of NIST ALFUS SP 1011-I-2.0:
      - HI: Human Independence  (0..10, higher = less human oversight needed)
      - MC: Mission Complexity  (0..10, higher = more complex objective)
      - EC: Environmental Complexity (0..10, higher = more uncertain context)

    Five tiers (0..4):
      tier 0/1: mandatory human approval
      tier 2/3: batch / policy approval
      tier 4  : autonomous in proven narrow domain
    """

    HI: float = Field(ge=0.0, le=10.0)
    MC: float = Field(ge=0.0, le=10.0)
    EC: float = Field(ge=0.0, le=10.0)
    tier: int = Field(ge=0, le=4)
    rationale: str = ""


class ActionEnvelope(BaseModel):
    """The wrapped proposal. Required by invariant #2."""

    action_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    action_type: str  # e.g. "file.write", "code.execute", "gmail.send"
    risk_level: RiskLevel
    cac_score: CACScore
    reason: str  # human-readable justification from the planner
    tool: str  # which executor handler will dispatch this
    payload_preview: str  # short string preview shown to approver
    payload: dict[str, Any] = Field(default_factory=dict)  # full args for the worker
    requires_approval: bool = True
    expires_in_sec: int = 600
    executed_at: Optional[datetime] = None  # set by worker on success
    status: ActionStatus = ActionStatus.PROPOSED
    revision_note: Optional[str] = None  # reviewer's revision text (if any)
    run_id: Optional[str] = None  # LangGraph run that proposed this
    result: Optional[dict[str, Any]] = None  # worker's result/output
    error: Optional[str] = None

    @field_validator("payload_preview")
    @classmethod
    def _truncate_preview(cls, v: str) -> str:
        # Keep previews short for mobile UI rendering.
        return v if len(v) <= 500 else v[:497] + "..."

    def is_replayable(self) -> bool:
        """Worker invariant #3: never dispatch an envelope already executed."""
        return self.executed_at is None

    def is_expired(self) -> bool:
        if self.executed_at is not None:
            return False
        age = (datetime.now(timezone.utc) - self.timestamp).total_seconds()
        return age > self.expires_in_sec


class ProposeRequest(BaseModel):
    """Body for POST /actions/propose."""

    envelope: ActionEnvelope


class ReviseRequest(BaseModel):
    """Body for POST /actions/{id}/revise."""

    revision_text: str


class ClarifyAnswer(BaseModel):
    """Body for POST /clarify/{run_id}/answer."""

    answer: str


class ClarifyQuestion(BaseModel):
    run_id: str
    question: str
    asked_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    answered: bool = False
    answer: Optional[str] = None
