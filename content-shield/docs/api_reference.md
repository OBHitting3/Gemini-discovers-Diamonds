# API Reference

## Core

### `ContentShield`

Main entry point. Located in `content_shield.__init__`.

```python
ContentShield(config: ContentShieldConfig | None = None)
```

| Method | Returns | Description |
|--------|---------|-------------|
| `validate(content)` | `ValidationResult` | Validate a single `Content` item |
| `validate_batch(contents)` | `list[ValidationResult]` | Validate a list of `Content` items |

### `ContentShieldConfig`

Dataclass in `content_shield.config`.

| Field | Type | Default | Env var |
|-------|------|---------|---------|
| `log_level` | `str` | `"INFO"` | `CONTENT_SHIELD_LOG_LEVEL` |
| `gcp_project` | `str \| None` | `None` | `GOOGLE_CLOUD_PROJECT` |
| `pubsub_topic` | `str` | `"content-shield-events"` | `PUBSUB_TOPIC` |
| `bigquery_dataset` | `str` | `"content_shield"` | `BIGQUERY_DATASET` |
| `slack_webhook_url` | `str \| None` | `None` | `SLACK_WEBHOOK_URL` |
| `gemini_api_key` | `str \| None` | `None` | `GEMINI_API_KEY` |
| `anthropic_api_key` | `str \| None` | `None` | `ANTHROPIC_API_KEY` |
| `openai_api_key` | `str \| None` | `None` | `OPENAI_API_KEY` |
| `default_retry_attempts` | `int` | `3` | -- |
| `default_timeout_seconds` | `float` | `30.0` | -- |
| `circuit_breaker_threshold` | `int` | `5` | -- |
| `circuit_breaker_recovery_seconds` | `float` | `60.0` | -- |

## Schema

### `Content`

Pydantic model in `content_shield.schema.content`.

| Field | Type | Default |
|-------|------|---------|
| `content_id` | `UUID` | auto |
| `text` | `str` | required |
| `content_type` | `ContentType` | required |
| `language` | `str` | `"en"` |
| `metadata` | `dict \| None` | `None` |
| `created_at` | `datetime` | now (UTC) |

### `ContentType` (enum)

`MARKETING`, `BLOG`, `EMAIL`, `SOCIAL`, `PRODUCT`, `LEGAL`

### `ValidationResult`

| Field | Type |
|-------|------|
| `passed` | `bool` |
| `shield_name` | `str` |
| `score` | `float` (0-1) |
| `issues` | `list[Issue]` |
| `suggestions` | `list[str]` |

### `Issue`

| Field | Type |
|-------|------|
| `code` | `str` |
| `message` | `str` |
| `severity` | `Severity` |
| `span_start` | `int \| None` |
| `span_end` | `int \| None` |

### `Severity` (enum)

`INFO`, `WARNING`, `ERROR`, `CRITICAL`

### `ValidationSummary`

| Property | Type | Description |
|----------|------|-------------|
| `results` | `list[ValidationResult]` | Individual results |
| `passed` | `bool` | True if all passed |
| `total_issues` | `int` | Sum of all issues |
| `average_score` | `float` | Mean score |

## Brand

### `BrandProfile`

| Field | Type |
|-------|------|
| `name` | `str` |
| `voice_attributes` | `list[str]` |
| `tone` | `str` |
| `banned_words` | `list[str]` |
| `required_terminology` | `dict[str, str]` |
| `target_audience` | `str` |
| `industry` | `str` |

Class methods: `from_json(path)`, instance method: `to_json(path)`.

### `VoiceMatcher`

| Method | Returns | Description |
|--------|---------|-------------|
| `score(text)` | `float` | Brand alignment score (0-1) |
| `suggest(text)` | `list[str]` | Actionable suggestions |

## Resilience

### `RetryPolicy`

Constructor kwargs: `max_attempts`, `backoff`, `backoff_base`, `backoff_max`, `retryable_exceptions`, `on_retry`.

Usable as a decorator (`@policy`) or context manager (`policy.context()`).

### `CircuitBreaker`

Constructor kwargs: `failure_threshold`, `recovery_timeout`, `half_open_max_calls`, `monitored_exceptions`, `name`, `on_state_change`.

Properties: `state`, `failure_count`. Methods: `call(fn, ...)`, `reset()`.

### `DeadLetterQueue`

Constructor kwargs: `persist_path`, `max_size`.

Methods: `enqueue(payload, error)`, `dequeue()`, `peek(count)`, `replay(handler)`, `size()`, `clear()`, `list_all()`.

## Agents

### `AgentRouter`

| Method | Description |
|--------|-------------|
| `register(agent)` | Add an agent to the registry |
| `route(task_type)` | Pick the best agent for a task type |
| `get_available()` | List available agents |
| `analyze_with_fallback(content, prompt)` | Try each agent in order until one succeeds |
