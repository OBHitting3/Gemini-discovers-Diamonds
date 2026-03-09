"""
`ironforge check` — Linting and validation command.

Runs configurable checks on the project: structure validation,
config schema checks, and optional external tool integration.
"""

from __future__ import annotations

import typer

from ironforge.core.config import find_project_root, load_project_config
from ironforge.utils.display import (
    console,
    create_table,
    print_error,
    print_success,
    print_warning,
)
from ironforge.utils.fs import collect_files
from ironforge.utils.process import command_exists, run_command


def check_project(
    strict: bool = typer.Option(False, "--strict", "-s", help="Fail on warnings too."),
    fix: bool = typer.Option(False, "--fix", help="Attempt to auto-fix issues."),
) -> None:
    """Run validation checks on the current project."""
    root = find_project_root()
    issues: list[tuple[str, str, str]] = []  # (severity, check_name, message)

    # Check 1: Project root and config
    if root is None:
        issues.append(("ERROR", "project-root", "No ironforge.toml found."))
    else:
        config = load_project_config()

        # Check 2: Project name
        name = config.get("project", {}).get("name", "")
        if not name:
            issues.append(("WARNING", "project-name", "Project name is empty in config."))

        # Check 3: Source directory
        src_dir = root / "src"
        if not src_dir.is_dir():
            issues.append(("WARNING", "source-dir", "No 'src' directory found."))
        else:
            source_files = collect_files(src_dir, extensions=[".py"])
            if len(source_files) == 0:
                issues.append(("INFO", "source-files", "No Python source files in src/."))

        # Check 4: Tests directory
        test_dir = root / "tests"
        if not test_dir.is_dir():
            issues.append(("WARNING", "test-dir", "No 'tests' directory found."))

        # Check 5: Config schema validation
        _validate_config_schema(config, issues)

        # Check 6: External tool checks (optional)
        if command_exists("ruff"):
            ruff_cmd = ["ruff", "check", str(root)]
            if fix:
                ruff_cmd.append("--fix")
            result = run_command(ruff_cmd, cwd=root)
            if not result.success:
                issues.append(("WARNING", "ruff", f"Ruff found issues:\n{result.stdout[:500]}"))
            else:
                label = "Ruff check passed (with auto-fix)." if fix else "Ruff check passed."
                issues.append(("PASS", "ruff", label))

    # Display results
    _display_results(issues, strict)


def _validate_config_schema(config: dict, issues: list[tuple[str, str, str]]) -> None:
    """Validate configuration structure."""
    required_sections = ["project", "build", "forge"]
    for section in required_sections:
        if section not in config:
            issues.append(("WARNING", f"config-{section}", f"Missing [{section}] section."))
        else:
            issues.append(("PASS", f"config-{section}", f"[{section}] section present."))

    # Validate version format
    version = config.get("project", {}).get("version", "")
    if version and not _is_semver(version):
        issues.append(("WARNING", "semver", f"Version '{version}' is not valid semver."))
    elif version:
        issues.append(("PASS", "semver", f"Version '{version}' is valid semver."))


def _is_semver(version: str) -> bool:
    """Basic semver validation."""
    parts = version.split(".")
    if len(parts) < 2 or len(parts) > 3:
        return False
    return all(part.isdigit() for part in parts)


def _display_results(issues: list[tuple[str, str, str]], strict: bool) -> None:
    """Display check results in a table."""
    table = create_table(
        "Iron Forge Check Results",
        [("Status", "bold"), ("Check", "cyan"), ("Details", "white")],
    )

    error_count = 0
    warning_count = 0
    pass_count = 0

    for severity, check_name, message in issues:
        if severity == "ERROR":
            status = "[bold red]FAIL[/bold red]"
            error_count += 1
        elif severity == "WARNING":
            status = "[bold yellow]WARN[/bold yellow]"
            warning_count += 1
        elif severity == "PASS":
            status = "[bold green]PASS[/bold green]"
            pass_count += 1
        else:
            status = "[dim]INFO[/dim]"

        table.add_row(status, check_name, message)

    console.print(table)

    # Summary
    if error_count > 0:
        print_error(f"{error_count} error(s), {warning_count} warning(s), {pass_count} passed")
        raise typer.Exit(code=1)
    elif warning_count > 0 and strict:
        print_warning(f"{warning_count} warning(s) in strict mode, {pass_count} passed")
        raise typer.Exit(code=1)
    elif warning_count > 0:
        print_warning(f"{warning_count} warning(s), {pass_count} passed — use --strict to fail")
    else:
        print_success(f"All {pass_count} checks passed!")
