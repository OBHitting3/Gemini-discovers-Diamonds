"""Preprocessor: Unicode NFKC normalization and optional HTML strip. First step in every validator."""

import re
import unicodedata


def normalize(text: str) -> str:
    """Unicode NFKC normalization — defeats homograph/Unicode tricks. PRD-mandated first step."""
    if not text or not isinstance(text, str):
        return ""
    return unicodedata.normalize("NFKC", text.strip())


def strip_html(text: str) -> str:
    """Remove HTML tags for plain-text validation. Simple tag strip."""
    if not text:
        return ""
    return re.sub(r"<[^>]+>", " ", text).strip()
