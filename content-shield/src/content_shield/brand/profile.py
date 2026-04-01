"""Brand profile model for content-shield."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from pydantic import BaseModel, Field


class BrandProfile(BaseModel):
    """Defines a brand's voice, tone, and terminology standards.

    A brand profile captures the key attributes that make a brand's
    communication consistent and recognizable. It is used by the
    VoiceMatcher and TerminologyChecker to evaluate and correct content.
    """

    name: str = Field(description="Brand or organization name")
    voice_attributes: list[str] = Field(
        default_factory=list,
        description='Adjectives describing the brand voice, e.g. ["professional", "warm"]',
    )
    tone: str = Field(
        default="neutral",
        description="Overall tone of the brand, e.g. 'formal', 'conversational'",
    )
    banned_words: list[str] = Field(
        default_factory=list,
        description="Words or phrases that must never appear in brand content",
    )
    required_terminology: dict[str, str] = Field(
        default_factory=dict,
        description="Mapping of incorrect terms to their correct replacements",
    )
    target_audience: str = Field(
        default="general",
        description="Primary audience for the brand's content",
    )
    industry: str = Field(
        default="general",
        description="Industry or vertical the brand operates in",
    )

    @classmethod
    def from_json(cls, path: str | Path) -> BrandProfile:
        """Load a brand profile from a JSON file.

        Args:
            path: Path to the JSON file containing the brand profile.

        Returns:
            A BrandProfile instance populated from the JSON data.

        Raises:
            FileNotFoundError: If the JSON file does not exist.
            json.JSONDecodeError: If the file contains invalid JSON.
        """
        path = Path(path)
        data: dict[str, Any] = json.loads(path.read_text(encoding="utf-8"))
        return cls.model_validate(data)

    def to_json(self, path: str | Path) -> None:
        """Persist the brand profile to a JSON file.

        Args:
            path: Destination file path.  Parent directories are created
                  automatically if they do not exist.
        """
        path = Path(path)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(
            self.model_dump_json(indent=2) + "\n",
            encoding="utf-8",
        )
