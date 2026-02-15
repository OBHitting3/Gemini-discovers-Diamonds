"""
`ironforge config` — Configuration management command.

View, get, set, and reset configuration values for the current
project or global settings.
"""

from __future__ import annotations

import typer

from ironforge.core.config import (
    CONFIG_FILENAME,
    find_project_root,
    load_global_config,
    load_project_config,
    save_global_config,
    save_project_config,
)
from ironforge.utils.display import (
    console,
    create_table,
    print_error,
    print_info,
    print_key_value,
    print_success,
    print_warning,
)

config_app = typer.Typer()


@config_app.callback(invoke_without_command=True)
def config_show(
    ctx: typer.Context,
    global_config: bool = typer.Option(False, "--global", "-g", help="Show global configuration."),
) -> None:
    """Display current configuration."""
    if ctx.invoked_subcommand is not None:
        return

    config = load_global_config() if global_config else load_project_config()
    scope = "Global" if global_config else "Project"

    table = create_table(
        f"{scope} Configuration",
        [("Section", "cyan"), ("Key", "bold"), ("Value", "white")],
    )

    for section, values in sorted(config.items()):
        if isinstance(values, dict):
            for key, value in sorted(values.items()):
                table.add_row(section, key, str(value))
        else:
            table.add_row("", section, str(values))

    console.print(table)


@config_app.command("get")
def config_get(
    key: str = typer.Argument(help="Config key in 'section.key' format."),
    global_config: bool = typer.Option(False, "--global", "-g", help="Read from global config."),
) -> None:
    """Get a specific configuration value."""
    config = load_global_config() if global_config else load_project_config()

    parts = key.split(".", 1)
    if len(parts) == 2:
        section, subkey = parts
        value = config.get(section, {}).get(subkey)
    else:
        value = config.get(key)

    if value is None:
        print_warning(f"Key '{key}' not found.")
        raise typer.Exit(code=1)

    print_key_value(key, str(value))


@config_app.command("set")
def config_set(
    key: str = typer.Argument(help="Config key in 'section.key' format."),
    value: str = typer.Argument(help="Value to set."),
    global_config: bool = typer.Option(False, "--global", "-g", help="Write to global config."),
) -> None:
    """Set a configuration value."""
    config = load_global_config() if global_config else load_project_config()

    parts = key.split(".", 1)
    if len(parts) == 2:
        section, subkey = parts
        if section not in config:
            config[section] = {}
        # Attempt type coercion
        config[section][subkey] = _coerce_value(value)
    else:
        config[key] = _coerce_value(value)

    if global_config:
        save_global_config(config)
    else:
        root = find_project_root()
        if root is None:
            print_error("No project found. Run 'ironforge init' first.")
            raise typer.Exit(code=1)
        save_project_config(config, root)

    print_success(f"Set {key} = {value}")


@config_app.command("path")
def config_path(
    global_config: bool = typer.Option(False, "--global", "-g", help="Show global config path."),
) -> None:
    """Show the path to the active configuration file."""
    if global_config:
        from ironforge.core.config import GLOBAL_CONFIG_FILE

        print_info(f"Global config: {GLOBAL_CONFIG_FILE}")
    else:
        root = find_project_root()
        if root:
            print_info(f"Project config: {root / CONFIG_FILENAME}")
        else:
            print_warning("No project configuration found.")


def _coerce_value(value: str) -> str | int | float | bool:
    """Attempt to coerce a string value to an appropriate Python type."""
    if value.lower() in ("true", "yes"):
        return True
    if value.lower() in ("false", "no"):
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
