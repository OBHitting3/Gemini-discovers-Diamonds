"""
Rich terminal display utilities for Iron Forge CLI.

Provides consistent, beautiful output across all commands with
support for panels, tables, progress bars, and status messages.
"""

from __future__ import annotations

from rich.console import Console
from rich.panel import Panel
from rich.table import Table
from rich.text import Text
from rich.theme import Theme

FORGE_THEME = Theme(
    {
        "info": "cyan",
        "success": "bold green",
        "warning": "bold yellow",
        "error": "bold red",
        "header": "bold magenta",
        "accent": "bold bright_blue",
        "muted": "dim",
        "key": "bold cyan",
        "value": "white",
    }
)

console = Console(theme=FORGE_THEME)
err_console = Console(stderr=True, theme=FORGE_THEME)

BANNER = r"""
  ___                   _____
 |_ _|_ __ ___  _ __   |  ___|__  _ __ __ _  ___
  | || '__/ _ \| '_ \  | |_ / _ \| '__/ _` |/ _ \
  | || | | (_) | | | | |  _| (_) | | | (_| |  __/
 |___|_|  \___/|_| |_| |_|  \___/|_|  \__, |\___|
                                       |___/
"""


def print_banner() -> None:
    """Display the Iron Forge ASCII banner."""
    console.print(Text(BANNER, style="bold bright_blue"))


def print_success(message: str) -> None:
    """Print a success message."""
    console.print(f"[success]  {message}[/success]")


def print_info(message: str) -> None:
    """Print an informational message."""
    console.print(f"[info]  {message}[/info]")


def print_warning(message: str) -> None:
    """Print a warning message."""
    err_console.print(f"[warning]  {message}[/warning]")


def print_error(message: str) -> None:
    """Print an error message."""
    err_console.print(f"[error]  {message}[/error]")


def print_key_value(key: str, value: str) -> None:
    """Print a key-value pair with styling."""
    console.print(f"  [key]{key}:[/key] [value]{value}[/value]")


def print_header(title: str) -> None:
    """Print a styled section header."""
    console.print(f"\n[header]{title}[/header]")
    console.print("[header]" + "─" * len(title) + "[/header]")


def print_panel(content: str, title: str = "", style: str = "cyan") -> None:
    """Print content inside a bordered panel."""
    console.print(Panel(content, title=title, border_style=style, padding=(1, 2)))


def create_table(title: str, columns: list[tuple[str, str]]) -> Table:
    """Create a styled Rich table with the given columns.

    Args:
        title: Table title.
        columns: List of (header, style) tuples.

    Returns:
        A Rich Table ready for row insertion.
    """
    table = Table(title=title, show_header=True, header_style="bold magenta")
    for header, style in columns:
        table.add_column(header, style=style)
    return table
