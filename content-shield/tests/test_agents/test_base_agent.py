"""Tests for BaseAgent interface."""

import pytest

from content_shield.agents.base_agent import BaseAgent


class ConcreteAgent(BaseAgent):
    """Minimal concrete implementation of BaseAgent for testing."""

    @property
    def name(self) -> str:
        return "test_agent"

    async def analyze(self, content: str, prompt: str) -> str:
        return f"Analyzed: {content}"

    def is_available(self) -> bool:
        return True


class UnavailableAgent(BaseAgent):
    """Agent that reports itself as unavailable."""

    @property
    def name(self) -> str:
        return "unavailable_agent"

    async def analyze(self, content: str, prompt: str) -> str:
        raise RuntimeError("Not available")

    def is_available(self) -> bool:
        return False


class TestBaseAgentInterface:
    """Tests for the BaseAgent abstract interface."""

    def test_concrete_agent_has_name(self):
        agent = ConcreteAgent()
        assert agent.name == "test_agent"

    def test_is_available(self):
        agent = ConcreteAgent()
        assert agent.is_available() is True

    @pytest.mark.asyncio
    async def test_analyze_returns_result(self):
        agent = ConcreteAgent()
        result = await agent.analyze("test content", "analyze this")
        assert "Analyzed" in result


class TestBaseAgentKeyResolution:
    """Tests for API key resolution."""

    def test_explicit_api_key(self):
        agent = ConcreteAgent(api_key="my-secret-key")
        assert agent._resolve_key("UNUSED_VAR") == "my-secret-key"

    def test_fallback_to_env_var(self, monkeypatch):
        monkeypatch.setenv("TEST_API_KEY", "env-key-value")
        agent = ConcreteAgent()
        assert agent._resolve_key("TEST_API_KEY") == "env-key-value"

    def test_no_key_returns_none(self):
        agent = ConcreteAgent()
        assert agent._resolve_key("NONEXISTENT_VAR_XYZ") is None
