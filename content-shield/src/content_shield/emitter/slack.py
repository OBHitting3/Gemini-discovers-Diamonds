"""Slack emitter that sends shield events as Block Kit messages."""

from __future__ import annotations

from typing import Any, Optional

import httpx
import structlog

from content_shield.schema.event import ShieldEvent

from .base import BaseEmitter

logger: structlog.stdlib.BoundLogger = structlog.get_logger(__name__)

# Mapping from severity to Slack-friendly emoji.
_SEVERITY_EMOJI: dict[str, str] = {
    "info": ":information_source:",
    "warning": ":warning:",
    "error": ":x:",
    "critical": ":rotating_light:",
}


def _build_blocks(event: ShieldEvent) -> list[dict[str, Any]]:
    """Build a Slack Block Kit payload for the given *event*."""
    status = ":white_check_mark: Passed" if event.passed else ":no_entry: Failed"
    emoji = _SEVERITY_EMOJI.get(event.severity.value, ":grey_question:")

    blocks: list[dict[str, Any]] = [
        {
            "type": "header",
            "text": {
                "type": "plain_text",
                "text": f"{emoji} Shield Event: {event.shield_name}",
                "emoji": True,
            },
        },
        {
            "type": "section",
            "fields": [
                {"type": "mrkdwn", "text": f"*Status:*\n{status}"},
                {"type": "mrkdwn", "text": f"*Severity:*\n{event.severity.value.upper()}"},
                {"type": "mrkdwn", "text": f"*Content ID:*\n`{event.content_id}`"},
                {"type": "mrkdwn", "text": f"*Event ID:*\n`{event.event_id}`"},
            ],
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": f"*Message:*\n{event.message}",
            },
        },
        {
            "type": "context",
            "elements": [
                {
                    "type": "mrkdwn",
                    "text": f":clock1: {event.timestamp.isoformat()}",
                },
            ],
        },
    ]

    # Append details as a code block when present.
    if event.details:
        import json

        details_text = json.dumps(event.details, indent=2)
        blocks.append(
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*Details:*\n```{details_text}```",
                },
            }
        )

    blocks.append({"type": "divider"})

    return blocks


class SlackEmitter(BaseEmitter):
    """Emitter that sends shield events to a Slack incoming-webhook URL.

    Events are formatted as `Slack Block Kit
    <https://api.slack.com/block-kit>`_ messages for rich display.

    Parameters
    ----------
    webhook_url:
        The Slack incoming-webhook URL.
    channel:
        Optional channel override (only works with legacy webhooks).
    username:
        Optional username override for the bot.
    timeout:
        Request timeout in seconds.  Defaults to ``10``.
    """

    def __init__(
        self,
        webhook_url: str,
        *,
        channel: Optional[str] = None,
        username: Optional[str] = None,
        timeout: float = 10.0,
    ) -> None:
        self._webhook_url = webhook_url
        self._channel = channel
        self._username = username or "Content Shield"
        self._timeout = timeout
        self._client: Optional[httpx.AsyncClient] = None

    # ------------------------------------------------------------------
    # Lifecycle
    # ------------------------------------------------------------------

    async def setup(self) -> None:
        """Create the :class:`httpx.AsyncClient`."""
        self._client = httpx.AsyncClient(timeout=self._timeout)

    async def teardown(self) -> None:
        """Close the underlying HTTP client."""
        if self._client is not None:
            await self._client.aclose()
            self._client = None

    # ------------------------------------------------------------------
    # Emit
    # ------------------------------------------------------------------

    async def emit(self, event: ShieldEvent) -> None:
        """Send *event* as a Block Kit message to the Slack webhook."""
        if self._client is None:
            await self.setup()
            assert self._client is not None  # noqa: S101

        payload: dict[str, Any] = {
            "username": self._username,
            "blocks": _build_blocks(event),
        }
        if self._channel:
            payload["channel"] = self._channel

        try:
            response = await self._client.post(
                self._webhook_url,
                json=payload,
                headers={"Content-Type": "application/json"},
            )
            response.raise_for_status()
            logger.debug(
                "slack_event_sent",
                webhook_url=self._webhook_url,
                event_id=str(event.event_id),
            )
        except httpx.HTTPError as exc:
            logger.error(
                "slack_event_failed",
                webhook_url=self._webhook_url,
                event_id=str(event.event_id),
                error=str(exc),
            )
            raise
