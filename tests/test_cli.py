"""Tests for the main CLI entry point and commands."""

from __future__ import annotations

import os
from pathlib import Path

from typer.testing import CliRunner

from ironforge.cli import app

runner = CliRunner()


class TestMainCLI:
    def test_help(self) -> None:
        result = runner.invoke(app, ["--help"])
        assert result.exit_code == 0
        assert "Iron Forge" in result.output

    def test_version(self) -> None:
        result = runner.invoke(app, ["--version"])
        assert result.exit_code == 0
        assert "1.0.0" in result.output

    def test_no_args_shows_help(self) -> None:
        result = runner.invoke(app, [])
        # no_args_is_help=True causes Typer to show help and exit with code 0
        # Some Typer versions use exit code 0, others 2 for no-args help
        assert result.exit_code in (0, 2)
        assert (
            "Iron Forge" in result.output
            or "Usage" in result.output
            or "ironforge" in result.output
        )


class TestInitCommand:
    def test_init_creates_project(self, tmp_path: Path) -> None:
        result = runner.invoke(app, ["init", "my-app", "--dir", str(tmp_path)])
        assert result.exit_code == 0
        assert "initialized" in result.output.lower() or "my-app" in result.output
        assert (tmp_path / "my-app" / "ironforge.toml").exists()
        assert (tmp_path / "my-app" / "src").is_dir()
        assert (tmp_path / "my-app" / "tests").is_dir()
        assert (tmp_path / "my-app" / "docs").is_dir()

    def test_init_minimal_template(self, tmp_path: Path) -> None:
        result = runner.invoke(
            app, ["init", "min-app", "--dir", str(tmp_path), "--template", "minimal"]
        )
        assert result.exit_code == 0
        assert (tmp_path / "min-app" / "src").is_dir()
        assert not (tmp_path / "min-app" / "docs").is_dir()

    def test_init_library_template(self, tmp_path: Path) -> None:
        result = runner.invoke(
            app, ["init", "lib-app", "--dir", str(tmp_path), "--template", "library"]
        )
        assert result.exit_code == 0
        assert (tmp_path / "lib-app" / "examples").is_dir()

    def test_init_invalid_template(self, tmp_path: Path) -> None:
        result = runner.invoke(
            app, ["init", "bad", "--dir", str(tmp_path), "--template", "nonexistent"]
        )
        assert result.exit_code == 1

    def test_init_no_overwrite_without_force(self, tmp_path: Path) -> None:
        runner.invoke(app, ["init", "dup", "--dir", str(tmp_path)])
        result = runner.invoke(app, ["init", "dup", "--dir", str(tmp_path)])
        assert result.exit_code == 1

    def test_init_force_overwrite(self, tmp_path: Path) -> None:
        runner.invoke(app, ["init", "dup2", "--dir", str(tmp_path)])
        result = runner.invoke(app, ["init", "dup2", "--dir", str(tmp_path), "--force"])
        assert result.exit_code == 0


class TestInfoCommand:
    def test_info_shows_version(self) -> None:
        result = runner.invoke(app, ["info"])
        assert result.exit_code == 0
        assert "1.0.0" in result.output

    def test_info_full(self) -> None:
        result = runner.invoke(app, ["info", "--full"])
        assert result.exit_code == 0
        assert "Python" in result.output

    def test_info_help(self) -> None:
        result = runner.invoke(app, ["info", "--help"])
        assert result.exit_code == 0


class TestConfigCommand:
    def test_config_show(self, tmp_project: Path) -> None:
        os.chdir(tmp_project)
        result = runner.invoke(app, ["config"])
        assert result.exit_code == 0

    def test_config_get(self, tmp_project: Path) -> None:
        os.chdir(tmp_project)
        result = runner.invoke(app, ["config", "get", "project.name"])
        assert result.exit_code == 0
        assert "test-project" in result.output

    def test_config_get_missing_key(self, tmp_project: Path) -> None:
        os.chdir(tmp_project)
        result = runner.invoke(app, ["config", "get", "nonexistent.key"])
        assert result.exit_code == 1

    def test_config_set(self, tmp_project: Path) -> None:
        os.chdir(tmp_project)
        result = runner.invoke(app, ["config", "set", "project.name", "new-name"])
        assert result.exit_code == 0
        # Verify it was saved
        result2 = runner.invoke(app, ["config", "get", "project.name"])
        assert "new-name" in result2.output

    def test_config_path(self, tmp_project: Path) -> None:
        os.chdir(tmp_project)
        result = runner.invoke(app, ["config", "path"])
        assert result.exit_code == 0
        assert "ironforge.toml" in result.output

    def test_config_help(self) -> None:
        result = runner.invoke(app, ["config", "--help"])
        assert result.exit_code == 0


class TestBuildCommand:
    def test_build_no_project(self, empty_dir: Path) -> None:
        os.chdir(empty_dir)
        result = runner.invoke(app, ["build"])
        # Should fail with project not found
        assert result.exit_code != 0

    def test_build_dry_run(self, tmp_project: Path) -> None:
        os.chdir(tmp_project)
        result = runner.invoke(app, ["build", "--dry-run"])
        assert result.exit_code == 0
        assert "dry run" in result.output.lower() or "would" in result.output.lower()

    def test_build_with_clean(self, tmp_project: Path) -> None:
        os.chdir(tmp_project)
        result = runner.invoke(app, ["build", "--clean"])
        assert result.exit_code == 0

    def test_build_help(self) -> None:
        result = runner.invoke(app, ["build", "--help"])
        assert result.exit_code == 0


class TestCheckCommand:
    def test_check_no_project(self, empty_dir: Path) -> None:
        os.chdir(empty_dir)
        result = runner.invoke(app, ["check"])
        # Should report errors
        assert result.exit_code == 1

    def test_check_valid_project(self, tmp_project: Path) -> None:
        os.chdir(tmp_project)
        result = runner.invoke(app, ["check"])
        assert result.exit_code == 0 or "WARN" in result.output

    def test_check_help(self) -> None:
        result = runner.invoke(app, ["check", "--help"])
        assert result.exit_code == 0
