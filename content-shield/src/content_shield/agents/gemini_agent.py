"""Gemini agent implementation for content-shield."""

from __future__ import annotations

import logging
from typing import TYPE_CHECKING

from content_shield.agents.base_agent import BaseAgent

if TYPE_CHECKING:
    pass

logger = logging.getLogger(__name__)

_GEMINI_ENV_VAR = "GEMINI_API_KEY"
_DEFAULT_MODEL = "gemini-2.0-flash"


class GeminiAgent(BaseAgent):
    """Agent that delegates analysis to Google's Gemini API.

    Parameters
    ----------
    api_key:
        Google AI API key.  Falls back to the ``GEMINI_API_KEY``
        environment variable when not provided.
    model:
        Gemini model identifier.  Defaults to ``gemini-2.0-flash``.
    """

    def __init__(
        self,
        api_key: str | None = None,
        model: str = _DEFAULT_MODEL,
    ) -> None:
        super().__init__(api_key=api_key)
        self._model_name = model
        self._genai = self._try_import()

    # ------------------------------------------------------------------
    # BaseAgent interface
    # ------------------------------------------------------------------

    @property
    def name(self) -> str:  # noqa: D401
        return "gemini"

    def is_available(self) -> bool:
        """Return *True* when the SDK is importable and a key is present."""
        return self._genai is not None and self._resolve_key(_GEMINI_ENV_VAR) is not None

    async def analyze(self, content: str, prompt: str) -> str:
        """Analyze *content* by sending it to Gemini with the given *prompt*."""
        if not self.is_available():
            raise RuntimeError("GeminiAgent is not available (missing SDK or API key)")

        genai = self._genai
        key = self._resolve_key(_GEMINI_ENV_VAR)
        genai.configure(api_key=key)

        model = genai.GenerativeModel(self._model_name)
        full_prompt = f"{prompt}\n\n---\n\n{content}"

        logger.debug("Sending request to Gemini model %s", self._model_name)
        response = model.generate_content(full_prompt)
        return response.text

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    @staticmethod
    def _try_import():
        """Attempt to import ``google.generativeai``; return *None* on failure."""
        try:
            import google.generativeai as genai  # type: ignore[import-untyped]

            return genai
        except ImportError:  # pragma: no cover
            logger.info(
                "google-generativeai is not installed – GeminiAgent will be unavailable"
            )
            return None
