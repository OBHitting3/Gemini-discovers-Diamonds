"""Tests for AgentRouter."""

import pytest

from content_shield.agents.base_agent import BaseAgent
from content_shield.agents.router import AgentRouter


class FakeAgent(BaseAgent):
    """A fake agent for testing the router."""

    def __init__(self, agent_name: str, available: bool = True, api_key=None):
        super().__init__(api_key=api_key)
        self._name = agent_name
        self._available = available

    @property
    def name(self) -> str:
        return self._name

    async def analyze(self, content: str, prompt: str) -> str:
        return f"{self._name}: {content}"

    def is_available(self) -> bool:
        return self._available


class TestAgentRouterRegistration:
    """Tests for agent registration and availability."""

    def test_register_and_get_available(self):
        router = AgentRouter()
        agent = FakeAgent("gemini")
        router.register(agent)
        available = router.get_available()
        assert len(available) == 1
        assert available[0].name == "gemini"

    def test_unavailable_agents_filtered(self):
        router = AgentRouter()
        router.register(FakeAgent("gemini", available=True))
        router.register(FakeAgent("offline", available=False))
        available = router.get_available()
        assert len(available) == 1


class TestAgentRouterRouting:
    """Tests for task routing."""

    def test_route_picks_preferred_agent(self):
        router = AgentRouter()
        router.register(FakeAgent("openai"))
        router.register(FakeAgent("gemini"))
        agent = router.route("content_analysis")
        assert agent.name == "gemini"

    def test_route_falls_back_to_first_available(self):
        router = AgentRouter()
        router.register(FakeAgent("custom_agent"))
        agent = router.route("unknown_task_type")
        assert agent.name == "custom_agent"

    def test_route_raises_when_no_agents(self):
        router = AgentRouter()
        with pytest.raises(RuntimeError, match="No agents are available"):
            router.route("content_analysis")


class TestAgentRouterFallback:
    """Tests for analyze_with_fallback."""

    @pytest.mark.asyncio
    async def test_fallback_uses_first_success(self):
        router = AgentRouter()
        router.register(FakeAgent("gemini"))
        result = await router.analyze_with_fallback("text", "prompt")
        assert "gemini" in result

    @pytest.mark.asyncio
    async def test_fallback_raises_when_empty(self):
        router = AgentRouter()
        with pytest.raises(RuntimeError, match="No agents are available"):
            await router.analyze_with_fallback("text", "prompt")
