"""Voice matching engine for evaluating brand-voice alignment."""

from __future__ import annotations

import re
from typing import TYPE_CHECKING

from content_shield.brand.terminology import TerminologyChecker

if TYPE_CHECKING:
    from content_shield.brand.profile import BrandProfile


# ------------------------------------------------------------------
# Voice-attribute keyword banks
# ------------------------------------------------------------------
# Each attribute maps to a set of indicator words whose presence
# suggests the text exhibits that attribute.
_ATTRIBUTE_INDICATORS: dict[str, set[str]] = {
    "professional": {
        "therefore", "consequently", "furthermore", "regarding",
        "accordingly", "ensure", "implement", "facilitate",
    },
    "warm": {
        "welcome", "glad", "happy", "wonderful", "thank", "appreciate",
        "delighted", "pleased", "enjoy",
    },
    "friendly": {
        "hey", "hi", "awesome", "great", "love", "cool", "excited",
        "fun", "amazing",
    },
    "formal": {
        "hereby", "pursuant", "henceforth", "shall", "whereas",
        "notwithstanding", "respectfully", "esteemed",
    },
    "conversational": {
        "you", "your", "let's", "we're", "you're", "gonna", "hey",
        "basically", "actually", "honestly",
    },
    "authoritative": {
        "must", "critical", "essential", "imperative", "mandate",
        "require", "standard", "compliance",
    },
    "luxurious": {
        "exquisite", "bespoke", "curated", "exclusive", "refined",
        "artisan", "premium", "sophisticated", "elegant",
    },
    "technical": {
        "api", "sdk", "implementation", "configure", "parameter",
        "endpoint", "deploy", "initialize", "runtime",
    },
    "empathetic": {
        "understand", "feel", "support", "care", "concern", "help",
        "listen", "compassion",
    },
    "innovative": {
        "cutting-edge", "revolutionary", "breakthrough", "transform",
        "disrupt", "pioneer", "next-generation", "novel",
    },
}


class VoiceMatcher:
    """Evaluates how closely a piece of text matches a :class:`BrandProfile`.

    The matcher considers three dimensions:

    1. **Banned words** -- any banned word found reduces the score.
    2. **Terminology** -- incorrect terminology reduces the score.
    3. **Voice attributes** -- the presence of attribute-indicator words
       increases the score.

    Args:
        profile: The brand profile to evaluate against.
    """

    def __init__(self, profile: BrandProfile) -> None:
        self._profile = profile
        self._terminology_checker = TerminologyChecker(
            profile.required_terminology,
        )
        # Pre-compile banned-word patterns (case-insensitive, whole-word).
        self._banned_patterns = [
            re.compile(r"\b" + re.escape(w) + r"\b", re.IGNORECASE)
            for w in profile.banned_words
        ]

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def score(self, text: str) -> float:
        """Return a score in [0.0, 1.0] indicating how well *text* matches
        the brand voice.

        A score of 1.0 means perfect alignment; 0.0 means the text
        completely violates brand guidelines.
        """
        if not text.strip():
            return 0.0

        penalties: float = 0.0
        bonuses: float = 0.0
        words = set(re.findall(r"[a-z'\-]+", text.lower()))
        word_count = max(len(words), 1)

        # --- Banned words ------------------------------------------------
        banned_hits = sum(
            1 for p in self._banned_patterns if p.search(text)
        )
        # Each unique banned word penalises up to 0.15, capped at 0.6.
        penalties += min(banned_hits * 0.15, 0.6)

        # --- Terminology -------------------------------------------------
        issues = self._terminology_checker.check(text)
        # Each terminology issue penalises up to 0.10, capped at 0.4.
        penalties += min(len(issues) * 0.10, 0.4)

        # --- Voice attributes --------------------------------------------
        for attr in self._profile.voice_attributes:
            indicators = _ATTRIBUTE_INDICATORS.get(attr.lower(), set())
            if not indicators:
                continue
            hits = words & indicators
            # Ratio of indicator words found vs available.
            ratio = len(hits) / min(len(indicators), word_count)
            bonuses += min(ratio, 0.25)  # cap per attribute

        # Combine: start at a base of 0.5, add bonuses, subtract penalties.
        raw = 0.5 + bonuses - penalties
        return max(0.0, min(1.0, raw))

    def suggest(self, text: str) -> list[str]:
        """Return a list of actionable suggestions for improving *text*
        so it better matches the brand voice.
        """
        suggestions: list[str] = []

        # --- Banned words ------------------------------------------------
        for pattern in self._banned_patterns:
            match = pattern.search(text)
            if match:
                suggestions.append(
                    f"Remove banned word/phrase: '{match.group()}'."
                )

        # --- Terminology -------------------------------------------------
        issues = self._terminology_checker.check(text)
        for issue in issues:
            suggestions.append(
                f"Replace '{issue.wrong_term}' with '{issue.correct_term}'."
            )

        # --- Missing voice attributes ------------------------------------
        words = set(re.findall(r"[a-z'\-]+", text.lower()))
        for attr in self._profile.voice_attributes:
            indicators = _ATTRIBUTE_INDICATORS.get(attr.lower(), set())
            if not indicators:
                continue
            hits = words & indicators
            if not hits:
                examples = sorted(indicators)[:3]
                suggestions.append(
                    f"Consider adding language that sounds more {attr}. "
                    f"Examples: {', '.join(examples)}."
                )

        return suggestions
