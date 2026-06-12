"""Tests for TextAnalyzer."""

import pytest

from content_shield.analyzers.text_analyzer import TextAnalyzer


class TestTextAnalyzerWordCount:
    """Tests for word count functionality."""

    def test_word_count_simple(self):
        assert TextAnalyzer.word_count("hello world") == 2

    def test_word_count_empty(self):
        assert TextAnalyzer.word_count("") == 0

    def test_word_count_multiword(self):
        assert TextAnalyzer.word_count("one two three four five") == 5


class TestTextAnalyzerSentences:
    """Tests for sentence count and average length."""

    def test_sentence_count(self):
        assert TextAnalyzer.sentence_count("Hello. World. Done.") == 3

    def test_sentence_count_no_punctuation(self):
        assert TextAnalyzer.sentence_count("No punctuation here") == 1

    def test_sentence_count_empty(self):
        assert TextAnalyzer.sentence_count("") == 0

    def test_avg_sentence_length(self):
        text = "One two three. Four five six."
        avg = TextAnalyzer.avg_sentence_length(text)
        assert avg == pytest.approx(3.0)


class TestTextAnalyzerKeywordDensity:
    """Tests for keyword density."""

    def test_keyword_density(self):
        text = "python is great and python is fun"
        density = TextAnalyzer.keyword_density(text, "python")
        assert density == pytest.approx(2 / 7)

    def test_keyword_density_empty_text(self):
        assert TextAnalyzer.keyword_density("", "test") == 0.0


class TestTextAnalyzerPassiveVoice:
    """Tests for passive voice detection."""

    def test_detects_passive_voice(self):
        text = "The report was written by the team."
        spans = TextAnalyzer.detect_passive_voice(text)
        assert len(spans) >= 1

    def test_no_passive_voice(self):
        text = "The team wrote the report."
        spans = TextAnalyzer.detect_passive_voice(text)
        assert len(spans) == 0
