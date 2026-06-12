"""Dead Letter Queue for failed events / payloads.

Provides an in-memory queue with optional file-based JSON persistence
so that failed items can be inspected, replayed, or cleared later.
"""

from __future__ import annotations

import json
import threading
import time
import uuid
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Sequence


@dataclass
class DLQEntry:
    """A single dead-letter-queue record."""

    id: str
    payload: Any
    error: str
    error_type: str
    timestamp: float
    metadata: Dict[str, Any] = field(default_factory=dict)
    retry_count: int = 0

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "DLQEntry":
        return cls(**data)


class DeadLetterQueue:
    """Thread-safe dead-letter queue with optional file persistence.

    Parameters
    ----------
    persist_path:
        If provided, the queue is loaded from (and flushed to) this
        JSON file on every mutation.  When *None* the queue is purely
        in-memory.
    max_size:
        Optional upper bound on the number of entries.  When the limit
        is reached the oldest entry is evicted on the next ``enqueue``.
    """

    def __init__(
        self,
        *,
        persist_path: Optional[str | Path] = None,
        max_size: Optional[int] = None,
    ) -> None:
        self._lock = threading.Lock()
        self._entries: List[DLQEntry] = []
        self._persist_path: Optional[Path] = (
            Path(persist_path) if persist_path else None
        )
        self.max_size = max_size

        if self._persist_path and self._persist_path.exists():
            self._load()

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def enqueue(
        self,
        payload: Any,
        error: BaseException,
        *,
        metadata: Optional[Dict[str, Any]] = None,
    ) -> DLQEntry:
        """Add a failed event to the queue.

        Parameters
        ----------
        payload:
            The original event / message that failed processing.
        error:
            The exception that caused the failure.
        metadata:
            Arbitrary key-value pairs to attach to the entry.

        Returns
        -------
        DLQEntry
            The newly created queue entry.
        """
        entry = DLQEntry(
            id=uuid.uuid4().hex,
            payload=payload,
            error=str(error),
            error_type=type(error).__qualname__,
            timestamp=time.time(),
            metadata=metadata or {},
        )
        with self._lock:
            if self.max_size is not None and len(self._entries) >= self.max_size:
                self._entries.pop(0)
            self._entries.append(entry)
            self._flush()
        return entry

    def dequeue(self) -> Optional[DLQEntry]:
        """Remove and return the oldest entry, or *None* if empty."""
        with self._lock:
            if not self._entries:
                return None
            entry = self._entries.pop(0)
            self._flush()
            return entry

    def peek(self, count: int = 1) -> List[DLQEntry]:
        """Return the oldest *count* entries without removing them."""
        with self._lock:
            return list(self._entries[:count])

    def replay(
        self,
        handler: Callable[[Any], Any],
        *,
        max_items: Optional[int] = None,
        remove_on_success: bool = True,
    ) -> Dict[str, Any]:
        """Attempt to replay queued entries through *handler*.

        Parameters
        ----------
        handler:
            A callable that receives the original payload.  If it
            returns without raising, the replay is considered successful.
        max_items:
            Maximum number of entries to replay.  Defaults to all.
        remove_on_success:
            When *True* (default), successfully replayed entries are
            removed from the queue.

        Returns
        -------
        dict
            ``{"succeeded": int, "failed": int, "errors": [str, ...]}``
        """
        with self._lock:
            to_replay = list(
                self._entries[: max_items] if max_items else self._entries
            )

        succeeded = 0
        failed = 0
        errors: List[str] = []
        replayed_ids: List[str] = []

        for entry in to_replay:
            try:
                handler(entry.payload)
                succeeded += 1
                if remove_on_success:
                    replayed_ids.append(entry.id)
            except Exception as exc:
                failed += 1
                errors.append(f"{entry.id}: {exc}")
                with self._lock:
                    # Bump retry count.
                    for e in self._entries:
                        if e.id == entry.id:
                            e.retry_count += 1
                            break

        if replayed_ids:
            with self._lock:
                self._entries = [
                    e for e in self._entries if e.id not in set(replayed_ids)
                ]
                self._flush()

        return {"succeeded": succeeded, "failed": failed, "errors": errors}

    def size(self) -> int:
        """Return the number of entries in the queue."""
        with self._lock:
            return len(self._entries)

    def clear(self) -> int:
        """Remove all entries from the queue. Returns the count removed."""
        with self._lock:
            count = len(self._entries)
            self._entries.clear()
            self._flush()
            return count

    def get_by_id(self, entry_id: str) -> Optional[DLQEntry]:
        """Look up an entry by its unique id."""
        with self._lock:
            for entry in self._entries:
                if entry.id == entry_id:
                    return entry
        return None

    def list_all(self) -> List[DLQEntry]:
        """Return a copy of all entries."""
        with self._lock:
            return list(self._entries)

    # ------------------------------------------------------------------
    # Persistence helpers
    # ------------------------------------------------------------------

    def _flush(self) -> None:
        """Write current state to disk (caller must hold ``_lock``)."""
        if self._persist_path is None:
            return
        self._persist_path.parent.mkdir(parents=True, exist_ok=True)
        data = [e.to_dict() for e in self._entries]
        self._persist_path.write_text(json.dumps(data, default=str))

    def _load(self) -> None:
        """Load state from disk (called once during ``__init__``)."""
        if self._persist_path is None or not self._persist_path.exists():
            return
        try:
            raw = json.loads(self._persist_path.read_text())
            self._entries = [DLQEntry.from_dict(item) for item in raw]
        except (json.JSONDecodeError, KeyError, TypeError):
            # Corrupted file -- start fresh.
            self._entries = []

    def __len__(self) -> int:
        return self.size()

    def __repr__(self) -> str:
        return f"DeadLetterQueue(size={self.size()}, persist={self._persist_path})"
