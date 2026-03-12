"""Timeout wrappers for synchronous and asynchronous operations.

Provides a unified ``Timeout`` class that works as a decorator or
context manager for both sync (thread-based) and async (asyncio-based)
code paths.
"""

from __future__ import annotations

import asyncio
import concurrent.futures
import functools
import threading
from contextlib import asynccontextmanager, contextmanager
from typing import Any, Callable, Optional, TypeVar

T = TypeVar("T")


class TimeoutError(Exception):  # noqa: A001  (intentional shadow of builtin)
    """Raised when an operation exceeds its allowed duration."""

    def __init__(self, timeout_seconds: float, operation: str = "") -> None:
        self.timeout_seconds = timeout_seconds
        self.operation = operation
        msg = f"Operation timed out after {timeout_seconds}s"
        if operation:
            msg = f"{operation}: {msg}"
        super().__init__(msg)


class Timeout:
    """Configurable timeout wrapper for sync and async code.

    Parameters
    ----------
    timeout_seconds:
        Maximum number of seconds an operation is allowed to run.
    operation:
        Optional label included in the ``TimeoutError`` message.

    Usage as a **decorator**::

        @Timeout(5.0)
        def slow_sync():
            ...

        @Timeout(5.0)
        async def slow_async():
            ...

    Usage as a **context manager**::

        with Timeout(5.0).sync_context():
            do_slow_thing()

        async with Timeout(5.0).async_context():
            await do_slow_thing()
    """

    def __init__(
        self,
        timeout_seconds: float,
        *,
        operation: str = "",
    ) -> None:
        if timeout_seconds <= 0:
            raise ValueError("timeout_seconds must be positive")
        self.timeout_seconds = timeout_seconds
        self.operation = operation

    # ------------------------------------------------------------------
    # Decorator interface
    # ------------------------------------------------------------------

    def __call__(self, fn: Callable) -> Callable:
        if asyncio.iscoroutinefunction(fn):
            return self._wrap_async(fn)
        return self._wrap_sync(fn)

    def _wrap_async(self, fn: Callable) -> Callable:
        @functools.wraps(fn)
        async def wrapper(*args: Any, **kwargs: Any) -> Any:
            try:
                return await asyncio.wait_for(
                    fn(*args, **kwargs),
                    timeout=self.timeout_seconds,
                )
            except asyncio.TimeoutError:
                raise TimeoutError(
                    self.timeout_seconds,
                    self.operation or fn.__qualname__,
                ) from None

        return wrapper

    def _wrap_sync(self, fn: Callable) -> Callable:
        @functools.wraps(fn)
        def wrapper(*args: Any, **kwargs: Any) -> Any:
            return self._run_with_thread_timeout(fn, *args, **kwargs)

        return wrapper

    # ------------------------------------------------------------------
    # Context manager interface
    # ------------------------------------------------------------------

    @contextmanager
    def sync_context(self):
        """Synchronous context manager that enforces a timeout.

        The body of the ``with`` block is executed in a worker thread.
        If it does not complete within ``timeout_seconds`` a
        ``TimeoutError`` is raised in the calling thread.

        .. note::
            Because Python threads cannot be forcibly killed, the
            background thread may continue running after the timeout.
            This is a limitation of CPython's threading model.

        Usage::

            with Timeout(2.0).sync_context() as check:
                # ``check`` is a callable that raises if the deadline
                # has already passed -- call it inside long loops.
                for chunk in large_work:
                    check()
                    process(chunk)
        """
        deadline_event = threading.Event()
        timer = threading.Timer(self.timeout_seconds, deadline_event.set)
        timer.daemon = True
        timer.start()

        def check() -> None:
            if deadline_event.is_set():
                raise TimeoutError(self.timeout_seconds, self.operation)

        try:
            yield check
        finally:
            timer.cancel()
            if deadline_event.is_set():
                raise TimeoutError(self.timeout_seconds, self.operation)

    @asynccontextmanager
    async def async_context(self):
        """Asynchronous context manager that enforces a timeout.

        Usage::

            async with Timeout(2.0).async_context():
                await do_something_slow()
        """
        try:
            async with asyncio.timeout(self.timeout_seconds):
                yield
        except asyncio.TimeoutError:
            raise TimeoutError(
                self.timeout_seconds, self.operation
            ) from None

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _run_with_thread_timeout(
        self, fn: Callable, *args: Any, **kwargs: Any
    ) -> Any:
        """Run *fn* in a thread-pool and enforce the timeout."""
        with concurrent.futures.ThreadPoolExecutor(max_workers=1) as pool:
            future = pool.submit(fn, *args, **kwargs)
            try:
                return future.result(timeout=self.timeout_seconds)
            except concurrent.futures.TimeoutError:
                raise TimeoutError(
                    self.timeout_seconds,
                    self.operation or getattr(fn, "__qualname__", str(fn)),
                ) from None

    def __repr__(self) -> str:
        return (
            f"Timeout(timeout_seconds={self.timeout_seconds}, "
            f"operation={self.operation!r})"
        )
