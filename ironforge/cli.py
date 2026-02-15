"""
Iron Forge CLI — Main entry point and command router.

This module defines the root Typer application, registers all command
groups, and handles global options (--verbose, --debug, --version).
"""

from __future__ import annotations

import sys

import typer

import ironforge
from ironforge.core.context import ForgeContext
from ironforge.core.errors import ForgeError
from ironforge.utils.display import console, print_banner, print_error

app = typer.Typer(
    name="ironforge",
    help="Iron Forge CLI Suite — Industrial-strength developer toolkit.",
    add_completion=True,
    no_args_is_help=True,
    rich_markup_mode="rich",
)

# Shared state
_ctx = ForgeContext()


def version_callback(value: bool) -> None:
    """Print version and exit."""
    if value:
        print_banner()
        console.print(f"  [accent]Iron Forge CLI[/accent] v{ironforge.__version__}")
        console.print(f"  [muted]Python {sys.version.split()[0]}[/muted]\n")
        raise typer.Exit()


@app.callback()
def main_callback(
    verbose: bool = typer.Option(False, "--verbose", "-v", help="Enable verbose output."),
    debug: bool = typer.Option(False, "--debug", help="Enable debug logging."),
    version: bool | None = typer.Option(
        None,
        "--version",
        "-V",
        help="Show version and exit.",
        callback=version_callback,
        is_eager=True,
    ),
) -> None:
    """Iron Forge CLI — Industrial-strength developer toolkit."""
    _ctx.verbose = verbose
    _ctx.debug = debug
    _ctx.setup_logging()


# ---------- Register commands from modules ----------
from ironforge.commands.build import build_project  # noqa: E402
from ironforge.commands.check import check_project  # noqa: E402
from ironforge.commands.config import config_app  # noqa: E402
from ironforge.commands.info import show_info  # noqa: E402
from ironforge.commands.init import init_project  # noqa: E402

app.command("init", help="Scaffold a new Iron Forge project.")(init_project)
app.command("build", help="Build and package the project.")(build_project)
app.command("check", help="Run linting and validation checks.")(check_project)
app.add_typer(config_app, name="config", help="View and manage configuration.")
app.command("info", help="Display system and project information.")(show_info)


def main() -> None:
    """CLI entry point invoked by the `ironforge` / `forge` console script."""
    try:
        app()
    except ForgeError as exc:
        print_error(str(exc))
        raise typer.Exit(code=exc.exit_code) from exc
    except KeyboardInterrupt:
        print_error("Interrupted by user.")
        raise typer.Exit(code=130) from None
    except Exception as exc:
        print_error(f"Unexpected error: {exc}")
        raise typer.Exit(code=1) from exc


if __name__ == "__main__":
    main()
