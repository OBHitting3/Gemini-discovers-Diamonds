"""Shield that checks content against a brand voice profile."""

from __future__ import annotations

from content_shield.brand.profile import BrandProfile
from content_shield.brand.voice_matcher import VoiceMatcher
from content_shield.schema import Content, Issue, Severity, ValidationResult
from content_shield.shields.base import BaseShield

# Heuristic voice analysis is noisy on very short snippets (taglines, CTAs).
_MIN_CHARS_FOR_VOICE_CONSISTENCY = 80


class BrandVoiceShield(BaseShield):
    """Validates that content matches a brand's tone, voice, and terminology.

    The shield inspects the text for banned words, incorrect terminology,
    and heuristic voice-consistency hints (via :class:`VoiceMatcher`)
    against the brand's declared voice attributes.
    """

    def __init__(self, brand_profile: BrandProfile) -> None:
        self._brand_profile = brand_profile
        self._voice_matcher = VoiceMatcher(profile=brand_profile)

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

        # Heuristic tone/voice consistency: VoiceMatcher maps declared attributes
        # to indicator vocabulary and flags long-form copy that shows none of it.
        voice_hints: list[str] = []
        stripped = content.text.strip()
        if (
            len(stripped) >= _MIN_CHARS_FOR_VOICE_CONSISTENCY
            and self._brand_profile.voice_attributes
        ):
            for hint in self._voice_matcher.suggest(content.text):
                if hint.startswith("Consider adding"):
                    voice_hints.append(hint)
                    issues.append(
                        Issue(
                            code="BRAND_VOICE_CONSISTENCY",
                            message=hint,
                            severity=Severity.WARNING,
                        )
                    )

        passed = len(issues) == 0
        score = max(0.0, 1.0 - len(issues) * 0.15)
        suggestions: list[str] = []
        if issues:
            suggestions.append(
                "Align content with brand voice attributes: "
                f"{', '.join(self._brand_profile.voice_attributes)}"
            )
            suggestions.extend(voice_hints)
        return ValidationResult(
            passed=passed,
            shield_name=self.name,
            score=score,
            issues=issues,
            suggestions=suggestions,
        )
