"""Google Cloud Pub/Sub emitter for shield events.

The ``google-cloud-pubsub`` package is an **optional** dependency.  Install
it via the ``gcp`` extra::

    pip install content-shield[gcp]
"""

from __future__ import annotations

import json
from typing import Any, Optional

import structlog

from content_shield.schema.event import ShieldEvent

from .base import BaseEmitter

logger: structlog.stdlib.BoundLogger = structlog.get_logger(__name__)

try:
    from google.cloud import pubsub_v1  # type: ignore[import-untyped]

    _HAS_PUBSUB = True
except ImportError:  # pragma: no cover
    _HAS_PUBSUB = False


class PubSubEmitter(BaseEmitter):
    """Emitter that publishes shield events to a Google Cloud Pub/Sub topic.

    Parameters
    ----------
    project_id:
        Google Cloud project ID.
    topic_id:
        Pub/Sub topic ID.
    ordering_key:
        Optional ordering key for message ordering.  Defaults to ``None``
        (unordered).
    """

    def __init__(
        self,
        project_id: str,
        topic_id: str,
        *,
        ordering_key: Optional[str] = None,
    ) -> None:
        if not _HAS_PUBSUB:
            raise ImportError(
                "google-cloud-pubsub is required for PubSubEmitter. "
                "Install it with: pip install content-shield[gcp]"
            )
        self._project_id = project_id
        self._topic_id = topic_id
        self._ordering_key = ordering_key or ""
        self._publisher: Optional[pubsub_v1.PublisherClient] = None
        self._topic_path: Optional[str] = None

    # ------------------------------------------------------------------
    # Lifecycle
    # ------------------------------------------------------------------

    async def setup(self) -> None:
        """Initialise the Pub/Sub publisher client."""
        publisher_options: dict[str, Any] = {}
        if self._ordering_key:
            publisher_options["enable_message_ordering"] = True

        self._publisher = pubsub_v1.PublisherClient(
            publisher_options=pubsub_v1.types.PublisherOptions(**publisher_options)
            if publisher_options
            else None,
        )
        self._topic_path = self._publisher.topic_path(self._project_id, self._topic_id)

    async def teardown(self) -> None:
        """Stop the underlying publisher transport."""
        if self._publisher is not None:
            self._publisher.stop()
            self._publisher = None

    # ------------------------------------------------------------------
    # Emit
    # ------------------------------------------------------------------

    async def emit(self, event: ShieldEvent) -> None:
        """Publish *event* as a JSON message to the configured Pub/Sub topic."""
        if self._publisher is None or self._topic_path is None:
            await self.setup()
            assert self._publisher is not None  # noqa: S101
            assert self._topic_path is not None  # noqa: S101

        data = json.dumps(event.model_dump(mode="json")).encode("utf-8")

        publish_kwargs: dict[str, Any] = {
            "topic": self._topic_path,
            "data": data,
            "shield_name": event.shield_name,
            "severity": event.severity.value,
        }
        if self._ordering_key:
            publish_kwargs["ordering_key"] = self._ordering_key

        future = self._publisher.publish(**publish_kwargs)
        message_id = future.result()

        logger.debug(
            "pubsub_event_published",
            topic=self._topic_path,
            message_id=message_id,
            event_id=str(event.event_id),
        )
