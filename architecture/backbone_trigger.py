#!/usr/bin/env python3
"""
Backbone Trigger — Replaces the Make.com Ghost
================================================

PROBLEM (identified by 4-LLM audit):
    The original architecture had Make.com as the glue between Airtable
    (source of truth) and the app. The MCP-only rewrite deleted Make.com
    but never replaced it. backbone-broadcast.json describes a workflow
    that has no trigger mechanism, no automation layer, and no fallback.
    It's an architectural intent document, not a functioning component.

SOLUTION:
    A lightweight Python-native trigger system that:
    1. Polls Airtable for changes (or receives webhooks)
    2. Dispatches events to registered handlers
    3. Broadcasts state changes to all connected services
    4. Replaces Make.com with zero external dependencies

    This is NOT a generic workflow engine. It does exactly one thing:
    detect changes in the source of truth and propagate them.

Usage:
    trigger = BackboneTrigger(
        airtable_token="pat...",
        base_id="appXXXXXX",
    )
    trigger.register_handler("config_changed", sync_to_supabase)
    trigger.register_handler("config_changed", invalidate_agent_cache)
    trigger.start_polling(interval_seconds=30)
"""

import hashlib
import json
import logging
import os
import signal
import sys
import threading
import time
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any, Callable, Dict, List, Optional, Set
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

logger = logging.getLogger("backbone_trigger")

# ---------------------------------------------------------------------------
# Data Classes
# ---------------------------------------------------------------------------


@dataclass
class AirtableRecord:
    """A single Airtable record."""

    id: str
    fields: Dict[str, Any]
    created_time: str


@dataclass
class ChangeEvent:
    """An event triggered by a change in the source of truth."""

    event_type: str
    table: str
    record_id: Optional[str]
    old_hash: Optional[str]
    new_hash: str
    payload: Dict[str, Any]
    timestamp: str = field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat()
    )

    def __str__(self) -> str:
        return f"[{self.event_type}] {self.table}/{self.record_id} at {self.timestamp}"


@dataclass
class HandlerResult:
    """Result of a handler execution."""

    handler_name: str
    success: bool
    elapsed_ms: float
    error: Optional[str] = None


@dataclass
class PollCycleReport:
    """Report from a single polling cycle."""

    cycle_number: int
    tables_checked: int
    changes_detected: int
    handlers_executed: int
    handler_results: List[HandlerResult] = field(default_factory=list)
    elapsed_ms: float = 0.0
    timestamp: str = field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat()
    )


# Type alias for event handlers
EventHandler = Callable[[ChangeEvent], bool]


# ---------------------------------------------------------------------------
# Airtable Client (minimal, no SDK dependency)
# ---------------------------------------------------------------------------


class AirtableClient:
    """
    Minimal Airtable API client using only urllib.
    Handles list records, get record, and webhook registration.
    """

    BASE_URL = "https://api.airtable.com/v0"

    def __init__(self, token: str, base_id: str) -> None:
        self.token = token
        self.base_id = base_id
        self.headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        }

    def list_records(
        self, table: str, fields: Optional[List[str]] = None, max_records: int = 100
    ) -> List[AirtableRecord]:
        """Fetch records from a table."""
        url = f"{self.BASE_URL}/{self.base_id}/{table}?maxRecords={max_records}"
        if fields:
            for f_name in fields:
                url += f"&fields%5B%5D={f_name}"

        req = Request(url, headers=self.headers, method="GET")
        try:
            with urlopen(req, timeout=15) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                return [
                    AirtableRecord(
                        id=r["id"],
                        fields=r.get("fields", {}),
                        created_time=r.get("createdTime", ""),
                    )
                    for r in data.get("records", [])
                ]
        except (HTTPError, URLError) as e:
            logger.error("Airtable list_records failed: %s", e)
            raise

    def get_record(self, table: str, record_id: str) -> AirtableRecord:
        """Fetch a single record."""
        url = f"{self.BASE_URL}/{self.base_id}/{table}/{record_id}"
        req = Request(url, headers=self.headers, method="GET")
        try:
            with urlopen(req, timeout=10) as resp:
                r = json.loads(resp.read().decode("utf-8"))
                return AirtableRecord(
                    id=r["id"],
                    fields=r.get("fields", {}),
                    created_time=r.get("createdTime", ""),
                )
        except (HTTPError, URLError) as e:
            logger.error("Airtable get_record failed: %s", e)
            raise

    def health_check(self) -> bool:
        """Check if Airtable API is reachable and token is valid."""
        url = f"{self.BASE_URL}/{self.base_id}"
        req = Request(url, headers=self.headers, method="GET")
        try:
            with urlopen(req, timeout=10) as resp:
                return resp.status == 200
        except (HTTPError, URLError):
            return False


# ---------------------------------------------------------------------------
# State Tracker
# ---------------------------------------------------------------------------


class StateTracker:
    """
    Tracks the hash of each table's records to detect changes.
    Persists state to disk so changes survive restarts.
    """

    def __init__(self, state_file: str = ".backbone-state.json") -> None:
        self.state_file = state_file
        self._hashes: Dict[str, str] = {}
        self._load()

    def get_hash(self, table: str) -> Optional[str]:
        return self._hashes.get(table)

    def set_hash(self, table: str, hash_value: str) -> None:
        self._hashes[table] = hash_value
        self._save()

    def has_changed(self, table: str, new_hash: str) -> bool:
        old = self._hashes.get(table)
        if old is None:
            return True
        return old != new_hash

    def _load(self) -> None:
        if os.path.exists(self.state_file):
            try:
                with open(self.state_file, "r") as f:
                    self._hashes = json.load(f)
            except (json.JSONDecodeError, OSError):
                self._hashes = {}

    def _save(self) -> None:
        try:
            with open(self.state_file, "w") as f:
                json.dump(self._hashes, f, indent=2)
        except OSError as e:
            logger.error("Failed to save state: %s", e)

    @staticmethod
    def compute_hash(records: List[AirtableRecord]) -> str:
        """Compute a deterministic hash of a set of records."""
        canonical = json.dumps(
            [{"id": r.id, "fields": r.fields} for r in records],
            sort_keys=True,
        )
        return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


# ---------------------------------------------------------------------------
# Backbone Trigger
# ---------------------------------------------------------------------------


class BackboneTrigger:
    """
    The replacement for Make.com.

    Polls Airtable tables for changes, detects modifications using
    content hashing, and dispatches events to registered handlers.
    """

    def __init__(
        self,
        airtable_token: str,
        base_id: str,
        tables: Optional[List[str]] = None,
        state_file: str = ".backbone-state.json",
    ) -> None:
        if not airtable_token:
            raise ValueError("airtable_token is required")
        if not base_id:
            raise ValueError("base_id is required")

        self.client = AirtableClient(airtable_token, base_id)
        self.tables = tables or []
        self.state = StateTracker(state_file)
        self._handlers: Dict[str, List[EventHandler]] = {}
        self._running = False
        self._cycle_count = 0
        self._reports: List[PollCycleReport] = []

    def register_handler(self, event_type: str, handler: EventHandler) -> None:
        """Register a handler for a specific event type."""
        self._handlers.setdefault(event_type, []).append(handler)
        logger.info(
            "Registered handler '%s' for event '%s'",
            getattr(handler, "__name__", str(handler)),
            event_type,
        )

    def register_table(self, table_name: str) -> None:
        """Add a table to the polling list."""
        if table_name not in self.tables:
            self.tables.append(table_name)
            logger.info("Registered table for polling: %s", table_name)

    def poll_once(self) -> PollCycleReport:
        """Execute a single polling cycle."""
        self._cycle_count += 1
        start = time.monotonic()
        report = PollCycleReport(
            cycle_number=self._cycle_count,
            tables_checked=len(self.tables),
            changes_detected=0,
            handlers_executed=0,
        )

        for table in self.tables:
            try:
                records = self.client.list_records(table)
            except Exception as e:
                logger.error("Failed to poll table '%s': %s", table, e)
                continue

            new_hash = self.state.compute_hash(records)

            if self.state.has_changed(table, new_hash):
                old_hash = self.state.get_hash(table)
                event = ChangeEvent(
                    event_type="config_changed",
                    table=table,
                    record_id=None,
                    old_hash=old_hash,
                    new_hash=new_hash,
                    payload={
                        "record_count": len(records),
                        "records": [
                            {"id": r.id, "fields": r.fields} for r in records
                        ],
                    },
                )

                report.changes_detected += 1
                logger.info("Change detected in table '%s'", table)

                # Dispatch to handlers
                handler_results = self._dispatch(event)
                report.handler_results.extend(handler_results)
                report.handlers_executed += len(handler_results)

                # Update state only after handlers succeed
                all_ok = all(hr.success for hr in handler_results)
                if all_ok or not handler_results:
                    self.state.set_hash(table, new_hash)

        report.elapsed_ms = (time.monotonic() - start) * 1000
        self._reports.append(report)
        return report

    def start_polling(self, interval_seconds: int = 30) -> None:
        """
        Start polling in the current thread.
        Blocks until stop() is called or SIGINT/SIGTERM received.
        """
        self._running = True
        logger.info(
            "Starting backbone polling: %d tables, %ds interval",
            len(self.tables),
            interval_seconds,
        )

        # Handle graceful shutdown
        def _signal_handler(sig: int, frame: Any) -> None:
            logger.info("Received signal %d, stopping...", sig)
            self._running = False

        signal.signal(signal.SIGINT, _signal_handler)
        signal.signal(signal.SIGTERM, _signal_handler)

        while self._running:
            try:
                report = self.poll_once()
                if report.changes_detected > 0:
                    logger.info(
                        "Cycle %d: %d changes, %d handlers in %.1fms",
                        report.cycle_number,
                        report.changes_detected,
                        report.handlers_executed,
                        report.elapsed_ms,
                    )
            except Exception as e:
                logger.error("Poll cycle error: %s", e)

            # Sleep in small increments for responsive shutdown
            for _ in range(interval_seconds * 10):
                if not self._running:
                    break
                time.sleep(0.1)

        logger.info("Backbone polling stopped after %d cycles", self._cycle_count)

    def stop(self) -> None:
        """Stop the polling loop."""
        self._running = False

    def _dispatch(self, event: ChangeEvent) -> List[HandlerResult]:
        """Dispatch an event to all registered handlers."""
        results: List[HandlerResult] = []
        handlers = self._handlers.get(event.event_type, [])

        for handler in handlers:
            name = getattr(handler, "__name__", str(handler))
            start = time.monotonic()
            try:
                success = handler(event)
                elapsed = (time.monotonic() - start) * 1000
                results.append(HandlerResult(name, bool(success), elapsed))
                logger.debug(
                    "Handler '%s' completed: success=%s, %.1fms",
                    name,
                    success,
                    elapsed,
                )
            except Exception as e:
                elapsed = (time.monotonic() - start) * 1000
                results.append(HandlerResult(name, False, elapsed, str(e)))
                logger.error("Handler '%s' failed: %s", name, e)

        return results

    @property
    def reports(self) -> List[PollCycleReport]:
        return list(self._reports)


# ---------------------------------------------------------------------------
# Built-in Handlers
# ---------------------------------------------------------------------------


def log_change_handler(event: ChangeEvent) -> bool:
    """Simple handler that logs changes."""
    logger.info(
        "CHANGE: %s in table '%s' — %d records",
        event.event_type,
        event.table,
        event.payload.get("record_count", 0),
    )
    return True


def write_snapshot_handler(event: ChangeEvent) -> bool:
    """Handler that writes the current state to a JSON snapshot file."""
    snapshot_dir = ".backbone-snapshots"
    os.makedirs(snapshot_dir, exist_ok=True)
    ts = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    filename = f"{snapshot_dir}/{event.table}_{ts}.json"
    try:
        with open(filename, "w") as f:
            json.dump(
                {
                    "table": event.table,
                    "timestamp": event.timestamp,
                    "hash": event.new_hash,
                    "records": event.payload.get("records", []),
                },
                f,
                indent=2,
            )
        logger.info("Snapshot written: %s", filename)
        return True
    except OSError as e:
        logger.error("Snapshot write failed: %s", e)
        return False


def webhook_forwarder_factory(webhook_url: str) -> EventHandler:
    """
    Factory that creates a handler forwarding events to an HTTP webhook.
    This is the bridge to any external system (Supabase, custom API, etc.)
    """

    def _forward(event: ChangeEvent) -> bool:
        payload = json.dumps(
            {
                "event_type": event.event_type,
                "table": event.table,
                "record_id": event.record_id,
                "hash": event.new_hash,
                "timestamp": event.timestamp,
                "payload": event.payload,
            }
        ).encode("utf-8")

        req = Request(
            webhook_url,
            data=payload,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        try:
            with urlopen(req, timeout=10) as resp:
                return resp.status in (200, 201, 202, 204)
        except (HTTPError, URLError) as e:
            logger.error("Webhook forward to %s failed: %s", webhook_url, e)
            return False

    _forward.__name__ = f"webhook_forwarder({webhook_url})"
    return _forward


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main() -> int:
    """CLI entry point."""
    import argparse

    parser = argparse.ArgumentParser(
        description="Backbone Trigger — polls Airtable for changes and dispatches events"
    )
    parser.add_argument(
        "--token",
        default=os.environ.get("AIRTABLE_TOKEN", ""),
        help="Airtable personal access token (or set AIRTABLE_TOKEN env var)",
    )
    parser.add_argument(
        "--base-id",
        default=os.environ.get("AIRTABLE_BASE_ID", ""),
        help="Airtable base ID (or set AIRTABLE_BASE_ID env var)",
    )
    parser.add_argument(
        "--tables",
        nargs="+",
        required=True,
        help="Table names to poll",
    )
    parser.add_argument(
        "--interval",
        type=int,
        default=30,
        help="Polling interval in seconds (default: 30)",
    )
    parser.add_argument(
        "--webhook",
        nargs="*",
        help="Webhook URLs to forward events to",
    )
    parser.add_argument(
        "--snapshots",
        action="store_true",
        help="Enable snapshot writing on change",
    )
    parser.add_argument(
        "--once",
        action="store_true",
        help="Run a single poll cycle and exit",
    )

    args = parser.parse_args()

    logging.basicConfig(
        level=logging.INFO,
        format="[%(asctime)s] %(levelname)s: %(message)s",
    )

    if not args.token:
        print(
            "ERROR: --token or AIRTABLE_TOKEN env var required.\n"
            "Get a personal access token from: https://airtable.com/create/tokens",
            file=sys.stderr,
        )
        return 1

    if not args.base_id:
        print(
            "ERROR: --base-id or AIRTABLE_BASE_ID env var required.\n"
            "Find it in your Airtable URL: https://airtable.com/appXXXXXXXX",
            file=sys.stderr,
        )
        return 1

    trigger = BackboneTrigger(
        airtable_token=args.token,
        base_id=args.base_id,
        tables=args.tables,
    )

    # Register built-in handlers
    trigger.register_handler("config_changed", log_change_handler)

    if args.snapshots:
        trigger.register_handler("config_changed", write_snapshot_handler)

    if args.webhook:
        for url in args.webhook:
            trigger.register_handler(
                "config_changed", webhook_forwarder_factory(url)
            )

    if args.once:
        report = trigger.poll_once()
        print(
            f"Cycle {report.cycle_number}: "
            f"{report.changes_detected} changes, "
            f"{report.handlers_executed} handlers in {report.elapsed_ms:.1f}ms"
        )
        return 0

    trigger.start_polling(interval_seconds=args.interval)
    return 0


if __name__ == "__main__":
    sys.exit(main())
