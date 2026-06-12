# Shields Guide

Shields are the core validation units in Content Shield. Each shield checks content for a specific class of issues.

## Built-in Shields

| Shield | Module | What it detects |
|--------|--------|-----------------|
| **Toxicity** | `shields.toxicity` | Offensive or toxic language via keyword and pattern matching |
| **Brand Voice** | `shields.brand_voice` | Deviations from a brand profile's voice and terminology |
| **Competitor Mention** | `shields.competitor_mention` | References to competitor brands |
| **Hallucination** | `shields.hallucination` | Unverifiable or fabricated claims |
| **Factual Claims** | `shields.factual_claims` | Unsupported factual assertions |
| **Legal Compliance** | `shields.legal_compliance` | Missing disclaimers, regulated language |
| **Contact Validation** | `shields.contact_validation` | Invalid emails, phone numbers, or URLs |

## Shield Interface

Every shield extends `BaseShield` and implements two things:

```python
from content_shield.shields.base import BaseShield
from content_shield.schema import Content, ValidationResult

class MyShield(BaseShield):
    @property
    def name(self) -> str:
        return "my_shield"

    async def check(self, content: Content) -> ValidationResult:
        # Your logic here
        return ValidationResult(
            passed=True,
            shield_name=self.name,
            score=1.0,
        )
```

## ValidationResult

Each `check()` call returns a `ValidationResult` containing:

- `passed` (bool) -- whether the content cleared this shield
- `shield_name` (str) -- which shield produced the result
- `score` (float, 0-1) -- quality score
- `issues` (list[Issue]) -- specific problems found
- `suggestions` (list[str]) -- actionable fixes

## Combining Results

Use `ValidationSummary` to aggregate results from multiple shields:

```python
from content_shield.schema.validation import ValidationSummary

summary = ValidationSummary(results=[result_a, result_b])
print(summary.passed, summary.average_score, summary.total_issues)
```
