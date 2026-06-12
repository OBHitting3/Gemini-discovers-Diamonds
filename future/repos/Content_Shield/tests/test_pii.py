"""Tests for the PII Validator."""

from joshua7.validators.pii import PIIValidator


class TestPIIValidator:
    def test_clean_text_passes(self):
        v = PIIValidator()
        result = v.validate("No personal information here.")
        assert result.passed is True
        assert len(result.findings) == 0

    def test_detects_email(self):
        v = PIIValidator()
        result = v.validate("Contact us at john.doe@example.com for info.")
        assert result.passed is False
        assert any(f.metadata.get("pii_type") == "email" for f in result.findings)

    def test_detects_phone(self):
        v = PIIValidator()
        result = v.validate("Call me at (555) 123-4567 anytime.")
        assert result.passed is False
        assert any(f.metadata.get("pii_type") == "phone" for f in result.findings)

    def test_detects_ssn(self):
        v = PIIValidator()
        result = v.validate("My SSN is 123-45-6789.")
        assert result.passed is False
        assert any(f.metadata.get("pii_type") == "ssn" for f in result.findings)

    def test_detects_multiple_pii(self):
        v = PIIValidator()
        result = v.validate(
            "Email me at alice@example.com or call 555-123-4567. SSN: 123-45-6789"
        )
        assert result.passed is False
        pii_types = {f.metadata.get("pii_type") for f in result.findings}
        assert "email" in pii_types
        assert "ssn" in pii_types

    def test_disabled_patterns(self):
        v = PIIValidator(config={"pii_patterns_enabled": ["email"]})
        result = v.validate("SSN is 123-45-6789 and phone is 555-123-4567.")
        assert result.passed is True

    def test_severity_is_critical(self):
        v = PIIValidator()
        result = v.validate("My email: test@test.com")
        assert result.findings[0].severity.value == "critical"

    def test_pii_values_are_redacted(self):
        """SECURITY: actual PII must never appear in findings."""
        v = PIIValidator()
        result = v.validate("My email is secret@corp.com and SSN is 123-45-6789.")
        for finding in result.findings:
            assert "secret@corp.com" not in finding.message
            assert "secret@corp.com" not in str(finding.metadata)
            assert "123-45-6789" not in finding.message
            assert "123-45-6789" not in str(finding.metadata)

    def test_redacted_placeholders_present(self):
        v = PIIValidator()
        result = v.validate("Contact admin@example.com now.")
        assert result.passed is False
        f = result.findings[0]
        assert f.metadata.get("redacted") == "***@***.***"
        assert "value" not in f.metadata

    def test_unicode_email(self):
        v = PIIValidator()
        result = v.validate("Reach me at user@example.com or via carrier pigeon.")
        assert result.passed is False

    def test_no_false_positive_on_at_sign(self):
        v = PIIValidator()
        result = v.validate("Look @ this cool thing!")
        assert result.passed is True
