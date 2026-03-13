"""Console emitter that pretty-prints shield events to stdout."""

from __future__ import annotations

import structlog

from content_shield.schema.event import ShieldEvent

from .base import BaseEmitter

logger: structlog.stdlib.BoundLogger = structlog.get_logger(__name__)


class ConsoleEmitter(BaseEmitter):
    """Emitter that renders shield events to *stdout* via :mod:`structlog`.

    Parameters
    ----------
    show_details:
        When ``True`` (the default) the ``details`` and ``metadata`` fields
        are included in the log output.
    """

    def __init__(self, *, show_details: bool = True) -> None:
        self._show_details = show_details

    async def emit(self, event: ShieldEvent) -> None:
        """Pretty-print *event* to stdout using structlog."""
        log_kwargs: dict[str, object] = {
            "event_id": str(event.event_id),
            "shield": event.shield_name,
            "content_id": event.content_id,
            "severity": event.severity.value,
            "passed": event.passed,
            "message": event.message,
            "timestamp": event.timestamp.isoformat(),
        }

        if self._show_details:
            if event.details:
                log_kwargs["details"] = event.details
            if event.metadata:
                log_kwargs["metadata"] = event.metadata

        # Route to the appropriate structlog level based on severity.
        severity_to_method = {
            "info": logger.info,
            "warning": logger.warning,
            "error": logger.error,
            "critical": logger.critical,
        }
        log_method = severity_to_method.get(event.severity.value, logger.info)
        log_method("shield_event", **log_kwargs)
