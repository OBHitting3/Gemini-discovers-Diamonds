"""
`ironforge init` — Project scaffolding command.

Creates a new Iron Forge project with standard directory layout,
configuration file, and optional template selection.
"""

from __future__ import annotations

from pathlib import Path

import typer

from ironforge.core.config import CONFIG_FILENAME, DEFAULT_CONFIG, save_project_config
from ironforge.utils.display import print_error, print_info, print_key_value, print_success
from ironforge.utils.fs import ensure_dir

TEMPLATES: dict[str, list[str]] = {
    "default": ["src", "tests", "docs"],
    "minimal": ["src"],
    "library": ["src", "tests", "docs", "examples"],
}


def init_project(
    name: str = typer.Argument("my-project", help="Name of the project to create."),
    template: str = typer.Option(
        "default",
        "--template",
        "-t",
        help=f"Project template: {', '.join(TEMPLATES.keys())}.",
    ),
    directory: str = typer.Option(
        ".",
        "--dir",
        "-d",
        help="Parent directory for the project.",
    ),
    force: bool = typer.Option(False, "--force", "-f", help="Overwrite existing configuration."),
) -> None:
    """Initialize a new Iron Forge project."""
    if template not in TEMPLATES:
        print_error(f"Unknown template '{template}'. Choose from: {', '.join(TEMPLATES.keys())}")
        raise typer.Exit(code=1)

    project_dir = Path(directory).resolve() / name if name != "." else Path(directory).resolve()
    config_path = project_dir / CONFIG_FILENAME

    if config_path.exists() and not force:
        print_error(f"Project already initialized at {project_dir}. Use --force to overwrite.")
        raise typer.Exit(code=1)

    # Create directory structure
    ensure_dir(project_dir)
    for subdir in TEMPLATES[template]:
        ensure_dir(project_dir / subdir)
        # Add .gitkeep to empty dirs
        gitkeep = project_dir / subdir / ".gitkeep"
        if not gitkeep.exists():
            gitkeep.touch()

    # Write configuration
    config = dict(DEFAULT_CONFIG)
    config["project"] = {
        "name": name,
        "version": "0.1.0",
        "description": f"{name} — An Iron Forge project.",
    }
    saved = save_project_config(config, project_dir)

    print_success(f"Project '{name}' initialized!")
    print_info("Project structure:")
    print_key_value("Root", str(project_dir))
    print_key_value("Config", str(saved))
    print_key_value("Template", template)
    for subdir in TEMPLATES[template]:
        print_key_value("  Directory", subdir)

    print_info("Next steps: cd into your project and run 'ironforge build'")
