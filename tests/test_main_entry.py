"""Tests for the main() CLI entry point and error handling."""

from __future__ import annotations

import contextlib
from unittest.mock import patch

import pytest

from ironforge.cli import main
from ironforge.core.errors import BuildError


class TestMainEntryPoint:
    def test_main_with_help(self) -> None:
        """main() should handle --help without crashing."""
        with (
            patch("sys.argv", ["ironforge", "--help"]),
            contextlib.suppress(SystemExit),
        ):
            main()

    def test_main_with_version(self) -> None:
        """main() should handle --version without crashing."""
        with (
            patch("sys.argv", ["ironforge", "--version"]),
            contextlib.suppress(SystemExit),
        ):
            main()

    def test_main_catches_forge_error(self) -> None:
        """main() should catch ForgeError and exit with error's exit code."""
        with patch("ironforge.cli.app", side_effect=BuildError("test failure")):
            with pytest.raises(SystemExit) as exc_info:
                main()
            assert exc_info.value.code == 4

    def test_main_catches_keyboard_interrupt(self) -> None:
        """main() should handle Ctrl+C gracefully."""
        with patch("ironforge.cli.app", side_effect=KeyboardInterrupt):
            with pytest.raises(SystemExit) as exc_info:
                main()
            assert exc_info.value.code == 130

    def test_main_catches_unexpected_error(self) -> None:
        """main() should catch unexpected exceptions and exit 1."""
        with patch("ironforge.cli.app", side_effect=RuntimeError("boom")):
            with pytest.raises(SystemExit) as exc_info:
                main()
            assert exc_info.value.code == 1
