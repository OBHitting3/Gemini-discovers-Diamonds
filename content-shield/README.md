# Content Shield

AI content quality validation framework with brand voice enforcement, factual accuracy checking, and resilience patterns.

## Features

- **Shields**: Pluggable validation checks (brand voice, factual claims, legal compliance, toxicity, hallucination, sentiment, competitor mentions, contact validation)
- **Brand Profiles**: Define and enforce brand voice, terminology, and tone
- **AI Agents**: Multi-provider support (Gemini, Claude, OpenAI) for intelligent content analysis
- **Resilience**: Retry strategies, circuit breakers, dead-letter queues, and error classification
- **Dashboards**: Grafana dashboard generation with Pain Line tracking
- **Integrations**: WordPress, HubSpot, Mailchimp, Shopify, and generic webhooks
- **Event System**: Schema-based event emission to console, webhooks, Pub/Sub, and Slack

## Quick Start

```bash
pip install content-shield

# With all optional dependencies
pip install content-shield[all]
```

```python
from content_shield import ContentShield
from content_shield.schema.content import Content

shield = ContentShield()
content = Content(text="Your marketing copy here", content_type="marketing")
result = shield.validate(content)
print(result)
```

## Development

```bash
git clone https://github.com/content-shield/content-shield.git
cd content-shield
make dev
make test
```

## Documentation

See the [docs/](docs/) directory for full documentation.

## License

Apache 2.0 - see [LICENSE](LICENSE) for details.
