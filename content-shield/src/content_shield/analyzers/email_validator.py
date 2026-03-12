"""Email validation and extraction utilities for content-shield."""

from __future__ import annotations

import re

# Basic RFC 5322 compliant email regex.
# Covers the vast majority of real-world addresses without attempting to
# encode every corner case of the RFC.
_EMAIL_RE = re.compile(
    r"(?:[a-zA-Z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-zA-Z0-9!#$%&'*+/=?^_`{|}~-]+)*)"
    r"@"
    r"(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+"
    r"[a-zA-Z]{2,}",
)

# Anchored version for full-string validation.
_EMAIL_FORMAT_RE = re.compile(rf"^{_EMAIL_RE.pattern}$")


class EmailValidator:
    """Validate and extract email addresses."""

    # ------------------------------------------------------------------ #
    # Public API
    # ------------------------------------------------------------------ #

    @staticmethod
    def validate_format(email: str) -> bool:
        """Return ``True`` if *email* matches a basic RFC 5322 format."""
        return _EMAIL_FORMAT_RE.match(email) is not None

    @staticmethod
    def extract_emails(text: str) -> list[str]:
        """Extract all email addresses found in *text*."""
        return _EMAIL_RE.findall(text)
