"""Content Shield - AI content quality validation framework."""

from content_shield.config import ContentShieldConfig

__version__ = "0.1.0"
__all__ = ["ContentShield", "ContentShieldConfig", "__version__"]


class ContentShield:
    """Main entry point for content validation."""

    def __init__(self, config: ContentShieldConfig | None = None) -> None:
        self.config = config or ContentShieldConfig()
        self._runner = None

    @property
    def runner(self):
        """Lazy-initialize the shield runner."""
        if self._runner is None:
            from content_shield.shields.runner import ShieldRunner

            self._runner = ShieldRunner()
        return self._runner

    def validate(self, content):
        """Validate a single content item against all configured shields."""
        return self.runner.run(content)

    def validate_batch(self, contents):
        """Validate a batch of content items."""
        return self.runner.run_batch(contents)
