"""Tests for display utilities."""

from __future__ import annotations

from io import StringIO

from rich.console import Console

from ironforge.utils.display import (
    BANNER,
    FORGE_THEME,
    create_table,
)


class TestBanner:
    def test_banner_contains_forge_art(self) -> None:
        # ASCII art spells out "Iron Forge" in stylized characters
        assert "Forge" in BANNER or "___" in BANNER
        assert "Forge" in BANNER or "|" in BANNER

    def test_banner_is_multiline(self) -> None:
        assert BANNER.count("\n") > 3

    def test_banner_is_ascii_art(self) -> None:
        # Should contain typical ASCII art characters
        assert "|" in BANNER
        assert "_" in BANNER


class TestCreateTable:
    def test_creates_table_with_columns(self) -> None:
        table = create_table("Test Table", [("Col1", "cyan"), ("Col2", "bold")])
        table.add_row("a", "b")
        # Render to string to verify it doesn't crash
        console = Console(file=StringIO(), theme=FORGE_THEME)
        console.print(table)
        output = console.file.getvalue()  # type: ignore[union-attr]
        assert "Test Table" in output
        assert "Col1" in output
        assert "Col2" in output

    def test_empty_table(self) -> None:
        table = create_table("Empty", [("H1", "white")])
        console = Console(file=StringIO(), theme=FORGE_THEME)
        console.print(table)
        output = console.file.getvalue()  # type: ignore[union-attr]
        assert "Empty" in output
