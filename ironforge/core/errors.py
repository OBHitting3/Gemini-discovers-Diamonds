"""
Custom exception hierarchy for Iron Forge CLI.

All forge-specific errors inherit from ForgeError so callers can
catch a single base class while still distinguishing specific failures.
"""

from __future__ import annotations


class ForgeError(Exception):
    """Base exception for all Iron Forge errors."""

    def __init__(self, message: str, exit_code: int = 1) -> None:
        super().__init__(message)
        self.exit_code = exit_code


class ConfigError(ForgeError):
    """Raised when configuration is invalid or missing."""

    def __init__(self, message: str) -> None:
        super().__init__(f"Configuration error: {message}", exit_code=2)


class ProjectNotFoundError(ForgeError):
    """Raised when no ironforge.toml project root can be located."""

    def __init__(self) -> None:
        super().__init__(
            "No ironforge.toml found. Run 'ironforge init' to create a project.",
            exit_code=3,
        )


class BuildError(ForgeError):
    """Raised when a build step fails."""

    def __init__(self, message: str) -> None:
        super().__init__(f"Build failed: {message}", exit_code=4)


class CommandNotFoundError(ForgeError):
    """Raised when an external command dependency is missing."""

    def __init__(self, command: str) -> None:
        super().__init__(
            f"Required command not found: {command}. Please install it first.",
            exit_code=5,
        )
