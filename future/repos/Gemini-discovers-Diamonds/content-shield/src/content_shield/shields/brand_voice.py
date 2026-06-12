"""Shield that checks content against a brand voice profile."""

from __future__ import annotations

from content_shield.brand.profile import BrandProfile
from content_shield.schema import Content, Issue, Severity, ValidationResult
from content_shield.shields.base import BaseShield


class BrandVoiceShield(BaseShield):
    """Validates that content matches a brand's tone, voice, and terminology.

    The shield inspects the text for banned words, incorrect terminology,
    and (in a future version) AI-based tone analysis against the brand's
    declared voice attributes.
    """

    def __init__(self, brand_profile: BrandProfile) -> None:
        self._brand_profile = brand_profile

    @property
    def name(self) -> str:
        return "brand_voice"

    async def check(self, content: Content) -> ValidationResult:
        issues: list[Issue] = []
        text_lower = content.text.lower()

        # Check for banned words.
        for word in self._brand_profile.banned_words:
            if word.lower() in text_lower:
                issues.append(
                    Issue(
                        code="BRAND_BANNED_WORD",
                        message=f"Banned word detected: '{word}'",
                        severity=Severity.WARNING,
                    )
                )

        # Check for incorrect terminology.
        for wrong, correct in self._brand_profile.required_terminology.items():
            if wrong.lower() in text_lower:
                issues.append(
                    Issue(
                        code="BRAND_TERMINOLOGY",
                        message=f"Use '{correct}' instead of '{wrong}'",
                        severity=Severity.WARNING,
                    )
                )

        # TODO: AI-based tone/voice consistency analysis.

        passed = len(issues) == 0
        score = max(0.0, 1.0 - len(issues) * 0.15)
        return ValidationResult(
            passed=passed,
            shield_name=self.name,
            score=score,
            issues=issues,
            suggestions=[
                f"Align content with brand voice attributes: {', '.join(self._brand_profile.voice_attributes)}"
            ]
            if issues
            else [],
        )
