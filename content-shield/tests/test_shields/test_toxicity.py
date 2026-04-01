"""Tests for ToxicityShield."""

import pytest

from content_shield.schema import Content, ContentType
from content_shield.shields.toxicity import ToxicityShield


class TestToxicityShield:
    """Tests for the ToxicityShield.check() method."""

    @pytest.mark.asyncio
    async def test_clean_content_passes(self):
        shield = ToxicityShield()
        content = Content(
            text="We are happy to help you with your request.",
            content_type=ContentType.EMAIL,
        )
        result = await shield.check(content)
        assert result.passed is True
        assert result.shield_name == "toxicity"

    @pytest.mark.asyncio
    async def test_toxic_keyword_detected(self):
        shield = ToxicityShield()
        content = Content(
            text="Only an idiot would believe that claim.",
            content_type=ContentType.SOCIAL,
        )
        result = await shield.check(content)
        assert result.passed is False
        assert any(i.code == "TOXIC_KEYWORD" for i in result.issues)

    @pytest.mark.asyncio
    async def test_aggressive_pattern_detected(self):
        shield = ToxicityShield()
        content = Content(
            text="Just shut up and listen to me.",
            content_type=ContentType.SOCIAL,
        )
        result = await shield.check(content)
        assert result.passed is False
        assert any(i.code == "TOXIC_PATTERN" for i in result.issues)

    @pytest.mark.asyncio
    async def test_custom_keywords(self):
        shield = ToxicityShield(extra_keywords=["awful"], replace_defaults=True)
        content = Content(
            text="That was an awful experience.",
            content_type=ContentType.SOCIAL,
        )
        result = await shield.check(content)
        assert result.passed is False
