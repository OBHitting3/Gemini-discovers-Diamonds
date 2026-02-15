"""
Process execution utilities for Iron Forge CLI.

Safe wrappers around subprocess for running external commands
with consistent output capture, timeout support, and error handling.
"""

from __future__ import annotations

import shutil
import subprocess
from dataclasses import dataclass
from pathlib import Path

from ironforge.core.errors import CommandNotFoundError


@dataclass
class RunResult:
    """Result of a subprocess execution."""

    command: str
    return_code: int
    stdout: str
    stderr: str

    @property
    def success(self) -> bool:
        return self.return_code == 0


def run_command(
    cmd: list[str],
    *,
    cwd: Path | None = None,
    env: dict[str, str] | None = None,
    timeout: int = 300,
    capture: bool = True,
    check: bool = False,
) -> RunResult:
    """Run an external command and return structured results.

    Args:
        cmd: Command and arguments as a list.
        cwd: Working directory (defaults to current).
        env: Additional environment variables (merged with current env).
        timeout: Timeout in seconds.
        capture: Whether to capture stdout/stderr.
        check: If True, raise on non-zero exit.

    Returns:
        RunResult with captured output and return code.

    Raises:
        CommandNotFoundError: If the command binary is not found on PATH.
        subprocess.TimeoutExpired: If execution exceeds timeout.
    """
    command_str = " ".join(cmd)

    # Verify the command exists
    if not shutil.which(cmd[0]):
        raise CommandNotFoundError(cmd[0])

    import os

    full_env = dict(os.environ)
    if env:
        full_env.update(env)

    result = subprocess.run(
        cmd,
        cwd=cwd,
        env=full_env,
        capture_output=capture,
        text=True,
        timeout=timeout,
    )

    run_result = RunResult(
        command=command_str,
        return_code=result.returncode,
        stdout=result.stdout if capture else "",
        stderr=result.stderr if capture else "",
    )

    if check and not run_result.success:
        from ironforge.core.errors import ForgeError

        raise ForgeError(
            f"Command failed (exit {result.returncode}): {command_str}\n{run_result.stderr}"
        )

    return run_result


def command_exists(name: str) -> bool:
    """Check whether a command is available on PATH."""
    return shutil.which(name) is not None
