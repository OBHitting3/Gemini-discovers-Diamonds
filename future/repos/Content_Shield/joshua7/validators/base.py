"""Abstract base class for all Joshua 7 validators."""

from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Any

from joshua7.models import ValidationResult


class BaseValidator(ABC):
    """Every validator must subclass this and implement ``validate``."""

    name: str = "base"

    def __init__(self, config: dict[str, Any] | None = None) -> None:
        self.config: dict[str, Any] = config or {}

    @abstractmethod
    def validate(self, text: str) -> ValidationResult:
        """Run the validator against *text* and return a result."""

    def __repr__(self) -> str:
        return f"<{self.__class__.__name__}>"
