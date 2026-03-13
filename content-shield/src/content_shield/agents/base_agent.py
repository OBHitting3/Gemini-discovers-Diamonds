"""Abstract base agent for content-shield AI integrations."""

from __future__ import annotations

import os
from abc import ABC, abstractmethod


class BaseAgent(ABC):
    """Abstract base class for all AI agent integrations.

    Each agent wraps a specific LLM provider and exposes a uniform
    interface for content analysis.

    Parameters
    ----------
    api_key:
        Provider API key.  When *None*, the concrete subclass should
        fall back to an environment variable specific to its provider.
    """

    def __init__(self, api_key: str | None = None) -> None:
        self._api_key = api_key

    @property
    @abstractmethod
    def name(self) -> str:
        """Human-readable name identifying the agent / provider."""

    @abstractmethod
    async def analyze(self, content: str, prompt: str) -> str:
        """Send *content* to the underlying model with the given *prompt*.

        Parameters
        ----------
        content:
            The text content to be analyzed.
        prompt:
            Instructions describing the desired analysis.

        Returns
        -------
        str
            The model's response text.
        """

    @abstractmethod
    def is_available(self) -> bool:
        """Return *True* when the agent is configured and ready to use.

        Implementations should check that the required SDK is importable
        and that valid credentials are present.
        """

    def _resolve_key(self, env_var: str) -> str | None:
        """Return the API key, falling back to *env_var* if needed."""
        return self._api_key or os.environ.get(env_var)
