"""Shield that ensures content sentiment matches a target."""

from __future__ import annotations

import re

from content_shield.schema import Content, Issue, Severity, ValidationResult
from content_shield.shields.base import BaseShield

# ------------------------------------------------------------------ #
# Minimal keyword-based sentiment heuristic.  A real implementation  #
# would use an NLP model (e.g. VADER, TextBlob, or a transformer).  #
# ------------------------------------------------------------------ #

_POSITIVE_WORDS: set[str] = {
    "amazing", "awesome", "beautiful", "best", "brilliant", "celebrate",
    "cheerful", "confident", "delightful", "excellent", "exciting",
    "fantastic", "friendly", "glad", "good", "great", "happy", "helpful",
    "incredible", "joy", "love", "magnificent", "nice", "outstanding",
    "perfect", "pleasant", "positive", "remarkable", "satisfied",
    "success", "superb", "terrific", "thankful", "thrilled", "tremendous",
    "wonderful",
}

_NEGATIVE_WORDS: set[str] = {
    "angry", "annoying", "awful", "bad", "boring", "broken", "confusing",
    "cruel", "dangerous", "depressing", "difficult", "disappointing",
    "disgusting", "dreadful", "fail", "frustrating", "gloomy", "hate",
    "horrible", "hostile", "hurt", "irritating", "lousy", "miserable",
    "nasty", "negative", "painful", "poor", "problem", "regret", "sad",
    "scary", "terrible", "tragic", "ugly", "unhappy", "unpleasant",
    "upset", "worse", "worst",
}

_WORD_RE = re.compile(r"\b[a-z]+\b")


def _estimate_sentiment(text: str) -> str:
    """Return ``'positive'``, ``'negative'``, or ``'neutral'``."""
    words = _WORD_RE.findall(text.lower())
    pos = sum(1 for w in words if w in _POSITIVE_WORDS)
    neg = sum(1 for w in words if w in _NEGATIVE_WORDS)
    if pos > neg:
        return "positive"
    if neg > pos:
        return "negative"
    return "neutral"


class SentimentShield(BaseShield):
    """Validates that the overall sentiment of content matches a target.

    Args:
        target_sentiment: The desired sentiment -- ``'positive'``,
            ``'negative'``, or ``'neutral'``.
    """

    VALID_SENTIMENTS = {"positive", "negative", "neutral"}

    def __init__(self, target_sentiment: str = "positive") -> None:
        if target_sentiment not in self.VALID_SENTIMENTS:
            raise ValueError(
                f"target_sentiment must be one of {self.VALID_SENTIMENTS}, "
                f"got '{target_sentiment}'"
            )
        self._target = target_sentiment

    @property
    def name(self) -> str:
        return "sentiment"

    async def check(self, content: Content) -> ValidationResult:
        detected = _estimate_sentiment(content.text)
        issues: list[Issue] = []

        if detected != self._target:
            issues.append(
                Issue(
                    code="SENTIMENT_MISMATCH",
                    message=(
                        f"Content sentiment is '{detected}', "
                        f"expected '{self._target}'"
                    ),
                    severity=Severity.WARNING,
                )
            )

        passed = len(issues) == 0
        score = 1.0 if passed else 0.5
        return ValidationResult(
            passed=passed,
            shield_name=self.name,
            score=score,
            issues=issues,
            suggestions=[
                f"Adjust content tone to be more {self._target}"
            ]
            if issues
            else [],
        )
