"""Mailchimp integration for content validation."""

from __future__ import annotations

import logging

import httpx

from content_shield.schema.content import Content

logger = logging.getLogger(__name__)


class MailchimpIntegration:
    """Validates Mailchimp campaign content."""

    def __init__(self, api_key: str, server_prefix: str) -> None:
        self._client = httpx.Client(
            base_url=f"https://{server_prefix}.api.mailchimp.com/3.0",
            headers={"Authorization": f"Bearer {api_key}"},
        )

    def fetch_campaign(self, campaign_id: str) -> Content:
        """Fetch campaign content for validation."""
        response = self._client.get(f"/campaigns/{campaign_id}/content")
        response.raise_for_status()
        data = response.json()
        return Content(
            text=data.get("plain_text", "") or data.get("html", ""),
            content_type="email",
            metadata={"source": "mailchimp", "campaign_id": campaign_id},
        )

    def list_campaigns(self, status: str = "save", limit: int = 10) -> list[dict]:
        """List campaigns by status."""
        response = self._client.get("/campaigns", params={"status": status, "count": limit})
        response.raise_for_status()
        return response.json().get("campaigns", [])

    def close(self) -> None:
        """Close the HTTP client."""
        self._client.close()
