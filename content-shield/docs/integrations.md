# Integrations

Content Shield ships with connectors for popular content platforms and a generic webhook adapter.

## Available Integrations

| Integration | Module | Purpose |
|-------------|--------|---------|
| **WordPress** | `integrations.wordpress` | Validate posts before publishing |
| **HubSpot** | `integrations.hubspot` | Screen marketing emails and landing pages |
| **Shopify** | `integrations.shopify` | Check product descriptions |
| **Mailchimp** | `integrations.mailchimp` | Validate email campaigns |
| **Generic Webhook** | `integrations.webhook_generic` | Connect any platform via HTTP webhook |

## Emitters

Emitters push validation events to external systems:

| Emitter | Module | Destination |
|---------|--------|-------------|
| **Console** | `emitter.console` | stdout (debugging) |
| **Webhook** | `emitter.webhook` | Any HTTP endpoint |
| **Slack** | `emitter.slack` | Slack channel via webhook URL |
| **Pub/Sub** | `emitter.pubsub` | Google Cloud Pub/Sub topic |

## Collectors

Collectors ingest content from external sources:

- `collector.local_handler` -- reads from a local directory or file
- `collector.gcf_handler` -- Google Cloud Functions HTTP handler
- `collector.storage` -- Google Cloud Storage bucket listener

## Generic Webhook Example

```python
from content_shield.integrations.webhook_generic import GenericWebhookIntegration

integration = GenericWebhookIntegration(
    endpoint_url="https://your-app.example.com/content",
    api_key="your-api-key",
)
```

## Environment Variables

| Variable | Used by |
|----------|---------|
| `SLACK_WEBHOOK_URL` | Slack emitter |
| `GOOGLE_CLOUD_PROJECT` | Pub/Sub emitter, GCF collector |
| `PUBSUB_TOPIC` | Pub/Sub emitter (default: `content-shield-events`) |
| `BIGQUERY_DATASET` | Storage collector (default: `content_shield`) |
