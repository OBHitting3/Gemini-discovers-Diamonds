# Quickstart

## 1. Install

```bash
pip install content-shield
```

## 2. Validate a single item

```python
from content_shield import ContentShield
from content_shield.schema.content import Content, ContentType

shield = ContentShield()
content = Content(
    text="Try our new feature today!",
    content_type=ContentType.MARKETING,
)
result = shield.validate(content)
print(result.passed, result.score)
```

## 3. Validate a batch

```python
items = [
    Content(text="First item", content_type=ContentType.BLOG),
    Content(text="Second item", content_type=ContentType.EMAIL),
]
results = shield.validate_batch(items)
for r in results:
    print(r.passed)
```

## 4. Add a brand profile

```python
from content_shield.brand.profile import BrandProfile

profile = BrandProfile(
    name="My Brand",
    voice_attributes=["professional", "warm"],
    banned_words=["cheap"],
)
profile.to_json("my_brand.json")
```

## 5. Configuration

`ContentShieldConfig` reads from environment variables by default:

| Variable | Purpose |
|----------|---------|
| `GEMINI_API_KEY` | Gemini agent |
| `ANTHROPIC_API_KEY` | Claude agent |
| `OPENAI_API_KEY` | OpenAI agent |
| `SLACK_WEBHOOK_URL` | Slack emitter |
| `GOOGLE_CLOUD_PROJECT` | GCP project for Pub/Sub and BigQuery |

See [API Reference](api_reference.md) for the full config dataclass.
