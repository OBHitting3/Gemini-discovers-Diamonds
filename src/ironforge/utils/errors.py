"""Custom exception hierarchy for Iron Forge CLI.

All exceptions inherit from IronForgeError so callers can catch them
uniformly while still being able to handle specific failure modes.
"""

from __future__ import annotations


class IronForgeError(Exception):
    """Base exception for all Iron Forge errors."""

    exit_code: int = 1

    def __init__(self, message: str, *, exit_code: int | None = None) -> None:
        super().__init__(message)
        if exit_code is not None:
            self.exit_code = exit_code


class ConfigError(IronForgeError):
    """Raised for configuration file issues (missing, invalid, corrupt)."""

    exit_code = 2


class ProjectNotFoundError(IronForgeError):
    """Raised when an operation requires a project but none is found."""

    exit_code = 3


class BuildError(IronForgeError):
    """Raised when a build operation fails."""

    exit_code = 4


class ValidationError(IronForgeError):
    """Raised for input validation failures."""

    exit_code = 5
