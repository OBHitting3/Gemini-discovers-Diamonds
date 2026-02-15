"""Shared pytest fixtures for Iron Forge CLI tests."""

from __future__ import annotations

from pathlib import Path

import pytest
from click.testing import CliRunner

from ironforge.cli import cli


@pytest.fixture
def runner() -> CliRunner:
    """Click test runner with isolated filesystem."""
    return CliRunner()


@pytest.fixture
def isolated_runner(runner: CliRunner):
    """Yield a Click runner inside an isolated temporary filesystem."""
    with runner.isolated_filesystem() as td:
        yield runner, Path(td)


@pytest.fixture
def init_project(isolated_runner):
    """Return (runner, project_dir) with a pre-initialised project."""
    runner, td = isolated_runner
    result = runner.invoke(cli, ["init", "testproj", "-d", str(td / "testproj")])
    assert result.exit_code == 0, result.output
    return runner, td / "testproj"
