"""Terminology checking utilities for brand consistency."""

from __future__ import annotations

import re
from dataclasses import dataclass


@dataclass(frozen=True)
class TerminologyIssue:
    """A single terminology violation found in text.

    Attributes:
        wrong_term: The term that violates the brand terminology guide.
        correct_term: The approved replacement term.
        position: Character offset where the wrong term starts in the text.
    """

    wrong_term: str
    correct_term: str
    position: int


class TerminologyChecker:
    """Checks text against a brand terminology mapping and applies corrections.

    Args:
        terminology: Mapping of wrong terms to their correct replacements.
                     Keys are matched case-insensitively in the source text.
    """

    def __init__(self, terminology: dict[str, str]) -> None:
        self._terminology = terminology
        # Pre-compile patterns for each wrong term (case-insensitive, whole-word).
        self._patterns: list[tuple[re.Pattern[str], str, str]] = []
        for wrong, correct in terminology.items():
            pattern = re.compile(
                r"\b" + re.escape(wrong) + r"\b",
                re.IGNORECASE,
            )
            self._patterns.append((pattern, wrong, correct))

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def check(self, text: str) -> list[TerminologyIssue]:
        """Find all terminology violations in *text*.

        Returns a list of :class:`TerminologyIssue` instances sorted by their
        position in the text.  If a wrong term appears multiple times, each
        occurrence is reported separately.
        """
        issues: list[TerminologyIssue] = []
        for pattern, wrong, correct in self._patterns:
            for match in pattern.finditer(text):
                issues.append(
                    TerminologyIssue(
                        wrong_term=match.group(),
                        correct_term=correct,
                        position=match.start(),
                    )
                )
        issues.sort(key=lambda issue: issue.position)
        return issues

    def apply_corrections(self, text: str) -> str:
        """Return a copy of *text* with all wrong terms replaced by their
        correct counterparts.

        Replacements preserve the original casing style of the matched term
        when possible (all-lower, all-upper, or title-case).  If the casing
        does not fall into one of those categories the correct term is used
        as-is.
        """
        for pattern, _wrong, correct in self._patterns:
            text = pattern.sub(
                lambda m, c=correct: _match_case(m.group(), c),
                text,
            )
        return text


# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------

def _match_case(original: str, replacement: str) -> str:
    """Apply the casing style of *original* to *replacement*."""
    if original.isupper():
        return replacement.upper()
    if original.islower():
        return replacement.lower()
    if original.istitle():
        return replacement.title()
    return replacement
