"""Resilience primitives for content-shield.

This package provides retry policies, circuit breakers, dead-letter queues,
timeout wrappers, and error classification utilities.
"""

from content_shield.resilience.circuit_breaker import (
    CircuitBreaker,
    CircuitBreakerOpen,
    CircuitState,
)
from content_shield.resilience.dlq import DeadLetterQueue, DLQEntry
from content_shield.resilience.error_classifier import (
    ErrorCategory,
    ErrorClassifier,
)
from content_shield.resilience.retry import RetryPolicy
from content_shield.resilience.timeout import Timeout, TimeoutError

__all__ = [
    # circuit_breaker
    "CircuitBreaker",
    "CircuitBreakerOpen",
    "CircuitState",
    # dlq
    "DeadLetterQueue",
    "DLQEntry",
    # error_classifier
    "ErrorCategory",
    "ErrorClassifier",
    # retry
    "RetryPolicy",
    # timeout
    "Timeout",
    "TimeoutError",
]
