"""Tests for ShieldEvent schema model."""

from datetime import datetime, timezone
from uuid import uuid4

import pytest
from pydantic import ValidationError

from content_shield.schema import Severity, ShieldEvent


class TestShieldEventCreation:
    """Tests for creating ShieldEvent instances."""

    def test_create_with_all_fields(self):
        event = ShieldEvent(
            event_id=uuid4(),
            shield_name="toxicity",
            content_id="c-001",
            timestamp=datetime.now(timezone.utc),
            severity=Severity.WARNING,
            passed=False,
            message="Toxic content detected",
            details={"keyword": "bad"},
            metadata={"source": "api"},
        )
        assert event.shield_name == "toxicity"
        assert event.passed is False
        assert event.details == {"keyword": "bad"}

    def test_defaults_for_optional_fields(self):
        event = ShieldEvent(
            event_id=uuid4(),
            shield_name="test",
            content_id="c-002",
            timestamp=datetime.now(timezone.utc),
            severity=Severity.INFO,
            passed=True,
            message="All clear",
        )
        assert event.details == {}
        assert event.metadata is None


class TestShieldEventSerialization:
    """Tests for ShieldEvent serialization."""

    def test_round_trip_dict(self, sample_event):
        data = sample_event.model_dump()
        restored = ShieldEvent.model_validate(data)
        assert restored.event_id == sample_event.event_id
        assert restored.message == sample_event.message

    def test_json_serialization(self, sample_event):
        json_str = sample_event.model_dump_json()
        restored = ShieldEvent.model_validate_json(json_str)
        assert restored.shield_name == sample_event.shield_name


class TestSeverity:
    """Tests for Severity enum values."""

    def test_severity_values(self):
        assert Severity.INFO.value == "info"
        assert Severity.WARNING.value == "warning"
        assert Severity.ERROR.value == "error"
        assert Severity.CRITICAL.value == "critical"

    def test_invalid_severity_rejected(self):
        with pytest.raises(ValidationError):
            ShieldEvent(
                event_id=uuid4(),
                shield_name="test",
                content_id="c-003",
                timestamp=datetime.now(timezone.utc),
                severity="invalid_level",
                passed=True,
                message="bad severity",
            )
