"""
Configuration management for Iron Forge CLI.

Handles loading, saving, and validating project and global configuration
from TOML/YAML files with sensible defaults and environment overrides.
"""

from __future__ import annotations

import os
from pathlib import Path
from typing import Any

import toml
import yaml

APP_NAME = "ironforge"
CONFIG_FILENAME = "ironforge.toml"
GLOBAL_CONFIG_DIR = Path.home() / f".{APP_NAME}"
GLOBAL_CONFIG_FILE = GLOBAL_CONFIG_DIR / "config.toml"

DEFAULT_CONFIG: dict[str, Any] = {
    "project": {
        "name": "",
        "version": "0.1.0",
        "description": "",
    },
    "build": {
        "target": "dist",
        "clean_before_build": True,
        "parallel": True,
    },
    "lint": {
        "enabled": True,
        "fix_on_check": False,
    },
    "forge": {
        "verbose": False,
        "color": True,
        "log_level": "INFO",
    },
}


def find_project_root(start: Path | None = None) -> Path | None:
    """Walk upward from `start` to find the nearest directory containing ironforge.toml."""
    current = start or Path.cwd()
    for parent in [current, *current.parents]:
        if (parent / CONFIG_FILENAME).is_file():
            return parent
    return None


def load_config(path: Path | None = None) -> dict[str, Any]:
    """Load configuration from a TOML file, merging with defaults."""
    config = _deep_copy_dict(DEFAULT_CONFIG)
    if path and path.is_file():
        with open(path) as f:
            user_config = toml.load(f)
        config = _deep_merge(config, user_config)
    # Environment variable overrides
    env_verbose = os.environ.get("IRONFORGE_VERBOSE")
    if env_verbose is not None:
        config["forge"]["verbose"] = env_verbose.lower() in ("1", "true", "yes")
    env_log = os.environ.get("IRONFORGE_LOG_LEVEL")
    if env_log:
        config["forge"]["log_level"] = env_log.upper()
    return config


def load_project_config() -> dict[str, Any]:
    """Find and load the project-level configuration."""
    root = find_project_root()
    if root:
        return load_config(root / CONFIG_FILENAME)
    return _deep_copy_dict(DEFAULT_CONFIG)


def load_global_config() -> dict[str, Any]:
    """Load the global (~/.ironforge/config.toml) configuration."""
    return load_config(GLOBAL_CONFIG_FILE)


def save_config(config: dict[str, Any], path: Path) -> None:
    """Persist configuration to a TOML file."""
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w") as f:
        toml.dump(config, f)


def save_project_config(config: dict[str, Any], directory: Path | None = None) -> Path:
    """Save project configuration to the given directory (or cwd)."""
    target = (directory or Path.cwd()) / CONFIG_FILENAME
    save_config(config, target)
    return target


def save_global_config(config: dict[str, Any]) -> Path:
    """Save global configuration."""
    save_config(config, GLOBAL_CONFIG_FILE)
    return GLOBAL_CONFIG_FILE


def load_yaml_config(path: Path) -> dict[str, Any]:
    """Load a YAML configuration file."""
    with open(path) as f:
        return yaml.safe_load(f) or {}


def _deep_merge(base: dict[str, Any], override: dict[str, Any]) -> dict[str, Any]:
    """Recursively merge override into base."""
    result = dict(base)
    for key, value in override.items():
        if key in result and isinstance(result[key], dict) and isinstance(value, dict):
            result[key] = _deep_merge(result[key], value)
        else:
            result[key] = value
    return result


def _deep_copy_dict(d: dict[str, Any]) -> dict[str, Any]:
    """Create a deep copy of a nested dict (simple implementation)."""
    result: dict[str, Any] = {}
    for k, v in d.items():
        if isinstance(v, dict):
            result[k] = _deep_copy_dict(v)
        elif isinstance(v, list):
            result[k] = list(v)
        else:
            result[k] = v
    return result
