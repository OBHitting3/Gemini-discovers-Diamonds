"""E2B Code Interpreter sandbox.

Short session timeouts; sandbox is destroyed after each execution. Secrets
are injected JIT from process env into the sandbox's environment, never
passed through the LLM context (invariant #7).
"""

from __future__ import annotations

import os
from typing import Any


def run_in_sandbox(
    code: str,
    *,
    timeout_sec: int = 60,
    secret_names: list[str] | None = None,
) -> dict[str, Any]:
    api_key = os.environ.get("E2B_API_KEY", "").strip()
    if not api_key:
        raise RuntimeError("E2B_API_KEY missing; cannot run code.execute.")

    # JIT secret pull from process env. The LLM never sees these names'
    # *values*; the planner can only request them by name and the worker
    # injects them at sandbox boot.
    env_payload: dict[str, str] = {}
    for name in (secret_names or []):
        v = os.environ.get(name)
        if v is None:
            raise PermissionError(f"requested secret {name!r} not present in worker env")
        env_payload[name] = v

    from e2b_code_interpreter import Sandbox

    sandbox = Sandbox.create(
        api_key=api_key,
        timeout=max(15, min(int(timeout_sec) + 30, 600)),
        env_vars=env_payload or None,
    )
    try:
        execution = sandbox.run_code(code, timeout=timeout_sec)
        return {
            "stdout": "".join(getattr(execution, "logs", {}).get("stdout", []) or []),
            "stderr": "".join(getattr(execution, "logs", {}).get("stderr", []) or []),
            "results": [
                {"text": getattr(r, "text", None), "type": getattr(r, "type", None)}
                for r in (getattr(execution, "results", []) or [])
            ],
            "error": (str(execution.error) if getattr(execution, "error", None) else None),
            "execution_count": getattr(execution, "execution_count", None),
        }
    finally:
        try:
            sandbox.kill()
        except Exception:
            pass
