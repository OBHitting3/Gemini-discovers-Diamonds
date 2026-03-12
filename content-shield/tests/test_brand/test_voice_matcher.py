"""Tests for VoiceMatcher."""

import pytest

from content_shield.brand.profile import BrandProfile
from content_shield.brand.voice_matcher import VoiceMatcher


@pytest.fixture
def voice_matcher(sample_brand_profile):
    return VoiceMatcher(profile=sample_brand_profile)


class TestVoiceMatcherScore:
    """Tests for VoiceMatcher.score()."""

    def test_empty_text_scores_zero(self, voice_matcher):
        assert voice_matcher.score("") == 0.0
        assert voice_matcher.score("   ") == 0.0

    def test_clean_text_scores_above_zero(self, voice_matcher):
        score = voice_matcher.score(
            "We ensure our customers enjoy a great experience on our platform."
        )
        assert 0.0 < score <= 1.0

    def test_banned_word_reduces_score(self, voice_matcher):
        clean_score = voice_matcher.score("Our platform is excellent.")
        dirty_score = voice_matcher.score("Our cheap platform is excellent.")
        assert dirty_score < clean_score


class TestVoiceMatcherSuggest:
    """Tests for VoiceMatcher.suggest()."""

    def test_suggests_removing_banned_words(self, voice_matcher):
        suggestions = voice_matcher.suggest("This cheap product sucks.")
        assert any("banned" in s.lower() for s in suggestions)

    def test_suggests_terminology_fix(self, voice_matcher):
        suggestions = voice_matcher.suggest("Visit our website to see what users think.")
        assert any("Replace" in s for s in suggestions)

    def test_no_suggestions_for_perfect_text(self):
        profile = BrandProfile(name="Simple", voice_attributes=[], banned_words=[])
        matcher = VoiceMatcher(profile=profile)
        suggestions = matcher.suggest("Just a normal sentence.")
        assert suggestions == []
