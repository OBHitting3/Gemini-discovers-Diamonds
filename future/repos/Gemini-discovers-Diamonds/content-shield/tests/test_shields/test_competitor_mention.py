"""Tests for CompetitorMentionShield."""

import pytest

from content_shield.schema import Content, ContentType, Severity
from content_shield.shields.competitor_mention import CompetitorMentionShield


class TestCompetitorMentionShield:
    """Tests for the CompetitorMentionShield.check() method."""

    @pytest.mark.asyncio
    async def test_no_competitors_passes(self):
        shield = CompetitorMentionShield(competitors=["Acme", "RivalCo"])
        content = Content(
            text="Our product is the best on the market.",
            content_type=ContentType.MARKETING,
        )
        result = await shield.check(content)
        assert result.passed is True
        assert result.shield_name == "competitor_mention"

    @pytest.mark.asyncio
    async def test_competitor_detected(self):
        shield = CompetitorMentionShield(competitors=["Acme"])
        content = Content(
            text="Unlike Acme, we deliver on time.",
            content_type=ContentType.BLOG,
        )
        result = await shield.check(content)
        assert result.passed is False
        assert any(i.code == "COMPETITOR_MENTION" for i in result.issues)

    @pytest.mark.asyncio
    async def test_custom_severity_map(self):
        shield = CompetitorMentionShield(
            competitors=["Acme"],
            severity_map={"acme": Severity.CRITICAL},
        )
        content = Content(
            text="Acme is our main competitor.",
            content_type=ContentType.MARKETING,
        )
        result = await shield.check(content)
        assert result.issues[0].severity == Severity.CRITICAL
