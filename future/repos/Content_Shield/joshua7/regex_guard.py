"""Regex execution guard — limits match time to prevent ReDoS."""

from __future__ import annotations

import logging
import re
import signal
import threading

logger = logging.getLogger(__name__)

_REGEX_TIMEOUT_SECONDS = 2


def _is_main_thread() -> bool:
    return threading.current_thread() is threading.main_thread()


def safe_finditer(
    pattern: re.Pattern[str],
    text: str,
    *,
    timeout: int = _REGEX_TIMEOUT_SECONDS,
) -> list[re.Match[str]]:
    """Run ``pattern.finditer(text)`` with a wall-clock timeout.

    Returns a (possibly empty) list of matches. If the regex exceeds
    *timeout* seconds the operation is aborted and an empty list is
    returned — the caller should treat this as a failed-open condition
    and log accordingly.

    On platforms/threads where ``signal.alarm`` is unavailable we fall
    back to an unguarded call (better to run than to silently skip).
    """
    if not _is_main_thread():
        return list(pattern.finditer(text))

    try:
        old_handler = signal.getsignal(signal.SIGALRM)

        def _alarm_handler(signum: int, frame: object) -> None:
            raise TimeoutError

        signal.signal(signal.SIGALRM, _alarm_handler)
        signal.alarm(timeout)
        try:
            matches = list(pattern.finditer(text))
        finally:
            signal.alarm(0)
            signal.signal(signal.SIGALRM, old_handler)
        return matches
    except TimeoutError:
        logger.warning(
            "Regex timed out after %ds on pattern %s (text length %d)",
            timeout,
            pattern.pattern[:80],
            len(text),
        )
        return []
    except (AttributeError, OSError):
        return list(pattern.finditer(text))
