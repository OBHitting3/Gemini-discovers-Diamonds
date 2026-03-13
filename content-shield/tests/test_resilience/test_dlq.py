"""Tests for DeadLetterQueue."""

import pytest

from content_shield.resilience.dlq import DeadLetterQueue, DLQEntry


class TestDLQEnqueueDequeue:
    """Tests for basic enqueue and dequeue operations."""

    def test_enqueue_adds_entry(self):
        dlq = DeadLetterQueue()
        entry = dlq.enqueue({"key": "value"}, RuntimeError("fail"))
        assert isinstance(entry, DLQEntry)
        assert entry.error == "fail"
        assert entry.error_type == "RuntimeError"
        assert dlq.size() == 1

    def test_dequeue_returns_oldest(self):
        dlq = DeadLetterQueue()
        dlq.enqueue("first", ValueError("e1"))
        dlq.enqueue("second", ValueError("e2"))
        entry = dlq.dequeue()
        assert entry.payload == "first"
        assert dlq.size() == 1

    def test_dequeue_empty_returns_none(self):
        dlq = DeadLetterQueue()
        assert dlq.dequeue() is None


class TestDLQMaxSize:
    """Tests for max_size eviction."""

    def test_evicts_oldest_when_full(self):
        dlq = DeadLetterQueue(max_size=2)
        dlq.enqueue("a", RuntimeError("e1"))
        dlq.enqueue("b", RuntimeError("e2"))
        dlq.enqueue("c", RuntimeError("e3"))
        assert dlq.size() == 2
        entry = dlq.dequeue()
        assert entry.payload == "b"


class TestDLQOperations:
    """Tests for peek, clear, and replay."""

    def test_peek_does_not_remove(self):
        dlq = DeadLetterQueue()
        dlq.enqueue("item", RuntimeError("err"))
        peeked = dlq.peek(1)
        assert len(peeked) == 1
        assert dlq.size() == 1

    def test_clear_removes_all(self):
        dlq = DeadLetterQueue()
        dlq.enqueue("a", RuntimeError("e1"))
        dlq.enqueue("b", RuntimeError("e2"))
        removed = dlq.clear()
        assert removed == 2
        assert dlq.size() == 0

    def test_replay_with_successful_handler(self):
        dlq = DeadLetterQueue()
        dlq.enqueue("payload1", RuntimeError("err"))
        results = dlq.replay(handler=lambda p: None)
        assert results["succeeded"] == 1
        assert results["failed"] == 0
        assert dlq.size() == 0
