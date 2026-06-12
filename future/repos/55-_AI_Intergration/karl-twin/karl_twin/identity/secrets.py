"""Secret loading + .env generation.

Owner-rule: NO master credentials in LLM context, ever. The LLM never reads
this module or the .env file directly; it only references the names.
JIT credential rotation is handled by the worker/sandbox layer when E2B is
invoked — sealed by the worker, never the planner.
"""

from __future__ import annotations

import os
import secrets
import string
from pathlib import Path
from typing import Optional

from dotenv import load_dotenv


def _project_root() -> Path:
    return Path(__file__).resolve().parents[2]


def load() -> None:
    """Load .env from project root if present."""
    env_path = _project_root() / ".env"
    if env_path.exists():
        load_dotenv(env_path, override=False)


def _gen_token(n: int = 48) -> str:
    alphabet = string.ascii_letters + string.digits
    return "".join(secrets.choice(alphabet) for _ in range(n))


def generate_env(force: bool = False) -> Path:
    """Create .env from .env.example, generating QDRANT_API_KEY and
    POSTGRES_PASSWORD. Raises if .env already exists and force=False.
    """
    root = _project_root()
    src = root / ".env.example"
    dst = root / ".env"
    if dst.exists() and not force:
        raise FileExistsError(f"{dst} already exists. Pass force=True to overwrite.")

    qdrant_key = _gen_token(48)
    pg_pass = _gen_token(32)

    text = src.read_text(encoding="utf-8")
    text = text.replace("QDRANT_API_KEY=", f"QDRANT_API_KEY={qdrant_key}")
    text = text.replace("POSTGRES_PASSWORD=", f"POSTGRES_PASSWORD={pg_pass}")
    text = text.replace(
        "POSTGRES_URL=postgresql://karl:CHANGEME@localhost:5432/karltwin",
        f"POSTGRES_URL=postgresql://karl:{pg_pass}@localhost:5432/karltwin",
    )

    dst.write_text(text, encoding="utf-8")
    try:
        os.chmod(dst, 0o600)
    except OSError:
        pass  # Windows ACLs handle this differently; user secured by gitignore.
    return dst


def require(name: str) -> str:
    val = os.environ.get(name, "").strip()
    if not val:
        raise RuntimeError(f"Required env var {name!r} is missing or empty. Edit .env.")
    return val


def optional(name: str, default: Optional[str] = None) -> Optional[str]:
    val = os.environ.get(name)
    return val if val not in (None, "") else default
