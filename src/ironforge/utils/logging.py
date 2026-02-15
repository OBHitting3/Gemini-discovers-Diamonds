"""Logging configuration for Iron Forge CLI.

Provides structured logging with both file and console handlers.
"""

from __future__ import annotations

import logging
import sys
from pathlib import Path

LOG_DIR = Path.home() / ".ironforge" / "logs"
LOG_FILE = LOG_DIR / "ironforge.log"

_configured = False


def setup_logging(*, verbose: bool = False, debug: bool = False) -> logging.Logger:
    """Configure and return the root Iron Forge logger.

    Parameters
    ----------
    verbose:
        If True, set console output to INFO.
    debug:
        If True, set console output to DEBUG and enable file logging.
    """
    global _configured  # noqa: PLW0603

    logger = logging.getLogger("ironforge")

    if _configured:
        return logger

    logger.setLevel(logging.DEBUG)

    # Console handler
    console_handler = logging.StreamHandler(sys.stderr)
    if debug:
        console_handler.setLevel(logging.DEBUG)
    elif verbose:
        console_handler.setLevel(logging.INFO)
    else:
        console_handler.setLevel(logging.WARNING)

    console_fmt = logging.Formatter("[%(levelname)s] %(message)s")
    console_handler.setFormatter(console_fmt)
    logger.addHandler(console_handler)

    # File handler (only in debug mode)
    if debug:
        LOG_DIR.mkdir(parents=True, exist_ok=True)
        file_handler = logging.FileHandler(LOG_FILE, encoding="utf-8")
        file_handler.setLevel(logging.DEBUG)
        file_fmt = logging.Formatter(
            "%(asctime)s [%(levelname)-8s] %(name)s: %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S",
        )
        file_handler.setFormatter(file_fmt)
        logger.addHandler(file_handler)

    _configured = True
    return logger


def get_logger(name: str = "ironforge") -> logging.Logger:
    """Return a child logger under the ironforge namespace."""
    return logging.getLogger(f"ironforge.{name}")
