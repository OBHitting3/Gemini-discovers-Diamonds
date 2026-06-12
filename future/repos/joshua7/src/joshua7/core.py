"""Core validation logic for Joshua 7."""

from joshua7.models import Finding, ValidationResult
from joshua7.validators.forbidden_phrases import validate as validate_forbidden_phrases
from joshua7.validators.pii_scanner import validate as validate_pii


def run_validation(text: str) -> ValidationResult:
    """Run all validators and return a combined result."""
    findings: list[Finding] = []
    findings.extend(validate_forbidden_phrases(text))
    findings.extend(validate_pii(text))
    passed = len(findings) == 0
    return ValidationResult(passed=passed, findings=findings)
