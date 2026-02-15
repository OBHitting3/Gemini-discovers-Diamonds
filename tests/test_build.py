"""Tests for ``ironforge build``."""

from __future__ import annotations

from pathlib import Path

from click.testing import CliRunner

from ironforge.cli import cli


class TestBuildCommand:
    """Tests for the build sub-command."""

    def test_build_succeeds_after_init(self):
        runner = CliRunner()
        with runner.isolated_filesystem() as td:
            proj = Path(td) / "proj"
            runner.invoke(cli, ["init", "proj", "-d", str(proj)])
            result = runner.invoke(cli, ["build", "-d", str(proj)])
            assert result.exit_code == 0
            assert "Build complete" in result.output

    def test_build_produces_artifacts(self):
        runner = CliRunner()
        with runner.isolated_filesystem() as td:
            proj = Path(td) / "proj"
            runner.invoke(cli, ["init", "proj", "-d", str(proj)])
            runner.invoke(cli, ["build", "-d", str(proj)])
            # Artifact should be in dist/
            assert (proj / "dist" / "main.py").is_file()

    def test_build_fails_without_init(self):
        runner = CliRunner()
        with runner.isolated_filesystem() as td:
            result = runner.invoke(cli, ["build", "-d", str(td)])
            assert result.exit_code != 0 or "No ironforge.toml" in result.output

    def test_build_verbose_shows_artifacts(self):
        runner = CliRunner()
        with runner.isolated_filesystem() as td:
            proj = Path(td) / "proj"
            runner.invoke(cli, ["init", "proj", "-d", str(proj)])
            result = runner.invoke(cli, ["-v", "build", "-d", str(proj)])
            assert result.exit_code == 0
            assert "main.py" in result.output

    def test_build_multiple_source_files(self):
        runner = CliRunner()
        with runner.isolated_filesystem() as td:
            proj = Path(td) / "proj"
            runner.invoke(cli, ["init", "proj", "-d", str(proj)])
            # Add extra source files
            (proj / "src" / "utils.py").write_text("# utils\n")
            (proj / "src" / "lib").mkdir()
            (proj / "src" / "lib" / "helper.py").write_text("# helper\n")
            result = runner.invoke(cli, ["build", "-d", str(proj)])
            assert result.exit_code == 0
            assert "3 artifact" in result.output
