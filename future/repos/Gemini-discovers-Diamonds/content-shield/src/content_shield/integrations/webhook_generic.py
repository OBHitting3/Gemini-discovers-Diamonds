"""Generic webhook integration for content validation."""

from __future__ import annotations

import logging
from typing import Any

import httpx

from content_shield.schema.content import Content
from content_shield.schema.validation import ValidationSummary

logger = logging.getLogger(__name__)


class GenericWebhookIntegration:
    """Sends validation results to a generic webhook endpoint."""

    def __init__(self, webhook_url: str, headers: dict[str, str] | None = None) -> None:
        self.webhook_url = webhook_url
        self._client = httpx.Client(headers=headers or {})

    def send_result(self, content: Content, summary: ValidationSummary) -> bool:
        """Send a validation result to the webhook."""
        payload = {
            "content_id": str(content.content_id),
            "content_type": content.content_type,
            "passed": summary.passed,
            "total_checks": summary.total_checks,
            "failed_checks": summary.failed_checks,
            "results": [r.model_dump(mode="json") for r in summary.results],
        }
        try:
            response = self._client.post(self.webhook_url, json=payload)
            response.raise_for_status()
            logger.info("Webhook delivered for content %s", content.content_id)
            return True
        except httpx.HTTPError:
            logger.exception("Failed to deliver webhook for content %s", content.content_id)
            return False

    def close(self) -> None:
        """Close the HTTP client."""
        self._client.close()
