"""Webhook emitter that POSTs shield events as JSON to a remote URL."""

from __future__ import annotations

from typing import Any, Optional

import httpx
import structlog

from content_shield.schema.event import ShieldEvent

from .base import BaseEmitter

logger: structlog.stdlib.BoundLogger = structlog.get_logger(__name__)


class WebhookEmitter(BaseEmitter):
    """Emitter that sends shield events to a webhook endpoint via HTTP POST.

    Parameters
    ----------
    url:
        The webhook URL to POST events to.
    headers:
        Optional extra HTTP headers to include with every request (e.g.
        ``Authorization``).
    timeout:
        Request timeout in seconds.  Defaults to ``10``.
    """

    def __init__(
        self,
        url: str,
        *,
        headers: Optional[dict[str, str]] = None,
        timeout: float = 10.0,
    ) -> None:
        self._url = url
        self._headers = headers or {}
        self._timeout = timeout
        self._client: Optional[httpx.AsyncClient] = None

    # ------------------------------------------------------------------
    # Lifecycle
    # ------------------------------------------------------------------

    async def setup(self) -> None:
        """Create the :class:`httpx.AsyncClient`."""
        self._client = httpx.AsyncClient(
            headers=self._headers,
            timeout=self._timeout,
        )

    async def teardown(self) -> None:
        """Close the underlying HTTP client."""
        if self._client is not None:
            await self._client.aclose()
            self._client = None

    # ------------------------------------------------------------------
    # Emit
    # ------------------------------------------------------------------

    async def emit(self, event: ShieldEvent) -> None:
        """POST *event* as JSON to the configured webhook URL."""
        if self._client is None:
            # Allow usage without explicit setup() by lazily creating the client.
            await self.setup()
            assert self._client is not None  # noqa: S101

        payload: dict[str, Any] = event.model_dump(mode="json")

        try:
            response = await self._client.post(
                self._url,
                json=payload,
                headers={"Content-Type": "application/json"},
            )
            response.raise_for_status()
            logger.debug(
                "webhook_event_sent",
                url=self._url,
                status_code=response.status_code,
                event_id=str(event.event_id),
            )
        except httpx.HTTPError as exc:
            logger.error(
                "webhook_event_failed",
                url=self._url,
                event_id=str(event.event_id),
                error=str(exc),
            )
            raise
