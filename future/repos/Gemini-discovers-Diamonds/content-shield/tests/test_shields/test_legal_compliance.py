"""Tests for LegalComplianceShield."""

import pytest

from content_shield.schema import Content, ContentType
from content_shield.shields.legal_compliance import LegalComplianceShield


class TestLegalComplianceShield:
    """Tests for the LegalComplianceShield.check() method."""

    @pytest.mark.asyncio
    async def test_no_rules_passes(self):
        shield = LegalComplianceShield()
        content = Content(text="Anything goes here.", content_type=ContentType.LEGAL)
        result = await shield.check(content)
        assert result.passed is True

    @pytest.mark.asyncio
    async def test_missing_disclaimer_flagged(self):
        shield = LegalComplianceShield(
            rules={"required_disclaimers": ["Results may vary"]}
        )
        content = Content(
            text="Our product works great!",
            content_type=ContentType.MARKETING,
        )
        result = await shield.check(content)
        assert result.passed is False
        assert any(i.code == "MISSING_DISCLAIMER" for i in result.issues)

    @pytest.mark.asyncio
    async def test_forbidden_claim_flagged(self):
        shield = LegalComplianceShield(
            rules={"forbidden_claims": ["FDA approved"]}
        )
        content = Content(
            text="This supplement is FDA approved for daily use.",
            content_type=ContentType.PRODUCT,
        )
        result = await shield.check(content)
        assert result.passed is False
        assert any(i.code == "FORBIDDEN_CLAIM" for i in result.issues)

    @pytest.mark.asyncio
    async def test_content_with_disclaimer_passes(self):
        shield = LegalComplianceShield(
            rules={"required_disclaimers": ["Results may vary"]}
        )
        content = Content(
            text="Our product works great! Results may vary.",
            content_type=ContentType.MARKETING,
        )
        result = await shield.check(content)
        assert result.passed is True
