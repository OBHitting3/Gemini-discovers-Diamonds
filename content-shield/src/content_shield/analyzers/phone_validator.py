"""Phone number validation, extraction, and normalization for content-shield."""

from __future__ import annotations

import re

# Country-specific validation patterns.
_COUNTRY_PATTERNS: dict[str, re.Pattern[str]] = {
    "US": re.compile(
        r"^(?:\+?1[-.\s]?)?"
        r"\(?[2-9]\d{2}\)?[-.\s]?"
        r"[2-9]\d{2}[-.\s]?"
        r"\d{4}$"
    ),
    "GB": re.compile(
        r"^(?:\+?44[-.\s]?)?"
        r"(?:0[-.\s]?)?"
        r"\d{4,5}[-.\s]?"
        r"\d{5,6}$"
    ),
    "DE": re.compile(
        r"^(?:\+?49[-.\s]?)?"
        r"(?:0[-.\s]?)?"
        r"\d{2,5}[-.\s]?"
        r"\d{4,10}$"
    ),
}

# Broad extraction pattern: matches common phone-like sequences.
_PHONE_EXTRACT_RE = re.compile(
    r"(?<!\d)"
    r"(?:\+?\d{1,3}[-.\s]?)?"
    r"\(?\d{2,4}\)?[-.\s]?"
    r"\d{3,4}[-.\s]?"
    r"\d{3,4}"
    r"(?!\d)",
)


class PhoneValidator:
    """Validate, extract, and normalize phone numbers."""

    # ------------------------------------------------------------------ #
    # Public API
    # ------------------------------------------------------------------ #

    @staticmethod
    def validate(phone: str, country_code: str = "US") -> bool:
        """Return ``True`` if *phone* matches the pattern for *country_code*.

        Supported country codes: ``US``, ``GB``, ``DE``.  Returns ``False``
        for unsupported country codes.
        """
        pattern = _COUNTRY_PATTERNS.get(country_code.upper())
        if pattern is None:
            return False
        return pattern.match(phone.strip()) is not None

    @staticmethod
    def extract_phones(text: str) -> list[str]:
        """Extract all phone-number-like sequences from *text*."""
        return [m.strip() for m in _PHONE_EXTRACT_RE.findall(text)]

    @staticmethod
    def normalize(phone: str) -> str:
        """Normalize *phone* to E.164-like digits-only format.

        Strips all non-digit characters except a leading ``+``.
        """
        digits = re.sub(r"[^\d+]", "", phone)
        # Ensure leading '+' is preserved if present.
        if phone.lstrip().startswith("+") and not digits.startswith("+"):
            digits = "+" + digits
        return digits
