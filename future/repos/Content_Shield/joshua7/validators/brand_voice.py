"""Brand Voice Scorer — scores content against a target brand-voice profile."""

from __future__ import annotations

import logging
import re
from typing import Any

from joshua7.models import Severity, ValidationFinding, ValidationResult
from joshua7.validators.base import BaseValidator

logger = logging.getLogger(__name__)

_TONE_PENALTY_WORDS: dict[str, list[str]] = {
    "professional": [
        "lol", "omg", "bruh", "gonna", "wanna", "kinda", "sorta",
        "tbh", "ngl", "fr fr", "yo", "dude", "bro",
    ],
    "casual": [
        "hereby", "aforementioned", "pursuant", "notwithstanding",
        "heretofore", "therein", "whereas",
    ],
}

_POSITIVE_SIGNALS = [
    re.compile(r"\b(?:we|our|us)\b", re.IGNORECASE),
    re.compile(r"\b(?:you|your)\b", re.IGNORECASE),
]


def _build_word_patterns(words: list[str]) -> list[tuple[str, re.Pattern[str]]]:
    """Build word-boundary regex patterns to avoid substring false positives."""
    pairs = []
    for w in words:
        if " " in w:
            pat = re.compile(re.escape(w), re.IGNORECASE)
        else:
            pat = re.compile(rf"\b{re.escape(w)}\b", re.IGNORECASE)
        pairs.append((w, pat))
    return pairs


class BrandVoiceScorer(BaseValidator):
    """Score content against a target tone and keyword list."""

    name = "brand_voice"

    def __init__(self, config: dict[str, Any] | None = None) -> None:
        super().__init__(config)
        self._target_score = self.config.get("brand_voice_target_score", 60.0)
        self._keywords = [k.lower() for k in self.config.get("brand_voice_keywords", [])]
        self._tone = self.config.get("brand_voice_tone", "professional")
        raw_words = _TONE_PENALTY_WORDS.get(self._tone, [])
        self._penalty_patterns = _build_word_patterns(raw_words)

    def validate(self, text: str) -> ValidationResult:
        findings: list[ValidationFinding] = []
        score = 70.0

        words = text.split()
        word_count = max(len(words), 1)

        penalty_count = 0
        for pw, pattern in self._penalty_patterns:
            matches = pattern.findall(text)
            occurrences = len(matches)
            if occurrences > 0:
                penalty_count += occurrences
                findings.append(
                    ValidationFinding(
                        validator_name=self.name,
                        severity=Severity.WARNING,
                        message=f"Off-tone word detected: '{pw}' ({occurrences}x)",
                        metadata={"word": pw, "count": occurrences},
                    )
                )

        score -= min(penalty_count * 5.0, 40.0)

        if self._keywords:
            keyword_hits = sum(
                1 for kw in self._keywords
                if re.search(rf"\b{re.escape(kw)}\b", text, re.IGNORECASE)
            )
            keyword_ratio = keyword_hits / len(self._keywords)
            score += keyword_ratio * 15.0

        signal_hits = 0
        for pattern in _POSITIVE_SIGNALS:
            signal_hits += len(pattern.findall(text))
        engagement_ratio = min(signal_hits / word_count, 0.15)
        score += engagement_ratio * 100.0

        score = max(0.0, min(100.0, score))
        passed = score >= self._target_score

        if not passed:
            findings.append(
                ValidationFinding(
                    validator_name=self.name,
                    severity=Severity.ERROR,
                    message=f"Brand voice score {score:.1f} below target {self._target_score}",
                    metadata={"score": score, "target": self._target_score},
                )
            )

        return ValidationResult(
            validator_name=self.name,
            passed=passed,
            score=round(score, 1),
            findings=findings,
        )
