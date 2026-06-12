"""Admin CLI.

  python -m karl_twin.admin pause           halts worker (leaves API running)
  python -m karl_twin.admin resume          resumes worker
  python -m karl_twin.admin status          queue depth, last events
  python -m karl_twin.admin generate_env    create .env from .env.example
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from karl_twin.api.event_log import EventLog, default_path
from karl_twin.identity import secrets as sec

PAUSE_FLAG = Path(__file__).resolve().parents[2] / "data" / ".secrets" / "worker.paused"


def cmd_pause(_args: argparse.Namespace) -> int:
    PAUSE_FLAG.parent.mkdir(parents=True, exist_ok=True)
    PAUSE_FLAG.write_text("paused", encoding="utf-8")
    print(f"worker paused; flag at {PAUSE_FLAG}")
    return 0


def cmd_resume(_args: argparse.Namespace) -> int:
    if PAUSE_FLAG.exists():
        PAUSE_FLAG.unlink()
        print("worker resumed")
    else:
        print("worker was not paused")
    return 0


def cmd_status(_args: argparse.Namespace) -> int:
    sec.load()
    paused = PAUSE_FLAG.exists()
    events = EventLog(default_path())
    recent = events.recent(limit=20)
    print(f"paused: {paused}")
    print(f"event log: {default_path()}")
    print(f"last {len(recent)} events:")
    for e in recent:
        print(
            f"  {e['ts']} [{e['event_type']:>20}] "
            f"node={e.get('node') or '-':>8} "
            f"action={(e.get('action_id') or '-')[:8]} "
            f"tier={e.get('cac_tier')}"
        )
    return 0


def cmd_generate_env(args: argparse.Namespace) -> int:
    try:
        path = sec.generate_env(force=args.force)
        print(f"wrote {path}")
        print("Edit it to add ANTHROPIC_API_KEY and E2B_API_KEY.")
        return 0
    except FileExistsError as e:
        print(str(e), file=sys.stderr)
        return 1


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="karl_twin.admin")
    sub = parser.add_subparsers(dest="cmd", required=True)
    sub.add_parser("pause").set_defaults(func=cmd_pause)
    sub.add_parser("resume").set_defaults(func=cmd_resume)
    sub.add_parser("status").set_defaults(func=cmd_status)
    g = sub.add_parser("generate_env")
    g.add_argument("--force", action="store_true", help="overwrite existing .env")
    g.set_defaults(func=cmd_generate_env)
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
