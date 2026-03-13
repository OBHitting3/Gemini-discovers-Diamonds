"""Metrics models for content-shield."""

from __future__ import annotations

from pydantic import BaseModel, Field, computed_field


class ShieldMetrics(BaseModel):
    """Aggregated metrics for a single shield."""

    shield_name: str
    total_checks: int
    passed: int
    failed: int
    avg_latency_ms: float

    @computed_field  # type: ignore[prop-decorator]
    @property
    def error_rate(self) -> float:
        """Fraction of checks that failed."""
        if self.total_checks == 0:
            return 0.0
        return self.failed / self.total_checks

    @computed_field  # type: ignore[prop-decorator]
    @property
    def pass_rate(self) -> float:
        """Fraction of checks that passed."""
        if self.total_checks == 0:
            return 0.0
        return self.passed / self.total_checks


class ContentQualityScore(BaseModel):
    """Quality score for a piece of content."""

    overall_score: float = Field(ge=0, le=100)
    dimension_scores: dict[str, float] = Field(default_factory=dict)
    recommendations: list[str] = Field(default_factory=list)
