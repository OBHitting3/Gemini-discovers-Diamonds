"""Content models for content-shield."""

from __future__ import annotations

import enum
from datetime import datetime, timezone
from typing import Any
from uuid import UUID, uuid4

from pydantic import BaseModel, Field


class ContentType(str, enum.Enum):
    """Supported content types."""

    MARKETING = "marketing"
    BLOG = "blog"
    EMAIL = "email"
    SOCIAL = "social"
    PRODUCT = "product"
    LEGAL = "legal"


class Content(BaseModel):
    """A piece of content to be analyzed by shields."""

    content_id: UUID = Field(default_factory=uuid4)
    text: str
    content_type: ContentType
    language: str = "en"
    metadata: dict[str, Any] | None = None
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


class ContentBatch(BaseModel):
    """A batch of content items for bulk processing."""

    items: list[Content]
