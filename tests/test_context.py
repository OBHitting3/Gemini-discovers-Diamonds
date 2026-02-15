"""Tests for the ForgeContext execution context."""

from __future__ import annotations

import logging
from pathlib import Path

from ironforge.core.context import ForgeContext


class TestForgeContext:
    def test_default_context(self) -> None:
        ctx = ForgeContext()
        assert ctx.verbose is False
        assert ctx.debug is False
        assert isinstance(ctx.config, dict)

    def test_verbose_context(self) -> None:
        ctx = ForgeContext(verbose=True)
        assert ctx.verbose is True

    def test_project_name_from_config(self, tmp_project: Path) -> None:
        from ironforge.core.config import CONFIG_FILENAME, load_config

        config = load_config(tmp_project / CONFIG_FILENAME)
        ctx = ForgeContext(config=config)
        assert ctx.project_name == "test-project"

    def test_project_version_from_config(self, tmp_project: Path) -> None:
        from ironforge.core.config import CONFIG_FILENAME, load_config

        config = load_config(tmp_project / CONFIG_FILENAME)
        ctx = ForgeContext(config=config)
        assert ctx.project_version == "1.2.3"

    def test_setup_logging_debug(self) -> None:
        ctx = ForgeContext(debug=True)
        ctx.setup_logging()
        assert ctx.logger.level == logging.DEBUG

    def test_setup_logging_verbose(self) -> None:
        ctx = ForgeContext(verbose=True)
        ctx.setup_logging()
        assert ctx.logger.level == logging.INFO

    def test_setup_logging_default(self) -> None:
        ctx = ForgeContext()
        ctx.setup_logging()
        assert ctx.logger.level == logging.WARNING

    def test_logger_property(self) -> None:
        ctx = ForgeContext()
        assert ctx.logger is not None
        assert ctx.logger.name == "ironforge"
