"""``ironforge init`` — scaffold a new project."""

from __future__ import annotations

from pathlib import Path

import click

from ironforge.core.config import project_config_exists
from ironforge.core.engine import init_project
from ironforge.utils.errors import ValidationError
from ironforge.utils.output import error, info, kv, success


@click.command()
@click.argument("name", required=False, default=None)
@click.option("-d", "--directory", type=click.Path(), default=None, help="Target directory.")
@click.option("--version", "proj_version", default="0.1.0", help="Initial version string.")
@click.option("--description", default="", help="Short project description.")
@click.option("--author", default="", help="Author name.")
@click.option("--license", "license_id", default="MIT", help="License identifier (e.g. MIT, Apache-2.0).")
@click.option("-f", "--force", is_flag=True, default=False, help="Overwrite existing config.")
@click.pass_context
def init(
    ctx: click.Context,
    name: str | None,
    directory: str | None,
    proj_version: str,
    description: str,
    author: str,
    license_id: str,
    force: bool,
) -> None:
    """Initialise a new Iron Forge project.

    If NAME is omitted the current directory name is used.
    """
    project_dir = Path(directory) if directory else Path.cwd()
    project_name = name or project_dir.resolve().name

    if not project_name.strip():
        raise ValidationError("Project name must not be empty.")

    if project_config_exists(project_dir) and not force:
        error(f"Project already initialised in {project_dir}.")
        error("Use --force to overwrite.")
        ctx.exit(1)
        return

    info(f"Initialising project [bold]{project_name}[/bold] in {project_dir.resolve()}")

    config = init_project(
        project_dir=project_dir,
        name=project_name,
        version=proj_version,
        description=description,
        author=author,
        license_id=license_id,
    )

    kv("Name", config.name)
    kv("Version", config.version)
    kv("Source dir", config.build.src_dir)
    kv("Build dir", config.build.output_dir)
    kv("License", config.license)

    success("Project initialised successfully.")
