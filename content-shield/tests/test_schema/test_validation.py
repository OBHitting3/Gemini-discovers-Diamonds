"""Tests for ValidationResult, Issue, and ValidationSummary schema models."""

import pytest

from content_shield.schema import Issue, Severity, ValidationResult, ValidationSummary


class TestIssueCreation:
    """Tests for creating Issue instances."""

    def test_create_issue(self):
        issue = Issue(
            code="TEST_ISSUE",
            message="Something went wrong",
            severity=Severity.WARNING,
        )
        assert issue.code == "TEST_ISSUE"
        assert issue.span_start is None
        assert issue.span_end is None

    def test_create_issue_with_spans(self):
        issue = Issue(
            code="SPAN_ISSUE",
            message="Bad span",
            severity=Severity.ERROR,
            span_start=10,
            span_end=20,
        )
        assert issue.span_start == 10
        assert issue.span_end == 20


class TestValidationResult:
    """Tests for ValidationResult model."""

    def test_create_passing_result(self):
        result = ValidationResult(
            passed=True,
            shield_name="test_shield",
            score=1.0,
        )
        assert result.passed is True
        assert result.issues == []
        assert result.suggestions == []

    def test_create_failing_result_with_issues(self):
        issue = Issue(
            code="FAIL",
            message="Failed check",
            severity=Severity.ERROR,
        )
        result = ValidationResult(
            passed=False,
            shield_name="test_shield",
            score=0.5,
            issues=[issue],
            suggestions=["Fix the issue"],
        )
        assert result.passed is False
        assert len(result.issues) == 1
        assert len(result.suggestions) == 1

    def test_score_bounds_enforced(self):
        with pytest.raises(Exception):
            ValidationResult(passed=True, shield_name="test", score=1.5)
        with pytest.raises(Exception):
            ValidationResult(passed=True, shield_name="test", score=-0.1)


class TestValidationSummary:
    """Tests for ValidationSummary aggregate properties."""

    def test_all_passed(self):
        results = [
            ValidationResult(passed=True, shield_name="a", score=0.9),
            ValidationResult(passed=True, shield_name="b", score=1.0),
        ]
        summary = ValidationSummary(results=results)
        assert summary.passed is True
        assert summary.total_issues == 0
        assert summary.average_score == pytest.approx(0.95)

    def test_one_failed(self):
        issue = Issue(code="X", message="x", severity=Severity.WARNING)
        results = [
            ValidationResult(passed=True, shield_name="a", score=1.0),
            ValidationResult(passed=False, shield_name="b", score=0.5, issues=[issue]),
        ]
        summary = ValidationSummary(results=results)
        assert summary.passed is False
        assert summary.total_issues == 1
        assert summary.average_score == pytest.approx(0.75)

    def test_empty_results(self):
        summary = ValidationSummary(results=[])
        assert summary.passed is True
        assert summary.total_issues == 0
        assert summary.average_score == 0.0
