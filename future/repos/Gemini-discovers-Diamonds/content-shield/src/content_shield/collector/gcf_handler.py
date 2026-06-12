"""Google Cloud Functions handler for receiving content validation events."""

from __future__ import annotations

import json
import logging
from typing import Any

from content_shield.schema.event import ShieldEvent
from content_shield.collector.storage import EventStorage

logger = logging.getLogger(__name__)


class GCFHandler:
    """Handles incoming Pub/Sub messages in a Google Cloud Function."""

    def __init__(self, storage: EventStorage | None = None) -> None:
        self.storage = storage or EventStorage()

    def handle_pubsub(self, event: dict[str, Any], context: Any = None) -> str:
        """Process a Pub/Sub-triggered Cloud Function event.

        Args:
            event: The Pub/Sub event payload.
            context: The Cloud Function context (unused).

        Returns:
            Acknowledgment string.
        """
        import base64

        raw_data = base64.b64decode(event["data"]).decode("utf-8")
        payload = json.loads(raw_data)
        shield_event = ShieldEvent.model_validate(payload)
        self.storage.store(shield_event)
        logger.info("Stored event %s from shield %s", shield_event.event_id, shield_event.shield_name)
        return "OK"

    def handle_http(self, request: Any) -> tuple[str, int]:
        """Process an HTTP-triggered Cloud Function request.

        Args:
            request: The HTTP request object.

        Returns:
            Tuple of (response_body, status_code).
        """
        try:
            payload = request.get_json(force=True)
            shield_event = ShieldEvent.model_validate(payload)
            self.storage.store(shield_event)
            return json.dumps({"status": "ok", "event_id": str(shield_event.event_id)}), 200
        except Exception as exc:
            logger.exception("Failed to process HTTP event")
            return json.dumps({"status": "error", "message": str(exc)}), 400
