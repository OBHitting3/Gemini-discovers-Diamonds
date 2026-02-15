"""Tests for ``ironforge config`` and the config core module."""

from __future__ import annotations

from pathlib import Path

from click.testing import CliRunner

from ironforge.cli import cli
from ironforge.core.config import (
    BuildConfig,
    GlobalConfig,
    ProjectConfig,
    load_project_config,
    save_project_config,
)


class TestConfigModels:
    """Tests for Pydantic config models."""

    def test_project_config_defaults(self):
        cfg = ProjectConfig()
        assert cfg.name == "untitled"
        assert cfg.version == "0.1.0"
        assert cfg.build.output_dir == "dist"
        assert cfg.build.src_dir == "src"

    def test_project_config_custom(self):
        cfg = ProjectConfig(name="myapp", version="2.0.0", license="Apache-2.0")
        assert cfg.name == "myapp"
        assert cfg.license == "Apache-2.0"

    def test_build_config_defaults(self):
        bc = BuildConfig()
        assert bc.parallel is True
        assert bc.optimization == "standard"
        assert bc.targets == ["default"]

    def test_global_config_defaults(self):
        gc = GlobalConfig()
        assert gc.default_license == "MIT"
        assert gc.color is True
        assert gc.verbose is False
        assert gc.profile == "default"

    def test_project_config_round_trip(self, tmp_path: Path):
        cfg = ProjectConfig(name="roundtrip", version="3.0.0", description="test")
        save_project_config(cfg, tmp_path)
        loaded = load_project_config(tmp_path)
        assert loaded.name == "roundtrip"
        assert loaded.version == "3.0.0"
        assert loaded.description == "test"

    def test_project_config_model_dump(self):
        cfg = ProjectConfig(name="dump_test")
        data = cfg.model_dump()
        assert isinstance(data, dict)
        assert data["name"] == "dump_test"
        assert "build" in data


class TestConfigCommand:
    """Tests for the config CLI sub-command."""

    def test_config_shows_global(self):
        runner = CliRunner()
        with runner.isolated_filesystem():
            result = runner.invoke(cli, ["config"])
            assert result.exit_code == 0
            assert "Global Configuration" in result.output

    def test_config_list_global(self):
        runner = CliRunner()
        with runner.isolated_filesystem():
            result = runner.invoke(cli, ["config", "list", "--global"])
            assert result.exit_code == 0
            assert "default_license" in result.output

    def test_config_get_project(self):
        runner = CliRunner()
        with runner.isolated_filesystem() as td:
            proj = Path(td)
            runner.invoke(cli, ["init", "cfg_test", "-d", str(proj)])
            result = runner.invoke(cli, ["config", "get", "name"], catch_exceptions=False)
            # We're in the isolated fs which is the proj dir
            assert result.exit_code == 0

    def test_config_set_and_get_project(self):
        runner = CliRunner()
        with runner.isolated_filesystem() as td:
            proj = Path(td)
            runner.invoke(cli, ["init", "cfg_test", "-d", str(proj)])
            runner.invoke(cli, ["config", "set", "version", "9.9.9"])
            result = runner.invoke(cli, ["config", "get", "version"])
            assert result.exit_code == 0
            assert "9.9.9" in result.output

    def test_config_path_global(self):
        runner = CliRunner()
        result = runner.invoke(cli, ["config", "path", "--global"])
        assert result.exit_code == 0
        assert ".ironforge" in result.output
