"""OpenAI agent implementation for content-shield."""

from __future__ import annotations

import logging
from typing import TYPE_CHECKING

from content_shield.agents.base_agent import BaseAgent

if TYPE_CHECKING:
    pass

logger = logging.getLogger(__name__)

_OPENAI_ENV_VAR = "OPENAI_API_KEY"
_DEFAULT_MODEL = "gpt-4o"
_DEFAULT_MAX_TOKENS = 4096


class OpenAIAgent(BaseAgent):
    """Agent that delegates analysis to the OpenAI API.

    Parameters
    ----------
    api_key:
        OpenAI API key.  Falls back to the ``OPENAI_API_KEY``
        environment variable when not provided.
    model:
        OpenAI model identifier.  Defaults to ``gpt-4o``.
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
        self._openai = self._try_import()

    # ------------------------------------------------------------------
    # BaseAgent interface
    # ------------------------------------------------------------------

    @property
    def name(self) -> str:  # noqa: D401
        return "openai"

    def is_available(self) -> bool:
        """Return *True* when the SDK is importable and a key is present."""
        return self._openai is not None and self._resolve_key(_OPENAI_ENV_VAR) is not None

    async def analyze(self, content: str, prompt: str) -> str:
        """Analyze *content* by sending it to OpenAI with the given *prompt*."""
        if not self.is_available():
            raise RuntimeError("OpenAIAgent is not available (missing SDK or API key)")

        openai = self._openai
        key = self._resolve_key(_OPENAI_ENV_VAR)
        client = openai.AsyncOpenAI(api_key=key)

        logger.debug("Sending request to OpenAI model %s", self._model_name)
        response = await client.chat.completions.create(
            model=self._model_name,
            max_tokens=self._max_tokens,
            messages=[
                {"role": "system", "content": prompt},
                {"role": "user", "content": content},
            ],
        )
        return response.choices[0].message.content

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    @staticmethod
    def _try_import():
        """Attempt to import ``openai``; return *None* on failure."""
        try:
            import openai  # type: ignore[import-untyped]

            return openai
        except ImportError:  # pragma: no cover
            logger.info(
                "openai is not installed – OpenAIAgent will be unavailable"
            )
            return None
