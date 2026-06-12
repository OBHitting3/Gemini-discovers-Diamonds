"""Local handler for processing content validation events during development."""

from __future__ import annotations

import logging

from content_shield.schema.event import ShieldEvent
from content_shield.collector.storage import EventStorage

logger = logging.getLogger(__name__)


class LocalHandler:
    """Processes shield events locally for development and testing."""

    def __init__(self, storage: EventStorage | None = None) -> None:
        self.storage = storage or EventStorage()

    def process(self, event: ShieldEvent) -> None:
        """Store an event locally."""
        self.storage.store(event)
        logger.info("Locally stored event %s (shield=%s, passed=%s)", event.event_id, event.shield_name, event.passed)

    def process_dict(self, data: dict) -> ShieldEvent:
        """Parse a dict into a ShieldEvent and store it."""
        event = ShieldEvent.model_validate(data)
        self.process(event)
        return event

    def get_recent(self, limit: int = 10) -> list[ShieldEvent]:
        """Retrieve the most recent stored events."""
        return self.storage.get_recent(limit)

    def get_summary(self) -> dict:
        """Get a summary of all stored events."""
        events = self.storage.get_all()
        total = len(events)
        passed = sum(1 for e in events if e.passed)
        return {
            "total_events": total,
            "passed": passed,
            "failed": total - passed,
            "pass_rate": passed / total if total > 0 else 0.0,
        }
