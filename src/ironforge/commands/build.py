"""``ironforge build`` — build the current project."""

from __future__ import annotations

from pathlib import Path

import click

from ironforge.core.engine import build_project
from ironforge.utils.errors import BuildError
from ironforge.utils.output import console, error, info, kv, success, warning


@click.command()
@click.option(
    "-d",
    "--directory",
    type=click.Path(exists=True, file_okay=False),
    default=None,
    help="Project root directory.",
)
@click.option("--dry-run", is_flag=True, default=False, help="Show what would be built without building.")
@click.pass_context
def build(ctx: click.Context, directory: str | None, dry_run: bool) -> None:
    """Build the current Iron Forge project.

    Collects source artifacts and produces build output.
    """
    project_dir = Path(directory) if directory else Path.cwd()

    if dry_run:
        info("Dry-run mode — no files will be written.")

    info(f"Building project in {project_dir.resolve()}")

    result = build_project(project_dir)

    for w in result.warnings:
        warning(w)

    if not result.success:
        for e in result.errors:
            error(e)
        raise BuildError("Build failed. See errors above.")

    kv("Artifacts", len(result.artifacts))
    kv("Duration", f"{result.duration_seconds:.3f}s")

    if result.artifacts and ctx.obj.get("verbose"):
        console.print()
        for a in result.artifacts:
            console.print(f"  [dim]  {a}[/dim]")

    success(f"Build complete — {len(result.artifacts)} artifact(s) produced.")
