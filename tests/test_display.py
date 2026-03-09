"""Tests for display utilities."""

from __future__ import annotations

from io import StringIO

from rich.console import Console

from ironforge.utils.display import (
    BANNER,
    FORGE_THEME,
    create_table,
    print_banner,
    print_error,
    print_header,
    print_info,
    print_key_value,
    print_panel,
    print_success,
    print_warning,
)


class TestBanner:
    def test_banner_contains_forge_art(self) -> None:
        assert "Forge" in BANNER or "___" in BANNER
        assert "Forge" in BANNER or "|" in BANNER

    def test_banner_is_multiline(self) -> None:
        assert BANNER.count("\n") > 3

    def test_banner_is_ascii_art(self) -> None:
        assert "|" in BANNER
        assert "_" in BANNER

    def test_print_banner_no_crash(self) -> None:
        print_banner()


class TestCreateTable:
    def test_creates_table_with_columns(self) -> None:
        table = create_table("Test Table", [("Col1", "cyan"), ("Col2", "bold")])
        table.add_row("a", "b")
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


class TestPrintFunctions:
    """Verify print functions execute without exceptions."""

    def test_print_success(self) -> None:
        print_success("Operation completed")

    def test_print_info(self) -> None:
        print_info("Informational message")

    def test_print_warning(self) -> None:
        print_warning("Warning message")

    def test_print_error(self) -> None:
        print_error("Error message")

    def test_print_key_value(self) -> None:
        print_key_value("Key", "Value")

    def test_print_header(self) -> None:
        print_header("Section Title")

    def test_print_panel(self) -> None:
        print_panel("Panel content", title="Test Panel", style="green")

    def test_print_panel_no_title(self) -> None:
        print_panel("Content only")
