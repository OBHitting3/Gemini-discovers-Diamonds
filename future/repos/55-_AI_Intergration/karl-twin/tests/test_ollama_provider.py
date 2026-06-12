import pytest
import httpx

from karl_twin.agents.providers import OllamaProvider, ReasoningRequest, create_reasoning_provider


class _FakeResponse:
    def __init__(self, body):
        self._body = body

    def raise_for_status(self):
        pass

    def json(self):
        return self._body


class _FakeClient:
    requests = []

    def __init__(self, timeout):
        self.timeout = timeout

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        return False

    def post(self, url, json):
        self.requests.append({"url": url, "json": json, "timeout": self.timeout})
        return _FakeResponse({
            "message": {"content": '{"summary":"ok","confidence":0.82}'},
            "prompt_eval_count": 12,
            "eval_count": 7,
        })


class _FailingClient(_FakeClient):
    def post(self, url, json):
        request = httpx.Request("POST", url)
        response = httpx.Response(500, request=request, text='{"error":"load failed"}')
        raise httpx.HTTPStatusError("server error", request=request, response=response)


def test_ollama_provider_requests_json(monkeypatch):
    _FakeClient.requests.clear()
    monkeypatch.setattr("karl_twin.agents.providers.httpx.Client", _FakeClient)

    provider = OllamaProvider(base_url="http://ollama.local", model="qwen-test", timeout_sec=3)
    result = provider.reason(ReasoningRequest(
        system="Summarize.",
        user="hello",
        context={"owner": "Karl"},
        json_schema={
            "type": "object",
            "required": ["summary", "confidence"],
            "properties": {
                "summary": {"type": "string"},
                "confidence": {"type": "number"},
            },
        },
    ))

    assert result.parsed == {"summary": "ok", "confidence": 0.82}
    assert result.confidence == 0.82
    assert result.model == "qwen-test"
    assert result.tokens_in == 12
    assert result.tokens_out == 7
    req = _FakeClient.requests[0]
    assert req["url"] == "http://ollama.local/api/chat"
    assert req["json"]["format"] == "json"
    assert req["json"]["stream"] is False
    assert req["json"]["model"] == "qwen-test"


def test_ollama_provider_wraps_server_errors(monkeypatch):
    monkeypatch.setattr("karl_twin.agents.providers.httpx.Client", _FailingClient)
    provider = OllamaProvider(base_url="http://ollama.local", model="broken-model", timeout_sec=3)

    with pytest.raises(RuntimeError, match="Ollama returned HTTP 500"):
        provider.reason(ReasoningRequest(
            system="Summarize.",
            user="hello",
            context={},
            json_schema={"type": "object"},
        ))


def test_create_reasoning_provider_selects_ollama(monkeypatch):
    monkeypatch.setenv("KARL_TWIN_PROVIDER", "ollama")
    monkeypatch.setenv("OLLAMA_MODEL", "llama-local")

    provider = create_reasoning_provider()

    assert isinstance(provider, OllamaProvider)
    assert provider.model == "llama-local"


def test_create_reasoning_provider_rejects_unknown(monkeypatch):
    monkeypatch.setenv("KARL_TWIN_PROVIDER", "mystery")

    with pytest.raises(RuntimeError, match="Unsupported KARL_TWIN_PROVIDER"):
        create_reasoning_provider()
