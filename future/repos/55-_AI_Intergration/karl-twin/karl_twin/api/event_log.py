"""Append-only SQLite event log. PRAGMA journal_mode=WAL on init (invariant #4)."""

from __future__ import annotations

import json
import sqlite3
import threading
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable

_LOCK = threading.Lock()


def _connect(db_path: Path) -> sqlite3.Connection:
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(db_path), isolation_level=None, check_same_thread=False)
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA synchronous=NORMAL")
    conn.execute("PRAGMA foreign_keys=ON")
    return conn


def _ensure_schema(conn: sqlite3.Connection) -> None:
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS events (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            ts          TEXT NOT NULL,
            run_id      TEXT,
            action_id   TEXT,
            event_type  TEXT NOT NULL,
            node        TEXT,
            latency_ms  INTEGER,
            model       TEXT,
            tokens_in   INTEGER,
            tokens_out  INTEGER,
            confidence  REAL,
            cac_tier    INTEGER,
            cac_hi      REAL,
            cac_mc      REAL,
            cac_ec      REAL,
            payload     TEXT
        )
        """
    )
    # Append-only enforcement: deny UPDATE/DELETE on events.
    conn.execute(
        """
        CREATE TRIGGER IF NOT EXISTS events_no_update
        BEFORE UPDATE ON events
        BEGIN
            SELECT RAISE(ABORT, 'events table is append-only');
        END
        """
    )
    conn.execute(
        """
        CREATE TRIGGER IF NOT EXISTS events_no_delete
        BEFORE DELETE ON events
        BEGIN
            SELECT RAISE(ABORT, 'events table is append-only');
        END
        """
    )
    conn.execute("CREATE INDEX IF NOT EXISTS idx_events_run ON events(run_id)")
    conn.execute("CREATE INDEX IF NOT EXISTS idx_events_action ON events(action_id)")
    conn.execute("CREATE INDEX IF NOT EXISTS idx_events_ts ON events(ts)")


class EventLog:
    def __init__(self, db_path: str | Path):
        self._path = Path(db_path)
        self._conn = _connect(self._path)
        with _LOCK:
            _ensure_schema(self._conn)

    def log(
        self,
        event_type: str,
        *,
        run_id: str | None = None,
        action_id: str | None = None,
        node: str | None = None,
        latency_ms: int | None = None,
        model: str | None = None,
        tokens_in: int | None = None,
        tokens_out: int | None = None,
        confidence: float | None = None,
        cac_tier: int | None = None,
        cac_hi: float | None = None,
        cac_mc: float | None = None,
        cac_ec: float | None = None,
        payload: dict[str, Any] | None = None,
    ) -> None:
        ts = datetime.now(timezone.utc).isoformat()
        with _LOCK:
            self._conn.execute(
                """
                INSERT INTO events (
                    ts, run_id, action_id, event_type, node,
                    latency_ms, model, tokens_in, tokens_out,
                    confidence, cac_tier, cac_hi, cac_mc, cac_ec, payload
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    ts, run_id, action_id, event_type, node,
                    latency_ms, model, tokens_in, tokens_out,
                    confidence, cac_tier, cac_hi, cac_mc, cac_ec,
                    json.dumps(payload) if payload is not None else None,
                ),
            )

    def recent(self, limit: int = 50) -> list[dict[str, Any]]:
        cur = self._conn.execute(
            "SELECT id, ts, run_id, action_id, event_type, node, latency_ms, model, "
            "tokens_in, tokens_out, confidence, cac_tier, cac_hi, cac_mc, cac_ec, payload "
            "FROM events ORDER BY id DESC LIMIT ?",
            (limit,),
        )
        cols = [c[0] for c in cur.description]
        return [dict(zip(cols, row)) for row in cur.fetchall()]

    def for_action(self, action_id: str) -> list[dict[str, Any]]:
        cur = self._conn.execute(
            "SELECT id, ts, event_type, node, payload FROM events WHERE action_id = ? ORDER BY id ASC",
            (action_id,),
        )
        cols = [c[0] for c in cur.description]
        return [dict(zip(cols, row)) for row in cur.fetchall()]

    def close(self) -> None:
        with _LOCK:
            self._conn.close()


def default_path() -> Path:
    """Default event DB path. Honours EVENT_DB_PATH env var if set."""
    import os
    p = os.environ.get("EVENT_DB_PATH")
    if p:
        return Path(p)
    return Path(__file__).resolve().parents[2] / "data" / "events.db"
