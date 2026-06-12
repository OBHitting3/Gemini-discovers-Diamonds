"""Shared dataclasses for Joshua 7 validators."""

from dataclasses import dataclass, field


@dataclass
class Finding:
    validator_id: str
    message: str
    severity: str = "CRITICAL"


@dataclass
class ValidationResult:
    passed: bool
    findings: list[Finding] = field(default_factory=list)

    def __str__(self) -> str:
        return "PASS" if self.passed else "FAIL"
