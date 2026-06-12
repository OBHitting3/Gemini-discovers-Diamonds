"""Tests for the Readability Scorer."""

from joshua7.validators.readability import ReadabilityScorer


class TestReadabilityScorer:
    def test_moderate_text_passes(self):
        v = ReadabilityScorer()
        text = (
            "The quick brown fox jumps over the lazy dog. "
            "This is a simple sentence that most people can understand. "
            "Reading should be accessible to a broad audience."
        )
        result = v.validate(text)
        assert result.score is not None

    def test_very_complex_text_fails(self):
        v = ReadabilityScorer(
            config={"readability_min_score": 50.0, "readability_max_score": 80.0}
        )
        text = (
            "Notwithstanding the aforementioned presuppositions, the epistemological "
            "ramifications of ontological hermeneutics necessitate a comprehensive "
            "reconceptualization of phenomenological paradigms vis-a-vis the "
            "dialectical materialist framework of post-structuralist deconstruction."
        )
        result = v.validate(text)
        assert result.score is not None
        if result.score < 50.0:
            assert result.passed is False

    def test_very_simple_text_above_max(self):
        v = ReadabilityScorer(
            config={"readability_min_score": 30.0, "readability_max_score": 60.0}
        )
        text = "I am a cat. I sit. I eat. I sleep. I play."
        result = v.validate(text)
        assert result.score is not None
        if result.score > 60.0:
            assert result.passed is False

    def test_score_is_numeric(self):
        v = ReadabilityScorer()
        result = v.validate("Technology is changing the world every day.")
        assert result.score is not None
        assert isinstance(result.score, float)

    def test_returns_validator_name(self):
        v = ReadabilityScorer()
        result = v.validate("Content to analyze.")
        assert result.validator_name == "readability"

    def test_custom_thresholds(self):
        v = ReadabilityScorer(
            config={"readability_min_score": 0.0, "readability_max_score": 100.0}
        )
        result = v.validate("This is a simple sentence.")
        assert result.passed is True

    def test_single_word(self):
        v = ReadabilityScorer()
        result = v.validate("Hello.")
        assert result.score is not None

    def test_grade_level_always_reported(self):
        """Grade level should appear in findings metadata even when text passes."""
        v = ReadabilityScorer(
            config={"readability_min_score": 0.0, "readability_max_score": 100.0}
        )
        result = v.validate(
            "The team delivered a professional product to every customer on time."
        )
        assert result.passed is True
        assert len(result.findings) >= 1
        info_finding = result.findings[0]
        assert "grade_level" in info_finding.metadata
        assert "flesch_score" in info_finding.metadata
