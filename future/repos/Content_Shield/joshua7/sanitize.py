"""Input sanitization utilities for Joshua 7.

All text passes through ``sanitize_input`` before reaching validators,
stripping characters that could be used to bypass detection.
"""

from __future__ import annotations

import re
import unicodedata

_NULL_BYTES = re.compile(r"\x00")

_CONTROL_CHARS = re.compile(
    r"[\x01-\x08\x0b\x0c\x0e-\x1f\x7f]",
)

_ZERO_WIDTH = re.compile(
    "["
    "\u200b"  # zero-width space
    "\u200c"  # zero-width non-joiner
    "\u200d"  # zero-width joiner
    "\u200e"  # left-to-right mark
    "\u200f"  # right-to-left mark
    "\u2060"  # word joiner
    "\ufeff"  # BOM / zero-width no-break space
    "\u00ad"  # soft hyphen
    "]"
)

_HOMOGLYPH_MAP: dict[str, str] = {
    "\u0430": "a",  # Cyrillic а → Latin a
    "\u0435": "e",  # Cyrillic е → Latin e
    "\u043e": "o",  # Cyrillic о → Latin o
    "\u0440": "p",  # Cyrillic р → Latin p
    "\u0441": "c",  # Cyrillic с → Latin c
    "\u0443": "y",  # Cyrillic у → Latin y (visual)
    "\u0456": "i",  # Cyrillic і → Latin i
    "\u0455": "s",  # Cyrillic ѕ → Latin s
    "\u0501": "d",  # Cyrillic ԁ → Latin d
    "\u051b": "q",  # Cyrillic ԛ → Latin q
    "\uff41": "a",  # Fullwidth a
    "\uff42": "b",  # Fullwidth b
    "\uff43": "c",  # Fullwidth c
    "\uff49": "i",  # Fullwidth i
    "\uff4e": "n",  # Fullwidth n
    "\uff4f": "o",  # Fullwidth o
    "\uff52": "r",  # Fullwidth r
    "\uff53": "s",  # Fullwidth s
    "\uff54": "t",  # Fullwidth t
}

_HOMOGLYPH_RE = re.compile("|".join(re.escape(k) for k in _HOMOGLYPH_MAP))


def _replace_homoglyphs(text: str) -> str:
    return _HOMOGLYPH_RE.sub(lambda m: _HOMOGLYPH_MAP[m.group()], text)


def sanitize_input(text: str) -> str:
    """Normalize and clean *text* before validation.

    Steps:
    1. Unicode NFC normalization (canonical decomposition + composition)
    2. Strip null bytes
    3. Strip invisible zero-width characters used for evasion
    4. Strip ASCII control characters (preserving \\n, \\r, \\t)
    5. Replace common homoglyphs with ASCII equivalents
    """
    text = unicodedata.normalize("NFC", text)
    text = _NULL_BYTES.sub("", text)
    text = _ZERO_WIDTH.sub("", text)
    text = _CONTROL_CHARS.sub("", text)
    text = _replace_homoglyphs(text)
    return text
