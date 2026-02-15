"""Rich terminal output helpers for Iron Forge CLI.

Provides consistent, colour-coded output across all commands with
graceful degradation when Rich is unavailable or colour is disabled.
"""

from __future__ import annotations

from typing import Any

from rich.console import Console
from rich.panel import Panel
from rich.table import Table
from rich.theme import Theme

# ---------------------------------------------------------------------------
# Theme
# ---------------------------------------------------------------------------

IRONFORGE_THEME = Theme(
    {
        "info": "cyan",
        "success": "bold green",
        "warning": "bold yellow",
        "error": "bold red",
        "header": "bold magenta",
        "key": "bold white",
        "value": "dim white",
        "accent": "bold bright_blue",
    }
)

# Shared console instance
console = Console(theme=IRONFORGE_THEME)
err_console = Console(theme=IRONFORGE_THEME, stderr=True)

# ---------------------------------------------------------------------------
# Convenience printers
# ---------------------------------------------------------------------------

ANVIL = "\u2692"  # ⚒
CHECK = "\u2714"  # ✔
CROSS = "\u2718"  # ✘
WARN = "\u26A0"   # ⚠
GEAR = "\u2699"   # ⚙
FIRE = "\U0001F525"  # 🔥


def banner() -> None:
    """Print the Iron Forge banner."""
    text = (
        f"[accent]{ANVIL}  IRON FORGE CLI v1.0.0[/accent]\n"
        "[dim]Developer tooling — forged in code[/dim]"
    )
    console.print(Panel(text, border_style="bright_blue", padding=(1, 2)))


def info(msg: str, **kw: Any) -> None:
    """Print an informational message."""
    console.print(f"[info]{GEAR}  {msg}[/info]", **kw)


def success(msg: str, **kw: Any) -> None:
    """Print a success message."""
    console.print(f"[success]{CHECK}  {msg}[/success]", **kw)


def warning(msg: str, **kw: Any) -> None:
    """Print a warning message."""
    err_console.print(f"[warning]{WARN}  {msg}[/warning]", **kw)


def error(msg: str, **kw: Any) -> None:
    """Print an error message."""
    err_console.print(f"[error]{CROSS}  {msg}[/error]", **kw)


def kv(key: str, value: Any, indent: int = 2) -> None:
    """Print a key-value pair."""
    pad = " " * indent
    console.print(f"{pad}[key]{key}:[/key] [value]{value}[/value]")


def header(title: str) -> None:
    """Print a section header."""
    console.print(f"\n[header]{title}[/header]")
    console.print("[dim]" + "─" * min(len(title) + 4, 60) + "[/dim]")


def make_table(title: str, columns: list[tuple[str, str]], rows: list[list[str]]) -> Table:
    """Create and return a Rich Table.

    *columns* is a list of (header, style) tuples.
    """
    table = Table(title=title, show_header=True, header_style="bold bright_blue")
    for col_name, col_style in columns:
        table.add_column(col_name, style=col_style)
    for row in rows:
        table.add_row(*row)
    return table
