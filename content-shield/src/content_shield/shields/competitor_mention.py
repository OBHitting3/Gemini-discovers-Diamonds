"""Shield that detects mentions of competitor names."""

from __future__ import annotations

import re

from content_shield.schema import Content, Issue, Severity, ValidationResult
from content_shield.shields.base import BaseShield

# Default severity mapping based on mention context.
_DEFAULT_SEVERITY = Severity.WARNING
_NEGATIVE_CONTEXT_SEVERITY = Severity.ERROR


class CompetitorMentionShield(BaseShield):
    """Detects references to competitor brands in content.

    Each competitor can be associated with an explicit severity level.
    If no severity is provided for a competitor, ``WARNING`` is used by
    default.

    Args:
        competitors: A list of competitor names to watch for.
        severity_map: Optional mapping of competitor name (lower-cased)
            to a ``Severity`` level.  Competitors not in the map default
            to ``Severity.WARNING``.
    """

    def __init__(
        self,
        competitors: list[str],
        severity_map: dict[str, Severity] | None = None,
    ) -> None:
        self._competitors = competitors
        self._severity_map = {k.lower(): v for k, v in (severity_map or {}).items()}

    @property
    def name(self) -> str:
        return "competitor_mention"

    async def check(self, content: Content) -> ValidationResult:
        issues: list[Issue] = []

        for competitor in self._competitors:
            pattern = re.compile(re.escape(competitor), re.IGNORECASE)
            for match in pattern.finditer(content.text):
                severity = self._severity_map.get(
                    competitor.lower(), _DEFAULT_SEVERITY
                )
                issues.append(
                    Issue(
                        code="COMPETITOR_MENTION",
                        message=f"Competitor mentioned: '{match.group()}'",
                        severity=severity,
                        span_start=match.start(),
                        span_end=match.end(),
                    )
                )

        passed = len(issues) == 0
        score = max(0.0, 1.0 - len(issues) * 0.2)
        return ValidationResult(
            passed=passed,
            shield_name=self.name,
            score=score,
            issues=issues,
            suggestions=["Remove or replace competitor references"] if issues else [],
        )
