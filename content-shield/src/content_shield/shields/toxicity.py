"""Shield that checks for toxic or offensive language."""

from __future__ import annotations

import re

from content_shield.schema import Content, Issue, Severity, ValidationResult
from content_shield.shields.base import BaseShield

# ------------------------------------------------------------------ #
# Lightweight keyword / pattern lists.  A production system would use #
# an ML classifier (e.g. Perspective API, a local transformer model) #
# rather than a static word list.                                     #
# ------------------------------------------------------------------ #

_DEFAULT_TOXIC_KEYWORDS: list[str] = [
    "idiot",
    "stupid",
    "moron",
    "loser",
    "dumb",
    "pathetic",
    "trash",
    "worthless",
    "disgusting",
    "hate",
]

_AGGRESSIVE_PATTERNS: list[re.Pattern[str]] = [
    re.compile(r"\byou\s+(are|r)\s+(an?\s+)?(idiot|moron|loser)\b", re.IGNORECASE),
    re.compile(r"\bshut\s+up\b", re.IGNORECASE),
    re.compile(r"\bgo\s+(to\s+)?hell\b", re.IGNORECASE),
    re.compile(r"\bkill\s+yourself\b", re.IGNORECASE),
]


class ToxicityShield(BaseShield):
    """Detects toxic or offensive language in content.

    Uses a combination of keyword matching and regex patterns.
    Custom keyword lists can be provided to extend or replace the
    defaults.

    Args:
        extra_keywords: Additional toxic keywords to check.
        replace_defaults: If ``True``, *extra_keywords* completely
            replaces the built-in list instead of extending it.
    """

    def __init__(
        self,
        extra_keywords: list[str] | None = None,
        replace_defaults: bool = False,
    ) -> None:
        if replace_defaults:
            self._keywords = list(extra_keywords or [])
        else:
            self._keywords = list(_DEFAULT_TOXIC_KEYWORDS)
            if extra_keywords:
                self._keywords.extend(extra_keywords)

    @property
    def name(self) -> str:
        return "toxicity"

    async def check(self, content: Content) -> ValidationResult:
        issues: list[Issue] = []
        text_lower = content.text.lower()

        # Keyword matching.
        for keyword in self._keywords:
            pattern = re.compile(r"\b" + re.escape(keyword) + r"\b", re.IGNORECASE)
            for match in pattern.finditer(content.text):
                issues.append(
                    Issue(
                        code="TOXIC_KEYWORD",
                        message=f"Potentially toxic language: '{match.group()}'",
                        severity=Severity.WARNING,
                        span_start=match.start(),
                        span_end=match.end(),
                    )
                )

        # Pattern matching for aggressive phrases.
        for pattern in _AGGRESSIVE_PATTERNS:
            for match in pattern.finditer(content.text):
                issues.append(
                    Issue(
                        code="TOXIC_PATTERN",
                        message=f"Aggressive language detected: '{match.group()}'",
                        severity=Severity.ERROR,
                        span_start=match.start(),
                        span_end=match.end(),
                    )
                )

        # TODO: Integrate ML-based toxicity classifier.

        passed = len(issues) == 0
        score = max(0.0, 1.0 - len(issues) * 0.2)
        return ValidationResult(
            passed=passed,
            shield_name=self.name,
            score=score,
            issues=issues,
            suggestions=["Revise language to remove toxic content"] if issues else [],
        )
