"""
Execution context for Iron Forge CLI.

Carries shared state (configuration, verbosity, working directory)
across all commands within a single invocation.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from ironforge.core.config import load_project_config


@dataclass
class ForgeContext:
    """Runtime context threaded through every CLI command."""

    verbose: bool = False
    debug: bool = False
    working_dir: Path = field(default_factory=Path.cwd)
    config: dict[str, Any] = field(default_factory=dict)
    _logger: logging.Logger | None = field(default=None, repr=False)

    def __post_init__(self) -> None:
        if not self.config:
            self.config = load_project_config()
        if self._logger is None:
            self._logger = logging.getLogger("ironforge")

    @property
    def logger(self) -> logging.Logger:
        assert self._logger is not None
        return self._logger

    @property
    def project_name(self) -> str:
        return str(self.config.get("project", {}).get("name", ""))

    @property
    def project_version(self) -> str:
        return str(self.config.get("project", {}).get("version", "0.1.0"))

    def setup_logging(self) -> None:
        """Configure logging based on context settings."""
        level = logging.DEBUG if self.debug else (logging.INFO if self.verbose else logging.WARNING)
        log_format = (
            "%(asctime)s [%(levelname)s] %(name)s: %(message)s" if self.debug else "%(message)s"
        )
        logging.basicConfig(level=level, format=log_format, force=True)
        self.logger.setLevel(level)
