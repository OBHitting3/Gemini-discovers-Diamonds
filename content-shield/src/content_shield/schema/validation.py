"""Validation result models for content-shield."""

from __future__ import annotations

from typing import Optional

from pydantic import BaseModel, Field, computed_field

from content_shield.schema.event import Severity


class Issue(BaseModel):
    """A specific issue found during validation."""

    code: str
    message: str
    severity: Severity
    span_start: Optional[int] = None
    span_end: Optional[int] = None


class ValidationResult(BaseModel):
    """Result of a single shield validation pass."""

    passed: bool
    shield_name: str
    score: float = Field(ge=0, le=1)
    issues: list[Issue] = Field(default_factory=list)
    suggestions: list[str] = Field(default_factory=list)


class ValidationSummary(BaseModel):
    """Aggregate summary across multiple validation results."""

    results: list[ValidationResult]

    @computed_field  # type: ignore[prop-decorator]
    @property
    def passed(self) -> bool:
        """True only if every individual result passed."""
        return all(r.passed for r in self.results)

    @computed_field  # type: ignore[prop-decorator]
    @property
    def total_issues(self) -> int:
        """Total number of issues across all results."""
        return sum(len(r.issues) for r in self.results)

    @computed_field  # type: ignore[prop-decorator]
    @property
    def average_score(self) -> float:
        """Mean score across all results."""
        if not self.results:
            return 0.0
        return sum(r.score for r in self.results) / len(self.results)
