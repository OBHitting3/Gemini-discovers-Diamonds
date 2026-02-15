"""Tests for process execution utilities."""

from __future__ import annotations

import pytest

from ironforge.core.errors import CommandNotFoundError
from ironforge.utils.process import RunResult, command_exists, run_command


class TestRunCommand:
    def test_successful_command(self) -> None:
        result = run_command(["echo", "hello world"])
        assert result.success
        assert result.return_code == 0
        assert "hello world" in result.stdout

    def test_failed_command(self) -> None:
        result = run_command(["false"])
        assert not result.success
        assert result.return_code != 0

    def test_command_not_found(self) -> None:
        with pytest.raises(CommandNotFoundError):
            run_command(["nonexistent_command_xyz_123"])

    def test_check_raises_on_failure(self) -> None:
        from ironforge.core.errors import ForgeError

        with pytest.raises(ForgeError):
            run_command(["false"], check=True)

    def test_captures_stderr(self) -> None:
        result = run_command(["python3", "-c", "import sys; sys.stderr.write('err\\n')"])
        assert "err" in result.stderr


class TestRunResult:
    def test_success_property(self) -> None:
        r = RunResult(command="test", return_code=0, stdout="", stderr="")
        assert r.success is True

    def test_failure_property(self) -> None:
        r = RunResult(command="test", return_code=1, stdout="", stderr="")
        assert r.success is False


class TestCommandExists:
    def test_existing_command(self) -> None:
        assert command_exists("python3") is True

    def test_nonexistent_command(self) -> None:
        assert command_exists("nonexistent_command_xyz_123") is False
