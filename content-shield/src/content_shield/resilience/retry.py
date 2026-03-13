"""Retry policy built on top of tenacity.

Provides a configurable ``RetryPolicy`` that can be used as a decorator
or as an async/sync context manager.
"""

from __future__ import annotations

import asyncio
import functools
from contextlib import asynccontextmanager, contextmanager
from typing import (
    Any,
    Callable,
    Optional,
    Sequence,
    Tuple,
    Type,
    Union,
)

import tenacity
from tenacity import (
    RetryCallState,
    retry_if_exception_type,
    stop_after_attempt,
    wait_exponential,
    wait_fixed,
    wait_none,
)


class RetryPolicy:
    """A configurable retry policy wrapping *tenacity*.

    Parameters
    ----------
    max_attempts:
        Maximum number of attempts (including the first call).
    backoff:
        ``"exponential"`` (default), ``"fixed"``, or ``"none"``.
    backoff_base:
        For exponential backoff the multiplier; for fixed backoff the
        constant wait in seconds.  Defaults to ``1``.
    backoff_max:
        Upper bound (seconds) for exponential backoff.  Defaults to ``60``.
    retryable_exceptions:
        Tuple / sequence of exception types that should trigger a retry.
        Defaults to ``(Exception,)``.
    on_retry:
        Optional callback invoked before each retry.  Receives the
        ``tenacity.RetryCallState``.
    """

    def __init__(
        self,
        *,
        max_attempts: int = 3,
        backoff: str = "exponential",
        backoff_base: float = 1,
        backoff_max: float = 60,
        retryable_exceptions: Union[
            Tuple[Type[BaseException], ...],
            Sequence[Type[BaseException]],
        ] = (Exception,),
        on_retry: Optional[Callable[[RetryCallState], Any]] = None,
    ) -> None:
        self.max_attempts = max_attempts
        self.backoff = backoff
        self.backoff_base = backoff_base
        self.backoff_max = backoff_max
        self.retryable_exceptions = tuple(retryable_exceptions)
        self.on_retry = on_retry

    # ------------------------------------------------------------------
    # Internal: build a tenacity Retrying instance
    # ------------------------------------------------------------------

    def _build_retrying(self) -> tenacity.Retrying:
        wait = self._build_wait()
        kwargs: dict[str, Any] = {
            "stop": stop_after_attempt(self.max_attempts),
            "wait": wait,
            "retry": retry_if_exception_type(self.retryable_exceptions),
            "reraise": True,
        }
        if self.on_retry is not None:
            kwargs["before_sleep"] = self.on_retry
        return tenacity.Retrying(**kwargs)

    def _build_async_retrying(self) -> tenacity.AsyncRetrying:
        wait = self._build_wait()
        kwargs: dict[str, Any] = {
            "stop": stop_after_attempt(self.max_attempts),
            "wait": wait,
            "retry": retry_if_exception_type(self.retryable_exceptions),
            "reraise": True,
        }
        if self.on_retry is not None:
            kwargs["before_sleep"] = self.on_retry
        return tenacity.AsyncRetrying(**kwargs)

    def _build_wait(self) -> Any:
        if self.backoff == "exponential":
            return wait_exponential(
                multiplier=self.backoff_base,
                max=self.backoff_max,
            )
        if self.backoff == "fixed":
            return wait_fixed(self.backoff_base)
        if self.backoff == "none":
            return wait_none()
        raise ValueError(f"Unknown backoff strategy: {self.backoff!r}")

    # ------------------------------------------------------------------
    # Decorator interface
    # ------------------------------------------------------------------

    def __call__(self, fn: Callable) -> Callable:
        """Use the policy as a decorator on sync or async functions."""
        if asyncio.iscoroutinefunction(fn):
            @functools.wraps(fn)
            async def async_wrapper(*args: Any, **kwargs: Any) -> Any:
                retrying = self._build_async_retrying()
                return await retrying(fn, *args, **kwargs)

            return async_wrapper

        @functools.wraps(fn)
        def sync_wrapper(*args: Any, **kwargs: Any) -> Any:
            retrying = self._build_retrying()
            return retrying(fn, *args, **kwargs)

        return sync_wrapper

    # ------------------------------------------------------------------
    # Context manager interface
    # ------------------------------------------------------------------

    @contextmanager
    def context(self):
        """Synchronous context manager that retries the wrapped block.

        Usage::

            policy = RetryPolicy(max_attempts=3)
            for attempt in policy.context():
                with attempt:
                    do_something_flaky()
        """
        retrying = self._build_retrying()
        yield from retrying

    @asynccontextmanager
    async def async_context(self):
        """Asynchronous context manager that retries the wrapped block.

        Usage::

            policy = RetryPolicy(max_attempts=3)
            async for attempt in policy.async_context():
                with attempt:
                    await do_something_flaky()
        """
        retrying = self._build_async_retrying()
        async for attempt in retrying:
            yield attempt

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------

    def copy(self, **overrides: Any) -> "RetryPolicy":
        """Return a shallow copy with optional parameter overrides."""
        params = {
            "max_attempts": self.max_attempts,
            "backoff": self.backoff,
            "backoff_base": self.backoff_base,
            "backoff_max": self.backoff_max,
            "retryable_exceptions": self.retryable_exceptions,
            "on_retry": self.on_retry,
        }
        params.update(overrides)
        return RetryPolicy(**params)

    def __repr__(self) -> str:
        return (
            f"RetryPolicy(max_attempts={self.max_attempts}, "
            f"backoff={self.backoff!r}, "
            f"retryable_exceptions={self.retryable_exceptions})"
        )
