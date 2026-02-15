"""Configuration management for Iron Forge CLI.

Handles loading, saving, and validating project and global configuration
using TOML format with Pydantic models for type safety.
"""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

import tomli_w
from pydantic import BaseModel, Field

if sys.version_info >= (3, 11):
    import tomllib
else:
    import tomli as tomllib

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

GLOBAL_CONFIG_DIR = Path.home() / ".ironforge"
GLOBAL_CONFIG_FILE = GLOBAL_CONFIG_DIR / "config.toml"
PROJECT_CONFIG_FILE = "ironforge.toml"

DEFAULT_BUILD_DIR = "dist"
DEFAULT_SRC_DIR = "src"

# ---------------------------------------------------------------------------
# Pydantic models
# ---------------------------------------------------------------------------


class BuildConfig(BaseModel):
    """Build-related settings."""

    output_dir: str = Field(default=DEFAULT_BUILD_DIR, description="Build output directory")
    src_dir: str = Field(default=DEFAULT_SRC_DIR, description="Source directory")
    targets: list[str] = Field(default_factory=lambda: ["default"], description="Build targets")
    parallel: bool = Field(default=True, description="Enable parallel builds")
    optimization: str = Field(default="standard", description="Optimization level")


class ProjectConfig(BaseModel):
    """Per-project configuration stored in ironforge.toml."""

    name: str = Field(default="untitled", description="Project name")
    version: str = Field(default="0.1.0", description="Project version")
    description: str = Field(default="", description="Project description")
    author: str = Field(default="", description="Project author")
    license: str = Field(default="MIT", description="Project license")
    build: BuildConfig = Field(default_factory=BuildConfig)


class GlobalConfig(BaseModel):
    """Global user-level configuration stored in ~/.ironforge/config.toml."""

    default_license: str = Field(default="MIT", description="Default license for new projects")
    default_author: str = Field(default="", description="Default author name")
    color: bool = Field(default=True, description="Enable color output")
    verbose: bool = Field(default=False, description="Enable verbose output")
    editor: str = Field(default="", description="Preferred editor command")
    profile: str = Field(default="default", description="Active configuration profile")


# ---------------------------------------------------------------------------
# Config I/O helpers
# ---------------------------------------------------------------------------


def _load_toml(path: Path) -> dict[str, Any]:
    """Load a TOML file and return the parsed dict."""
    if not path.is_file():
        return {}
    data = path.read_bytes()
    return tomllib.loads(data.decode("utf-8"))


def _save_toml(path: Path, data: dict[str, Any]) -> None:
    """Serialize *data* and write it to *path* as TOML."""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(tomli_w.dumps(data).encode("utf-8"))


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


def load_project_config(project_dir: Path | None = None) -> ProjectConfig:
    """Load project configuration from *project_dir*/ironforge.toml.

    Falls back to defaults when the file is absent.
    """
    base = project_dir or Path.cwd()
    raw = _load_toml(base / PROJECT_CONFIG_FILE)
    return ProjectConfig(**raw)


def save_project_config(config: ProjectConfig, project_dir: Path | None = None) -> Path:
    """Persist *config* to *project_dir*/ironforge.toml and return the path."""
    base = project_dir or Path.cwd()
    dest = base / PROJECT_CONFIG_FILE
    _save_toml(dest, config.model_dump())
    return dest


def load_global_config() -> GlobalConfig:
    """Load the global configuration from ~/.ironforge/config.toml."""
    raw = _load_toml(GLOBAL_CONFIG_FILE)
    return GlobalConfig(**raw)


def save_global_config(config: GlobalConfig) -> Path:
    """Persist the global config and return the path."""
    _save_toml(GLOBAL_CONFIG_FILE, config.model_dump())
    return GLOBAL_CONFIG_FILE


def ensure_global_config() -> GlobalConfig:
    """Ensure the global config file exists; create with defaults if missing."""
    if not GLOBAL_CONFIG_FILE.is_file():
        cfg = GlobalConfig()
        save_global_config(cfg)
        return cfg
    return load_global_config()


def project_config_exists(project_dir: Path | None = None) -> bool:
    """Return True if an ironforge.toml exists in *project_dir*."""
    base = project_dir or Path.cwd()
    return (base / PROJECT_CONFIG_FILE).is_file()
