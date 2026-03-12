"""Generates Grafana dashboard JSON from templates."""

from __future__ import annotations

import json
import logging
from pathlib import Path
from typing import Any

logger = logging.getLogger(__name__)

TEMPLATES_DIR = Path(__file__).parent / "templates"


class GrafanaGenerator:
    """Generates Grafana dashboards from bundled or custom templates."""

    def __init__(self, datasource: str = "BigQuery", templates_dir: Path | None = None) -> None:
        self.datasource = datasource
        self.templates_dir = templates_dir or TEMPLATES_DIR

    def list_templates(self) -> list[str]:
        """List available dashboard template names."""
        return [p.stem for p in self.templates_dir.glob("*.json")]

    def load_template(self, name: str) -> dict[str, Any]:
        """Load a dashboard template by name."""
        path = self.templates_dir / f"{name}.json"
        if not path.exists():
            raise FileNotFoundError(f"Template '{name}' not found at {path}")
        with open(path) as f:
            return json.load(f)

    def generate(self, template_name: str, overrides: dict[str, Any] | None = None) -> dict[str, Any]:
        """Generate a Grafana dashboard JSON from a template.

        Args:
            template_name: Name of the template to use.
            overrides: Optional dict of values to override in the template.

        Returns:
            Complete Grafana dashboard JSON dict.
        """
        dashboard = self.load_template(template_name)
        dashboard["datasource"] = self.datasource
        if overrides:
            dashboard.update(overrides)
        logger.info("Generated dashboard from template '%s'", template_name)
        return dashboard

    def save(self, dashboard: dict[str, Any], output_path: str | Path) -> Path:
        """Save a generated dashboard to a JSON file."""
        output_path = Path(output_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        with open(output_path, "w") as f:
            json.dump(dashboard, f, indent=2)
        logger.info("Saved dashboard to %s", output_path)
        return output_path
