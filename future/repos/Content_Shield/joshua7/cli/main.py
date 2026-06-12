"""Typer CLI entry point for Joshua 7."""

from __future__ import annotations

import sys
from pathlib import Path

import typer
import uvicorn
from pydantic import ValidationError

from joshua7 import __version__
from joshua7.config import get_settings
from joshua7.engine import ValidationEngine
from joshua7.models import MAX_TEXT_LENGTH, ValidationResponse

app = typer.Typer(
    name="joshua7",
    help="Joshua 7 — Content Shield: Pre-publication AI content validation.",
    add_completion=False,
)


def _version_callback(value: bool) -> None:
    if value:
        typer.echo(f"Joshua 7 v{__version__}")
        raise typer.Exit()


@app.callback()
def main(
    version: bool | None = typer.Option(
        None, "--version", "-V", callback=_version_callback, is_eager=True,
        help="Show version and exit.",
    ),
) -> None:
    """Joshua 7 — Content Shield CLI."""


@app.command()
def validate(
    text: str | None = typer.Option(None, "--text", "-t", help="Inline text to validate."),
    file: Path | None = typer.Option(None, "--file", "-f", help="Path to file to validate."),
    stdin: bool = typer.Option(False, "--stdin", "-s", help="Read content from stdin."),
    validators: str | None = typer.Option(
        "all", "--validators", "-v",
        help="Comma-separated validator names, or 'all'.",
    ),
    config: Path | None = typer.Option(
        None, "--config", "-c", help="Path to YAML config file.",
    ),
    output_json: bool = typer.Option(False, "--json", "-j", help="Output raw JSON."),
) -> None:
    """Validate content against enabled validators."""
    sources = sum([text is not None, file is not None, stdin])
    if sources == 0:
        typer.echo(
            "Error: provide exactly one input source: --text, --file, or --stdin\n"
            "Examples:\n"
            '  joshua7 validate --text "Your content here"\n'
            "  joshua7 validate --file article.txt\n"
            "  echo 'content' | joshua7 validate --stdin",
            err=True,
        )
        raise typer.Exit(code=2)
    if sources > 1:
        typer.echo("Error: provide only one of --text, --file, or --stdin", err=True)
        raise typer.Exit(code=2)

    content = ""
    if text is not None:
        content = text
    elif file is not None:
        if not file.exists():
            typer.echo(f"Error: file not found: {file}", err=True)
            raise typer.Exit(code=2)
        if not file.is_file():
            typer.echo(f"Error: not a regular file: {file}", err=True)
            raise typer.Exit(code=2)
        file_size = file.stat().st_size
        if file_size > MAX_TEXT_LENGTH * 4:
            typer.echo(
                f"Error: file too large ({file_size:,} bytes). "
                f"Max supported: ~{MAX_TEXT_LENGTH:,} characters.",
                err=True,
            )
            raise typer.Exit(code=2)
        content = file.read_text(encoding="utf-8")
    elif stdin:
        content = sys.stdin.read()

    if not content.strip():
        typer.echo("Error: input content is empty", err=True)
        raise typer.Exit(code=2)

    settings = get_settings(config_path=config)

    if len(content) > settings.max_text_length:
        typer.echo(
            f"Error: content too long ({len(content):,} chars). "
            f"Maximum allowed: {settings.max_text_length:,} chars.",
            err=True,
        )
        raise typer.Exit(code=2)

    engine = ValidationEngine(settings=settings)

    validator_list = [v.strip() for v in (validators or "all").split(",")]
    try:
        response = engine.validate_text(content, validators=validator_list)
    except ValidationError as exc:
        for err in exc.errors():
            typer.echo(f"Error: {err['msg']}", err=True)
        raise typer.Exit(code=2) from None

    if output_json:
        typer.echo(response.model_dump_json(indent=2))
    else:
        _print_report(response)

    if not response.passed:
        raise typer.Exit(code=1)


def _print_report(response: ValidationResponse) -> None:
    if response.passed:
        status = typer.style("PASS", fg=typer.colors.GREEN, bold=True)
    else:
        status = typer.style("FAIL", fg=typer.colors.RED, bold=True)

    typer.echo(f"\n{'='*60}")
    typer.echo("  Joshua 7 — Content Shield Report")
    typer.echo(f"  Request ID: {response.request_id}")
    typer.echo(f"{'='*60}")
    typer.echo(f"  Overall: {status}")
    typer.echo(f"  Text length: {response.text_length:,} chars")
    typer.echo(f"  Validators run: {response.validators_run}")
    typer.echo(f"{'─'*60}")

    for result in response.results:
        if result.passed:
            icon = typer.style("✓", fg=typer.colors.GREEN)
        else:
            icon = typer.style("✗", fg=typer.colors.RED)
        score_str = f" (score: {result.score})" if result.score is not None else ""
        typer.echo(f"  {icon} {result.validator_name}{score_str}")
        for finding in result.findings:
            sev = finding.severity.value.upper()
            typer.echo(f"      [{sev}] {finding.message}")

    typer.echo(f"{'='*60}\n")


@app.command()
def serve(
    host: str = typer.Option("0.0.0.0", "--host", help="Bind address."),
    port: int = typer.Option(8000, "--port", "-p", help="Port number."),
    reload: bool = typer.Option(False, "--reload", help="Enable auto-reload."),
) -> None:
    """Start the FastAPI server."""
    uvicorn.run(
        "joshua7.api.main:app",
        host=host,
        port=port,
        reload=reload,
        log_level="info",
    )


@app.command(name="list")
def list_validators() -> None:
    """List all available validators."""
    engine = ValidationEngine()
    typer.echo("Available validators:")
    for name in engine.available_validators:
        typer.echo(f"  • {name}")


if __name__ == "__main__":
    app()
