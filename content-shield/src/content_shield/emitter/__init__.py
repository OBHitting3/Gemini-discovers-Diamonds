"""Emitter sub-package for content-shield.

Emitters are responsible for delivering :class:`ShieldEvent` instances to
external systems (console, webhooks, Pub/Sub, Slack, etc.).
"""

from .base import BaseEmitter
from .console import ConsoleEmitter
from .slack import SlackEmitter
from .webhook import WebhookEmitter

__all__ = [
    "BaseEmitter",
    "ConsoleEmitter",
    "PubSubEmitter",
    "SlackEmitter",
    "WebhookEmitter",
]


def __getattr__(name: str):  # noqa: ANN001
    """Lazily import PubSubEmitter so the optional google-cloud-pubsub
    dependency is not required at package import time."""
    if name == "PubSubEmitter":
        from .pubsub import PubSubEmitter

        return PubSubEmitter
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")
