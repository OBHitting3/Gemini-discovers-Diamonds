"""Abstract base class for all content shields."""

from __future__ import annotations

from abc import ABC, abstractmethod

from content_shield.schema import Content, ValidationResult


class BaseShield(ABC):
    """Base class that every shield must inherit from.

    Subclasses must implement :pyattr:`name` and :pymeth:`check`.
    """

    @property
    @abstractmethod
    def name(self) -> str:
        """Human-readable identifier for this shield."""

    @abstractmethod
    async def check(self, content: Content) -> ValidationResult:
        """Run the shield against a single piece of content.

        Args:
            content: The content item to validate.

        Returns:
            A ValidationResult describing whether the content passed
            and any issues found.
        """
