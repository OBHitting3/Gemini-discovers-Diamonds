# Retry and Resilience Playbook

Content Shield includes three resilience primitives: **RetryPolicy**, **CircuitBreaker**, and **DeadLetterQueue**.

## RetryPolicy

Wraps [tenacity](https://tenacity.readthedocs.io/) with a simplified interface.

```python
from content_shield.resilience.retry import RetryPolicy

policy = RetryPolicy(
    max_attempts=3,
    backoff="exponential",   # "exponential", "fixed", or "none"
    backoff_base=1,
    backoff_max=60,
    retryable_exceptions=(TimeoutError, ConnectionError),
)
```

### As a decorator

```python
@policy
async def call_external_api():
    ...
```

### As a context manager

```python
for attempt in policy.context():
    with attempt:
        do_something_flaky()
```

## CircuitBreaker

Prevents cascading failures by stopping calls to a failing dependency.

```python
from content_shield.resilience.circuit_breaker import CircuitBreaker

breaker = CircuitBreaker(
    failure_threshold=5,
    recovery_timeout=30.0,
    name="gemini-api",
)
```

States: **CLOSED** (normal) -> **OPEN** (rejecting) -> **HALF_OPEN** (probing).

```python
@breaker
def call_gemini():
    ...
```

Handle open circuits:

```python
from content_shield.resilience.circuit_breaker import CircuitBreakerOpen

try:
    call_gemini()
except CircuitBreakerOpen:
    use_fallback()
```

## DeadLetterQueue

Captures failed events for later inspection or replay.

```python
from content_shield.resilience.dlq import DeadLetterQueue

dlq = DeadLetterQueue(persist_path="dlq.json", max_size=1000)

try:
    process(event)
except Exception as exc:
    dlq.enqueue(event, exc, metadata={"source": "webhook"})
```

Replay failed items:

```python
result = dlq.replay(handler=process, max_items=10)
print(result)  # {"succeeded": 8, "failed": 2, "errors": [...]}
```

## Recommended Defaults

| Setting | Default | Notes |
|---------|---------|-------|
| Retry attempts | 3 | Covers transient network blips |
| Backoff strategy | exponential | Avoids thundering herd |
| Circuit breaker threshold | 5 | Opens after 5 consecutive failures |
| Recovery timeout | 60 s | Time before probing resumes |
| DLQ max size | 1000 | Prevents unbounded memory growth |
