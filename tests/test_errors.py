"""Tests for the custom exception hierarchy."""

from __future__ import annotations

import pytest

from ironforge.core.errors import (
    BuildError,
    CommandNotFoundError,
    ConfigError,
    ForgeError,
    ProjectNotFoundError,
)


class TestForgeError:
    def test_base_error(self) -> None:
        err = ForgeError("something went wrong")
        assert str(err) == "something went wrong"
        assert err.exit_code == 1

    def test_custom_exit_code(self) -> None:
        err = ForgeError("oops", exit_code=42)
        assert err.exit_code == 42

    def test_is_exception(self) -> None:
        with pytest.raises(ForgeError):
            raise ForgeError("test")


class TestConfigError:
    def test_message_prefix(self) -> None:
        err = ConfigError("missing key")
        assert "Configuration error" in str(err)
        assert err.exit_code == 2


class TestProjectNotFoundError:
    def test_message(self) -> None:
        err = ProjectNotFoundError()
        assert "ironforge.toml" in str(err)
        assert "init" in str(err)
        assert err.exit_code == 3


class TestBuildError:
    def test_message(self) -> None:
        err = BuildError("compilation failed")
        assert "Build failed" in str(err)
        assert err.exit_code == 4


class TestCommandNotFoundError:
    def test_message(self) -> None:
        err = CommandNotFoundError("gcc")
        assert "gcc" in str(err)
        assert err.exit_code == 5


class TestInheritance:
    def test_all_inherit_from_forge_error(self) -> None:
        errors = [
            ConfigError("x"),
            ProjectNotFoundError(),
            BuildError("x"),
            CommandNotFoundError("x"),
        ]
        for err in errors:
            assert isinstance(err, ForgeError)
            assert isinstance(err, Exception)
