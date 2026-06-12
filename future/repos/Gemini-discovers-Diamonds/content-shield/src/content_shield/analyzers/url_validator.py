"""URL validation and extraction utilities for content-shield."""

from __future__ import annotations

import re

import httpx

# RFC 3986 inspired URL pattern (simplified but practical).
_URL_RE = re.compile(
    r"https?://"
    r"(?:[a-zA-Z0-9\-._~:/?#\[\]@!$&'()*+,;=%])+",
)

# Stricter format validation pattern.
_URL_FORMAT_RE = re.compile(
    r"^https?://"
    r"(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+"
    r"[a-zA-Z]{2,}"
    r"(?::\d{1,5})?"
    r"(?:/[^\s]*)?$",
)


class URLValidator:
    """Validate, check reachability, and extract URLs."""

    # ------------------------------------------------------------------ #
    # Public API
    # ------------------------------------------------------------------ #

    @staticmethod
    def validate(url: str) -> bool:
        """Return ``True`` if *url* has a valid HTTP/HTTPS format."""
        return _URL_FORMAT_RE.match(url) is not None

    @staticmethod
    async def check_reachability(url: str, *, timeout: float = 10.0) -> bool:
        """Send an async HTTP HEAD request and return ``True`` if the server responds with a success status.

        Uses *httpx* for the async request.  Returns ``False`` on any
        network or HTTP error.
        """
        try:
            async with httpx.AsyncClient(follow_redirects=True, timeout=timeout) as client:
                response = await client.head(url)
                return response.is_success
        except (httpx.HTTPError, ValueError):
            return False

    @staticmethod
    def extract_urls(text: str) -> list[str]:
        """Extract all HTTP/HTTPS URLs found in *text*."""
        return _URL_RE.findall(text)
