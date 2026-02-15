"""Tests for version and package metadata."""

from __future__ import annotations

import ironforge


def test_version_is_string() -> None:
    """Version should be a non-empty string."""
    assert isinstance(ironforge.__version__, str)
    assert len(ironforge.__version__) > 0


def test_version_format() -> None:
    """Version should be valid semver."""
    parts = ironforge.__version__.split(".")
    assert len(parts) == 3
    assert all(p.isdigit() for p in parts)


def test_app_name() -> None:
    """App name should be 'ironforge'."""
    assert ironforge.__app_name__ == "ironforge"
