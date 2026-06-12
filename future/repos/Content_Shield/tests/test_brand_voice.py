"""Tests for the Brand Voice Scorer."""

from joshua7.validators.brand_voice import BrandVoiceScorer


class TestBrandVoiceScorer:
    def test_professional_text_passes(self):
        v = BrandVoiceScorer()
        text = (
            "We are committed to delivering exceptional value to our customers. "
            "Our team works diligently to ensure your success."
        )
        result = v.validate(text)
        assert result.passed is True
        assert result.score is not None
        assert result.score >= 60.0

    def test_off_tone_penalized(self):
        v = BrandVoiceScorer()
        text = "lol bruh this is gonna be kinda sorta great tbh ngl fr fr dude"
        result = v.validate(text)
        assert result.score is not None
        assert result.score < 70.0

    def test_keyword_boost(self):
        v = BrandVoiceScorer(config={
            "brand_voice_keywords": ["innovation", "security", "trust"],
        })
        text = "Our innovation in security builds trust with every customer."
        result = v.validate(text)
        assert result.score is not None
        assert result.score >= 60.0

    def test_casual_tone_penalizes_formal(self):
        v = BrandVoiceScorer(config={"brand_voice_tone": "casual"})
        text = "Hereby the aforementioned party, pursuant to notwithstanding clauses."
        result = v.validate(text)
        assert len(result.findings) > 0

    def test_score_bounded(self):
        v = BrandVoiceScorer()
        result = v.validate("A" * 500)
        assert result.score is not None
        assert 0.0 <= result.score <= 100.0

    def test_returns_validator_name(self):
        v = BrandVoiceScorer()
        result = v.validate("Test content.")
        assert result.validator_name == "brand_voice"

    def test_no_false_positive_on_bro_in_broken(self):
        """Word boundary fix: 'bro' should not match inside 'broken'."""
        v = BrandVoiceScorer()
        result = v.validate("The broken system was repaired by our professional team.")
        off_tone_words = [f.metadata.get("word") for f in result.findings]
        assert "bro" not in off_tone_words

    def test_yo_does_not_match_your(self):
        """Word boundary fix: 'yo' should not match inside 'your'."""
        v = BrandVoiceScorer()
        result = v.validate("Your professional results exceed expectations.")
        off_tone_words = [f.metadata.get("word") for f in result.findings]
        assert "yo" not in off_tone_words

    def test_yo_matches_standalone(self):
        v = BrandVoiceScorer()
        result = v.validate("Yo check this out dude.")
        off_tone_words = [f.metadata.get("word") for f in result.findings]
        assert "yo" in off_tone_words
