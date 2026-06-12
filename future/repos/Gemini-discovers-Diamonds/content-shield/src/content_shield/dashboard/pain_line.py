"""Pain Line tracking for content quality monitoring."""

from __future__ import annotations

import logging
from dataclasses import dataclass, field
from datetime import datetime

logger = logging.getLogger(__name__)


@dataclass
class PainPoint:
    """A single pain point measurement."""

    timestamp: datetime
    score: float  # 0-100, higher = more pain
    shield_name: str
    description: str


class PainLineTracker:
    """Tracks pain line metrics over time.

    The Pain Line represents cumulative content quality issues,
    helping teams visualize problem trends and set quality thresholds.
    """

    def __init__(self, threshold: float = 50.0) -> None:
        self.threshold = threshold
        self._points: list[PainPoint] = []

    def record(self, shield_name: str, score: float, description: str = "") -> PainPoint:
        """Record a pain point."""
        point = PainPoint(
            timestamp=datetime.utcnow(),
            score=score,
            shield_name=shield_name,
            description=description,
        )
        self._points.append(point)
        if score > self.threshold:
            logger.warning("Pain threshold exceeded: %s scored %.1f (threshold=%.1f)", shield_name, score, self.threshold)
        return point

    @property
    def current_score(self) -> float:
        """Calculate the current aggregate pain score."""
        if not self._points:
            return 0.0
        recent = self._points[-10:]  # Last 10 measurements
        return sum(p.score for p in recent) / len(recent)

    @property
    def is_above_threshold(self) -> bool:
        """Check if the current pain score exceeds the threshold."""
        return self.current_score > self.threshold

    def get_history(self, limit: int = 100) -> list[PainPoint]:
        """Get recent pain point history."""
        return list(self._points[-limit:])

    def get_by_shield(self, shield_name: str) -> list[PainPoint]:
        """Get pain points for a specific shield."""
        return [p for p in self._points if p.shield_name == shield_name]

    def clear(self) -> None:
        """Clear all recorded pain points."""
        self._points.clear()
