#!/usr/bin/env python3
"""
Comprehensive tests for the Strict Execution Mechanism.
"""

import time
import unittest
from typing import List, Optional
from unittest.mock import MagicMock

from strict_execution import (
    AuditTrail,
    CircuitBreakerOpenError,
    CircuitBreakerState,
    ExecutionRecord,
    ExecutionStatus,
    PostconditionError,
    PreconditionError,
    RetryExhaustedError,
    StrictExecutionError,
    TimeoutExecutionError,
    TypeEnforcementError,
    ValidationError,
    ValidationLevel,
    get_audit_trail,
    get_execution_statistics,
    reset_audit_trail,
    strict,
    strict_context,
    strict_retry,
    strict_timeout,
    strict_types,
    strict_validate,
    validate_input,
)


class TestTypeEnforcement(unittest.TestCase):
    """Tests for type hint enforcement."""

    def test_correct_types_pass(self):
        @strict(enforce_types=True, audit=False)
        def add(a: int, b: int) -> int:
            return a + b

        self.assertEqual(add(1, 2), 3)

    def test_wrong_argument_type_raises(self):
        @strict(enforce_types=True, audit=False)
        def add(a: int, b: int) -> int:
            return a + b

        with self.assertRaises(TypeEnforcementError) as ctx:
            add("hello", 2)
        self.assertIn("a", str(ctx.exception))

    def test_wrong_return_type_raises(self):
        @strict(enforce_types=True, validate_return=True, audit=False)
        def bad_return(x: int) -> int:
            return str(x)  # type: ignore

        with self.assertRaises(TypeEnforcementError) as ctx:
            bad_return(42)
        self.assertIn("Return value", str(ctx.exception))

    def test_optional_type_allows_none(self):
        @strict(enforce_types=True, audit=False)
        def maybe(x: Optional[int]) -> Optional[int]:
            return x

        self.assertIsNone(maybe(None))
        self.assertEqual(maybe(5), 5)

    def test_list_type_enforcement(self):
        @strict(enforce_types=True, audit=False)
        def process(items: list) -> int:
            return len(items)

        self.assertEqual(process([1, 2, 3]), 3)

        with self.assertRaises(TypeEnforcementError):
            process("not a list")  # type: ignore

    def test_no_type_hints_skips_check(self):
        @strict(enforce_types=True, audit=False)
        def untyped(x, y):
            return x + y

        self.assertEqual(untyped(1, 2), 3)
        self.assertEqual(untyped("a", "b"), "ab")

    def test_strict_types_convenience(self):
        @strict_types
        def multiply(a: int, b: int) -> int:
            return a * b

        self.assertEqual(multiply(3, 4), 12)

        with self.assertRaises(TypeEnforcementError):
            multiply(3.0, 4)  # type: ignore


class TestPreconditions(unittest.TestCase):
    """Tests for precondition validation."""

    def test_precondition_passes(self):
        @strict(
            enforce_types=False,
            preconditions=[lambda x: x > 0],
            audit=False,
        )
        def positive_only(x):
            return x * 2

        self.assertEqual(positive_only(5), 10)

    def test_precondition_fails(self):
        @strict(
            enforce_types=False,
            preconditions=[lambda x: x > 0],
            audit=False,
        )
        def positive_only(x):
            return x * 2

        with self.assertRaises(PreconditionError):
            positive_only(-1)

    def test_multiple_preconditions(self):
        @strict(
            enforce_types=False,
            preconditions=[
                lambda x: x > 0,
                lambda x: x < 100,
                lambda x: x % 2 == 0,
            ],
            audit=False,
        )
        def bounded_even(x):
            return x

        self.assertEqual(bounded_even(10), 10)

        with self.assertRaises(PreconditionError):
            bounded_even(101)  # Fails x < 100

        with self.assertRaises(PreconditionError):
            bounded_even(11)  # Fails x % 2 == 0

    def test_precondition_exception_wraps(self):
        def bad_condition(x):
            raise ValueError("bad")

        @strict(
            enforce_types=False,
            preconditions=[bad_condition],
            audit=False,
        )
        def func(x):
            return x

        with self.assertRaises(PreconditionError) as ctx:
            func(1)
        self.assertIn("raised an error", str(ctx.exception))


class TestPostconditions(unittest.TestCase):
    """Tests for postcondition validation."""

    def test_postcondition_passes(self):
        @strict(
            enforce_types=False,
            postconditions=[lambda result: result >= 0],
            audit=False,
        )
        def absolute(x):
            return abs(x)

        self.assertEqual(absolute(-5), 5)

    def test_postcondition_fails(self):
        @strict(
            enforce_types=False,
            postconditions=[lambda result: result >= 0],
            audit=False,
        )
        def negate(x):
            return -x

        with self.assertRaises(PostconditionError):
            negate(5)

    def test_postcondition_exception_wraps(self):
        def bad_post(result):
            raise RuntimeError("oops")

        @strict(
            enforce_types=False,
            postconditions=[bad_post],
            audit=False,
        )
        def func(x):
            return x

        with self.assertRaises(PostconditionError):
            func(1)


class TestRetryMechanism(unittest.TestCase):
    """Tests for retry logic with exponential backoff."""

    def test_succeeds_on_first_try(self):
        call_count = 0

        @strict(enforce_types=False, retries=3, retry_delay=0.01, audit=False)
        def succeed():
            nonlocal call_count
            call_count += 1
            return "ok"

        result = succeed()
        self.assertEqual(result, "ok")
        self.assertEqual(call_count, 1)

    def test_retries_on_failure(self):
        call_count = 0

        @strict(enforce_types=False, retries=3, retry_delay=0.01, audit=False)
        def fail_twice():
            nonlocal call_count
            call_count += 1
            if call_count < 3:
                raise RuntimeError(f"Attempt {call_count}")
            return "recovered"

        result = fail_twice()
        self.assertEqual(result, "recovered")
        self.assertEqual(call_count, 3)

    def test_retries_exhausted(self):
        call_count = 0

        @strict(enforce_types=False, retries=2, retry_delay=0.01, audit=False)
        def always_fail():
            nonlocal call_count
            call_count += 1
            raise RuntimeError("always fails")

        with self.assertRaises(StrictExecutionError):
            always_fail()
        self.assertEqual(call_count, 3)  # 1 initial + 2 retries

    def test_retry_on_specific_exceptions(self):
        call_count = 0

        @strict(
            enforce_types=False,
            retries=3,
            retry_delay=0.01,
            retry_on={ConnectionError},
            audit=False,
        )
        def selective_fail():
            nonlocal call_count
            call_count += 1
            if call_count == 1:
                raise ConnectionError("network issue")
            if call_count == 2:
                raise ValueError("bad value")
            return "ok"

        # ValueError should not be retried
        with self.assertRaises(StrictExecutionError):
            selective_fail()
        self.assertEqual(call_count, 2)

    def test_strict_retry_convenience(self):
        call_count = 0

        @strict_retry(retries=2, delay=0.01)
        def flaky():
            nonlocal call_count
            call_count += 1
            if call_count < 2:
                raise RuntimeError("flaky")
            return "ok"

        result = flaky()
        self.assertEqual(result, "ok")
        self.assertEqual(call_count, 2)


class TestTimeout(unittest.TestCase):
    """Tests for execution timeout enforcement."""

    def test_fast_function_passes(self):
        @strict(enforce_types=False, timeout_seconds=5, audit=False)
        def quick():
            return "done"

        self.assertEqual(quick(), "done")

    def test_timeout_raises(self):
        @strict(enforce_types=False, timeout_seconds=1, audit=False)
        def slow():
            time.sleep(5)
            return "done"

        with self.assertRaises(TimeoutExecutionError):
            slow()

    def test_strict_timeout_convenience(self):
        @strict_timeout(5)
        def quick():
            return "fast"

        self.assertEqual(quick(), "fast")


class TestCircuitBreaker(unittest.TestCase):
    """Tests for circuit breaker pattern."""

    def test_circuit_stays_closed_on_success(self):
        @strict(
            enforce_types=False,
            circuit_breaker=True,
            circuit_threshold=3,
            audit=False,
        )
        def reliable():
            return "ok"

        for _ in range(10):
            self.assertEqual(reliable(), "ok")

    def test_circuit_opens_after_threshold(self):
        state = CircuitBreakerState(threshold=3, recovery_timeout=60.0)

        state.record_failure()
        self.assertFalse(state.is_open)
        state.record_failure()
        self.assertFalse(state.is_open)
        state.record_failure()
        self.assertTrue(state.is_open)

    def test_circuit_resets_on_success(self):
        state = CircuitBreakerState(threshold=3, recovery_timeout=60.0)
        state.record_failure()
        state.record_failure()
        state.record_success()
        self.assertEqual(state.failure_count, 0)
        self.assertFalse(state.is_open)

    def test_circuit_recovery(self):
        state = CircuitBreakerState(threshold=2, recovery_timeout=0.1)
        state.record_failure()
        state.record_failure()
        self.assertTrue(state.is_open)
        self.assertFalse(state.can_execute())

        time.sleep(0.15)
        self.assertTrue(state.can_execute())


class TestAuditTrail(unittest.TestCase):
    """Tests for the audit trail system."""

    def setUp(self):
        reset_audit_trail()

    def test_records_success(self):
        @strict(enforce_types=False)
        def tracked():
            return 42

        tracked()
        trail = get_audit_trail()
        records = trail.get_records()
        self.assertEqual(len(records), 1)
        self.assertEqual(records[0].status, ExecutionStatus.SUCCESS)
        self.assertEqual(records[0].result, 42)

    def test_records_failure(self):
        @strict(enforce_types=False)
        def tracked_fail():
            raise ValueError("fail")

        with self.assertRaises(StrictExecutionError):
            tracked_fail()

        trail = get_audit_trail()
        records = trail.get_records()
        self.assertEqual(len(records), 1)
        self.assertEqual(records[0].status, ExecutionStatus.FAILED)

    def test_records_retries(self):
        call_count = 0

        @strict(enforce_types=False, retries=2, retry_delay=0.01)
        def flaky():
            nonlocal call_count
            call_count += 1
            if call_count < 3:
                raise RuntimeError("fail")
            return "ok"

        flaky()
        trail = get_audit_trail()
        records = trail.get_records()
        self.assertEqual(len(records), 3)  # 2 retries + 1 success

    def test_filter_by_function_name(self):
        @strict(enforce_types=False)
        def func_a():
            return 1

        @strict(enforce_types=False)
        def func_b():
            return 2

        func_a()
        func_b()
        func_a()

        trail = get_audit_trail()
        a_records = trail.get_records(
            function_name="TestAuditTrail.test_filter_by_function_name.<locals>.func_a"
        )
        self.assertEqual(len(a_records), 2)

    def test_filter_by_status(self):
        @strict(enforce_types=False)
        def success():
            return 1

        @strict(enforce_types=False)
        def failure():
            raise ValueError("x")

        success()
        try:
            failure()
        except StrictExecutionError:
            pass

        trail = get_audit_trail()
        successes = trail.get_records(status=ExecutionStatus.SUCCESS)
        failures = trail.get_records(status=ExecutionStatus.FAILED)
        self.assertEqual(len(successes), 1)
        self.assertEqual(len(failures), 1)

    def test_statistics(self):
        @strict(enforce_types=False)
        def tracked():
            return 1

        for _ in range(5):
            tracked()

        stats = get_execution_statistics()
        self.assertEqual(stats["total"], 5)
        self.assertEqual(stats["successes"], 5)
        self.assertEqual(stats["failures"], 0)
        self.assertEqual(stats["success_rate"], 1.0)
        self.assertGreater(stats["avg_duration_ms"], 0)

    def test_max_records_limit(self):
        trail = AuditTrail(max_records=5)
        for i in range(10):
            trail.add_record(
                ExecutionRecord(
                    function_name=f"func_{i}",
                    status=ExecutionStatus.SUCCESS,
                    start_time=None,
                    end_time=None,
                    duration_ms=1.0,
                    args=(),
                    kwargs={},
                )
            )
        self.assertEqual(trail.record_count, 5)

    def test_clear_trail(self):
        trail = get_audit_trail()

        @strict(enforce_types=False)
        def tracked():
            return 1

        tracked()
        self.assertGreater(trail.record_count, 0)
        trail.clear()
        self.assertEqual(trail.record_count, 0)


class TestValidateInput(unittest.TestCase):
    """Tests for the validate_input utility."""

    def test_type_validation(self):
        result = validate_input(42, expected_type=int, param_name="x")
        self.assertEqual(result, 42)

        with self.assertRaises(ValidationError):
            validate_input("hello", expected_type=int, param_name="x")

    def test_min_value(self):
        validate_input(10, min_value=5)

        with self.assertRaises(ValidationError):
            validate_input(3, min_value=5)

    def test_max_value(self):
        validate_input(10, max_value=20)

        with self.assertRaises(ValidationError):
            validate_input(25, max_value=20)

    def test_min_max_range(self):
        validate_input(15, min_value=10, max_value=20)

        with self.assertRaises(ValidationError):
            validate_input(5, min_value=10, max_value=20)

    def test_min_length(self):
        validate_input("hello", min_length=3)

        with self.assertRaises(ValidationError):
            validate_input("hi", min_length=3)

    def test_max_length(self):
        validate_input("hi", max_length=5)

        with self.assertRaises(ValidationError):
            validate_input("hello world", max_length=5)

    def test_allowed_values(self):
        validate_input("red", allowed_values={"red", "green", "blue"})

        with self.assertRaises(ValidationError):
            validate_input("yellow", allowed_values={"red", "green", "blue"})

    def test_custom_validator(self):
        validate_input(10, custom_validator=lambda x: x % 2 == 0)

        with self.assertRaises(ValidationError):
            validate_input(11, custom_validator=lambda x: x % 2 == 0)

    def test_combined_validations(self):
        validate_input(
            42,
            expected_type=int,
            min_value=0,
            max_value=100,
            custom_validator=lambda x: x % 2 == 0,
            param_name="age",
        )

    def test_error_context(self):
        with self.assertRaises(ValidationError) as ctx:
            validate_input("bad", expected_type=int, param_name="my_param")
        self.assertIn("my_param", str(ctx.exception))
        self.assertIn("my_param", ctx.exception.context["param"])


class TestStrictContext(unittest.TestCase):
    """Tests for the strict_context context manager."""

    def setUp(self):
        reset_audit_trail()

    def test_successful_context(self):
        with strict_context("test_op"):
            x = 1 + 1

        trail = get_audit_trail()
        records = trail.get_records()
        self.assertEqual(len(records), 1)
        self.assertEqual(records[0].status, ExecutionStatus.SUCCESS)
        self.assertIn("context:test_op", records[0].function_name)

    def test_failed_context(self):
        with self.assertRaises(ValueError):
            with strict_context("failing_op"):
                raise ValueError("test error")

        trail = get_audit_trail()
        records = trail.get_records()
        self.assertEqual(len(records), 1)
        self.assertEqual(records[0].status, ExecutionStatus.FAILED)

    def test_context_without_audit(self):
        with strict_context("silent_op", audit=False):
            pass

        trail = get_audit_trail()
        records = trail.get_records()
        self.assertEqual(len(records), 0)


class TestAllowedExceptions(unittest.TestCase):
    """Tests for allowed exception propagation."""

    def test_allowed_exception_propagates_directly(self):
        @strict(
            enforce_types=False,
            allowed_exceptions={ValueError},
            audit=False,
        )
        def raises_value_error():
            raise ValueError("allowed")

        with self.assertRaises(ValueError) as ctx:
            raises_value_error()
        self.assertEqual(str(ctx.exception), "allowed")

    def test_unallowed_exception_wraps(self):
        @strict(
            enforce_types=False,
            allowed_exceptions={ValueError},
            audit=False,
        )
        def raises_runtime_error():
            raise RuntimeError("not allowed")

        with self.assertRaises(StrictExecutionError):
            raises_runtime_error()


class TestOnFailureCallback(unittest.TestCase):
    """Tests for the on_failure callback."""

    def test_callback_invoked_on_failure(self):
        callback = MagicMock()

        @strict(
            enforce_types=False,
            on_failure=callback,
            audit=False,
        )
        def failing():
            raise RuntimeError("fail")

        with self.assertRaises(StrictExecutionError):
            failing()

        callback.assert_called_once()
        self.assertIsInstance(callback.call_args[0][0], RuntimeError)


class TestStrictValidateConvenience(unittest.TestCase):
    """Tests for the strict_validate convenience decorator."""

    def test_precondition_with_convenience(self):
        @strict_validate(preconditions=[lambda x: x > 0])
        def positive(x):
            return x

        self.assertEqual(positive(5), 5)

        with self.assertRaises(PreconditionError):
            positive(-1)

    def test_postcondition_with_convenience(self):
        @strict_validate(postconditions=[lambda r: r is not None])
        def not_none(x):
            return x

        self.assertEqual(not_none(1), 1)

        with self.assertRaises(PostconditionError):
            not_none(None)


class TestDecoratorMetadata(unittest.TestCase):
    """Tests that decorated functions preserve metadata."""

    def test_preserves_function_name(self):
        @strict(enforce_types=False, audit=False)
        def my_func():
            """My docstring."""
            return 1

        self.assertEqual(my_func.__name__, "my_func")
        self.assertEqual(my_func.__doc__, "My docstring.")

    def test_strict_config_attached(self):
        @strict(
            enforce_types=True,
            retries=3,
            timeout_seconds=10,
            circuit_breaker=True,
            audit=False,
        )
        def configured():
            return 1

        config = configured._strict_config
        self.assertTrue(config["enforce_types"])
        self.assertEqual(config["retries"], 3)
        self.assertEqual(config["timeout_seconds"], 10)
        self.assertTrue(config["circuit_breaker"])


class TestExceptionHierarchy(unittest.TestCase):
    """Tests for the exception class hierarchy."""

    def test_all_inherit_from_base(self):
        exceptions = [
            ValidationError,
            TypeEnforcementError,
            PreconditionError,
            PostconditionError,
            TimeoutExecutionError,
            RetryExhaustedError,
            CircuitBreakerOpenError,
        ]
        for exc_class in exceptions:
            self.assertTrue(issubclass(exc_class, StrictExecutionError))

    def test_exception_has_context(self):
        exc = ValidationError("test", context={"key": "value"})
        self.assertEqual(exc.context["key"], "value")
        self.assertIsNotNone(exc.timestamp)

    def test_exception_default_context(self):
        exc = StrictExecutionError("test")
        self.assertEqual(exc.context, {})


class TestExecutionRecord(unittest.TestCase):
    """Tests for the ExecutionRecord dataclass."""

    def test_record_is_immutable(self):
        from datetime import datetime, timezone

        record = ExecutionRecord(
            function_name="test",
            status=ExecutionStatus.SUCCESS,
            start_time=datetime.now(timezone.utc),
            end_time=datetime.now(timezone.utc),
            duration_ms=1.0,
            args=(1, 2),
            kwargs={"key": "value"},
            result=42,
        )

        with self.assertRaises(AttributeError):
            record.function_name = "modified"  # type: ignore


class TestEdgeCases(unittest.TestCase):
    """Tests for edge cases and boundary conditions."""

    def test_no_args_function(self):
        @strict(enforce_types=True, audit=False)
        def no_args() -> str:
            return "hello"

        self.assertEqual(no_args(), "hello")

    def test_kwargs_only(self):
        @strict(enforce_types=True, audit=False)
        def kw_only(*, name: str, age: int) -> str:
            return f"{name}: {age}"

        self.assertEqual(kw_only(name="Alice", age=30), "Alice: 30")

        with self.assertRaises(TypeEnforcementError):
            kw_only(name=123, age=30)  # type: ignore

    def test_default_parameters(self):
        @strict(enforce_types=True, audit=False)
        def with_defaults(x: int, y: int = 10) -> int:
            return x + y

        self.assertEqual(with_defaults(5), 15)
        self.assertEqual(with_defaults(5, 20), 25)

    def test_empty_preconditions_list(self):
        @strict(enforce_types=False, preconditions=[], audit=False)
        def func(x):
            return x

        self.assertEqual(func(42), 42)

    def test_zero_retries(self):
        @strict(enforce_types=False, retries=0, audit=False)
        def single_attempt():
            raise RuntimeError("fail")

        with self.assertRaises(StrictExecutionError):
            single_attempt()


if __name__ == "__main__":
    unittest.main()
