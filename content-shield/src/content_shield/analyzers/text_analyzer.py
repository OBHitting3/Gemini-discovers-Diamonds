"""Text analysis utilities for content-shield."""

from __future__ import annotations

import re
from dataclasses import dataclass


@dataclass(frozen=True)
class Span:
    """A span of text identified by start and end character offsets."""

    start: int
    end: int
    text: str


# Regex for splitting text into sentences.
_SENTENCE_RE = re.compile(r"[^.!?]*[.!?]+", re.DOTALL)

# Common passive-voice patterns: "be" auxiliary + optional adverb + past participle.
# Past participles are approximated as words ending in -ed, -en, -wn, -ht, -ng (irregular).
_PASSIVE_AUX = r"(?:am|is|are|was|were|be|been|being)"
_PAST_PARTICIPLE = r"[a-z]+(?:ed|en|wn|ht|ng)"
_PASSIVE_RE = re.compile(
    rf"\b({_PASSIVE_AUX})\s+(?:\w+\s+)?({_PAST_PARTICIPLE})\b",
    re.IGNORECASE,
)


class TextAnalyzer:
    """Regex-based text analysis for word count, sentence metrics, and passive voice detection."""

    # ------------------------------------------------------------------ #
    # Public API
    # ------------------------------------------------------------------ #

    @staticmethod
    def word_count(text: str) -> int:
        """Return the number of whitespace-delimited words in *text*."""
        return len(text.split())

    @staticmethod
    def sentence_count(text: str) -> int:
        """Return the number of sentences detected in *text*.

        Sentences are delimited by `.`, `!`, or `?`.  If the text contains
        no terminal punctuation, a single sentence is assumed when the text
        is non-empty.
        """
        sentences = _SENTENCE_RE.findall(text)
        if not sentences and text.strip():
            return 1
        return len(sentences)

    @classmethod
    def avg_sentence_length(cls, text: str) -> float:
        """Return the average number of words per sentence."""
        n_sentences = cls.sentence_count(text)
        if n_sentences == 0:
            return 0.0
        return cls.word_count(text) / n_sentences

    @staticmethod
    def keyword_density(text: str, keyword: str) -> float:
        """Return the density of *keyword* as a fraction of total words.

        The comparison is case-insensitive.  Returns ``0.0`` when the text
        is empty.
        """
        words = text.lower().split()
        if not words:
            return 0.0
        kw_lower = keyword.lower()
        count = sum(1 for w in words if w.strip(".,!?;:\"'()[]{}") == kw_lower)
        return count / len(words)

    @staticmethod
    def detect_passive_voice(text: str) -> list[Span]:
        """Return a list of :class:`Span` objects for passive-voice constructions found in *text*."""
        spans: list[Span] = []
        for match in _PASSIVE_RE.finditer(text):
            spans.append(Span(start=match.start(), end=match.end(), text=match.group()))
        return spans
