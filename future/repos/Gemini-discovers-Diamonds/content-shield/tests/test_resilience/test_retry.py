"""Tests for RetryPolicy."""

import pytest

from content_shield.resilience.retry import RetryPolicy


class TestRetryPolicyCreation:
    """Tests for RetryPolicy initialization and configuration."""

    def test_default_parameters(self):
        policy = RetryPolicy()
        assert policy.max_attempts == 3
        assert policy.backoff == "exponential"
        assert policy.backoff_base == 1
        assert policy.backoff_max == 60

    def test_custom_parameters(self):
        policy = RetryPolicy(
            max_attempts=5,
            backoff="fixed",
            backoff_base=2.0,
        )
        assert policy.max_attempts == 5
        assert policy.backoff == "fixed"
        assert policy.backoff_base == 2.0

    def test_invalid_backoff_strategy_raises(self):
        policy = RetryPolicy(backoff="invalid_strategy")
        with pytest.raises(ValueError, match="Unknown backoff strategy"):
            policy._build_wait()


class TestRetryPolicyCopy:
    """Tests for RetryPolicy.copy()."""

    def test_copy_creates_new_instance(self):
        original = RetryPolicy(max_attempts=3)
        copied = original.copy(max_attempts=5)
        assert copied.max_attempts == 5
        assert original.max_attempts == 3

    def test_copy_preserves_unoverridden_fields(self):
        original = RetryPolicy(max_attempts=3, backoff="fixed", backoff_base=2.0)
        copied = original.copy(max_attempts=10)
        assert copied.backoff == "fixed"
        assert copied.backoff_base == 2.0


class TestRetryPolicyDecorator:
    """Tests for using RetryPolicy as a decorator."""

    def test_sync_decorator_retries_on_failure(self):
        call_count = 0
        policy = RetryPolicy(max_attempts=3, backoff="none")

        @policy
        def flaky():
            nonlocal call_count
            call_count += 1
            if call_count < 3:
                raise ValueError("not yet")
            return "done"

        result = flaky()
        assert result == "done"
        assert call_count == 3
