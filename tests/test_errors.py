"""Tests for the custom error hierarchy."""

from __future__ import annotations

from ironforge.utils.errors import (
    BuildError,
    ConfigError,
    IronForgeError,
    ProjectNotFoundError,
    ValidationError,
)


class TestErrorHierarchy:
    """Verify the exception class hierarchy and exit codes."""

    def test_base_error(self):
        err = IronForgeError("base")
        assert str(err) == "base"
        assert err.exit_code == 1

    def test_config_error(self):
        err = ConfigError("bad config")
        assert isinstance(err, IronForgeError)
        assert err.exit_code == 2

    def test_project_not_found(self):
        err = ProjectNotFoundError("missing")
        assert isinstance(err, IronForgeError)
        assert err.exit_code == 3

    def test_build_error(self):
        err = BuildError("failed")
        assert isinstance(err, IronForgeError)
        assert err.exit_code == 4

    def test_validation_error(self):
        err = ValidationError("invalid")
        assert isinstance(err, IronForgeError)
        assert err.exit_code == 5

    def test_custom_exit_code(self):
        err = IronForgeError("custom", exit_code=42)
        assert err.exit_code == 42

    def test_exceptions_catchable_as_base(self):
        errors = [
            ConfigError("c"),
            ProjectNotFoundError("p"),
            BuildError("b"),
            ValidationError("v"),
        ]
        for err in errors:
            try:
                raise err
            except IronForgeError as caught:
                assert caught is err
