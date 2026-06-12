"""Validator for PII (Personally Identifiable Information) detection."""

import re

from joshua7.models import Finding

# Email: common pattern (local@domain.tld)
EMAIL_RE = re.compile(
    r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}",
    re.IGNORECASE,
)

# US phone: (XXX) XXX-XXXX, XXX-XXX-XXXX, XXX.XXX.XXXX, XXXXXXXXXX
PHONE_RE = re.compile(
    r"(?:\+?1[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}"
)

# SSN: XXX-XX-XXXX
SSN_RE = re.compile(r"\b\d{3}-\d{2}-\d{4}\b")


def validate(text: str) -> list[Finding]:
    """Detect emails, US phone numbers, and SSN patterns."""
    findings: list[Finding] = []

    for match in EMAIL_RE.finditer(text):
        findings.append(
            Finding(
                validator_id="pii_scanner",
                message=f"Detected email address: {match.group()}",
                severity="CRITICAL",
            )
        )

    for match in PHONE_RE.finditer(text):
        findings.append(
            Finding(
                validator_id="pii_scanner",
                message=f"Detected US phone number: {match.group()}",
                severity="CRITICAL",
            )
        )

    for match in SSN_RE.finditer(text):
        findings.append(
            Finding(
                validator_id="pii_scanner",
                message=f"Detected SSN pattern: {match.group()}",
                severity="CRITICAL",
            )
        )

    return findings
