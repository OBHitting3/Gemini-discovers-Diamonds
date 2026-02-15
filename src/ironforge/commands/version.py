"""``ironforge version`` — display version and environment info."""

from __future__ import annotations

import platform
import sys

import click

from ironforge import __version__
from ironforge.utils.output import console, header, kv


@click.command()
@click.option("--short", is_flag=True, default=False, help="Print only the version number.")
def version(short: bool) -> None:
    """Show Iron Forge version and environment details."""
    if short:
        click.echo(__version__)
        return

    header("Iron Forge CLI")
    kv("Version", __version__)
    kv("Python", f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}")
    kv("Platform", platform.platform())
    kv("Architecture", platform.machine())
    kv("Executable", sys.executable)

    # Show dependency versions
    console.print()
    header("Dependencies")
    _show_dep("click")
    _show_dep("rich")
    _show_dep("pydantic")
    _show_dep("tomli_w")


def _show_dep(name: str) -> None:
    """Print the version of an installed dependency."""
    try:
        from importlib.metadata import version as pkg_version

        ver = pkg_version(name)
        kv(name, ver)
    except Exception:
        kv(name, "not installed")
