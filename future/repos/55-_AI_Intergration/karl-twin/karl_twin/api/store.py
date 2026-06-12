"""In-process action and clarify queue.

The single source of truth is the SQLite event log + LangGraph PostgresSaver
checkpoints; this in-memory store is the hot working set the API exposes
to the approval UI. Worker reads `approved` envelopes here, dispatches,
then writes the executed_at back via update_status().

Thread-safe; the FastAPI app and worker thread share one instance per
process. (Worker runs as a separate process in production; cross-process
coordination is via the Postgres checkpoint + a `runs.pending_actions` row
written by the API. For step 8/10 the in-memory store is the read model.)
"""

from __future__ import annotations

import threading
from collections import OrderedDict
from datetime import datetime, timezone
from typing import Iterable, Optional

from karl_twin.actions.envelope import (
    ActionEnvelope,
    ActionStatus,
    ClarifyQuestion,
)


class ActionStore:
    def __init__(self) -> None:
        self._lock = threading.RLock()
        self._actions: "OrderedDict[str, ActionEnvelope]" = OrderedDict()
        self._clarify: "OrderedDict[str, ClarifyQuestion]" = OrderedDict()

    # -------- actions --------

    def add(self, env: ActionEnvelope) -> ActionEnvelope:
        with self._lock:
            self._actions[env.action_id] = env
            return env

    def get(self, action_id: str) -> Optional[ActionEnvelope]:
        with self._lock:
            return self._actions.get(action_id)

    def update_status(
        self,
        action_id: str,
        status: ActionStatus,
        *,
        revision_note: str | None = None,
        executed_at: datetime | None = None,
        result: dict | None = None,
        error: str | None = None,
    ) -> Optional[ActionEnvelope]:
        with self._lock:
            env = self._actions.get(action_id)
            if env is None:
                return None
            env.status = status
            if revision_note is not None:
                env.revision_note = revision_note
            if executed_at is not None:
                env.executed_at = executed_at
            if result is not None:
                env.result = result
            if error is not None:
                env.error = error
            return env

    def pending(self) -> list[ActionEnvelope]:
        """Envelopes awaiting human action: status=proposed and not expired."""
        with self._lock:
            out: list[ActionEnvelope] = []
            for env in self._actions.values():
                if env.status == ActionStatus.PROPOSED and not env.is_expired():
                    out.append(env)
            return out

    def approved_unexecuted(self) -> list[ActionEnvelope]:
        """Worker dispatch queue. Invariant #3: must check executed_at is null."""
        with self._lock:
            out: list[ActionEnvelope] = []
            for env in self._actions.values():
                if env.status == ActionStatus.APPROVED and env.executed_at is None:
                    out.append(env)
            return out

    def all(self) -> list[ActionEnvelope]:
        with self._lock:
            return list(self._actions.values())

    # -------- clarify --------

    def add_clarify(self, q: ClarifyQuestion) -> ClarifyQuestion:
        with self._lock:
            self._clarify[q.run_id] = q
            return q

    def pending_clarify(self) -> list[ClarifyQuestion]:
        with self._lock:
            return [q for q in self._clarify.values() if not q.answered]

    def answer_clarify(self, run_id: str, answer: str) -> Optional[ClarifyQuestion]:
        with self._lock:
            q = self._clarify.get(run_id)
            if q is None:
                return None
            q.answered = True
            q.answer = answer
            return q


# module-level singleton, attached to the FastAPI app
STORE = ActionStore()
