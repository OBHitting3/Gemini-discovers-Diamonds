"""``ironforge config`` — view and manage configuration."""

from __future__ import annotations

from pathlib import Path

import click

from ironforge.core.config import (
    load_global_config,
    load_project_config,
    project_config_exists,
    save_global_config,
    save_project_config,
)
from ironforge.utils.output import console, header, info, kv, success, warning


@click.group(invoke_without_command=True)
@click.pass_context
def config(ctx: click.Context) -> None:
    """View and manage Iron Forge configuration.

    Without a sub-command, displays the current effective configuration.
    """
    if ctx.invoked_subcommand is not None:
        return

    # Show merged view
    header("Global Configuration")
    gcfg = load_global_config()
    for field_name, value in gcfg.model_dump().items():
        kv(field_name, value)

    if project_config_exists():
        header("Project Configuration")
        pcfg = load_project_config()
        for field_name, value in pcfg.model_dump().items():
            if isinstance(value, dict):
                kv(field_name, "")
                for k, v in value.items():
                    kv(f"  {k}", v, indent=4)
            else:
                kv(field_name, value)
    else:
        console.print()
        warning("No project configuration found in current directory.")


@config.command("set")
@click.argument("key")
@click.argument("value")
@click.option("--global", "is_global", is_flag=True, default=False, help="Set in global config.")
@click.pass_context
def config_set(ctx: click.Context, key: str, value: str, is_global: bool) -> None:
    """Set a configuration value.

    KEY uses dot-notation (e.g. build.output_dir).
    """
    if is_global:
        cfg = load_global_config()
        data = cfg.model_dump()
        _set_nested(data, key, _coerce(value))
        from ironforge.core.config import GlobalConfig

        new_cfg = GlobalConfig(**data)
        save_global_config(new_cfg)
        success(f"Global config: {key} = {value}")
    else:
        if not project_config_exists():
            warning("No project config found. Use `ironforge init` first or pass --global.")
            ctx.exit(1)
            return
        cfg = load_project_config()
        data = cfg.model_dump()
        _set_nested(data, key, _coerce(value))
        from ironforge.core.config import ProjectConfig

        new_cfg = ProjectConfig(**data)
        save_project_config(new_cfg)
        success(f"Project config: {key} = {value}")


@config.command("get")
@click.argument("key")
@click.option("--global", "is_global", is_flag=True, default=False, help="Read from global config.")
def config_get(key: str, is_global: bool) -> None:
    """Get a configuration value by KEY (dot-notation)."""
    if is_global:
        cfg = load_global_config()
        data = cfg.model_dump()
    else:
        cfg = load_project_config()  # type: ignore[assignment]
        data = cfg.model_dump()

    val = _get_nested(data, key)
    if val is None:
        warning(f"Key '{key}' not found.")
    else:
        info(f"{key} = {val}")


@config.command("list")
@click.option("--global", "is_global", is_flag=True, default=False, help="List global config.")
def config_list(is_global: bool) -> None:
    """List all configuration keys and values."""
    if is_global:
        cfg = load_global_config()
        header("Global Configuration")
    else:
        cfg = load_project_config()  # type: ignore[assignment]
        header("Project Configuration")

    for field_name, value in cfg.model_dump().items():
        if isinstance(value, dict):
            for k, v in value.items():
                kv(f"{field_name}.{k}", v)
        else:
            kv(field_name, value)


@config.command("path")
@click.option("--global", "is_global", is_flag=True, default=False, help="Show global config path.")
def config_path(is_global: bool) -> None:
    """Show the path to the active configuration file."""
    if is_global:
        from ironforge.core.config import GLOBAL_CONFIG_FILE

        info(f"Global config: {GLOBAL_CONFIG_FILE}")
    else:
        path = Path.cwd() / "ironforge.toml"
        if path.is_file():
            info(f"Project config: {path}")
        else:
            warning("No project config in current directory.")


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _set_nested(data: dict, dotted_key: str, value: object) -> None:
    """Set a value in a nested dict using dot-notation key."""
    keys = dotted_key.split(".")
    current = data
    for k in keys[:-1]:
        current = current.setdefault(k, {})
    current[keys[-1]] = value


def _get_nested(data: dict, dotted_key: str) -> object:
    """Get a value from a nested dict using dot-notation key."""
    keys = dotted_key.split(".")
    current = data
    for k in keys:
        if isinstance(current, dict) and k in current:
            current = current[k]
        else:
            return None
    return current


def _coerce(value: str) -> str | bool | int | float:
    """Best-effort coercion of a string value to a Python type."""
    if value.lower() in ("true", "yes", "1", "on"):
        return True
    if value.lower() in ("false", "no", "0", "off"):
        return False
    try:
        return int(value)
    except ValueError:
        pass
    try:
        return float(value)
    except ValueError:
        pass
    return value
