"""Claude agent implementation for content-shield."""

from __future__ import annotations

import logging
from typing import TYPE_CHECKING

from content_shield.agents.base_agent import BaseAgent

if TYPE_CHECKING:
    pass

logger = logging.getLogger(__name__)

_ANTHROPIC_ENV_VAR = "ANTHROPIC_API_KEY"
_DEFAULT_MODEL = "claude-sonnet-4-20250514"
_DEFAULT_MAX_TOKENS = 4096


class ClaudeAgent(BaseAgent):
    """Agent that delegates analysis to the Anthropic Claude API.

    Parameters
    ----------
    api_key:
        Anthropic API key.  Falls back to the ``ANTHROPIC_API_KEY``
        environment variable when not provided.
    model:
        Claude model identifier.  Defaults to ``claude-sonnet-4-20250514``.
    max_tokens:
        Maximum number of tokens in the response.
    """

    def __init__(
        self,
        api_key: str | None = None,
        model: str = _DEFAULT_MODEL,
        max_tokens: int = _DEFAULT_MAX_TOKENS,
    ) -> None:
        super().__init__(api_key=api_key)
        self._model_name = model
        self._max_tokens = max_tokens
        self._anthropic = self._try_import()

    # ------------------------------------------------------------------
    # BaseAgent interface
    # ------------------------------------------------------------------

    @property
    def name(self) -> str:  # noqa: D401
        return "claude"

    def is_available(self) -> bool:
        """Return *True* when the SDK is importable and a key is present."""
        return (
            self._anthropic is not None
            and self._resolve_key(_ANTHROPIC_ENV_VAR) is not None
        )

    async def analyze(self, content: str, prompt: str) -> str:
        """Analyze *content* by sending it to Claude with the given *prompt*."""
        if not self.is_available():
            raise RuntimeError("ClaudeAgent is not available (missing SDK or API key)")

        anthropic = self._anthropic
        key = self._resolve_key(_ANTHROPIC_ENV_VAR)
        client = anthropic.AsyncAnthropic(api_key=key)

        full_message = f"{prompt}\n\n---\n\n{content}"

        logger.debug("Sending request to Claude model %s", self._model_name)
        response = await client.messages.create(
            model=self._model_name,
            max_tokens=self._max_tokens,
            messages=[{"role": "user", "content": full_message}],
        )
        return response.content[0].text

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    @staticmethod
    def _try_import():
        """Attempt to import ``anthropic``; return *None* on failure."""
        try:
            import anthropic  # type: ignore[import-untyped]

            return anthropic
        except ImportError:  # pragma: no cover
            logger.info(
                "anthropic is not installed – ClaudeAgent will be unavailable"
            )
            return None
