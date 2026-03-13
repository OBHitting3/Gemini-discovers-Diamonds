"""Tests for ErrorClassifier."""

import pytest

from content_shield.resilience.error_classifier import ErrorCategory, ErrorClassifier


class TestErrorClassifier:
    """Tests for classifying exceptions."""

    def test_transient_error_classified(self):
        classifier = ErrorClassifier()
        assert classifier.classify(ConnectionError("timeout")) == ErrorCategory.TRANSIENT

    def test_permanent_error_classified(self):
        classifier = ErrorClassifier()
        assert classifier.classify(ValueError("bad value")) == ErrorCategory.PERMANENT

    def test_unknown_error_classified(self):
        classifier = ErrorClassifier()

        class CustomError(BaseException):
            pass

        assert classifier.classify(CustomError()) == ErrorCategory.UNKNOWN

    def test_is_transient_helper(self):
        classifier = ErrorClassifier()
        assert classifier.is_transient(TimeoutError("timed out")) is True
        assert classifier.is_transient(ValueError("nope")) is False

    def test_is_permanent_helper(self):
        classifier = ErrorClassifier()
        assert classifier.is_permanent(TypeError("wrong type")) is True
        assert classifier.is_permanent(ConnectionError("down")) is False


class TestErrorClassifierCustomRules:
    """Tests for custom classification rules."""

    def test_register_custom_type_rule(self):
        classifier = ErrorClassifier()

        class MyTransientError(Exception):
            pass

        classifier.register(MyTransientError, ErrorCategory.TRANSIENT)
        assert classifier.classify(MyTransientError()) == ErrorCategory.TRANSIENT

    def test_register_callable_rule(self):
        classifier = ErrorClassifier()

        def custom_rule(exc):
            if "retry" in str(exc).lower():
                return ErrorCategory.TRANSIENT
            return None

        classifier.register_rule(custom_rule)
        assert classifier.classify(Exception("please retry")) == ErrorCategory.TRANSIENT
        assert classifier.classify(Exception("fatal")) != ErrorCategory.TRANSIENT

    def test_no_defaults(self):
        classifier = ErrorClassifier(include_defaults=False)
        assert classifier.classify(ValueError("test")) == ErrorCategory.UNKNOWN
