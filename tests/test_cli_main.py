"""Tests for the top-level CLI entry point and global options."""

from __future__ import annotations

from click.testing import CliRunner

from ironforge import __version__
from ironforge.cli import cli


def test_cli_no_subcommand_shows_banner():
    """Invoking ironforge without a sub-command prints the banner + help."""
    runner = CliRunner()
    result = runner.invoke(cli, [])
    assert result.exit_code == 0
    assert "IRON FORGE CLI" in result.output
    assert "Commands:" in result.output


def test_cli_help_flag():
    runner = CliRunner()
    result = runner.invoke(cli, ["--help"])
    assert result.exit_code == 0
    assert "Usage:" in result.output
    assert "init" in result.output
    assert "build" in result.output


def test_cli_short_help_flag():
    runner = CliRunner()
    result = runner.invoke(cli, ["-h"])
    assert result.exit_code == 0
    assert "Usage:" in result.output


def test_cli_version_flag():
    runner = CliRunner()
    result = runner.invoke(cli, ["-V"])
    assert result.exit_code == 0
    assert __version__ in result.output


def test_cli_verbose_flag():
    runner = CliRunner()
    result = runner.invoke(cli, ["-v"])
    assert result.exit_code == 0


def test_cli_debug_flag():
    runner = CliRunner()
    result = runner.invoke(cli, ["--debug"])
    assert result.exit_code == 0


def test_cli_unknown_command():
    runner = CliRunner()
    result = runner.invoke(cli, ["nonexistent"])
    assert result.exit_code != 0
