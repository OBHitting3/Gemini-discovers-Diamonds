"""Error classification for resilience strategies.

Categorizes exceptions as transient (retriable), permanent (non-retriable),
or unknown, enabling intelligent retry and circuit-breaker decisions.
"""

from __future__ import annotations

import enum
from typing import Callable, Dict, List, Optional, Type


class ErrorCategory(enum.Enum):
    """Classification categories for exceptions."""

    TRANSIENT = "transient"
    PERMANENT = "permanent"
    UNKNOWN = "unknown"


# Type alias for a rule function: takes an exception, returns a category or None.
ClassificationRule = Callable[[BaseException], Optional[ErrorCategory]]


# Built-in mapping of exception types to categories.
_DEFAULT_RULES: Dict[Type[BaseException], ErrorCategory] = {
    # Transient - network / IO issues that may resolve on retry
    ConnectionError: ErrorCategory.TRANSIENT,
    ConnectionAbortedError: ErrorCategory.TRANSIENT,
    ConnectionRefusedError: ErrorCategory.TRANSIENT,
    ConnectionResetError: ErrorCategory.TRANSIENT,
    TimeoutError: ErrorCategory.TRANSIENT,
    OSError: ErrorCategory.TRANSIENT,
    IOError: ErrorCategory.TRANSIENT,
    BrokenPipeError: ErrorCategory.TRANSIENT,
    InterruptedError: ErrorCategory.TRANSIENT,
    # Permanent - programming / data errors that won't resolve on retry
    ValueError: ErrorCategory.PERMANENT,
    TypeError: ErrorCategory.PERMANENT,
    KeyError: ErrorCategory.PERMANENT,
    IndexError: ErrorCategory.PERMANENT,
    AttributeError: ErrorCategory.PERMANENT,
    ImportError: ErrorCategory.PERMANENT,
    SyntaxError: ErrorCategory.PERMANENT,
    NotImplementedError: ErrorCategory.PERMANENT,
    PermissionError: ErrorCategory.PERMANENT,
    FileNotFoundError: ErrorCategory.PERMANENT,
    UnicodeDecodeError: ErrorCategory.PERMANENT,
    UnicodeEncodeError: ErrorCategory.PERMANENT,
    ArithmeticError: ErrorCategory.PERMANENT,
    ZeroDivisionError: ErrorCategory.PERMANENT,
    OverflowError: ErrorCategory.PERMANENT,
}


class ErrorClassifier:
    """Classifies exceptions into transient, permanent, or unknown categories.

    The classifier checks rules in the following priority order:
    1. Custom callable rules (checked in registration order).
    2. Custom type-based rules (most-specific subclass wins).
    3. Built-in type-based rules (most-specific subclass wins).

    Parameters
    ----------
    include_defaults:
        When *True* (the default), the built-in rules for common stdlib
        exceptions are active.  Set to *False* to start with a blank slate.
    """

    def __init__(self, *, include_defaults: bool = True) -> None:
        self._type_rules: Dict[Type[BaseException], ErrorCategory] = {}
        self._callable_rules: List[ClassificationRule] = []
        self._include_defaults = include_defaults

    # ------------------------------------------------------------------
    # Registration helpers
    # ------------------------------------------------------------------

    def register(
        self,
        exc_type: Type[BaseException],
        category: ErrorCategory,
    ) -> "ErrorClassifier":
        """Register a type-based classification rule.

        Parameters
        ----------
        exc_type:
            The exception class to match (including subclasses).
        category:
            The category to assign when the exception matches.

        Returns
        -------
        ErrorClassifier
            *self*, for fluent chaining.
        """
        self._type_rules[exc_type] = category
        return self

    def register_rule(self, rule: ClassificationRule) -> "ErrorClassifier":
        """Register a custom callable classification rule.

        The callable receives an exception instance and must return an
        ``ErrorCategory`` if it can classify the exception, or ``None``
        to defer to subsequent rules.

        Parameters
        ----------
        rule:
            A callable ``(BaseException) -> Optional[ErrorCategory]``.

        Returns
        -------
        ErrorClassifier
            *self*, for fluent chaining.
        """
        self._callable_rules.append(rule)
        return self

    # ------------------------------------------------------------------
    # Classification
    # ------------------------------------------------------------------

    def classify(self, exc: BaseException) -> ErrorCategory:
        """Classify an exception instance.

        Parameters
        ----------
        exc:
            The exception to classify.

        Returns
        -------
        ErrorCategory
            The determined category.
        """
        # 1. Custom callable rules (first match wins).
        for rule in self._callable_rules:
            result = rule(exc)
            if result is not None:
                return result

        # 2. Custom type-based rules (most-specific first).
        category = self._match_type_rules(exc, self._type_rules)
        if category is not None:
            return category

        # 3. Built-in defaults.
        if self._include_defaults:
            category = self._match_type_rules(exc, _DEFAULT_RULES)
            if category is not None:
                return category

        return ErrorCategory.UNKNOWN

    def is_transient(self, exc: BaseException) -> bool:
        """Return *True* if *exc* is classified as transient."""
        return self.classify(exc) == ErrorCategory.TRANSIENT

    def is_permanent(self, exc: BaseException) -> bool:
        """Return *True* if *exc* is classified as permanent."""
        return self.classify(exc) == ErrorCategory.PERMANENT

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    @staticmethod
    def _match_type_rules(
        exc: BaseException,
        rules: Dict[Type[BaseException], ErrorCategory],
    ) -> Optional[ErrorCategory]:
        """Find the most-specific matching type rule via MRO."""
        exc_type = type(exc)
        best_match: Optional[Type[BaseException]] = None
        for candidate in rules:
            if isinstance(exc, candidate):
                if best_match is None or issubclass(candidate, best_match):
                    best_match = candidate
        if best_match is not None:
            return rules[best_match]
        return None
