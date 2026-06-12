"""Tests for SentimentShield."""

import pytest

from content_shield.schema import Content, ContentType
from content_shield.shields.sentiment import SentimentShield


class TestSentimentShield:
    """Tests for the SentimentShield.check() method."""

    @pytest.mark.asyncio
    async def test_positive_content_matches_positive_target(self):
        shield = SentimentShield(target_sentiment="positive")
        content = Content(
            text="This is an amazing and wonderful product that brings joy.",
            content_type=ContentType.MARKETING,
        )
        result = await shield.check(content)
        assert result.passed is True
        assert result.shield_name == "sentiment"

    @pytest.mark.asyncio
    async def test_negative_content_fails_positive_target(self):
        shield = SentimentShield(target_sentiment="positive")
        content = Content(
            text="This is a terrible and horrible experience. Very disappointing.",
            content_type=ContentType.SOCIAL,
        )
        result = await shield.check(content)
        assert result.passed is False
        assert any(i.code == "SENTIMENT_MISMATCH" for i in result.issues)

    @pytest.mark.asyncio
    async def test_invalid_target_sentiment_raises(self):
        with pytest.raises(ValueError, match="target_sentiment must be one of"):
            SentimentShield(target_sentiment="angry")
