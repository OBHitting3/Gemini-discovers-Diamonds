# Gemini-discovers-Diamonds

## Strict Execution Mechanism

A robust Python execution framework that enforces strict validation, type checking, error handling, and audit logging for function execution.

### Features

- **Type Enforcement** - Decorator-based strict type hint checking for arguments and return values
- **Pre/Post Conditions** - Validate invariants before and after function execution
- **Retry with Backoff** - Automatic retry with configurable exponential backoff
- **Timeout Enforcement** - SIGALRM-based execution time limits
- **Audit Trail** - Comprehensive, queryable log of all execution records with statistics
- **Circuit Breaker** - Fault tolerance pattern that stops calling failing functions
- **Input Validation** - Standalone utility for validating values against constraints
- **Execution Context** - Context manager for strict execution of code blocks

### Quick Start

```python
from strict_execution import strict, validate_input, strict_context

# Full strict enforcement
@strict(
    enforce_types=True,
    retries=3,
    retry_delay=1.0,
    timeout_seconds=30,
    preconditions=[lambda items: len(items) > 0],
    postconditions=[lambda result: result >= 0],
)
def process_data(items: list) -> int:
    return sum(items)

# Input validation
validate_input(42, expected_type=int, min_value=0, max_value=100)

# Context manager
with strict_context("heavy_operation", timeout_seconds=60):
    result = expensive_computation()
```

### Convenience Decorators

```python
from strict_execution import strict_types, strict_retry, strict_timeout, strict_validate

@strict_types
def add(a: int, b: int) -> int:
    return a + b

@strict_retry(retries=3, delay=1.0, backoff=2.0)
def fetch_data(url: str):
    ...

@strict_timeout(seconds=10)
def quick_task():
    ...

@strict_validate(
    preconditions=[lambda x: x > 0],
    postconditions=[lambda r: r is not None],
)
def safe_operation(x):
    ...
```

### Running Tests

```bash
python3 -m unittest test_strict_execution -v
```
