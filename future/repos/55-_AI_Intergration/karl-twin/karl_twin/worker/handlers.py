"""Tool handlers. Pure functions: receive payload, return result dict."""

from __future__ import annotations

import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def file_write(payload: dict[str, Any]) -> dict[str, Any]:
    """Write content to a file inside OUTPUT_DIR.

    Payload schema:
      { "path": "<relative or absolute>", "content": "<text>", "mode": "w"|"a" }
    Absolute paths must resolve under OUTPUT_DIR; otherwise we raise.
    """
    output_dir = Path(os.environ.get("OUTPUT_DIR", "data/outputs")).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    raw_path = payload.get("path")
    if not raw_path:
        raise ValueError("file.write payload missing 'path'")
    target = Path(raw_path)
    if not target.is_absolute():
        target = output_dir / target
    target = target.resolve()

    # Sandbox enforcement.
    try:
        target.relative_to(output_dir)
    except ValueError:
        raise PermissionError(f"file.write rejected: {target} is outside {output_dir}")

    target.parent.mkdir(parents=True, exist_ok=True)
    mode = payload.get("mode", "w")
    if mode not in ("w", "a"):
        raise ValueError(f"unsupported mode: {mode}")
    target.write_text(payload.get("content", ""), encoding="utf-8") if mode == "w" else \
        target.open("a", encoding="utf-8").write(payload.get("content", ""))

    return {
        "path": str(target),
        "bytes_written": len(payload.get("content", "").encode("utf-8")),
        "written_at": datetime.now(timezone.utc).isoformat(),
    }


def code_execute(payload: dict[str, Any]) -> dict[str, Any]:
    """Run code in an E2B sandbox. JIT secret injection per spec.

    Payload schema:
      { "code": "<python>", "language": "python", "timeout_sec": 60,
        "secret_names": ["NAME1", ...]   # injected from process env, NEVER from LLM context
      }
    """
    from karl_twin.orchestration.e2b_sandbox import run_in_sandbox

    code = payload.get("code")
    if not code:
        raise ValueError("code.execute payload missing 'code'")
    language = payload.get("language", "python")
    if language != "python":
        raise NotImplementedError(f"only python sandbox supported in v0.1, got {language!r}")

    timeout = int(payload.get("timeout_sec", 60))
    secret_names = list(payload.get("secret_names") or [])
    return run_in_sandbox(code=code, timeout_sec=timeout, secret_names=secret_names)


HANDLERS = {
    "file.write": file_write,
    "code.execute": code_execute,
}
