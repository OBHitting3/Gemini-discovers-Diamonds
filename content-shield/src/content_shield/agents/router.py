"""Agent router for content-shield multi-provider orchestration."""

from __future__ import annotations

import logging
from typing import Sequence

from content_shield.agents.base_agent import BaseAgent

logger = logging.getLogger(__name__)

# Simple mapping from logical task types to preferred provider names.
# When no mapping exists the router falls back to the first available agent.
_TASK_PREFERENCES: dict[str, list[str]] = {
    "content_analysis": ["gemini", "claude", "openai"],
    "safety_check": ["claude", "gemini", "openai"],
    "summarization": ["openai", "gemini", "claude"],
    "classification": ["gemini", "openai", "claude"],
}


class AgentRouter:
    """Manages multiple :class:`BaseAgent` instances and routes tasks.

    The router keeps an ordered registry of agents.  It can pick the
    best available agent for a given *task_type* and transparently
    fall back through all agents when one fails.
    """

    def __init__(self) -> None:
        self._agents: list[BaseAgent] = []

    # ------------------------------------------------------------------
    # Registration / introspection
    # ------------------------------------------------------------------

    def register(self, agent: BaseAgent) -> None:
        """Add *agent* to the router's registry."""
        self._agents.append(agent)
        logger.debug("Registered agent: %s", agent.name)

    def get_available(self) -> list[BaseAgent]:
        """Return the subset of registered agents that are currently available."""
        return [a for a in self._agents if a.is_available()]

    # ------------------------------------------------------------------
    # Routing
    # ------------------------------------------------------------------

    def route(self, task_type: str) -> BaseAgent:
        """Pick the best available agent for *task_type*.

        The router consults an internal preference map.  If none of the
        preferred agents are available it falls back to the first
        available agent regardless of preference.

        Raises
        ------
        RuntimeError
            If no agents are available.
        """
        available = self.get_available()
        if not available:
            raise RuntimeError("No agents are available")

        available_names = {a.name for a in available}
        preferences = _TASK_PREFERENCES.get(task_type, [])

        for preferred_name in preferences:
            if preferred_name in available_names:
                agent = next(a for a in available if a.name == preferred_name)
                logger.debug(
                    "Routed task_type=%s to preferred agent %s",
                    task_type,
                    agent.name,
                )
                return agent

        # Fallback: first available agent.
        agent = available[0]
        logger.debug(
            "No preference match for task_type=%s; falling back to %s",
            task_type,
            agent.name,
        )
        return agent

    # ------------------------------------------------------------------
    # Analysis with fallback
    # ------------------------------------------------------------------

    async def analyze_with_fallback(self, content: str, prompt: str) -> str:
        """Try each available agent in order; return the first successful result.

        Parameters
        ----------
        content:
            The text content to analyze.
        prompt:
            Instructions describing the desired analysis.

        Returns
        -------
        str
            The response text from the first agent that succeeds.

        Raises
        ------
        RuntimeError
            If no agents are available or all agents fail.
        """
        available = self.get_available()
        if not available:
            raise RuntimeError("No agents are available")

        errors: list[tuple[str, Exception]] = []

        for agent in available:
            try:
                logger.debug("Attempting analysis with agent %s", agent.name)
                result = await agent.analyze(content, prompt)
                return result
            except Exception as exc:  # noqa: BLE001
                logger.warning(
                    "Agent %s failed: %s",
                    agent.name,
                    exc,
                )
                errors.append((agent.name, exc))

        # All agents failed – build an informative error message.
        summary = "; ".join(f"{name}: {exc}" for name, exc in errors)
        raise RuntimeError(f"All agents failed. Errors: {summary}")
