"""Shield that identifies factual claims and flags unverifiable ones."""

from __future__ import annotations

import re

from content_shield.schema import Content, Issue, Severity, ValidationResult
from content_shield.shields.base import BaseShield

# Naive patterns that often indicate factual claims.
_CLAIM_PATTERNS: list[re.Pattern[str]] = [
    re.compile(r"\b\d+%\b", re.IGNORECASE),
    re.compile(r"\bstudies\s+show\b", re.IGNORECASE),
    re.compile(r"\baccording\s+to\b", re.IGNORECASE),
    re.compile(r"\bproven\b", re.IGNORECASE),
    re.compile(r"\bscientifically\b", re.IGNORECASE),
    re.compile(r"\bresearch\s+(shows|suggests|indicates)\b", re.IGNORECASE),
    re.compile(r"\b#?\d+\s+(in|worldwide|globally)\b", re.IGNORECASE),
    re.compile(r"\bguaranteed\b", re.IGNORECASE),
]


class FactualClaimsShield(BaseShield):
    """Scans content for factual claims and flags those that cannot be verified.

    Uses heuristic pattern matching to identify statistical claims,
    research references, and superlatives.  A future version will
    integrate with external fact-checking APIs.
    """

    @property
    def name(self) -> str:
        return "factual_claims"

    async def check(self, content: Content) -> ValidationResult:
        issues: list[Issue] = []

        for pattern in _CLAIM_PATTERNS:
            for match in pattern.finditer(content.text):
                issues.append(
                    Issue(
                        code="UNVERIFIED_CLAIM",
                        message=f"Potentially unverifiable claim: '{match.group()}'",
                        severity=Severity.WARNING,
                        span_start=match.start(),
                        span_end=match.end(),
                    )
                )

        # TODO: Integrate external fact-checking / source verification.

        passed = len(issues) == 0
        score = max(0.0, 1.0 - len(issues) * 0.1)
        return ValidationResult(
            passed=passed,
            shield_name=self.name,
            score=score,
            issues=issues,
            suggestions=["Provide citations for factual claims"] if issues else [],
        )
