"""Thread-safe circuit breaker implementation.

Prevents cascading failures by short-circuiting calls to a failing
dependency once a failure threshold is reached, then gradually allowing
traffic through after a recovery period.
"""

from __future__ import annotations

import enum
import functools
import threading
import time
from typing import Any, Callable, Optional, Sequence, Tuple, Type, Union


class CircuitState(enum.Enum):
    """Possible states for a circuit breaker."""

    CLOSED = "closed"
    OPEN = "open"
    HALF_OPEN = "half_open"


class CircuitBreakerOpen(Exception):
    """Raised when a call is rejected because the circuit is open."""

    def __init__(self, breaker: "CircuitBreaker") -> None:
        self.breaker = breaker
        remaining = breaker._time_until_recovery()
        super().__init__(
            f"Circuit breaker {breaker.name!r} is OPEN "
            f"(recovery in {remaining:.1f}s)"
        )


class CircuitBreaker:
    """Thread-safe circuit breaker.

    Parameters
    ----------
    failure_threshold:
        Number of consecutive failures before the circuit opens.
    recovery_timeout:
        Seconds to wait in the OPEN state before transitioning to HALF_OPEN.
    half_open_max_calls:
        Maximum concurrent trial calls allowed in the HALF_OPEN state.
    monitored_exceptions:
        Exception types that count as failures.  Defaults to ``(Exception,)``.
    name:
        Optional human-readable name for logging / error messages.
    on_state_change:
        Optional callback ``(old_state, new_state) -> None`` invoked on
        every state transition.
    """

    def __init__(
        self,
        *,
        failure_threshold: int = 5,
        recovery_timeout: float = 30.0,
        half_open_max_calls: int = 1,
        monitored_exceptions: Union[
            Tuple[Type[BaseException], ...],
            Sequence[Type[BaseException]],
        ] = (Exception,),
        name: str = "default",
        on_state_change: Optional[
            Callable[[CircuitState, CircuitState], Any]
        ] = None,
    ) -> None:
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.half_open_max_calls = half_open_max_calls
        self.monitored_exceptions = tuple(monitored_exceptions)
        self.name = name
        self.on_state_change = on_state_change

        self._lock = threading.Lock()
        self._state = CircuitState.CLOSED
        self._failure_count: int = 0
        self._success_count: int = 0
        self._half_open_calls: int = 0
        self._opened_at: float = 0.0

    # ------------------------------------------------------------------
    # Properties
    # ------------------------------------------------------------------

    @property
    def state(self) -> CircuitState:
        """Current circuit state (may trigger OPEN -> HALF_OPEN transition)."""
        with self._lock:
            self._maybe_transition_to_half_open()
            return self._state

    @property
    def failure_count(self) -> int:
        with self._lock:
            return self._failure_count

    # ------------------------------------------------------------------
    # Decorator interface
    # ------------------------------------------------------------------

    def __call__(self, fn: Callable) -> Callable:
        """Use the circuit breaker as a decorator."""

        @functools.wraps(fn)
        def wrapper(*args: Any, **kwargs: Any) -> Any:
            self._before_call()
            try:
                result = fn(*args, **kwargs)
            except BaseException as exc:
                self._on_failure(exc)
                raise
            else:
                self._on_success()
                return result

        return wrapper

    # ------------------------------------------------------------------
    # Manual call interface
    # ------------------------------------------------------------------

    def call(self, fn: Callable, *args: Any, **kwargs: Any) -> Any:
        """Execute *fn* through the circuit breaker."""
        self._before_call()
        try:
            result = fn(*args, **kwargs)
        except BaseException as exc:
            self._on_failure(exc)
            raise
        else:
            self._on_success()
            return result

    # ------------------------------------------------------------------
    # Administrative
    # ------------------------------------------------------------------

    def reset(self) -> None:
        """Force-reset the circuit to CLOSED."""
        with self._lock:
            old = self._state
            self._state = CircuitState.CLOSED
            self._failure_count = 0
            self._success_count = 0
            self._half_open_calls = 0
            self._opened_at = 0.0
        if old != CircuitState.CLOSED and self.on_state_change:
            self.on_state_change(old, CircuitState.CLOSED)

    # ------------------------------------------------------------------
    # Internals
    # ------------------------------------------------------------------

    def _before_call(self) -> None:
        with self._lock:
            self._maybe_transition_to_half_open()

            if self._state == CircuitState.OPEN:
                raise CircuitBreakerOpen(self)

            if self._state == CircuitState.HALF_OPEN:
                if self._half_open_calls >= self.half_open_max_calls:
                    raise CircuitBreakerOpen(self)
                self._half_open_calls += 1

    def _on_success(self) -> None:
        with self._lock:
            if self._state == CircuitState.HALF_OPEN:
                self._success_count += 1
                if self._success_count >= self.half_open_max_calls:
                    self._transition(CircuitState.CLOSED)
                    self._failure_count = 0
                    self._success_count = 0
                    self._half_open_calls = 0
            elif self._state == CircuitState.CLOSED:
                # Reset consecutive failure count on success.
                self._failure_count = 0

    def _on_failure(self, exc: BaseException) -> None:
        if not isinstance(exc, self.monitored_exceptions):
            return
        with self._lock:
            self._failure_count += 1
            if self._state == CircuitState.HALF_OPEN:
                # Any failure in half-open immediately reopens.
                self._transition(CircuitState.OPEN)
                self._opened_at = time.monotonic()
                self._success_count = 0
                self._half_open_calls = 0
            elif self._state == CircuitState.CLOSED:
                if self._failure_count >= self.failure_threshold:
                    self._transition(CircuitState.OPEN)
                    self._opened_at = time.monotonic()

    def _maybe_transition_to_half_open(self) -> None:
        """Must be called while holding ``_lock``."""
        if self._state == CircuitState.OPEN:
            if time.monotonic() - self._opened_at >= self.recovery_timeout:
                self._transition(CircuitState.HALF_OPEN)
                self._half_open_calls = 0
                self._success_count = 0

    def _transition(self, new_state: CircuitState) -> None:
        """Must be called while holding ``_lock``."""
        old = self._state
        self._state = new_state
        if self.on_state_change and old != new_state:
            # Fire callback outside the lock to avoid deadlocks.
            threading.Thread(
                target=self.on_state_change,
                args=(old, new_state),
                daemon=True,
            ).start()

    def _time_until_recovery(self) -> float:
        elapsed = time.monotonic() - self._opened_at
        return max(0.0, self.recovery_timeout - elapsed)

    def __repr__(self) -> str:
        return (
            f"CircuitBreaker(name={self.name!r}, state={self._state.value}, "
            f"failures={self._failure_count}/{self.failure_threshold})"
        )
