"""
`ironforge info` — System and project information command.

Displays diagnostic information about the current environment,
Python installation, project status, and available tools.
"""

from __future__ import annotations

import os
import platform
import shutil
import sys

import typer

import ironforge
from ironforge.core.config import find_project_root, load_project_config
from ironforge.utils.display import (
    console,
    create_table,
    print_banner,
    print_header,
    print_info,
    print_key_value,
)

TOOLS_CHECK = ["git", "python3", "pip", "ruff", "mypy", "pytest", "docker", "node", "npm"]


def show_info(
    full: bool = typer.Option(False, "--full", "-f", help="Show extended diagnostics."),
) -> None:
    """Display system and project information."""
    print_banner()

    # Version info
    print_header("Iron Forge CLI")
    print_key_value("Version", ironforge.__version__)
    print_key_value("Python", f"{sys.version}")
    print_key_value("Platform", platform.platform())
    print_key_value("Architecture", platform.machine())

    # Project info
    root = find_project_root()
    print_header("Project")
    if root:
        config = load_project_config()
        print_key_value("Root", str(root))
        print_key_value("Name", config.get("project", {}).get("name", "n/a"))
        print_key_value("Version", config.get("project", {}).get("version", "n/a"))
        print_key_value("Description", config.get("project", {}).get("description", "n/a"))
    else:
        print_info("No Iron Forge project detected in current directory tree.")

    # Environment
    if full:
        print_header("Environment")
        print_key_value("CWD", os.getcwd())
        print_key_value("HOME", str(os.path.expanduser("~")))
        print_key_value("Shell", os.environ.get("SHELL", "unknown"))
        print_key_value("PATH entries", str(len(os.environ.get("PATH", "").split(os.pathsep))))

        # Tool availability
        print_header("Tool Availability")
        table = create_table(
            "Developer Tools",
            [("Tool", "cyan"), ("Status", "bold"), ("Path", "dim")],
        )
        for tool in TOOLS_CHECK:
            path = shutil.which(tool)
            if path:
                table.add_row(tool, "[green]Available[/green]", path)
            else:
                table.add_row(tool, "[red]Not found[/red]", "-")
        console.print(table)
