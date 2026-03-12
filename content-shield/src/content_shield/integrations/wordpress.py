"""WordPress integration for content validation."""

from __future__ import annotations

import logging
from typing import Any

import httpx

from content_shield.schema.content import Content

logger = logging.getLogger(__name__)


class WordPressIntegration:
    """Validates WordPress content before or after publishing."""

    def __init__(self, site_url: str, username: str, app_password: str) -> None:
        self.site_url = site_url.rstrip("/")
        self.auth = (username, app_password)
        self._client = httpx.Client(base_url=f"{self.site_url}/wp-json/wp/v2", auth=self.auth)

    def fetch_post(self, post_id: int) -> Content:
        """Fetch a WordPress post and convert to Content."""
        response = self._client.get(f"/posts/{post_id}")
        response.raise_for_status()
        data = response.json()
        return Content(
            text=data.get("content", {}).get("rendered", ""),
            content_type="blog",
            metadata={"source": "wordpress", "post_id": post_id, "title": data.get("title", {}).get("rendered", "")},
        )

    def fetch_draft_posts(self, limit: int = 10) -> list[Content]:
        """Fetch recent draft posts for validation."""
        response = self._client.get("/posts", params={"status": "draft", "per_page": limit})
        response.raise_for_status()
        return [
            Content(
                text=post.get("content", {}).get("rendered", ""),
                content_type="blog",
                metadata={"source": "wordpress", "post_id": post["id"]},
            )
            for post in response.json()
        ]

    def close(self) -> None:
        """Close the HTTP client."""
        self._client.close()
