"""Shield that validates contact information found in content."""

from __future__ import annotations

import re

from content_shield.schema import Content, Issue, Severity, ValidationResult
from content_shield.shields.base import BaseShield

# --------------------------------------------------------------------- #
# Simple patterns used as lightweight analysers.                        #
# A production implementation would delegate to dedicated Analyzer      #
# classes (e.g. EmailAnalyzer, PhoneAnalyzer, URLAnalyzer).             #
# --------------------------------------------------------------------- #

_EMAIL_RE = re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}")
_PHONE_RE = re.compile(
    r"(?:\+?\d{1,3}[-.\s]?)?\(?\d{2,4}\)?[-.\s]?\d{3,4}[-.\s]?\d{3,4}"
)
_URL_RE = re.compile(
    r"https?://[A-Za-z0-9._~:/?#\[\]@!$&'()*+,;=%-]+"
)


class ContactValidationShield(BaseShield):
    """Validates emails, phone numbers, and URLs found in content.

    Each detected contact item is run through a basic format check.
    Invalid items are reported as issues.  Future versions will use
    pluggable analyser components for richer validation (DNS checks for
    email domains, phone-number library for phones, HEAD requests for
    URLs, etc.).
    """

    @property
    def name(self) -> str:
        return "contact_validation"

    # -- helpers -------------------------------------------------------- #

    @staticmethod
    def _validate_email(email: str) -> str | None:
        """Return an error message if *email* looks malformed, else None."""
        if email.count("@") != 1:
            return f"Malformed email address: '{email}'"
        local, domain = email.rsplit("@", 1)
        if not local or not domain or "." not in domain:
            return f"Invalid email domain in: '{email}'"
        return None

    @staticmethod
    def _validate_phone(phone: str) -> str | None:
        """Return an error message if *phone* is suspicious, else None."""
        digits = re.sub(r"\D", "", phone)
        if len(digits) < 7 or len(digits) > 15:
            return f"Phone number has unexpected length: '{phone}'"
        return None

    @staticmethod
    def _validate_url(url: str) -> str | None:
        """Return an error message if *url* looks malformed, else None."""
        if not url.startswith(("http://", "https://")):
            return f"URL missing scheme: '{url}'"
        return None

    # -- main check ----------------------------------------------------- #

    async def check(self, content: Content) -> ValidationResult:
        issues: list[Issue] = []

        for match in _EMAIL_RE.finditer(content.text):
            err = self._validate_email(match.group())
            if err:
                issues.append(
                    Issue(
                        code="INVALID_EMAIL",
                        message=err,
                        severity=Severity.ERROR,
                        span_start=match.start(),
                        span_end=match.end(),
                    )
                )

        for match in _PHONE_RE.finditer(content.text):
            err = self._validate_phone(match.group())
            if err:
                issues.append(
                    Issue(
                        code="INVALID_PHONE",
                        message=err,
                        severity=Severity.WARNING,
                        span_start=match.start(),
                        span_end=match.end(),
                    )
                )

        for match in _URL_RE.finditer(content.text):
            err = self._validate_url(match.group())
            if err:
                issues.append(
                    Issue(
                        code="INVALID_URL",
                        message=err,
                        severity=Severity.ERROR,
                        span_start=match.start(),
                        span_end=match.end(),
                    )
                )

        passed = len(issues) == 0
        score = max(0.0, 1.0 - len(issues) * 0.15)
        return ValidationResult(
            passed=passed,
            shield_name=self.name,
            score=score,
            issues=issues,
            suggestions=["Fix invalid contact information"] if issues else [],
        )
