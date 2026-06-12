"""SQLite event-log invariants: WAL mode + append-only triggers."""

import sqlite3
import tempfile
from pathlib import Path

import pytest

from karl_twin.api.event_log import EventLog


def test_wal_mode_enabled(tmp_path):
    log = EventLog(tmp_path / "events.db")
    log.log("test.event", node="t")
    cur = log._conn.execute("PRAGMA journal_mode")
    mode = cur.fetchone()[0].lower()
    assert mode == "wal"


def test_append_only_blocks_update(tmp_path):
    log = EventLog(tmp_path / "events.db")
    log.log("test.event", node="t")
    with pytest.raises(sqlite3.IntegrityError):
        log._conn.execute("UPDATE events SET event_type='x'")


def test_append_only_blocks_delete(tmp_path):
    log = EventLog(tmp_path / "events.db")
    log.log("test.event", node="t")
    with pytest.raises(sqlite3.IntegrityError):
        log._conn.execute("DELETE FROM events")


def test_event_round_trip(tmp_path):
    log = EventLog(tmp_path / "events.db")
    log.log("a.b", run_id="r1", action_id="a1", node="n", cac_tier=1)
    rows = log.recent()
    assert len(rows) == 1
    assert rows[0]["event_type"] == "a.b"
    assert rows[0]["run_id"] == "r1"
    assert rows[0]["cac_tier"] == 1
