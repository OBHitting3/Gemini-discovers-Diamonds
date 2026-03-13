"""Tests for EmailValidator and PhoneValidator."""

import pytest

from content_shield.analyzers.email_validator import EmailValidator
from content_shield.analyzers.phone_validator import PhoneValidator


class TestEmailValidator:
    """Tests for email format validation and extraction."""

    def test_valid_email(self):
        assert EmailValidator.validate_format("user@example.com") is True

    def test_invalid_email_no_at(self):
        assert EmailValidator.validate_format("userexample.com") is False

    def test_invalid_email_no_domain(self):
        assert EmailValidator.validate_format("user@") is False

    def test_extract_emails(self):
        text = "Contact alice@example.com or bob@test.org for help."
        emails = EmailValidator.extract_emails(text)
        assert len(emails) == 2


class TestPhoneValidator:
    """Tests for phone number validation and normalization."""

    def test_valid_us_phone(self):
        assert PhoneValidator.validate("(212) 555-1234", country_code="US") is True

    def test_invalid_us_phone(self):
        assert PhoneValidator.validate("123", country_code="US") is False

    def test_unsupported_country_code(self):
        assert PhoneValidator.validate("+33 1 23 45 67 89", country_code="FR") is False

    def test_normalize_phone(self):
        result = PhoneValidator.normalize("+1 (555) 123-4567")
        assert result == "+15551234567"

    def test_extract_phones(self):
        text = "Call us at (555) 123-4567 or +1-800-555-0199."
        phones = PhoneValidator.extract_phones(text)
        assert len(phones) >= 1
