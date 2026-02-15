"""``ironforge status`` — inspect project state."""

from __future__ import annotations

from pathlib import Path

import click

from ironforge.core.engine import get_project_status
from ironforge.utils.output import console, header, kv, make_table, warning


@click.command()
@click.option(
    "-d",
    "--directory",
    type=click.Path(exists=True, file_okay=False),
    default=None,
    help="Project root directory.",
)
@click.option("--json", "as_json", is_flag=True, default=False, help="Output as JSON.")
@click.pass_context
def status(ctx: click.Context, directory: str | None, as_json: bool) -> None:
    """Show the current project status and health."""
    project_dir = Path(directory) if directory else Path.cwd()
    st = get_project_status(project_dir)

    if as_json:
        import json

        data = {
            "name": st.name,
            "version": st.version,
            "config_present": st.config_present,
            "src_dir_exists": st.src_dir_exists,
            "build_dir_exists": st.build_dir_exists,
            "artifact_count": st.artifact_count,
            "src_file_count": st.src_file_count,
        }
        click.echo(json.dumps(data, indent=2))
        return

    if not st.config_present:
        warning("No ironforge.toml found — showing defaults.")

    header(f"Project Status: {st.name}")

    kv("Version", st.version)
    kv("Config", "found" if st.config_present else "missing")
    kv("Source dir", "exists" if st.src_dir_exists else "missing")
    kv("Build dir", "exists" if st.build_dir_exists else "missing")
    kv("Source files", st.src_file_count)
    kv("Build artifacts", st.artifact_count)

    # Health table
    rows = []
    checks = [
        ("Configuration file", st.config_present),
        ("Source directory", st.src_dir_exists),
        ("Build directory", st.build_dir_exists),
        ("Source files present", st.src_file_count > 0),
    ]
    for label, ok in checks:
        status_text = "[green]OK[/green]" if ok else "[red]MISSING[/red]"
        rows.append([label, status_text])

    table = make_table(
        "Health Checks",
        [("Check", "white"), ("Status", "white")],
        rows,
    )
    console.print()
    console.print(table)
