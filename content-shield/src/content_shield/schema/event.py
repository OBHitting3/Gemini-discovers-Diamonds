"""Shield event models for content-shield."""

from __future__ import annotations

import enum
from datetime import datetime
from typing import Any
from uuid import UUID

from pydantic import BaseModel, Field


class Severity(str, enum.Enum):
    """Severity levels for shield events."""

    INFO = "info"
    WARNING = "warning"
    ERROR = "error"
    CRITICAL = "critical"


class ShieldEvent(BaseModel):
    """Represents an event emitted by a shield during content checks."""

    event_id: UUID
    shield_name: str
    content_id: str
    timestamp: datetime
    severity: Severity
    passed: bool
    message: str
    details: dict[str, Any] = Field(default_factory=dict)
    metadata: dict[str, Any] | None = None
