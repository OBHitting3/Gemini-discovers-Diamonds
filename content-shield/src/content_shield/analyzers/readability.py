"""Readability metrics for content-shield.

Implements the Flesch Reading Ease and Flesch-Kincaid Grade Level formulas.
"""

from __future__ import annotations

import re


# Simple vowel-group heuristic for syllable counting.
_VOWEL_GROUP_RE = re.compile(r"[aeiouy]+", re.IGNORECASE)

# Sentence-ending punctuation.
_SENTENCE_RE = re.compile(r"[^.!?]*[.!?]+", re.DOTALL)


class ReadabilityAnalyzer:
    """Compute Flesch readability scores for English text."""

    # ------------------------------------------------------------------ #
    # Syllable counting
    # ------------------------------------------------------------------ #

    @staticmethod
    def syllable_count(word: str) -> int:
        """Estimate the number of syllables in *word*.

        Uses a vowel-group heuristic with adjustments for silent-e and
        common suffixes.
        """
        word = word.lower().strip(".,!?;:\"'()[]{}").strip()
        if not word:
            return 0

        count = len(_VOWEL_GROUP_RE.findall(word))

        # Silent trailing 'e' (e.g. "make" -> 1 syllable, not 2).
        if word.endswith("e") and not word.endswith(("le", "ce", "se", "ge")):
            count = max(count - 1, 1)

        # Trailing "-ed" that is silent (e.g. "walked") — unless preceded
        # by 't' or 'd' where the -ed is pronounced.
        if word.endswith("ed") and len(word) > 3 and word[-3] not in "td":
            count = max(count - 1, 1)

        return max(count, 1)

    # ------------------------------------------------------------------ #
    # Internal helpers
    # ------------------------------------------------------------------ #

    @classmethod
    def _words(cls, text: str) -> list[str]:
        """Split *text* into a list of words."""
        return text.split()

    @classmethod
    def _sentence_count(cls, text: str) -> int:
        sentences = _SENTENCE_RE.findall(text)
        if not sentences and text.strip():
            return 1
        return len(sentences)

    @classmethod
    def _total_syllables(cls, words: list[str]) -> int:
        return sum(cls.syllable_count(w) for w in words)

    # ------------------------------------------------------------------ #
    # Public API
    # ------------------------------------------------------------------ #

    @classmethod
    def flesch_reading_ease(cls, text: str) -> float:
        """Compute the Flesch Reading Ease score.

        Formula::

            206.835
            - 1.015 * (total_words / total_sentences)
            - 84.6  * (total_syllables / total_words)

        Returns ``0.0`` for empty text.
        """
        words = cls._words(text)
        n_words = len(words)
        n_sentences = cls._sentence_count(text)

        if n_words == 0 or n_sentences == 0:
            return 0.0

        asl = n_words / n_sentences
        asw = cls._total_syllables(words) / n_words
        return 206.835 - 1.015 * asl - 84.6 * asw

    @classmethod
    def flesch_kincaid_grade(cls, text: str) -> float:
        """Compute the Flesch-Kincaid Grade Level.

        Formula::

            0.39  * (total_words / total_sentences)
            + 11.8 * (total_syllables / total_words)
            - 15.59

        Returns ``0.0`` for empty text.
        """
        words = cls._words(text)
        n_words = len(words)
        n_sentences = cls._sentence_count(text)

        if n_words == 0 or n_sentences == 0:
            return 0.0

        asl = n_words / n_sentences
        asw = cls._total_syllables(words) / n_words
        return 0.39 * asl + 11.8 * asw - 15.59
