"""Tests for HallucinationShield."""

import pytest

from content_shield.schema import Content, ContentType
from content_shield.shields.hallucination import HallucinationShield


class TestHallucinationShield:
    """Tests for the HallucinationShield.check() method."""

    @pytest.mark.asyncio
    async def test_stub_always_passes(self):
        shield = HallucinationShield()
        content = Content(
            text="The earth orbits the sun.",
            content_type=ContentType.BLOG,
        )
        result = await shield.check(content)
        assert result.passed is True
        assert result.shield_name == "hallucination"
        assert result.score == 1.0

    @pytest.mark.asyncio
    async def test_custom_confidence_threshold(self):
        shield = HallucinationShield(confidence_threshold=0.9)
        assert shield._confidence_threshold == 0.9

    @pytest.mark.asyncio
    async def test_returns_empty_issues(self):
        shield = HallucinationShield()
        content = Content(
            text="Any content should pass the stub.",
            content_type=ContentType.MARKETING,
        )
        result = await shield.check(content)
        assert result.issues == []
        assert result.suggestions == []
