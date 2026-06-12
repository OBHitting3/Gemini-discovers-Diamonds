"""Collector module for ingesting content validation events."""

from content_shield.collector.gcf_handler import GCFHandler
from content_shield.collector.local_handler import LocalHandler
from content_shield.collector.storage import EventStorage

__all__ = ["GCFHandler", "LocalHandler", "EventStorage"]
