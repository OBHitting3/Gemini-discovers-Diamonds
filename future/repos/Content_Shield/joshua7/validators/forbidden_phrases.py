"""Forbidden Phrase Detector — flags banned words/phrases in content."""

from __future__ import annotations

import logging
import re
from typing import Any

from joshua7.config import _DEFAULT_FORBIDDEN_PHRASES
from joshua7.models import Severity, ValidationFinding, ValidationResult
from joshua7.regex_guard import safe_finditer
from joshua7.validators.base import BaseValidator

logger = logging.getLogger(__name__)


class ForbiddenPhraseDetector(BaseValidator):
    """Scan content for forbidden/banned phrases."""

    name = "forbidden_phrases"

    def __init__(self, config: dict[str, Any] | None = None) -> None:
        super().__init__(config)
        phrases = self.config.get("forbidden_phrases", _DEFAULT_FORBIDDEN_PHRASES)
        self._phrases = [p.lower() for p in phrases]
        self._patterns = [re.compile(re.escape(p), re.IGNORECASE) for p in self._phrases]

    def validate(self, text: str) -> ValidationResult:
        findings: list[ValidationFinding] = []

        for pattern, phrase in zip(self._patterns, self._phrases):
            for match in safe_finditer(pattern, text):
                findings.append(
                    ValidationFinding(
                        validator_name=self.name,
                        severity=Severity.ERROR,
                        message=f"Forbidden phrase detected: '{phrase}'",
                        span=(match.start(), match.end()),
                        metadata={"phrase": phrase},
                    )
                )

        return ValidationResult(
            validator_name=self.name,
            passed=len(findings) == 0,
            findings=findings,
        )
