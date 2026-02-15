"""
Filesystem utilities for Iron Forge CLI.

Safe helpers for directory creation, file discovery, path validation,
and temporary workspace management.
"""

from __future__ import annotations

import shutil
from pathlib import Path


def ensure_dir(path: Path) -> Path:
    """Create directory (and parents) if it doesn't exist. Returns the path."""
    path.mkdir(parents=True, exist_ok=True)
    return path


def clean_dir(path: Path) -> None:
    """Remove a directory tree if it exists, then recreate it empty."""
    if path.exists():
        shutil.rmtree(path)
    path.mkdir(parents=True, exist_ok=True)


def safe_copy(src: Path, dst: Path) -> Path:
    """Copy a file, creating parent directories as needed. Returns destination."""
    dst.parent.mkdir(parents=True, exist_ok=True)
    return Path(shutil.copy2(src, dst))


def collect_files(
    root: Path,
    extensions: list[str] | None = None,
    exclude_dirs: list[str] | None = None,
) -> list[Path]:
    """Recursively collect files under root, optionally filtering by extension.

    Args:
        root: Directory to search.
        extensions: If set, only include files with these suffixes (e.g. [".py", ".toml"]).
        exclude_dirs: Directory names to skip (e.g. ["__pycache__", ".git"]).

    Returns:
        Sorted list of matching file paths.
    """
    exclude = set(exclude_dirs or ["__pycache__", ".git", "node_modules", ".venv", "venv"])
    results: list[Path] = []
    if not root.is_dir():
        return results
    for item in sorted(root.rglob("*")):
        # Skip excluded directories
        if any(part in exclude for part in item.parts):
            continue
        if item.is_file() and (extensions is None or item.suffix in extensions):
            results.append(item)
    return results


def file_size_human(path: Path) -> str:
    """Return a human-readable file size string."""
    size = path.stat().st_size
    for unit in ("B", "KB", "MB", "GB"):
        if size < 1024:
            return f"{size:.1f} {unit}"
        size /= 1024
    return f"{size:.1f} TB"


def is_inside(child: Path, parent: Path) -> bool:
    """Check if child path is contained within parent path."""
    try:
        child.resolve().relative_to(parent.resolve())
        return True
    except ValueError:
        return False
