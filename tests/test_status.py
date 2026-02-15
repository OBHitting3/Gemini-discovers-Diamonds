"""Tests for ``ironforge status``."""

from __future__ import annotations

import json
from pathlib import Path

from click.testing import CliRunner

from ironforge.cli import cli


class TestStatusCommand:
    """Tests for the status sub-command."""

    def test_status_with_project(self):
        runner = CliRunner()
        with runner.isolated_filesystem() as td:
            proj = Path(td) / "proj"
            runner.invoke(cli, ["init", "proj", "-d", str(proj)])
            result = runner.invoke(cli, ["status", "-d", str(proj)])
            assert result.exit_code == 0
            assert "proj" in result.output
            assert "OK" in result.output

    def test_status_json_output(self):
        runner = CliRunner()
        with runner.isolated_filesystem() as td:
            proj = Path(td) / "proj"
            runner.invoke(cli, ["init", "proj", "-d", str(proj)])
            result = runner.invoke(cli, ["status", "-d", str(proj), "--json"])
            assert result.exit_code == 0
            data = json.loads(result.output)
            assert data["name"] == "proj"
            assert data["config_present"] is True
            assert data["src_dir_exists"] is True

    def test_status_without_project(self):
        runner = CliRunner()
        with runner.isolated_filesystem() as td:
            result = runner.invoke(cli, ["status", "-d", str(td)])
            assert result.exit_code == 0
            # Should show missing warnings
            assert "MISSING" in result.output or "missing" in result.output

    def test_status_after_build(self):
        runner = CliRunner()
        with runner.isolated_filesystem() as td:
            proj = Path(td) / "proj"
            runner.invoke(cli, ["init", "proj", "-d", str(proj)])
            runner.invoke(cli, ["build", "-d", str(proj)])
            result = runner.invoke(cli, ["status", "-d", str(proj), "--json"])
            data = json.loads(result.output)
            assert data["artifact_count"] >= 1
