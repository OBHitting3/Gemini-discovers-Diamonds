"""Tests for CircuitBreaker."""

import pytest

from content_shield.resilience.circuit_breaker import (
    CircuitBreaker,
    CircuitBreakerOpen,
    CircuitState,
)


class TestCircuitBreakerStates:
    """Tests for CircuitBreaker state transitions."""

    def test_initial_state_is_closed(self):
        cb = CircuitBreaker(failure_threshold=3)
        assert cb.state == CircuitState.CLOSED

    def test_opens_after_threshold_failures(self):
        cb = CircuitBreaker(failure_threshold=2, recovery_timeout=60)
        for _ in range(2):
            try:
                cb.call(self._failing_fn)
            except RuntimeError:
                pass
        assert cb.state == CircuitState.OPEN

    def test_open_circuit_rejects_calls(self):
        cb = CircuitBreaker(failure_threshold=1, recovery_timeout=60)
        try:
            cb.call(self._failing_fn)
        except RuntimeError:
            pass
        with pytest.raises(CircuitBreakerOpen):
            cb.call(lambda: "should not run")

    @staticmethod
    def _failing_fn():
        raise RuntimeError("boom")


class TestCircuitBreakerReset:
    """Tests for manual reset."""

    def test_reset_returns_to_closed(self):
        cb = CircuitBreaker(failure_threshold=1, recovery_timeout=60)
        try:
            cb.call(lambda: (_ for _ in ()).throw(RuntimeError("fail")))
        except RuntimeError:
            pass
        assert cb.state == CircuitState.OPEN
        cb.reset()
        assert cb.state == CircuitState.CLOSED
        assert cb.failure_count == 0

    def test_successful_call_resets_failure_count(self):
        cb = CircuitBreaker(failure_threshold=3)
        try:
            cb.call(lambda: (_ for _ in ()).throw(RuntimeError("fail")))
        except RuntimeError:
            pass
        assert cb.failure_count == 1
        cb.call(lambda: "ok")
        assert cb.failure_count == 0
