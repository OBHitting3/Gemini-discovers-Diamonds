"""Shared fixtures for Iron Forge CLI tests."""

from __future__ import annotations

import os
from pathlib import Path

import pytest

from ironforge.core.config import CONFIG_FILENAME, DEFAULT_CONFIG, save_project_config


@pytest.fixture
def tmp_project(tmp_path: Path) -> Path:
    """Create a minimal Iron Forge project in a temp directory."""
    config = dict(DEFAULT_CONFIG)
    config["project"] = {
        "name": "test-project",
        "version": "1.2.3",
        "description": "A test project.",
    }
    save_project_config(config, tmp_path)
    (tmp_path / "src").mkdir()
    (tmp_path / "tests").mkdir()
    # Add a sample source file
    (tmp_path / "src" / "main.py").write_text("print('hello')\n")
    return tmp_path


@pytest.fixture
def empty_dir(tmp_path: Path) -> Path:
    """Return an empty temp directory with no project files."""
    return tmp_path


@pytest.fixture
def chdir_tmp(tmp_path: Path) -> Path:
    """Change working directory to tmp_path for the test, restore after."""
    original = os.getcwd()
    os.chdir(tmp_path)
    yield tmp_path
    os.chdir(original)
