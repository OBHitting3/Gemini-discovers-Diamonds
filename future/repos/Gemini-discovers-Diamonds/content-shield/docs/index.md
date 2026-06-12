# Content Shield Documentation

Content Shield is a Python framework for validating AI-generated (and human-written) content against quality, safety, and brand-voice standards.

## Contents

- [Quickstart](quickstart.md) -- get running in five minutes
- [Shields Guide](shields_guide.md) -- available shield types and how to use them
- [Brand Profiles](brand_profiles.md) -- define and enforce brand voice
- [Pain Line Setup](pain_line_setup.md) -- track content quality over time
- [Retry Playbook](retry_playbook.md) -- resilience patterns (retries, circuit breakers, DLQ)
- [Integrations](integrations.md) -- connect to WordPress, HubSpot, Shopify, and more
- [API Reference](api_reference.md) -- classes, methods, and configuration
- [For Agencies](for_agencies.md) -- multi-client workflows

## Installation

```bash
pip install content-shield
```

## Quick Example

```python
from content_shield import ContentShield
from content_shield.schema.content import Content, ContentType

shield = ContentShield()
result = shield.validate(
    Content(text="Hello world!", content_type=ContentType.MARKETING)
)
print(result.passed, result.score)
```
