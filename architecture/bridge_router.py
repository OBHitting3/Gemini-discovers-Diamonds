#!/usr/bin/env python3
"""
Bridge Router — Working Config Translation Across 4 Agent Formats
==================================================================

PROBLEM (identified by 4-LLM audit):
    bridge-router-mcp.json claims to translate one unified config into four
    formats. But those formats have fundamentally incompatible constraint
    models:
      - .cursorrules: flat text directives, no token limit enforcement
      - Claude Knowledge Base: chunked/embedded with retrieval semantics
      - ChatGPT system instructions: different token budget
      - Gemini system prompt: different token budget
    A "unified" config that maps cleanly to all four is either so generic
    it's useless, or silently loses format-specific capabilities.

SOLUTION:
    Instead of pretending one config maps to all four, this bridge router:
    1. Defines a canonical schema with ALL capabilities
    2. Uses format-specific adapters that KNOW the constraints of each target
    3. Emits warnings when a capability can't be translated faithfully
    4. Generates a fidelity report showing exactly what was preserved/lost

    The output is four separate, optimized configs — not one generic blob.
    Each adapter understands the token limits, syntax requirements, and
    semantic model of its target format.

Usage:
    router = BridgeRouter()
    router.load_canonical(canonical_config)
    results = router.translate_all()
    for fmt, result in results.items():
        print(f"{fmt}: {result.fidelity_score}% fidelity")
        print(result.output)
"""

import json
import logging
import re
import sys
import textwrap
from dataclasses import dataclass, field
from datetime import datetime, timezone
from enum import Enum, auto
from typing import Any, Callable, Dict, List, Optional, Set, Tuple

logger = logging.getLogger("bridge_router")

# ---------------------------------------------------------------------------
# Constants: Token/character limits per format (as of Feb 2026)
# ---------------------------------------------------------------------------

FORMAT_LIMITS = {
    "cursorrules": {
        "max_chars": 50_000,
        "supports_structured": False,
        "supports_retrieval": False,
        "enforcement": "honor_system",
    },
    "claude_kb": {
        "max_chars": 200_000,
        "supports_structured": True,
        "supports_retrieval": True,
        "enforcement": "context_window",
    },
    "chatgpt_system": {
        "max_chars": 32_000,
        "supports_structured": True,
        "supports_retrieval": False,
        "enforcement": "system_prompt",
    },
    "gemini_system": {
        "max_chars": 32_000,
        "supports_structured": True,
        "supports_retrieval": False,
        "enforcement": "system_instruction",
    },
}


# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------


class TargetFormat(Enum):
    CURSORRULES = "cursorrules"
    CLAUDE_KB = "claude_kb"
    CHATGPT_SYSTEM = "chatgpt_system"
    GEMINI_SYSTEM = "gemini_system"


class FidelityLevel(Enum):
    """How faithfully a directive was translated."""

    EXACT = auto()
    ADAPTED = auto()
    DEGRADED = auto()
    DROPPED = auto()


# ---------------------------------------------------------------------------
# Data Classes
# ---------------------------------------------------------------------------


@dataclass
class Directive:
    """A single architectural directive in canonical form."""

    id: str
    category: str
    text: str
    priority: int = 1  # 1 = critical, 2 = high, 3 = medium, 4 = low
    requires_structured: bool = False
    requires_retrieval: bool = False
    min_chars: int = 0
    tags: Set[str] = field(default_factory=set)

    def char_count(self) -> int:
        return len(self.text)


@dataclass
class CanonicalConfig:
    """
    The single source of truth. Contains ALL directives at full fidelity.
    Format-specific adapters reduce this to what their target supports.
    """

    project_name: str
    version: str
    directives: List[Directive] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)

    def total_chars(self) -> int:
        return sum(d.char_count() for d in self.directives)

    def by_category(self) -> Dict[str, List[Directive]]:
        result: Dict[str, List[Directive]] = {}
        for d in self.directives:
            result.setdefault(d.category, []).append(d)
        return result

    def by_priority(self, max_priority: int = 4) -> List[Directive]:
        return sorted(
            [d for d in self.directives if d.priority <= max_priority],
            key=lambda d: d.priority,
        )


@dataclass
class TranslationEntry:
    """How a single directive was translated."""

    directive_id: str
    fidelity: FidelityLevel
    original_text: str
    translated_text: str
    warning: Optional[str] = None


@dataclass
class TranslationResult:
    """Result of translating canonical config to a target format."""

    target: TargetFormat
    output: str
    entries: List[TranslationEntry] = field(default_factory=list)
    warnings: List[str] = field(default_factory=list)
    char_count: int = 0
    char_limit: int = 0
    generated_at: str = ""

    @property
    def fidelity_score(self) -> float:
        """Percentage of directives preserved at EXACT or ADAPTED level."""
        if not self.entries:
            return 0.0
        good = sum(
            1
            for e in self.entries
            if e.fidelity in (FidelityLevel.EXACT, FidelityLevel.ADAPTED)
        )
        return round((good / len(self.entries)) * 100, 1)

    @property
    def dropped_count(self) -> int:
        return sum(1 for e in self.entries if e.fidelity == FidelityLevel.DROPPED)

    @property
    def degraded_count(self) -> int:
        return sum(1 for e in self.entries if e.fidelity == FidelityLevel.DEGRADED)

    def summary(self) -> str:
        lines = [
            f"--- {self.target.value} ---",
            f"  Fidelity:   {self.fidelity_score}%",
            f"  Characters: {self.char_count}/{self.char_limit}",
            f"  Directives: {len(self.entries)} total, "
            f"{self.dropped_count} dropped, {self.degraded_count} degraded",
        ]
        if self.warnings:
            lines.append(f"  Warnings:")
            for w in self.warnings:
                lines.append(f"    - {w}")
        return "\n".join(lines)


# ---------------------------------------------------------------------------
# Format Adapters
# ---------------------------------------------------------------------------


class CursorRulesAdapter:
    """
    Translates canonical config to .cursorrules format.

    Constraints:
    - Flat text file, no structured data support
    - No retrieval/embedding — the entire file is injected as context
    - No enforcement mechanism beyond "the AI should follow this"
    - Practical limit ~50K chars (varies by model context window)
    """

    TARGET = TargetFormat.CURSORRULES

    def translate(self, config: CanonicalConfig) -> TranslationResult:
        limits = FORMAT_LIMITS["cursorrules"]
        entries: List[TranslationEntry] = []
        warnings: List[str] = []
        sections: List[str] = []

        sections.append(f"# {config.project_name} — Agent Rules")
        sections.append(f"# Version: {config.version}")
        sections.append(f"# Generated: {datetime.now(timezone.utc).isoformat()}")
        sections.append("")

        # Group by category, emit as markdown-like sections
        for category, directives in config.by_category().items():
            sections.append(f"## {category.upper()}")
            sections.append("")

            for d in sorted(directives, key=lambda x: x.priority):
                if d.requires_retrieval:
                    warnings.append(
                        f"Directive '{d.id}' requires retrieval (not supported in .cursorrules). Degraded to flat text."
                    )
                    entry = TranslationEntry(
                        directive_id=d.id,
                        fidelity=FidelityLevel.DEGRADED,
                        original_text=d.text,
                        translated_text=f"- {d.text}",
                        warning="Requires retrieval; flattened",
                    )
                elif d.requires_structured:
                    entry = TranslationEntry(
                        directive_id=d.id,
                        fidelity=FidelityLevel.ADAPTED,
                        original_text=d.text,
                        translated_text=f"- {d.text}",
                        warning="Structured data flattened to bullet",
                    )
                else:
                    entry = TranslationEntry(
                        directive_id=d.id,
                        fidelity=FidelityLevel.EXACT,
                        original_text=d.text,
                        translated_text=f"- {d.text}",
                    )

                sections.append(entry.translated_text)
                entries.append(entry)

            sections.append("")

        output = "\n".join(sections)

        # Truncation check
        if len(output) > limits["max_chars"]:
            warnings.append(
                f"Output exceeds {limits['max_chars']} chars. "
                f"Truncating low-priority directives."
            )
            output, entries = self._truncate(config, limits["max_chars"], entries)

        return TranslationResult(
            target=self.TARGET,
            output=output,
            entries=entries,
            warnings=warnings,
            char_count=len(output),
            char_limit=limits["max_chars"],
            generated_at=datetime.now(timezone.utc).isoformat(),
        )

    def _truncate(
        self,
        config: CanonicalConfig,
        max_chars: int,
        entries: List[TranslationEntry],
    ) -> Tuple[str, List[TranslationEntry]]:
        """Drop lowest-priority directives until we fit."""
        priority_sorted = config.by_priority()
        kept: List[str] = [
            f"# {config.project_name} — Agent Rules (TRUNCATED)",
            "",
        ]
        kept_entries: List[TranslationEntry] = []
        current_len = sum(len(l) + 1 for l in kept)

        for d in priority_sorted:
            line = f"- [{d.category}] {d.text}"
            if current_len + len(line) + 1 > max_chars:
                # Mark remaining as dropped
                for e in entries:
                    if e.directive_id == d.id:
                        e.fidelity = FidelityLevel.DROPPED
                        e.warning = "Dropped due to size limit"
                        kept_entries.append(e)
                continue
            kept.append(line)
            current_len += len(line) + 1
            for e in entries:
                if e.directive_id == d.id:
                    kept_entries.append(e)

        return "\n".join(kept), kept_entries


class ClaudeKBAdapter:
    """
    Translates canonical config to Claude Knowledge Base format.

    Constraints:
    - Supports structured documents (markdown with sections)
    - Supports retrieval semantics (embeddings, chunked search)
    - Large context (~200K chars effective)
    - Each "document" should be a coherent chunk for retrieval
    """

    TARGET = TargetFormat.CLAUDE_KB

    def translate(self, config: CanonicalConfig) -> TranslationResult:
        limits = FORMAT_LIMITS["claude_kb"]
        entries: List[TranslationEntry] = []
        warnings: List[str] = []

        # Claude KB = list of documents, each is a retrievable chunk
        documents: List[Dict[str, Any]] = []

        for category, directives in config.by_category().items():
            doc_content_parts: List[str] = []
            doc_content_parts.append(f"# {category.title()}")
            doc_content_parts.append("")

            for d in sorted(directives, key=lambda x: x.priority):
                priority_label = {1: "CRITICAL", 2: "HIGH", 3: "MEDIUM", 4: "LOW"}.get(
                    d.priority, "MEDIUM"
                )
                doc_content_parts.append(f"## [{priority_label}] {d.id}")
                doc_content_parts.append("")
                doc_content_parts.append(d.text)
                doc_content_parts.append("")

                entries.append(
                    TranslationEntry(
                        directive_id=d.id,
                        fidelity=FidelityLevel.EXACT,
                        original_text=d.text,
                        translated_text=d.text,
                    )
                )

            documents.append(
                {
                    "title": f"{config.project_name} — {category.title()}",
                    "content": "\n".join(doc_content_parts),
                    "metadata": {
                        "category": category,
                        "project": config.project_name,
                        "version": config.version,
                    },
                }
            )

        output = json.dumps(
            {
                "knowledge_base": {
                    "name": f"{config.project_name} Architecture KB",
                    "documents": documents,
                }
            },
            indent=2,
        )

        return TranslationResult(
            target=self.TARGET,
            output=output,
            entries=entries,
            warnings=warnings,
            char_count=len(output),
            char_limit=limits["max_chars"],
            generated_at=datetime.now(timezone.utc).isoformat(),
        )


class ChatGPTSystemAdapter:
    """
    Translates canonical config to ChatGPT system instructions format.

    Constraints:
    - System prompt has ~32K char effective limit
    - No retrieval (everything must fit in the system message)
    - Structured data supported (JSON mode, etc.)
    - Must be concise — every token counts
    """

    TARGET = TargetFormat.CHATGPT_SYSTEM

    def translate(self, config: CanonicalConfig) -> TranslationResult:
        limits = FORMAT_LIMITS["chatgpt_system"]
        entries: List[TranslationEntry] = []
        warnings: List[str] = []
        parts: List[str] = []

        parts.append(f"You are an assistant for the {config.project_name} project.")
        parts.append("")
        parts.append("Follow these directives strictly:")
        parts.append("")

        budget_remaining = limits["max_chars"] - sum(len(p) + 1 for p in parts)

        # Prioritize: include critical/high first, compress medium/low
        for d in config.by_priority():
            if d.requires_retrieval:
                # ChatGPT has no retrieval — summarize
                compressed = self._compress(d.text, max_len=200)
                line = f"- [{d.category}] {compressed}"
                fidelity = FidelityLevel.DEGRADED
                warning = "Retrieval-dependent directive compressed"
            elif d.priority >= 3 and budget_remaining < 500:
                # Low priority and running out of space — drop
                entries.append(
                    TranslationEntry(
                        directive_id=d.id,
                        fidelity=FidelityLevel.DROPPED,
                        original_text=d.text,
                        translated_text="",
                        warning="Dropped: insufficient budget",
                    )
                )
                warnings.append(f"Dropped '{d.id}': insufficient token budget")
                continue
            elif len(d.text) > 500 and budget_remaining < len(d.text) + 50:
                compressed = self._compress(d.text, max_len=200)
                line = f"- [{d.category}] {compressed}"
                fidelity = FidelityLevel.ADAPTED
                warning = "Compressed to fit budget"
            else:
                line = f"- [{d.category}] {d.text}"
                fidelity = FidelityLevel.EXACT
                warning = None

            if len(line) + 1 > budget_remaining:
                entries.append(
                    TranslationEntry(
                        directive_id=d.id,
                        fidelity=FidelityLevel.DROPPED,
                        original_text=d.text,
                        translated_text="",
                        warning="Dropped: exceeded char limit",
                    )
                )
                warnings.append(f"Dropped '{d.id}': exceeded char limit")
                continue

            parts.append(line)
            budget_remaining -= len(line) + 1
            entries.append(
                TranslationEntry(
                    directive_id=d.id,
                    fidelity=fidelity,
                    original_text=d.text,
                    translated_text=line,
                    warning=warning,
                )
            )

        output = "\n".join(parts)

        return TranslationResult(
            target=self.TARGET,
            output=output,
            entries=entries,
            warnings=warnings,
            char_count=len(output),
            char_limit=limits["max_chars"],
            generated_at=datetime.now(timezone.utc).isoformat(),
        )

    @staticmethod
    def _compress(text: str, max_len: int = 200) -> str:
        """Compress text to fit within a character budget."""
        if len(text) <= max_len:
            return text
        # Take first sentence + ellipsis
        sentences = re.split(r"(?<=[.!?])\s+", text)
        result = sentences[0]
        if len(result) > max_len:
            return result[: max_len - 3] + "..."
        for s in sentences[1:]:
            if len(result) + len(s) + 1 > max_len - 3:
                break
            result += " " + s
        return result + "..."


class GeminiSystemAdapter:
    """
    Translates canonical config to Gemini system instruction format.

    Constraints:
    - Similar to ChatGPT: ~32K char system instruction limit
    - No retrieval
    - Supports structured output
    - Gemini tends to follow numbered lists better than bullets
    """

    TARGET = TargetFormat.GEMINI_SYSTEM

    def translate(self, config: CanonicalConfig) -> TranslationResult:
        limits = FORMAT_LIMITS["gemini_system"]
        entries: List[TranslationEntry] = []
        warnings: List[str] = []
        parts: List[str] = []

        parts.append(f"System: You are operating within the {config.project_name} architecture.")
        parts.append(f"Version: {config.version}")
        parts.append("")
        parts.append("DIRECTIVES (numbered by priority, follow in order):")
        parts.append("")

        budget_remaining = limits["max_chars"] - sum(len(p) + 1 for p in parts)
        counter = 1

        for d in config.by_priority():
            if d.requires_retrieval:
                compressed = d.text[:200] + "..." if len(d.text) > 200 else d.text
                line = f"{counter}. [{d.category.upper()}] {compressed}"
                fidelity = FidelityLevel.DEGRADED
                warning = "Retrieval not supported in Gemini system prompt"
            elif len(d.text) + 20 > budget_remaining:
                if d.priority <= 2:
                    compressed = d.text[:150] + "..." if len(d.text) > 150 else d.text
                    line = f"{counter}. [{d.category.upper()}] {compressed}"
                    fidelity = FidelityLevel.ADAPTED
                    warning = "Compressed critical directive to fit"
                else:
                    entries.append(
                        TranslationEntry(
                            directive_id=d.id,
                            fidelity=FidelityLevel.DROPPED,
                            original_text=d.text,
                            translated_text="",
                            warning="Dropped: budget exhausted",
                        )
                    )
                    warnings.append(f"Dropped '{d.id}': budget exhausted")
                    continue
            else:
                line = f"{counter}. [{d.category.upper()}] {d.text}"
                fidelity = FidelityLevel.EXACT
                warning = None

            parts.append(line)
            budget_remaining -= len(line) + 1
            counter += 1

            entries.append(
                TranslationEntry(
                    directive_id=d.id,
                    fidelity=fidelity,
                    original_text=d.text,
                    translated_text=line,
                    warning=warning,
                )
            )

        output = "\n".join(parts)

        return TranslationResult(
            target=self.TARGET,
            output=output,
            entries=entries,
            warnings=warnings,
            char_count=len(output),
            char_limit=limits["max_chars"],
            generated_at=datetime.now(timezone.utc).isoformat(),
        )


# ---------------------------------------------------------------------------
# Bridge Router
# ---------------------------------------------------------------------------


class BridgeRouter:
    """
    Translates a canonical config into all four agent formats,
    tracking fidelity loss at every step.
    """

    def __init__(self) -> None:
        self._adapters = {
            TargetFormat.CURSORRULES: CursorRulesAdapter(),
            TargetFormat.CLAUDE_KB: ClaudeKBAdapter(),
            TargetFormat.CHATGPT_SYSTEM: ChatGPTSystemAdapter(),
            TargetFormat.GEMINI_SYSTEM: GeminiSystemAdapter(),
        }
        self._config: Optional[CanonicalConfig] = None

    def load_canonical(self, config: CanonicalConfig) -> None:
        """Load the canonical configuration."""
        self._config = config

    def load_from_dict(self, data: Dict[str, Any]) -> None:
        """Load canonical config from a dictionary (e.g., parsed JSON)."""
        directives = []
        for d in data.get("directives", []):
            directives.append(
                Directive(
                    id=d["id"],
                    category=d.get("category", "general"),
                    text=d["text"],
                    priority=d.get("priority", 2),
                    requires_structured=d.get("requires_structured", False),
                    requires_retrieval=d.get("requires_retrieval", False),
                    tags=set(d.get("tags", [])),
                )
            )
        self._config = CanonicalConfig(
            project_name=data.get("project_name", "Unknown"),
            version=data.get("version", "0.0.0"),
            directives=directives,
            metadata=data.get("metadata", {}),
        )

    def translate(self, target: TargetFormat) -> TranslationResult:
        """Translate to a specific target format."""
        if not self._config:
            raise RuntimeError("No canonical config loaded. Call load_canonical() first.")
        adapter = self._adapters[target]
        return adapter.translate(self._config)

    def translate_all(self) -> Dict[TargetFormat, TranslationResult]:
        """Translate to all four formats."""
        if not self._config:
            raise RuntimeError("No canonical config loaded.")
        results = {}
        for target, adapter in self._adapters.items():
            results[target] = adapter.translate(self._config)
        return results

    def fidelity_report(self) -> str:
        """Generate a fidelity report across all formats."""
        results = self.translate_all()

        lines = [
            "=" * 70,
            "BRIDGE ROUTER FIDELITY REPORT",
            "=" * 70,
            f"  Project: {self._config.project_name}",
            f"  Version: {self._config.version}",
            f"  Total Directives: {len(self._config.directives)}",
            f"  Total Chars (canonical): {self._config.total_chars()}",
            "-" * 70,
        ]

        for target, result in results.items():
            lines.append(result.summary())
            lines.append("")

        # Cross-format comparison
        lines.append("-" * 70)
        lines.append("CROSS-FORMAT FIDELITY MATRIX:")
        lines.append("")
        header = f"  {'Directive ID':<30} {'Cursor':>8} {'Claude':>8} {'GPT':>8} {'Gemini':>8}"
        lines.append(header)
        lines.append("  " + "-" * 66)

        directive_ids = [d.id for d in self._config.directives]
        for did in directive_ids:
            row = f"  {did:<30}"
            for target in TargetFormat:
                entry = next(
                    (e for e in results[target].entries if e.directive_id == did),
                    None,
                )
                if entry:
                    symbol = {
                        FidelityLevel.EXACT: "EXACT",
                        FidelityLevel.ADAPTED: "ADAPT",
                        FidelityLevel.DEGRADED: "DEGRD",
                        FidelityLevel.DROPPED: "DROP",
                    }[entry.fidelity]
                else:
                    symbol = "N/A"
                row += f" {symbol:>8}"
            lines.append(row)

        lines.append("")
        lines.append("=" * 70)
        return "\n".join(lines)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main() -> int:
    """CLI entry point."""
    import argparse

    parser = argparse.ArgumentParser(
        description="Translate canonical config to all agent formats with fidelity tracking"
    )
    parser.add_argument(
        "--config",
        required=True,
        help="Path to canonical config JSON file",
    )
    parser.add_argument(
        "--target",
        choices=["cursorrules", "claude_kb", "chatgpt_system", "gemini_system", "all"],
        default="all",
        help="Target format (default: all)",
    )
    parser.add_argument(
        "--output-dir",
        default=".",
        help="Directory to write output files",
    )
    parser.add_argument(
        "--report",
        action="store_true",
        help="Print fidelity report",
    )

    args = parser.parse_args()

    with open(args.config, "r") as f:
        data = json.load(f)

    router = BridgeRouter()
    router.load_from_dict(data)

    if args.report:
        print(router.fidelity_report())
        return 0

    if args.target == "all":
        results = router.translate_all()
        for target, result in results.items():
            ext = {
                TargetFormat.CURSORRULES: ".cursorrules",
                TargetFormat.CLAUDE_KB: ".claude-kb.json",
                TargetFormat.CHATGPT_SYSTEM: ".chatgpt-system.txt",
                TargetFormat.GEMINI_SYSTEM: ".gemini-system.txt",
            }[target]
            outpath = f"{args.output_dir}/{data.get('project_name', 'config')}{ext}"
            with open(outpath, "w") as f:
                f.write(result.output)
            print(f"Wrote {outpath} ({result.fidelity_score}% fidelity)")
    else:
        target = TargetFormat(args.target)
        result = router.translate(target)
        print(result.output)

    return 0


if __name__ == "__main__":
    sys.exit(main())
