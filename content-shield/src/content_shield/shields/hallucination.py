"""Shield that detects potentially hallucinated content."""

from __future__ import annotations

from content_shield.schema import Content, Issue, Severity, ValidationResult
from content_shield.shields.base import BaseShield


class HallucinationShield(BaseShield):
    """Identifies content that may contain hallucinated information.

    This shield is intended to work with an AI verification agent that
    cross-references claims against trusted sources.  The current
    implementation is a stub that always passes; the real logic will be
    added once the agent infrastructure is in place.

    Args:
        confidence_threshold: Minimum confidence (0-1) required for a
            claim to be considered verified.  Claims below this
            threshold are flagged.
    """

    def __init__(self, confidence_threshold: float = 0.7) -> None:
        self._confidence_threshold = confidence_threshold

    @property
    def name(self) -> str:
        return "hallucination"

    async def check(self, content: Content) -> ValidationResult:
        issues: list[Issue] = []

        # TODO: Integrate AI agent for verification.
        #
        # Future implementation outline:
        #   1. Extract claims / assertions from content.text.
        #   2. Send each claim to the verification agent.
        #   3. For every claim whose confidence < self._confidence_threshold,
        #      append an Issue with code="POTENTIAL_HALLUCINATION".

        passed = len(issues) == 0
        score = 1.0 if passed else max(0.0, 1.0 - len(issues) * 0.15)
        return ValidationResult(
            passed=passed,
            shield_name=self.name,
            score=score,
            issues=issues,
            suggestions=["Verify flagged claims against trusted sources"]
            if issues
            else [],
        )
