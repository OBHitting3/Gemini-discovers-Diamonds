"""Tests for ShieldRunner."""

import pytest

from content_shield.schema import Content, ContentType
from content_shield.shields.hallucination import HallucinationShield
from content_shield.shields.runner import ShieldRunner
from content_shield.shields.sentiment import SentimentShield
from content_shield.shields.toxicity import ToxicityShield


@pytest.fixture
def runner():
    shields = [HallucinationShield(), ToxicityShield()]
    return ShieldRunner(shields=shields)


class TestShieldRunner:
    """Tests for ShieldRunner.run() and run_batch()."""

    @pytest.mark.asyncio
    async def test_run_returns_summary(self, runner):
        content = Content(
            text="A perfectly clean sentence.",
            content_type=ContentType.BLOG,
        )
        summary = await runner.run(content)
        assert summary.passed is True
        assert len(summary.results) == 2

    @pytest.mark.asyncio
    async def test_run_detects_issues(self, runner):
        content = Content(
            text="You are an idiot for thinking that.",
            content_type=ContentType.SOCIAL,
        )
        summary = await runner.run(content)
        assert summary.passed is False
        assert summary.total_issues > 0

    @pytest.mark.asyncio
    async def test_run_batch(self, runner):
        contents = [
            Content(text="Clean content here.", content_type=ContentType.BLOG),
            Content(text="Another clean one.", content_type=ContentType.EMAIL),
        ]
        summaries = await runner.run_batch(contents)
        assert len(summaries) == 2
        assert all(s.passed for s in summaries)

    @pytest.mark.asyncio
    async def test_sequential_mode(self):
        runner = ShieldRunner(
            shields=[HallucinationShield()],
            parallel=False,
        )
        content = Content(text="Test content.", content_type=ContentType.MARKETING)
        summary = await runner.run(content)
        assert len(summary.results) == 1
