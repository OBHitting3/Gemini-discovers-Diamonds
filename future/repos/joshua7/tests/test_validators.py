"""Tests for validators. Run: pytest tests/ -v"""

from joshua7.core import run_validation


def test_safe_content_passes():
    r = run_validation("Hello, this is safe professional content.")
    assert r.passed is True
    assert len(r.findings) == 0
    assert str(r) == "PASS"


def test_forbidden_phrase_fails():
    r = run_validation("We guarantee you guaranteed results!")
    assert r.passed is False
    assert len(r.findings) >= 1
    assert any("forbidden_phrases" in f.validator_id for f in r.findings)
    assert str(r) == "FAIL"


def test_pii_later():
    """Placeholder: PII validator not in MVP; add when implemented."""
    pass
