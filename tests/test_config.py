"""Tests for configuration management."""

from __future__ import annotations

from pathlib import Path

import pytest

from ironforge.core.config import (
    CONFIG_FILENAME,
    _deep_copy_dict,
    _deep_merge,
    find_project_root,
    load_config,
    load_yaml_config,
    save_config,
    save_project_config,
)


class TestDeepMerge:
    def test_merge_flat(self) -> None:
        base = {"a": 1, "b": 2}
        override = {"b": 3, "c": 4}
        result = _deep_merge(base, override)
        assert result == {"a": 1, "b": 3, "c": 4}

    def test_merge_nested(self) -> None:
        base = {"x": {"a": 1, "b": 2}, "y": 10}
        override = {"x": {"b": 99, "c": 3}}
        result = _deep_merge(base, override)
        assert result == {"x": {"a": 1, "b": 99, "c": 3}, "y": 10}

    def test_merge_empty_override(self) -> None:
        base = {"a": 1}
        result = _deep_merge(base, {})
        assert result == {"a": 1}

    def test_merge_empty_base(self) -> None:
        result = _deep_merge({}, {"a": 1})
        assert result == {"a": 1}


class TestDeepCopy:
    def test_copy_is_independent(self) -> None:
        original = {"a": {"b": [1, 2, 3]}, "c": 4}
        copy = _deep_copy_dict(original)
        copy["a"]["b"].append(4)
        assert original["a"]["b"] == [1, 2, 3]
        assert copy["a"]["b"] == [1, 2, 3, 4]


class TestFindProjectRoot:
    def test_finds_root(self, tmp_project: Path) -> None:
        # Create subdirectory and search from there
        subdir = tmp_project / "src" / "deep" / "nested"
        subdir.mkdir(parents=True)
        result = find_project_root(subdir)
        assert result == tmp_project

    def test_returns_none_when_no_config(self, empty_dir: Path) -> None:
        result = find_project_root(empty_dir)
        assert result is None

    def test_finds_root_at_exact_dir(self, tmp_project: Path) -> None:
        result = find_project_root(tmp_project)
        assert result == tmp_project


class TestLoadConfig:
    def test_load_defaults_when_no_file(self) -> None:
        config = load_config(Path("/nonexistent/path/config.toml"))
        assert "project" in config
        assert "build" in config
        assert "forge" in config

    def test_load_from_file(self, tmp_project: Path) -> None:
        config = load_config(tmp_project / CONFIG_FILENAME)
        assert config["project"]["name"] == "test-project"
        assert config["project"]["version"] == "1.2.3"

    def test_env_override_verbose(self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
        monkeypatch.setenv("IRONFORGE_VERBOSE", "true")
        config = load_config()
        assert config["forge"]["verbose"] is True

    def test_env_override_log_level(self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
        monkeypatch.setenv("IRONFORGE_LOG_LEVEL", "debug")
        config = load_config()
        assert config["forge"]["log_level"] == "DEBUG"


class TestSaveConfig:
    def test_save_and_reload(self, tmp_path: Path) -> None:
        config = {"project": {"name": "saved-project"}, "build": {"target": "out"}}
        path = tmp_path / "sub" / "config.toml"
        save_config(config, path)
        assert path.exists()
        loaded = load_config(path)
        assert loaded["project"]["name"] == "saved-project"

    def test_save_project_config(self, tmp_path: Path) -> None:
        config = {"project": {"name": "my-proj"}}
        result = save_project_config(config, tmp_path)
        assert result == tmp_path / CONFIG_FILENAME
        assert result.exists()


class TestYamlConfig:
    def test_load_yaml(self, tmp_path: Path) -> None:
        yaml_file = tmp_path / "test.yaml"
        yaml_file.write_text("key: value\nnested:\n  a: 1\n")
        result = load_yaml_config(yaml_file)
        assert result["key"] == "value"
        assert result["nested"]["a"] == 1

    def test_load_empty_yaml(self, tmp_path: Path) -> None:
        yaml_file = tmp_path / "empty.yaml"
        yaml_file.write_text("")
        result = load_yaml_config(yaml_file)
        assert result == {}
