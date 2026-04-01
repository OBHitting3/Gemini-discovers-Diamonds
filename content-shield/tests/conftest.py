"""Shared fixtures for content-shield tests."""

from datetime import datetime, timezone
from uuid import uuid4

import pytest

from content_shield.schema import (
    Content,
    ContentType,
    Issue,
    Severity,
    ShieldEvent,
    ValidationResult,
)
from content_shield.brand.profile import BrandProfile


@pytest.fixture
def sample_content() -> Content:
    """A basic Content instance for use in tests."""
    return Content(
        text="This is sample marketing content for testing.",
        content_type=ContentType.MARKETING,
    )


@pytest.fixture
def sample_event() -> ShieldEvent:
    """A basic ShieldEvent instance for use in tests."""
    return ShieldEvent(
        event_id=uuid4(),
        shield_name="test_shield",
        content_id="content-001",
        timestamp=datetime.now(timezone.utc),
        severity=Severity.INFO,
        passed=True,
        message="Test event message",
    )


@pytest.fixture
def sample_brand_profile() -> BrandProfile:
    """A basic BrandProfile instance for use in tests."""
    return BrandProfile(
        name="TestBrand",
        voice_attributes=["professional", "friendly"],
        tone="conversational",
        banned_words=["cheap", "sucks"],
        required_terminology={"website": "platform", "users": "customers"},
        target_audience="developers",
        industry="technology",
    )


@pytest.fixture
def sample_validation_result() -> ValidationResult:
    """A basic ValidationResult instance for use in tests."""
    return ValidationResult(
        passed=True,
        shield_name="test_shield",
        score=0.95,
        issues=[],
        suggestions=[],
    )
