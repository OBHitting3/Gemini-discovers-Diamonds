"""Configuration for Content Shield."""

from __future__ import annotations

import os
from dataclasses import dataclass, field


@dataclass
class ContentShieldConfig:
    """Global configuration for the Content Shield framework."""

    log_level: str = field(default_factory=lambda: os.getenv("CONTENT_SHIELD_LOG_LEVEL", "INFO"))

    # GCP settings
    gcp_project: str | None = field(default_factory=lambda: os.getenv("GOOGLE_CLOUD_PROJECT"))
    pubsub_topic: str = field(default_factory=lambda: os.getenv("PUBSUB_TOPIC", "content-shield-events"))
    bigquery_dataset: str = field(default_factory=lambda: os.getenv("BIGQUERY_DATASET", "content_shield"))

    # Slack
    slack_webhook_url: str | None = field(default_factory=lambda: os.getenv("SLACK_WEBHOOK_URL"))

    # Agent API keys
    gemini_api_key: str | None = field(default_factory=lambda: os.getenv("GEMINI_API_KEY"))
    anthropic_api_key: str | None = field(default_factory=lambda: os.getenv("ANTHROPIC_API_KEY"))
    openai_api_key: str | None = field(default_factory=lambda: os.getenv("OPENAI_API_KEY"))

    # Resilience defaults
    default_retry_attempts: int = 3
    default_timeout_seconds: float = 30.0
    circuit_breaker_threshold: int = 5
    circuit_breaker_recovery_seconds: float = 60.0
