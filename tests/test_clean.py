"""Tests for ``ironforge clean``."""

from __future__ import annotations

from pathlib import Path

from click.testing import CliRunner

from ironforge.cli import cli


class TestCleanCommand:
    """Tests for the clean sub-command."""

    def test_clean_removes_artifacts(self):
        runner = CliRunner()
        with runner.isolated_filesystem() as td:
            proj = Path(td) / "proj"
            runner.invoke(cli, ["init", "proj", "-d", str(proj)])
            runner.invoke(cli, ["build", "-d", str(proj)])
            assert (proj / "dist" / "main.py").is_file()
            result = runner.invoke(cli, ["clean", "-d", str(proj), "-y"])
            assert result.exit_code == 0
            assert "Clean complete" in result.output
            assert not (proj / "dist" / "main.py").is_file()

    def test_clean_full_removes_build_dir(self):
        runner = CliRunner()
        with runner.isolated_filesystem() as td:
            proj = Path(td) / "proj"
            runner.invoke(cli, ["init", "proj", "-d", str(proj)])
            runner.invoke(cli, ["build", "-d", str(proj)])
            result = runner.invoke(cli, ["clean", "-d", str(proj), "--full", "-y"])
            assert result.exit_code == 0
            assert not (proj / "dist").exists()

    def test_clean_without_project_fails(self):
        runner = CliRunner()
        with runner.isolated_filesystem() as td:
            result = runner.invoke(cli, ["clean", "-d", str(td), "-y"])
            assert result.exit_code != 0 or "failed" in result.output.lower()

    def test_clean_idempotent(self):
        runner = CliRunner()
        with runner.isolated_filesystem() as td:
            proj = Path(td) / "proj"
            runner.invoke(cli, ["init", "proj", "-d", str(proj)])
            runner.invoke(cli, ["clean", "-d", str(proj), "-y"])
            result = runner.invoke(cli, ["clean", "-d", str(proj), "-y"])
            assert result.exit_code == 0
            assert "Files removed" in result.output
