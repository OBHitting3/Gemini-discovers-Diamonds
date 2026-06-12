"""Tests for BrandVoiceShield."""

import pytest

from content_shield.brand.profile import BrandProfile
from content_shield.schema import Content, ContentType
from content_shield.shields.brand_voice import BrandVoiceShield


@pytest.fixture
def brand_voice_shield(sample_brand_profile):
    return BrandVoiceShield(brand_profile=sample_brand_profile)


class TestBrandVoiceShield:
    """Tests for the BrandVoiceShield.check() method."""

    @pytest.mark.asyncio
    async def test_clean_content_passes(self, brand_voice_shield):
        content = Content(
            text="Our platform helps customers succeed.",
            content_type=ContentType.MARKETING,
        )
        result = await brand_voice_shield.check(content)
        assert result.passed is True
        assert result.shield_name == "brand_voice"
        assert len(result.issues) == 0

    @pytest.mark.asyncio
    async def test_banned_word_detected(self, brand_voice_shield):
        content = Content(
            text="Our cheap product is available now.",
            content_type=ContentType.MARKETING,
        )
        result = await brand_voice_shield.check(content)
        assert result.passed is False
        assert any(i.code == "BRAND_BANNED_WORD" for i in result.issues)

    @pytest.mark.asyncio
    async def test_incorrect_terminology_detected(self, brand_voice_shield):
        content = Content(
            text="Visit our website to see what users are saying.",
            content_type=ContentType.BLOG,
        )
        result = await brand_voice_shield.check(content)
        assert result.passed is False
        assert any(i.code == "BRAND_TERMINOLOGY" for i in result.issues)
