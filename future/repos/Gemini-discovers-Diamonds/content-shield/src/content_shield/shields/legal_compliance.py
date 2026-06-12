"""Shield that checks content for legal compliance."""

from __future__ import annotations

from typing import Any

from content_shield.schema import Content, Issue, Severity, ValidationResult
from content_shield.shields.base import BaseShield


class LegalComplianceShield(BaseShield):
    """Ensures content meets configurable legal compliance rules.

    Rules are provided as a dictionary with two optional keys:

    * ``required_disclaimers`` -- a list of strings that **must** appear
      somewhere in the content text.
    * ``forbidden_claims`` -- a list of strings that **must not** appear
      in the content text.

    Example ``rules``::

        {
            "required_disclaimers": [
                "Results may vary",
                "Not financial advice",
            ],
            "forbidden_claims": [
                "FDA approved",
                "cures cancer",
            ],
        }
    """

    def __init__(self, rules: dict[str, Any] | None = None) -> None:
        self._rules = rules or {}

    @property
    def name(self) -> str:
        return "legal_compliance"

    async def check(self, content: Content) -> ValidationResult:
        issues: list[Issue] = []
        text_lower = content.text.lower()

        # Check required disclaimers.
        for disclaimer in self._rules.get("required_disclaimers", []):
            if disclaimer.lower() not in text_lower:
                issues.append(
                    Issue(
                        code="MISSING_DISCLAIMER",
                        message=f"Required disclaimer missing: '{disclaimer}'",
                        severity=Severity.ERROR,
                    )
                )

        # Check forbidden claims.
        for claim in self._rules.get("forbidden_claims", []):
            if claim.lower() in text_lower:
                issues.append(
                    Issue(
                        code="FORBIDDEN_CLAIM",
                        message=f"Forbidden claim detected: '{claim}'",
                        severity=Severity.CRITICAL,
                    )
                )

        passed = len(issues) == 0
        score = max(0.0, 1.0 - len(issues) * 0.2)
        return ValidationResult(
            passed=passed,
            shield_name=self.name,
            score=score,
            issues=issues,
            suggestions=["Review content for legal compliance"] if issues else [],
        )
