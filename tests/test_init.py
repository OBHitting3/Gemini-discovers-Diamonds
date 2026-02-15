"""Tests for ``ironforge init``."""

from __future__ import annotations

from pathlib import Path

from click.testing import CliRunner

from ironforge.cli import cli


class TestInitCommand:
    """Tests for the init sub-command."""

    def test_init_creates_project(self):
        runner = CliRunner()
        with runner.isolated_filesystem() as td:
            result = runner.invoke(cli, ["init", "myproj", "-d", str(Path(td) / "myproj")])
            assert result.exit_code == 0, result.output
            assert "initialised successfully" in result.output.lower() or "initialised" in result.output.lower()

            proj = Path(td) / "myproj"
            assert (proj / "ironforge.toml").is_file()
            assert (proj / "src").is_dir()
            assert (proj / "dist").is_dir()
            assert (proj / "src" / "main.py").is_file()

    def test_init_uses_cwd_name_when_no_name(self):
        runner = CliRunner()
        with runner.isolated_filesystem() as td:
            result = runner.invoke(cli, ["init", "-d", str(td)])
            assert result.exit_code == 0
            assert (Path(td) / "ironforge.toml").is_file()

    def test_init_custom_version(self):
        runner = CliRunner()
        with runner.isolated_filesystem() as td:
            proj = Path(td) / "proj"
            result = runner.invoke(cli, ["init", "proj", "-d", str(proj), "--version", "2.0.0"])
            assert result.exit_code == 0
            assert "2.0.0" in result.output

    def test_init_refuses_duplicate_without_force(self):
        runner = CliRunner()
        with runner.isolated_filesystem() as td:
            proj = Path(td) / "proj"
            runner.invoke(cli, ["init", "proj", "-d", str(proj)])
            result = runner.invoke(cli, ["init", "proj", "-d", str(proj)])
            assert result.exit_code != 0 or "--force" in result.output

    def test_init_force_overwrites(self):
        runner = CliRunner()
        with runner.isolated_filesystem() as td:
            proj = Path(td) / "proj"
            runner.invoke(cli, ["init", "proj", "-d", str(proj)])
            result = runner.invoke(cli, ["init", "proj", "-d", str(proj), "--force"])
            assert result.exit_code == 0
            assert "initialised" in result.output.lower()

    def test_init_with_all_options(self):
        runner = CliRunner()
        with runner.isolated_filesystem() as td:
            proj = Path(td) / "fullproj"
            result = runner.invoke(
                cli,
                [
                    "init",
                    "fullproj",
                    "-d",
                    str(proj),
                    "--version",
                    "1.2.3",
                    "--description",
                    "A full project",
                    "--author",
                    "Tester",
                    "--license",
                    "Apache-2.0",
                ],
            )
            assert result.exit_code == 0
            assert "fullproj" in result.output
            assert "Apache-2.0" in result.output
