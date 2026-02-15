"""Iron Forge CLI — main entry point.

This module wires together the Click command group, global options,
and all sub-commands.  It also configures logging and error handling
so that every command gets a consistent runtime environment.
"""

from __future__ import annotations

import sys

import click

from ironforge import __version__
from ironforge.commands.build import build
from ironforge.commands.clean import clean
from ironforge.commands.config_cmd import config
from ironforge.commands.init import init
from ironforge.commands.status import status
from ironforge.commands.version import version
from ironforge.utils.errors import IronForgeError
from ironforge.utils.logging import setup_logging
from ironforge.utils.output import banner, error


class IronForgeCLI(click.Group):
    """Custom Click group with enhanced error handling and help display."""

    def invoke(self, ctx: click.Context) -> None:
        try:
            super().invoke(ctx)
        except IronForgeError as exc:
            error(str(exc))
            ctx.exit(exc.exit_code)
        except click.exceptions.Exit:
            raise
        except Exception as exc:
            error(f"Unexpected error: {exc}")
            ctx.exit(1)


@click.group(
    cls=IronForgeCLI,
    invoke_without_command=True,
    context_settings={"help_option_names": ["-h", "--help"]},
)
@click.option("-v", "--verbose", is_flag=True, default=False, help="Enable verbose output.")
@click.option("--debug", is_flag=True, default=False, help="Enable debug logging.")
@click.option("--no-color", is_flag=True, default=False, help="Disable colour output.")
@click.version_option(__version__, "-V", "--version", prog_name="ironforge")
@click.pass_context
def cli(ctx: click.Context, verbose: bool, debug: bool, no_color: bool) -> None:
    """Iron Forge CLI Suite — developer tooling forged in code.

    Scaffold, build, and manage projects from the command line.
    """
    ctx.ensure_object(dict)
    ctx.obj["verbose"] = verbose
    ctx.obj["debug"] = debug
    ctx.obj["no_color"] = no_color

    setup_logging(verbose=verbose, debug=debug)

    if ctx.invoked_subcommand is None:
        banner()
        click.echo()
        click.echo(ctx.get_help())


# Register sub-commands
cli.add_command(init)
cli.add_command(build)
cli.add_command(status)
cli.add_command(clean)
cli.add_command(config)
cli.add_command(version)


def main() -> None:
    """Package entry point for ``console_scripts``."""
    cli(standalone_mode=False)
    sys.exit(0)


if __name__ == "__main__":
    main()
