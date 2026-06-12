"""Action Envelope unit tests."""

from datetime import datetime, timezone, timedelta

from karl_twin.actions.envelope import (
    ActionEnvelope,
    ActionStatus,
    CACScore,
    RiskLevel,
)


def _envelope(**overrides):
    base = dict(
        action_type="file.write",
        risk_level=RiskLevel.LOW,
        cac_score=CACScore(HI=4.0, MC=2.0, EC=2.0, tier=1),
        reason="write hello world",
        tool="file.write",
        payload_preview="WRITE -> hello.txt",
        payload={"path": "hello.txt", "content": "hello world"},
    )
    base.update(overrides)
    return ActionEnvelope(**base)


def test_envelope_required_fields():
    e = _envelope()
    assert e.action_id
    assert e.timestamp
    assert e.status == ActionStatus.PROPOSED
    assert e.executed_at is None
    assert e.requires_approval is True


def test_envelope_replayable_invariant():
    e = _envelope()
    assert e.is_replayable() is True
    e.executed_at = datetime.now(timezone.utc)
    assert e.is_replayable() is False


def test_envelope_expiry():
    e = _envelope()
    e.timestamp = datetime.now(timezone.utc) - timedelta(seconds=e.expires_in_sec + 10)
    assert e.is_expired() is True


def test_payload_preview_truncation():
    long = "x" * 1000
    e = _envelope(payload_preview=long)
    assert len(e.payload_preview) <= 500
    assert e.payload_preview.endswith("...")
