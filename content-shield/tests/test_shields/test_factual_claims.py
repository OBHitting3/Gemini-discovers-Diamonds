"""Tests for FactualClaimsShield."""

import pytest

from content_shield.schema import Content, ContentType
from content_shield.shields.factual_claims import FactualClaimsShield


@pytest.fixture
def factual_shield():
    return FactualClaimsShield()


class TestFactualClaimsShield:
    """Tests for the FactualClaimsShield.check() method."""

    @pytest.mark.asyncio
    async def test_clean_content_passes(self, factual_shield):
        content = Content(
            text="We offer a wide range of products.",
            content_type=ContentType.MARKETING,
        )
        result = await factual_shield.check(content)
        assert result.passed is True
        assert result.shield_name == "factual_claims"

    @pytest.mark.asyncio
    async def test_proven_claim_flagged(self, factual_shield):
        content = Content(
            text="Our product is proven to be the best guaranteed solution.",
            content_type=ContentType.MARKETING,
        )
        result = await factual_shield.check(content)
        assert result.passed is False
        assert any(i.code == "UNVERIFIED_CLAIM" for i in result.issues)

    @pytest.mark.asyncio
    async def test_studies_show_flagged(self, factual_shield):
        content = Content(
            text="Studies show that our approach is best.",
            content_type=ContentType.BLOG,
        )
        result = await factual_shield.check(content)
        assert result.passed is False
        assert any("studies show" in i.message.lower() for i in result.issues)
