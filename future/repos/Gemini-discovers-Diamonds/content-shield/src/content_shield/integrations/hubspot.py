"""HubSpot integration for content validation."""

from __future__ import annotations

import logging

import httpx

from content_shield.schema.content import Content

logger = logging.getLogger(__name__)


class HubSpotIntegration:
    """Validates HubSpot marketing content."""

    def __init__(self, api_key: str) -> None:
        self._client = httpx.Client(
            base_url="https://api.hubapi.com",
            headers={"Authorization": f"Bearer {api_key}"},
        )

    def fetch_blog_post(self, post_id: str) -> Content:
        """Fetch a HubSpot blog post."""
        response = self._client.get(f"/cms/v3/blogs/posts/{post_id}")
        response.raise_for_status()
        data = response.json()
        return Content(
            text=data.get("postBody", ""),
            content_type="blog",
            metadata={"source": "hubspot", "post_id": post_id, "title": data.get("name", "")},
        )

    def fetch_email(self, email_id: str) -> Content:
        """Fetch a HubSpot marketing email."""
        response = self._client.get(f"/marketing-emails/v1/emails/{email_id}")
        response.raise_for_status()
        data = response.json()
        return Content(
            text=data.get("body", ""),
            content_type="email",
            metadata={"source": "hubspot", "email_id": email_id, "subject": data.get("subject", "")},
        )

    def close(self) -> None:
        """Close the HTTP client."""
        self._client.close()
