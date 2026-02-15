"""
`ironforge build` — Build orchestration command.

Handles project building with configurable targets, clean builds,
and step-by-step progress reporting.
"""

from __future__ import annotations

import time

import typer

from ironforge.core.config import find_project_root, load_project_config
from ironforge.core.errors import BuildError, ProjectNotFoundError
from ironforge.utils.display import (
    console,
    print_info,
    print_key_value,
    print_success,
    print_warning,
)
from ironforge.utils.fs import clean_dir, collect_files, ensure_dir


def build_project(
    target: str = typer.Option("dist", "--target", "-t", help="Build output directory."),
    clean: bool = typer.Option(False, "--clean", "-c", help="Clean target before building."),
    dry_run: bool = typer.Option(False, "--dry-run", "-n", help="Show what would be built."),
) -> None:
    """Build the current Iron Forge project."""
    root = find_project_root()
    if root is None:
        raise ProjectNotFoundError()

    config = load_project_config()
    project_name = config.get("project", {}).get("name", "unknown")
    target_dir = root / target

    print_info(f"Building project: {project_name}")
    print_key_value("Root", str(root))
    print_key_value("Target", str(target_dir))

    if dry_run:
        print_warning("Dry run — no files will be modified.")

    # Step 1: Clean (if requested)
    if clean:
        if dry_run:
            print_info(f"Would clean: {target_dir}")
        else:
            clean_dir(target_dir)
            print_info("Cleaned target directory.")

    # Step 2: Ensure output directory
    if not dry_run:
        ensure_dir(target_dir)

    # Step 3: Discover source files
    src_dir = root / "src"
    if not src_dir.is_dir():
        print_warning("No 'src' directory found. Creating empty build artifact.")
        if not dry_run:
            ensure_dir(src_dir)

    source_files = collect_files(src_dir)
    print_key_value("Source files", str(len(source_files)))

    # Step 4: Build (copy source to target as a simple build step)
    start = time.monotonic()
    built_count = 0

    if not dry_run:
        with console.status("[bold green]Building...") as _status:
            for src_file in source_files:
                rel = src_file.relative_to(src_dir)
                dst = target_dir / rel
                dst.parent.mkdir(parents=True, exist_ok=True)
                dst.write_bytes(src_file.read_bytes())
                built_count += 1

        # Write build manifest
        manifest = target_dir / "BUILD_MANIFEST"
        manifest.write_text(
            f"project={project_name}\nfiles={built_count}\ntimestamp={time.time()}\n"
        )
    else:
        for src_file in source_files:
            rel = src_file.relative_to(src_dir)
            print_info(f"  Would copy: {rel}")
            built_count += 1

    elapsed = time.monotonic() - start

    if built_count == 0 and not dry_run:
        raise BuildError("No source files found to build.")

    print_success(f"Build complete! {built_count} file(s) in {elapsed:.2f}s -> {target_dir}")
