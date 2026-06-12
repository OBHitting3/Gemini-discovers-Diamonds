"""Validator for forbidden marketing phrases."""

from joshua7.models import Finding

FORBIDDEN = [
    "guaranteed results",
    "guarantee",
    "100% success",
    "risk-free",
    "no risk",
]


def validate(text: str) -> list[Finding]:
    """Check text (case-insensitive) for forbidden phrases."""
    findings: list[Finding] = []
    lower = text.lower()
    for phrase in FORBIDDEN:
        if phrase in lower:
            findings.append(
                Finding(
                    validator_id="forbidden_phrases",
                    message=f'Found forbidden phrase: "{phrase}"',
                )
            )
    return findings
