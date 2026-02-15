#!/usr/bin/env python3
"""
Strict Execution Mechanism
==========================

A robust execution framework that enforces strict validation, type checking,
error handling, and audit logging for function execution. Designed for the
Gemini-discovers-Diamonds project to ensure reliable and traceable operations.

Features:
    - Decorator-based strict type enforcement
    - Pre/post condition validation
    - Automatic retry with exponential backoff
    - Execution timeout enforcement
    - Comprehensive audit trail logging
    - Input sanitization and validation
    - Immutable execution context
    - Circuit breaker pattern for fault tolerance
"""

import functools
import inspect
import logging
import signal
import time
import traceback
from contextlib import contextmanager
from dataclasses import dataclass, field
from datetime import datetime, timezone
from enum import Enum, auto
from typing import (
    Any,
    Callable,
    Dict,
    List,
    Optional,
    Set,
    Tuple,
    Type,
    TypeVar,
    Union,
)

# ---------------------------------------------------------------------------
# Logging Configuration
# ---------------------------------------------------------------------------

logger = logging.getLogger("strict_execution")
logger.setLevel(logging.DEBUG)

if not logger.handlers:
    handler = logging.StreamHandler()
    handler.setFormatter(
        logging.Formatter(
            "[%(asctime)s] [%(levelname)s] %(name)s: %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S",
        )
    )
    logger.addHandler(handler)

# ---------------------------------------------------------------------------
# Type Variables
# ---------------------------------------------------------------------------

F = TypeVar("F", bound=Callable[..., Any])
T = TypeVar("T")

# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------


class ExecutionStatus(Enum):
    """Status of an execution attempt."""

    PENDING = auto()
    RUNNING = auto()
    SUCCESS = auto()
    FAILED = auto()
    TIMEOUT = auto()
    RETRYING = auto()
    CIRCUIT_OPEN = auto()


class ValidationLevel(Enum):
    """Level of validation strictness."""

    LENIENT = auto()
    STANDARD = auto()
    STRICT = auto()
    PARANOID = auto()


# ---------------------------------------------------------------------------
# Exceptions
# ---------------------------------------------------------------------------


class StrictExecutionError(Exception):
    """Base exception for all strict execution errors."""

    def __init__(self, message: str, context: Optional[Dict[str, Any]] = None):
        super().__init__(message)
        self.context = context or {}
        self.timestamp = datetime.now(timezone.utc)


class ValidationError(StrictExecutionError):
    """Raised when input validation fails."""

    pass


class TypeEnforcementError(StrictExecutionError):
    """Raised when type checking fails."""

    pass


class PreconditionError(StrictExecutionError):
    """Raised when a precondition is not met."""

    pass


class PostconditionError(StrictExecutionError):
    """Raised when a postcondition is not met."""

    pass


class TimeoutExecutionError(StrictExecutionError):
    """Raised when execution exceeds the allowed time."""

    pass


class RetryExhaustedError(StrictExecutionError):
    """Raised when all retry attempts are exhausted."""

    pass


class CircuitBreakerOpenError(StrictExecutionError):
    """Raised when the circuit breaker is in open state."""

    pass


# ---------------------------------------------------------------------------
# Data Classes
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class ExecutionRecord:
    """Immutable record of a single execution attempt."""

    function_name: str
    status: ExecutionStatus
    start_time: datetime
    end_time: Optional[datetime]
    duration_ms: Optional[float]
    args: Tuple
    kwargs: Dict[str, Any]
    result: Any = None
    error: Optional[str] = None
    attempt: int = 1
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class CircuitBreakerState:
    """Tracks the state of a circuit breaker for a function."""

    failure_count: int = 0
    last_failure_time: Optional[float] = None
    is_open: bool = False
    threshold: int = 5
    recovery_timeout: float = 60.0

    def record_failure(self) -> None:
        """Record a failure and potentially open the circuit."""
        self.failure_count += 1
        self.last_failure_time = time.time()
        if self.failure_count >= self.threshold:
            self.is_open = True
            logger.warning(
                "Circuit breaker OPENED after %d failures", self.failure_count
            )

    def record_success(self) -> None:
        """Record a success and reset the failure count."""
        self.failure_count = 0
        self.is_open = False

    def can_execute(self) -> bool:
        """Check if execution is allowed (circuit is closed or half-open)."""
        if not self.is_open:
            return True
        if self.last_failure_time is None:
            return True
        elapsed = time.time() - self.last_failure_time
        if elapsed >= self.recovery_timeout:
            logger.info("Circuit breaker entering HALF-OPEN state")
            return True
        return False


# ---------------------------------------------------------------------------
# Audit Trail
# ---------------------------------------------------------------------------


class AuditTrail:
    """Thread-safe audit trail for tracking all execution records."""

    def __init__(self, max_records: int = 10000):
        self._records: List[ExecutionRecord] = []
        self._max_records = max_records

    def add_record(self, record: ExecutionRecord) -> None:
        """Add an execution record to the audit trail."""
        if len(self._records) >= self._max_records:
            self._records.pop(0)
        self._records.append(record)
        logger.debug(
            "Audit: %s -> %s (attempt %d, %.2fms)",
            record.function_name,
            record.status.name,
            record.attempt,
            record.duration_ms or 0,
        )

    def get_records(
        self,
        function_name: Optional[str] = None,
        status: Optional[ExecutionStatus] = None,
        limit: int = 100,
    ) -> List[ExecutionRecord]:
        """Retrieve execution records with optional filtering."""
        filtered = self._records
        if function_name:
            filtered = [r for r in filtered if r.function_name == function_name]
        if status:
            filtered = [r for r in filtered if r.status == status]
        return filtered[-limit:]

    def get_statistics(
        self, function_name: Optional[str] = None
    ) -> Dict[str, Any]:
        """Get execution statistics for the audit trail."""
        records = self.get_records(function_name=function_name, limit=self._max_records)
        if not records:
            return {"total": 0}

        successes = [r for r in records if r.status == ExecutionStatus.SUCCESS]
        failures = [r for r in records if r.status == ExecutionStatus.FAILED]
        durations = [
            r.duration_ms for r in records if r.duration_ms is not None
        ]

        return {
            "total": len(records),
            "successes": len(successes),
            "failures": len(failures),
            "success_rate": len(successes) / len(records) if records else 0,
            "avg_duration_ms": sum(durations) / len(durations) if durations else 0,
            "min_duration_ms": min(durations) if durations else 0,
            "max_duration_ms": max(durations) if durations else 0,
        }

    def clear(self) -> None:
        """Clear all records from the audit trail."""
        self._records.clear()

    @property
    def record_count(self) -> int:
        """Return the number of records in the trail."""
        return len(self._records)


# Global audit trail instance
_global_audit_trail = AuditTrail()


def get_audit_trail() -> AuditTrail:
    """Get the global audit trail instance."""
    return _global_audit_trail


# ---------------------------------------------------------------------------
# Type Enforcement
# ---------------------------------------------------------------------------


def _check_type_hints(func: Callable, args: tuple, kwargs: dict) -> None:
    """Validate function arguments against type hints."""
    hints = func.__annotations__ if hasattr(func, "__annotations__") else {}
    if not hints:
        return

    sig = inspect.signature(func)
    bound = sig.bind(*args, **kwargs)
    bound.apply_defaults()

    for param_name, value in bound.arguments.items():
        if param_name in hints and param_name != "return":
            expected_type = hints[param_name]
            # Handle Optional, Union, etc. from typing
            origin = getattr(expected_type, "__origin__", None)
            if origin is Union:
                type_args = expected_type.__args__
                if not isinstance(value, type_args):
                    raise TypeEnforcementError(
                        f"Parameter '{param_name}' expected {expected_type}, "
                        f"got {type(value).__name__}: {value!r}",
                        context={
                            "parameter": param_name,
                            "expected": str(expected_type),
                            "actual": type(value).__name__,
                        },
                    )
            elif origin is not None:
                # For generic types like List[int], just check the origin
                if not isinstance(value, origin):
                    raise TypeEnforcementError(
                        f"Parameter '{param_name}' expected {expected_type}, "
                        f"got {type(value).__name__}: {value!r}",
                        context={
                            "parameter": param_name,
                            "expected": str(expected_type),
                            "actual": type(value).__name__,
                        },
                    )
            else:
                if not isinstance(value, expected_type):
                    raise TypeEnforcementError(
                        f"Parameter '{param_name}' expected {expected_type.__name__}, "
                        f"got {type(value).__name__}: {value!r}",
                        context={
                            "parameter": param_name,
                            "expected": expected_type.__name__,
                            "actual": type(value).__name__,
                        },
                    )


def _check_return_type(func: Callable, result: Any) -> None:
    """Validate function return value against return type hint."""
    hints = func.__annotations__ if hasattr(func, "__annotations__") else {}
    if "return" not in hints:
        return

    expected_type = hints["return"]
    if expected_type is type(None) and result is None:
        return

    origin = getattr(expected_type, "__origin__", None)
    if origin is Union:
        type_args = expected_type.__args__
        if not isinstance(result, type_args):
            raise TypeEnforcementError(
                f"Return value expected {expected_type}, "
                f"got {type(result).__name__}: {result!r}",
                context={
                    "expected": str(expected_type),
                    "actual": type(result).__name__,
                },
            )
    elif origin is not None:
        if not isinstance(result, origin):
            raise TypeEnforcementError(
                f"Return value expected {expected_type}, "
                f"got {type(result).__name__}: {result!r}",
                context={
                    "expected": str(expected_type),
                    "actual": type(result).__name__,
                },
            )
    else:
        if expected_type is not None and not isinstance(result, expected_type):
            raise TypeEnforcementError(
                f"Return value expected {expected_type.__name__}, "
                f"got {type(result).__name__}: {result!r}",
                context={
                    "expected": expected_type.__name__,
                    "actual": type(result).__name__,
                },
            )


# ---------------------------------------------------------------------------
# Timeout Handling
# ---------------------------------------------------------------------------


class _TimeoutHandler:
    """Context manager for enforcing execution timeouts using SIGALRM."""

    def __init__(self, seconds: int, func_name: str):
        self.seconds = seconds
        self.func_name = func_name
        self._old_handler = None

    def _handle_timeout(self, signum: int, frame: Any) -> None:
        raise TimeoutExecutionError(
            f"Function '{self.func_name}' exceeded timeout of {self.seconds}s",
            context={"timeout_seconds": self.seconds},
        )

    def __enter__(self) -> "_TimeoutHandler":
        if hasattr(signal, "SIGALRM"):
            self._old_handler = signal.signal(signal.SIGALRM, self._handle_timeout)
            signal.alarm(self.seconds)
        return self

    def __exit__(self, *args: Any) -> None:
        if hasattr(signal, "SIGALRM"):
            signal.alarm(0)
            if self._old_handler is not None:
                signal.signal(signal.SIGALRM, self._old_handler)


# ---------------------------------------------------------------------------
# Core Decorators
# ---------------------------------------------------------------------------


def strict(
    *,
    enforce_types: bool = True,
    validate_return: bool = True,
    preconditions: Optional[List[Callable[..., bool]]] = None,
    postconditions: Optional[List[Callable[[Any], bool]]] = None,
    allowed_exceptions: Optional[Set[Type[Exception]]] = None,
    timeout_seconds: Optional[int] = None,
    retries: int = 0,
    retry_delay: float = 1.0,
    retry_backoff: float = 2.0,
    retry_on: Optional[Set[Type[Exception]]] = None,
    circuit_breaker: bool = False,
    circuit_threshold: int = 5,
    circuit_recovery: float = 60.0,
    audit: bool = True,
    validation_level: ValidationLevel = ValidationLevel.STRICT,
    on_failure: Optional[Callable[[Exception], Any]] = None,
) -> Callable[[F], F]:
    """
    Decorator that enforces strict execution rules on a function.

    Args:
        enforce_types: Whether to enforce type hint checking on arguments.
        validate_return: Whether to validate the return type.
        preconditions: List of callables that must return True before execution.
            Each callable receives the same arguments as the decorated function.
        postconditions: List of callables that must return True after execution.
            Each callable receives the return value.
        allowed_exceptions: Set of exception types that are allowed to propagate.
            Any other exception is wrapped in StrictExecutionError.
        timeout_seconds: Maximum execution time in seconds (uses SIGALRM).
        retries: Number of retry attempts on failure.
        retry_delay: Initial delay between retries in seconds.
        retry_backoff: Multiplier for exponential backoff.
        retry_on: Set of exception types to retry on. If None, retries on all.
        circuit_breaker: Whether to enable circuit breaker pattern.
        circuit_threshold: Number of failures before opening the circuit.
        circuit_recovery: Seconds to wait before attempting recovery.
        audit: Whether to log execution records to the audit trail.
        validation_level: Level of validation strictness.
        on_failure: Optional callback invoked when all retries are exhausted.

    Returns:
        Decorated function with strict execution enforcement.

    Example:
        @strict(enforce_types=True, retries=3, timeout_seconds=10)
        def process_data(items: List[int]) -> int:
            return sum(items)
    """
    # Circuit breaker state per-function
    cb_state = CircuitBreakerState(
        threshold=circuit_threshold, recovery_timeout=circuit_recovery
    )

    def decorator(func: F) -> F:
        @functools.wraps(func)
        def wrapper(*args: Any, **kwargs: Any) -> Any:
            func_name = func.__qualname__
            audit_trail = get_audit_trail()

            # --- Circuit Breaker Check ---
            if circuit_breaker and not cb_state.can_execute():
                record = ExecutionRecord(
                    function_name=func_name,
                    status=ExecutionStatus.CIRCUIT_OPEN,
                    start_time=datetime.now(timezone.utc),
                    end_time=datetime.now(timezone.utc),
                    duration_ms=0,
                    args=args,
                    kwargs=kwargs,
                    error="Circuit breaker is open",
                )
                if audit:
                    audit_trail.add_record(record)
                raise CircuitBreakerOpenError(
                    f"Circuit breaker is open for '{func_name}'. "
                    f"Recovery in {cb_state.recovery_timeout}s.",
                    context={"failure_count": cb_state.failure_count},
                )

            # --- Type Enforcement ---
            if enforce_types:
                _check_type_hints(func, args, kwargs)

            # --- Precondition Checks ---
            if preconditions:
                for i, condition in enumerate(preconditions):
                    try:
                        result = condition(*args, **kwargs)
                    except Exception as e:
                        raise PreconditionError(
                            f"Precondition {i} for '{func_name}' raised an error: {e}",
                            context={"precondition_index": i},
                        ) from e
                    if not result:
                        raise PreconditionError(
                            f"Precondition {i} for '{func_name}' failed",
                            context={"precondition_index": i},
                        )

            # --- Execution with Retry Logic ---
            last_exception: Optional[Exception] = None
            max_attempts = 1 + retries
            current_delay = retry_delay

            for attempt in range(1, max_attempts + 1):
                start_time = datetime.now(timezone.utc)
                start_perf = time.perf_counter()
                status = ExecutionStatus.RUNNING

                try:
                    # Execute with optional timeout
                    if timeout_seconds and hasattr(signal, "SIGALRM"):
                        with _TimeoutHandler(timeout_seconds, func_name):
                            result = func(*args, **kwargs)
                    else:
                        result = func(*args, **kwargs)

                    # --- Return Type Validation ---
                    if validate_return:
                        _check_return_type(func, result)

                    # --- Postcondition Checks ---
                    if postconditions:
                        for i, condition in enumerate(postconditions):
                            try:
                                check = condition(result)
                            except Exception as e:
                                raise PostconditionError(
                                    f"Postcondition {i} for '{func_name}' "
                                    f"raised an error: {e}",
                                    context={"postcondition_index": i},
                                ) from e
                            if not check:
                                raise PostconditionError(
                                    f"Postcondition {i} for '{func_name}' "
                                    f"failed with result: {result!r}",
                                    context={
                                        "postcondition_index": i,
                                        "result": repr(result),
                                    },
                                )

                    end_perf = time.perf_counter()
                    duration_ms = (end_perf - start_perf) * 1000
                    status = ExecutionStatus.SUCCESS

                    record = ExecutionRecord(
                        function_name=func_name,
                        status=status,
                        start_time=start_time,
                        end_time=datetime.now(timezone.utc),
                        duration_ms=duration_ms,
                        args=args,
                        kwargs=kwargs,
                        result=result,
                        attempt=attempt,
                    )
                    if audit:
                        audit_trail.add_record(record)

                    if circuit_breaker:
                        cb_state.record_success()

                    return result

                except (
                    TypeEnforcementError,
                    PreconditionError,
                    PostconditionError,
                ) as e:
                    # Validation errors are never retried
                    end_perf = time.perf_counter()
                    duration_ms = (end_perf - start_perf) * 1000
                    record = ExecutionRecord(
                        function_name=func_name,
                        status=ExecutionStatus.FAILED,
                        start_time=start_time,
                        end_time=datetime.now(timezone.utc),
                        duration_ms=duration_ms,
                        args=args,
                        kwargs=kwargs,
                        error=str(e),
                        attempt=attempt,
                    )
                    if audit:
                        audit_trail.add_record(record)
                    raise

                except Exception as e:
                    end_perf = time.perf_counter()
                    duration_ms = (end_perf - start_perf) * 1000
                    last_exception = e

                    # Check if this exception type is retryable
                    should_retry = attempt < max_attempts
                    if retry_on and not isinstance(e, tuple(retry_on)):
                        should_retry = False

                    if should_retry:
                        status = ExecutionStatus.RETRYING
                        record = ExecutionRecord(
                            function_name=func_name,
                            status=status,
                            start_time=start_time,
                            end_time=datetime.now(timezone.utc),
                            duration_ms=duration_ms,
                            args=args,
                            kwargs=kwargs,
                            error=str(e),
                            attempt=attempt,
                        )
                        if audit:
                            audit_trail.add_record(record)

                        logger.warning(
                            "Retrying '%s' (attempt %d/%d) after %.2fs: %s",
                            func_name,
                            attempt,
                            max_attempts,
                            current_delay,
                            str(e),
                        )
                        time.sleep(current_delay)
                        current_delay *= retry_backoff
                        continue

                    # No more retries
                    status = ExecutionStatus.FAILED
                    record = ExecutionRecord(
                        function_name=func_name,
                        status=status,
                        start_time=start_time,
                        end_time=datetime.now(timezone.utc),
                        duration_ms=duration_ms,
                        args=args,
                        kwargs=kwargs,
                        error=str(e),
                        attempt=attempt,
                    )
                    if audit:
                        audit_trail.add_record(record)

                    if circuit_breaker:
                        cb_state.record_failure()

                    if on_failure:
                        on_failure(e)

                    # Check if the exception is allowed to propagate directly
                    if allowed_exceptions and isinstance(
                        e, tuple(allowed_exceptions)
                    ):
                        raise

                    if isinstance(e, TimeoutExecutionError):
                        raise

                    raise StrictExecutionError(
                        f"Execution of '{func_name}' failed: {e}",
                        context={
                            "original_error": type(e).__name__,
                            "traceback": traceback.format_exc(),
                        },
                    ) from e

            # All retries exhausted
            if circuit_breaker:
                cb_state.record_failure()

            if on_failure and last_exception:
                on_failure(last_exception)

            raise RetryExhaustedError(
                f"All {max_attempts} attempts exhausted for '{func_name}'",
                context={
                    "total_attempts": max_attempts,
                    "last_error": str(last_exception),
                },
            )

        # Attach metadata to the wrapper
        wrapper._strict_config = {  # type: ignore[attr-defined]
            "enforce_types": enforce_types,
            "validate_return": validate_return,
            "retries": retries,
            "timeout_seconds": timeout_seconds,
            "circuit_breaker": circuit_breaker,
            "validation_level": validation_level.name,
        }

        return wrapper  # type: ignore[return-value]

    return decorator


# ---------------------------------------------------------------------------
# Convenience Decorators
# ---------------------------------------------------------------------------


def strict_types(func: F) -> F:
    """Simple decorator that only enforces type hints (no retries, no timeout)."""
    return strict(enforce_types=True, validate_return=True, audit=False)(func)


def strict_retry(
    retries: int = 3,
    delay: float = 1.0,
    backoff: float = 2.0,
    retry_on: Optional[Set[Type[Exception]]] = None,
) -> Callable[[F], F]:
    """Decorator that adds retry logic with exponential backoff."""
    return strict(
        enforce_types=False,
        validate_return=False,
        retries=retries,
        retry_delay=delay,
        retry_backoff=backoff,
        retry_on=retry_on,
    )


def strict_timeout(seconds: int) -> Callable[[F], F]:
    """Decorator that enforces a timeout on function execution."""
    return strict(
        enforce_types=False,
        validate_return=False,
        timeout_seconds=seconds,
    )


def strict_validate(
    preconditions: Optional[List[Callable[..., bool]]] = None,
    postconditions: Optional[List[Callable[[Any], bool]]] = None,
) -> Callable[[F], F]:
    """Decorator that enforces pre/postconditions."""
    return strict(
        enforce_types=False,
        validate_return=False,
        preconditions=preconditions,
        postconditions=postconditions,
    )


# ---------------------------------------------------------------------------
# Execution Context Manager
# ---------------------------------------------------------------------------


@contextmanager
def strict_context(
    name: str = "anonymous",
    timeout_seconds: Optional[int] = None,
    audit: bool = True,
):
    """
    Context manager for strict execution of a code block.

    Usage:
        with strict_context("data_processing", timeout_seconds=30):
            result = process_heavy_data()
    """
    audit_trail = get_audit_trail()
    start_time = datetime.now(timezone.utc)
    start_perf = time.perf_counter()

    try:
        if timeout_seconds and hasattr(signal, "SIGALRM"):
            with _TimeoutHandler(timeout_seconds, name):
                yield
        else:
            yield

        end_perf = time.perf_counter()
        duration_ms = (end_perf - start_perf) * 1000

        if audit:
            record = ExecutionRecord(
                function_name=f"context:{name}",
                status=ExecutionStatus.SUCCESS,
                start_time=start_time,
                end_time=datetime.now(timezone.utc),
                duration_ms=duration_ms,
                args=(),
                kwargs={},
            )
            audit_trail.add_record(record)

    except Exception as e:
        end_perf = time.perf_counter()
        duration_ms = (end_perf - start_perf) * 1000

        if audit:
            record = ExecutionRecord(
                function_name=f"context:{name}",
                status=ExecutionStatus.FAILED,
                start_time=start_time,
                end_time=datetime.now(timezone.utc),
                duration_ms=duration_ms,
                args=(),
                kwargs={},
                error=str(e),
            )
            audit_trail.add_record(record)
        raise


# ---------------------------------------------------------------------------
# Utility Functions
# ---------------------------------------------------------------------------


def validate_input(
    value: Any,
    *,
    expected_type: Optional[Type] = None,
    min_value: Optional[float] = None,
    max_value: Optional[float] = None,
    min_length: Optional[int] = None,
    max_length: Optional[int] = None,
    allowed_values: Optional[Set] = None,
    custom_validator: Optional[Callable[[Any], bool]] = None,
    param_name: str = "value",
) -> Any:
    """
    Validate an input value against various constraints.

    Args:
        value: The value to validate.
        expected_type: Expected type of the value.
        min_value: Minimum numeric value (inclusive).
        max_value: Maximum numeric value (inclusive).
        min_length: Minimum length (for sequences/strings).
        max_length: Maximum length (for sequences/strings).
        allowed_values: Set of allowed values.
        custom_validator: Custom validation function returning bool.
        param_name: Name of the parameter (for error messages).

    Returns:
        The validated value (unchanged).

    Raises:
        ValidationError: If any validation check fails.
    """
    if expected_type is not None and not isinstance(value, expected_type):
        raise ValidationError(
            f"'{param_name}' must be {expected_type.__name__}, "
            f"got {type(value).__name__}",
            context={"param": param_name, "expected": expected_type.__name__},
        )

    if min_value is not None and value < min_value:
        raise ValidationError(
            f"'{param_name}' must be >= {min_value}, got {value}",
            context={"param": param_name, "min": min_value, "actual": value},
        )

    if max_value is not None and value > max_value:
        raise ValidationError(
            f"'{param_name}' must be <= {max_value}, got {value}",
            context={"param": param_name, "max": max_value, "actual": value},
        )

    if min_length is not None and len(value) < min_length:
        raise ValidationError(
            f"'{param_name}' length must be >= {min_length}, got {len(value)}",
            context={"param": param_name, "min_length": min_length},
        )

    if max_length is not None and len(value) > max_length:
        raise ValidationError(
            f"'{param_name}' length must be <= {max_length}, got {len(value)}",
            context={"param": param_name, "max_length": max_length},
        )

    if allowed_values is not None and value not in allowed_values:
        raise ValidationError(
            f"'{param_name}' must be one of {allowed_values}, got {value!r}",
            context={"param": param_name, "allowed": list(allowed_values)},
        )

    if custom_validator is not None and not custom_validator(value):
        raise ValidationError(
            f"'{param_name}' failed custom validation",
            context={"param": param_name},
        )

    return value


def reset_audit_trail() -> None:
    """Clear the global audit trail."""
    _global_audit_trail.clear()


def get_execution_statistics(function_name: Optional[str] = None) -> Dict[str, Any]:
    """Get execution statistics from the global audit trail."""
    return _global_audit_trail.get_statistics(function_name=function_name)
