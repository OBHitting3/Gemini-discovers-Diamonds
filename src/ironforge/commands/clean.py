"""``ironforge clean`` — remove build artifacts."""

from __future__ import annotations

from pathlib import Path

import click

from ironforge.core.engine import clean_project
from ironforge.utils.output import error, info, kv, success


@click.command()
@click.option(
    "-d",
    "--directory",
    type=click.Path(exists=True, file_okay=False),
    default=None,
    help="Project root directory.",
)
@click.option("--full", is_flag=True, default=False, help="Remove the entire build directory.")
@click.option("-y", "--yes", is_flag=True, default=False, help="Skip confirmation prompt.")
@click.pass_context
def clean(ctx: click.Context, directory: str | None, full: bool, yes: bool) -> None:
    """Remove build artifacts from the project.

    By default only files inside the build directory are removed.
    Use --full to delete the build directory entirely.
    """
    project_dir = Path(directory) if directory else Path.cwd()

    if not yes:
        mode = "full clean (remove build dir)" if full else "clean build artifacts"
        if not click.confirm(f"Proceed with {mode}?", default=True):
            info("Clean cancelled.")
            return

    info(f"Cleaning project in {project_dir.resolve()}")

    result = clean_project(project_dir, full=full)

    if not result.success:
        error("Clean failed — is this an Iron Forge project?")
        ctx.exit(1)
        return

    kv("Files removed", result.files_removed)
    kv("Dirs removed", result.dirs_removed)
    kv("Space freed", _human_size(result.bytes_freed))

    success("Clean complete.")


def _human_size(nbytes: int) -> str:
    """Convert byte count to human-readable string."""
    for unit in ("B", "KB", "MB", "GB"):
        if abs(nbytes) < 1024:
            return f"{nbytes:.1f} {unit}"
        nbytes /= 1024  # type: ignore[assignment]
    return f"{nbytes:.1f} TB"
