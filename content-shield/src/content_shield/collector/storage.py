"""In-memory and file-based event storage."""

from __future__ import annotations

import json
import logging
from pathlib import Path

from content_shield.schema.event import ShieldEvent

logger = logging.getLogger(__name__)


class EventStorage:
    """Stores shield events in memory with optional file persistence."""

    def __init__(self, persist_path: str | Path | None = None) -> None:
        self._events: list[ShieldEvent] = []
        self._persist_path = Path(persist_path) if persist_path else None

    def store(self, event: ShieldEvent) -> None:
        """Store a shield event."""
        self._events.append(event)
        if self._persist_path:
            self._append_to_file(event)

    def get_all(self) -> list[ShieldEvent]:
        """Return all stored events."""
        return list(self._events)

    def get_recent(self, limit: int = 10) -> list[ShieldEvent]:
        """Return the most recent events."""
        return list(self._events[-limit:])

    def get_by_shield(self, shield_name: str) -> list[ShieldEvent]:
        """Return events for a specific shield."""
        return [e for e in self._events if e.shield_name == shield_name]

    def clear(self) -> None:
        """Clear all stored events."""
        self._events.clear()

    @property
    def size(self) -> int:
        """Number of stored events."""
        return len(self._events)

    def _append_to_file(self, event: ShieldEvent) -> None:
        """Append an event to the persistence file."""
        try:
            with open(self._persist_path, "a") as f:
                f.write(event.model_dump_json() + "\n")
        except OSError:
            logger.warning("Failed to persist event to %s", self._persist_path)

    def load_from_file(self) -> int:
        """Load events from persistence file. Returns count loaded."""
        if not self._persist_path or not self._persist_path.exists():
            return 0
        count = 0
        with open(self._persist_path) as f:
            for line in f:
                line = line.strip()
                if line:
                    event = ShieldEvent.model_validate_json(line)
                    self._events.append(event)
                    count += 1
        return count
