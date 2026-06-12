"""Tests for ContactValidationShield."""

import pytest

from content_shield.schema import Content, ContentType
from content_shield.shields.contact_validation import ContactValidationShield


@pytest.fixture
def contact_shield():
    return ContactValidationShield()


class TestContactValidationShield:
    """Tests for the ContactValidationShield.check() method."""

    @pytest.mark.asyncio
    async def test_valid_email_passes(self, contact_shield):
        content = Content(
            text="Contact us at support@example.com for help.",
            content_type=ContentType.EMAIL,
        )
        result = await contact_shield.check(content)
        assert result.passed is True

    @pytest.mark.asyncio
    async def test_valid_url_passes(self, contact_shield):
        content = Content(
            text="Visit https://example.com for more info.",
            content_type=ContentType.MARKETING,
        )
        result = await contact_shield.check(content)
        assert result.passed is True

    @pytest.mark.asyncio
    async def test_no_contact_info_passes(self, contact_shield):
        content = Content(
            text="Just a regular sentence with no contact details.",
            content_type=ContentType.BLOG,
        )
        result = await contact_shield.check(content)
        assert result.passed is True
        assert result.shield_name == "contact_validation"
