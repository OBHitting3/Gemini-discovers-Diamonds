"""Pydantic data models for Joshua 7."""

from __future__ import annotations

import uuid
from datetime import datetime, timezone
from enum import Enum
from typing import Any

from pydantic import BaseModel, Field

MAX_TEXT_LENGTH = 500_000


class Severity(str, Enum):
    """Severity level for a validation finding."""

    INFO = "info"
    WARNING = "warning"
    ERROR = "error"
    CRITICAL = "critical"


class ValidationFinding(BaseModel):
    """A single finding produced by a validator."""

    validator_name: str
    severity: Severity
    message: str
    span: tuple[int, int] | None = Field(
        default=None,
        description="Character offset (start, end) of the flagged region.",
    )
    metadata: dict[str, Any] = Field(default_factory=dict)


class ValidationResult(BaseModel):
    """Aggregated result from one validator."""

    validator_name: str
    passed: bool
    score: float | None = Field(
        default=None,
        description="Optional numeric score (0-100) from scoring validators.",
    )
    findings: list[ValidationFinding] = Field(default_factory=list)


class ValidationRequest(BaseModel):
    """Inbound request to validate content."""

    text: str = Field(
        ...,
        min_length=1,
        max_length=MAX_TEXT_LENGTH,
        description=f"Content to validate (max {MAX_TEXT_LENGTH:,} chars).",
    )
    validators: list[str] = Field(
        default=["all"],
        description='List of validator names to run, or ["all"].',
    )
    config_overrides: dict[str, Any] = Field(
        default_factory=dict,
        description="Per-request config overrides keyed by validator name.",
    )


class RiskAxis(BaseModel):
    """Score for a single axis of the RISK_TAXONOMY_v0."""

    axis: str
    label: str
    weight: float
    raw_score: float = Field(description="Raw axis score 0-100 (100 = maximum risk).")
    weighted_score: float = Field(description="raw_score * weight contribution.")


class RiskTaxonomy(BaseModel):
    """RISK_TAXONOMY_v0 composite risk assessment."""

    composite_risk_score: float = Field(
        default=0.0,
        ge=0.0,
        le=100.0,
        description="Weighted composite risk score (0.0–100.0).",
    )
    risk_level: str = Field(
        default="GREEN",
        description="GREEN (0-19) | YELLOW (20-49) | ORANGE (50-79) | RED (80-100).",
    )
    axes: list[RiskAxis] = Field(default_factory=list)


class ValidationResponse(BaseModel):
    """Outbound response from the validation engine."""

    request_id: str = Field(
        default_factory=lambda: uuid.uuid4().hex,
        description="Unique identifier for this validation run.",
    )
    timestamp: str = Field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat(),
        description="ISO-8601 UTC timestamp of this response.",
    )
    version: str = Field(default="", description="Engine version.")
    passed: bool = Field(description="True only if every validator passed.")
    results: list[ValidationResult] = Field(default_factory=list)
    risk: RiskTaxonomy = Field(default_factory=RiskTaxonomy)
    text_length: int = 0
    validators_run: int = 0
