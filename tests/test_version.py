"""Tests for ``ironforge version``."""

from __future__ import annotations

from click.testing import CliRunner

from ironforge import __version__
from ironforge.cli import cli


class TestVersionCommand:
    """Tests for the version sub-command."""

    def test_version_full(self):
        runner = CliRunner()
        result = runner.invoke(cli, ["version"])
        assert result.exit_code == 0
        assert __version__ in result.output
        assert "Python" in result.output
        assert "Platform" in result.output

    def test_version_short(self):
        runner = CliRunner()
        result = runner.invoke(cli, ["version", "--short"])
        assert result.exit_code == 0
        assert result.output.strip() == __version__

    def test_version_shows_dependencies(self):
        runner = CliRunner()
        result = runner.invoke(cli, ["version"])
        assert result.exit_code == 0
        assert "Dependencies" in result.output
        assert "click" in result.output
        assert "rich" in result.output
