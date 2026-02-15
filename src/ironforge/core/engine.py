"""Iron Forge build engine.

Contains the core logic for project initialization, build orchestration,
clean-up, and status inspection.
"""

from __future__ import annotations

import shutil
import time
from dataclasses import dataclass, field
from pathlib import Path

from ironforge.core.config import (
    BuildConfig,
    ProjectConfig,
    load_project_config,
    project_config_exists,
    save_project_config,
)


# ---------------------------------------------------------------------------
# Data transfer objects
# ---------------------------------------------------------------------------


@dataclass
class BuildResult:
    """Outcome of a build operation."""

    success: bool
    duration_seconds: float
    artifacts: list[str] = field(default_factory=list)
    errors: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)


@dataclass
class ProjectStatus:
    """Snapshot of a project's current state."""

    name: str
    version: str
    config_present: bool
    src_dir_exists: bool
    build_dir_exists: bool
    artifact_count: int
    src_file_count: int


@dataclass
class CleanResult:
    """Outcome of a clean operation."""

    success: bool
    files_removed: int
    dirs_removed: int
    bytes_freed: int


# ---------------------------------------------------------------------------
# Engine functions
# ---------------------------------------------------------------------------


def init_project(
    project_dir: Path,
    name: str,
    version: str = "0.1.0",
    description: str = "",
    author: str = "",
    license_id: str = "MIT",
) -> ProjectConfig:
    """Scaffold a new Iron Forge project in *project_dir*.

    Creates the project directory, source sub-directory, build output
    directory, and writes the initial ``ironforge.toml``.
    """
    project_dir.mkdir(parents=True, exist_ok=True)

    config = ProjectConfig(
        name=name,
        version=version,
        description=description,
        author=author,
        license=license_id,
        build=BuildConfig(),
    )

    # Create conventional directories
    (project_dir / config.build.src_dir).mkdir(parents=True, exist_ok=True)
    (project_dir / config.build.output_dir).mkdir(parents=True, exist_ok=True)

    # Write a placeholder source file so the project isn't empty
    main_file = project_dir / config.build.src_dir / "main.py"
    if not main_file.exists():
        main_file.write_text(
            f'"""Entry point for {name}."""\n\n\ndef main() -> None:\n'
            f'    print("{name} v{version} — forged with Iron Forge")\n\n\n'
            'if __name__ == "__main__":\n    main()\n',
            encoding="utf-8",
        )

    # Write .gitkeep in build dir
    gitkeep = project_dir / config.build.output_dir / ".gitkeep"
    if not gitkeep.exists():
        gitkeep.touch()

    save_project_config(config, project_dir)
    return config


def build_project(project_dir: Path | None = None) -> BuildResult:
    """Execute a build for the project rooted at *project_dir*.

    This is a framework-level build orchestrator.  In Phase 1 it performs
    validation, collects source artifacts, and copies them to the output
    directory as a baseline "build".
    """
    base = project_dir or Path.cwd()
    start = time.monotonic()
    errors: list[str] = []
    warnings: list[str] = []
    artifacts: list[str] = []

    if not project_config_exists(base):
        return BuildResult(
            success=False,
            duration_seconds=time.monotonic() - start,
            errors=["No ironforge.toml found. Run `ironforge init` first."],
        )

    config = load_project_config(base)
    src = base / config.build.src_dir
    out = base / config.build.output_dir

    if not src.is_dir():
        errors.append(f"Source directory '{config.build.src_dir}' does not exist.")
        return BuildResult(
            success=False,
            duration_seconds=time.monotonic() - start,
            errors=errors,
        )

    out.mkdir(parents=True, exist_ok=True)

    # Collect source files
    source_files = list(src.rglob("*"))
    source_files = [f for f in source_files if f.is_file()]

    if not source_files:
        warnings.append("No source files found — nothing to build.")

    # Copy each source file to output, preserving relative structure
    for sf in source_files:
        rel = sf.relative_to(src)
        dest = out / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(sf, dest)
        artifacts.append(str(rel))

    duration = time.monotonic() - start
    return BuildResult(
        success=len(errors) == 0,
        duration_seconds=duration,
        artifacts=artifacts,
        errors=errors,
        warnings=warnings,
    )


def get_project_status(project_dir: Path | None = None) -> ProjectStatus:
    """Inspect and return the current status of a project."""
    base = project_dir or Path.cwd()
    has_config = project_config_exists(base)

    if has_config:
        config = load_project_config(base)
    else:
        config = ProjectConfig()

    src = base / config.build.src_dir
    out = base / config.build.output_dir

    src_files = list(src.rglob("*")) if src.is_dir() else []
    src_file_count = len([f for f in src_files if f.is_file()])

    artifact_files = list(out.rglob("*")) if out.is_dir() else []
    artifact_count = len([f for f in artifact_files if f.is_file() and f.name != ".gitkeep"])

    return ProjectStatus(
        name=config.name,
        version=config.version,
        config_present=has_config,
        src_dir_exists=src.is_dir(),
        build_dir_exists=out.is_dir(),
        artifact_count=artifact_count,
        src_file_count=src_file_count,
    )


def clean_project(project_dir: Path | None = None, *, full: bool = False) -> CleanResult:
    """Remove build artifacts from *project_dir*.

    When *full* is True, removes the entire build directory.  Otherwise
    only files inside the build directory are removed.
    """
    base = project_dir or Path.cwd()

    if not project_config_exists(base):
        return CleanResult(success=False, files_removed=0, dirs_removed=0, bytes_freed=0)

    config = load_project_config(base)
    out = base / config.build.output_dir

    if not out.is_dir():
        return CleanResult(success=True, files_removed=0, dirs_removed=0, bytes_freed=0)

    files_removed = 0
    dirs_removed = 0
    bytes_freed = 0

    if full:
        # Calculate sizes first
        for item in out.rglob("*"):
            if item.is_file():
                bytes_freed += item.stat().st_size
                files_removed += 1
            elif item.is_dir():
                dirs_removed += 1
        shutil.rmtree(out)
        dirs_removed += 1  # The output dir itself
    else:
        for item in sorted(out.rglob("*"), reverse=True):
            if item.is_file() and item.name != ".gitkeep":
                bytes_freed += item.stat().st_size
                item.unlink()
                files_removed += 1
            elif item.is_dir() and not any(item.iterdir()):
                item.rmdir()
                dirs_removed += 1

    return CleanResult(
        success=True,
        files_removed=files_removed,
        dirs_removed=dirs_removed,
        bytes_freed=bytes_freed,
    )
