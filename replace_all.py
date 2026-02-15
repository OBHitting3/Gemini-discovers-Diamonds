#!/usr/bin/env python3
"""
All-Occurrences Replacement Engine
===================================

A strict-execution replacement engine that finds and replaces all occurrences
of patterns across text content and files. Designed for the
Gemini-discovers-Diamonds project with full audit trails, backup management,
and comprehensive reporting.

Features:
    - Literal string and regex-based pattern matching
    - Single-file and recursive directory replacement
    - Dry-run mode for safe previewing
    - Automatic backup creation before modification
    - Detailed replacement reports with line-level granularity
    - Case-sensitive and case-insensitive modes
    - Word-boundary matching support
    - Encoding detection and handling
    - Strict input validation and error handling
    - Comprehensive audit logging

Usage:
    from replace_all import ReplacementEngine

    engine = ReplacementEngine()
    result = engine.replace_in_file("target.txt", "old_text", "new_text")
    print(result.summary())

CLI:
    python replace_all.py --path ./src --find "old" --replace "new" --dry-run
"""

import argparse
import fnmatch
import hashlib
import logging
import os
import re
import shutil
import sys
import time
from dataclasses import dataclass, field
from datetime import datetime, timezone
from enum import Enum, auto
from pathlib import Path
from typing import (
    Any,
    Callable,
    Dict,
    List,
    Optional,
    Pattern,
    Set,
    Tuple,
    Union,
)

# ---------------------------------------------------------------------------
# Logging Configuration
# ---------------------------------------------------------------------------

logger = logging.getLogger("replace_all")
logger.setLevel(logging.DEBUG)

if not logger.handlers:
    handler = logging.StreamHandler()
    handler.setFormatter(
        logging.Formatter(
            "[%(asctime)s] [%(levelname)s] %(name)s: %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S",
        )
    )
    logger.addHandler(handler)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

DEFAULT_ENCODING = "utf-8"
DEFAULT_BACKUP_SUFFIX = ".bak"
MAX_FILE_SIZE_BYTES = 50 * 1024 * 1024  # 50 MB
BINARY_CHECK_BYTES = 8192

# Default file patterns to exclude from processing
DEFAULT_EXCLUDE_PATTERNS = frozenset(
    {
        "*.pyc",
        "*.pyo",
        "__pycache__",
        ".git",
        ".svn",
        ".hg",
        "node_modules",
        ".DS_Store",
        "*.exe",
        "*.dll",
        "*.so",
        "*.dylib",
        "*.bin",
        "*.jpg",
        "*.jpeg",
        "*.png",
        "*.gif",
        "*.bmp",
        "*.ico",
        "*.pdf",
        "*.zip",
        "*.tar",
        "*.gz",
        "*.bz2",
        "*.7z",
        "*.mp3",
        "*.mp4",
        "*.avi",
        "*.mov",
    }
)


# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------


class MatchMode(Enum):
    """Pattern matching mode."""

    LITERAL = auto()
    REGEX = auto()
    WORD_BOUNDARY = auto()


class ReplacementStatus(Enum):
    """Status of a replacement operation."""

    SUCCESS = auto()
    NO_MATCHES = auto()
    SKIPPED = auto()
    ERROR = auto()
    DRY_RUN = auto()


# ---------------------------------------------------------------------------
# Data Classes
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class Occurrence:
    """A single occurrence of a match within a file."""

    line_number: int
    column_start: int
    column_end: int
    original_line: str
    replaced_line: str
    match_text: str

    def __str__(self) -> str:
        return (
            f"Line {self.line_number}, Col {self.column_start}-{self.column_end}: "
            f"'{self.match_text}'"
        )


@dataclass
class FileResult:
    """Result of a replacement operation on a single file."""

    file_path: str
    status: ReplacementStatus
    occurrences: List[Occurrence] = field(default_factory=list)
    error_message: Optional[str] = None
    backup_path: Optional[str] = None
    original_hash: Optional[str] = None
    modified_hash: Optional[str] = None
    encoding: str = DEFAULT_ENCODING
    elapsed_ms: float = 0.0

    @property
    def occurrence_count(self) -> int:
        return len(self.occurrences)

    def summary(self) -> str:
        lines = [f"File: {self.file_path}"]
        lines.append(f"  Status: {self.status.name}")
        lines.append(f"  Occurrences: {self.occurrence_count}")
        if self.backup_path:
            lines.append(f"  Backup: {self.backup_path}")
        if self.error_message:
            lines.append(f"  Error: {self.error_message}")
        lines.append(f"  Elapsed: {self.elapsed_ms:.2f}ms")
        return "\n".join(lines)


@dataclass
class ReplacementReport:
    """Aggregate report for a replacement operation across multiple files."""

    find_pattern: str
    replace_with: str
    match_mode: MatchMode
    case_sensitive: bool
    dry_run: bool
    file_results: List[FileResult] = field(default_factory=list)
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None

    @property
    def total_files_scanned(self) -> int:
        return len(self.file_results)

    @property
    def total_files_modified(self) -> int:
        return sum(
            1
            for r in self.file_results
            if r.status in (ReplacementStatus.SUCCESS, ReplacementStatus.DRY_RUN)
            and r.occurrence_count > 0
        )

    @property
    def total_occurrences(self) -> int:
        return sum(r.occurrence_count for r in self.file_results)

    @property
    def total_errors(self) -> int:
        return sum(1 for r in self.file_results if r.status == ReplacementStatus.ERROR)

    @property
    def elapsed_seconds(self) -> float:
        if self.started_at and self.completed_at:
            return (self.completed_at - self.started_at).total_seconds()
        return 0.0

    def summary(self) -> str:
        lines = [
            "=" * 60,
            "ALL-OCCURRENCES REPLACEMENT REPORT",
            "=" * 60,
            f"  Pattern:        '{self.find_pattern}'",
            f"  Replacement:    '{self.replace_with}'",
            f"  Mode:           {self.match_mode.name}",
            f"  Case Sensitive: {self.case_sensitive}",
            f"  Dry Run:        {self.dry_run}",
            "-" * 60,
            f"  Files Scanned:  {self.total_files_scanned}",
            f"  Files Modified: {self.total_files_modified}",
            f"  Total Matches:  {self.total_occurrences}",
            f"  Errors:         {self.total_errors}",
            f"  Elapsed:        {self.elapsed_seconds:.3f}s",
            "=" * 60,
        ]

        if self.total_errors > 0:
            lines.append("\nERRORS:")
            for fr in self.file_results:
                if fr.status == ReplacementStatus.ERROR:
                    lines.append(f"  {fr.file_path}: {fr.error_message}")

        if self.total_occurrences > 0:
            lines.append("\nMODIFIED FILES:")
            for fr in self.file_results:
                if fr.occurrence_count > 0:
                    lines.append(f"  {fr.file_path} ({fr.occurrence_count} replacements)")
                    for occ in fr.occurrences:
                        lines.append(f"    {occ}")

        return "\n".join(lines)


@dataclass
class ReplaceConfig:
    """Configuration for a replacement operation."""

    find_pattern: str
    replace_with: str
    match_mode: MatchMode = MatchMode.LITERAL
    case_sensitive: bool = True
    dry_run: bool = False
    create_backup: bool = True
    backup_suffix: str = DEFAULT_BACKUP_SUFFIX
    encoding: str = DEFAULT_ENCODING
    max_file_size: int = MAX_FILE_SIZE_BYTES
    include_patterns: Optional[List[str]] = None
    exclude_patterns: Optional[Set[str]] = None
    follow_symlinks: bool = False
    recursive: bool = True

    def __post_init__(self) -> None:
        if self.exclude_patterns is None:
            self.exclude_patterns = set(DEFAULT_EXCLUDE_PATTERNS)
        self._validate()

    def _validate(self) -> None:
        if not self.find_pattern:
            raise ValueError("find_pattern must not be empty")
        if self.find_pattern == self.replace_with:
            raise ValueError("find_pattern and replace_with must be different")
        if self.max_file_size <= 0:
            raise ValueError("max_file_size must be positive")
        if self.match_mode == MatchMode.REGEX:
            try:
                flags = 0 if self.case_sensitive else re.IGNORECASE
                re.compile(self.find_pattern, flags)
            except re.error as e:
                raise ValueError(f"Invalid regex pattern: {e}") from e


# ---------------------------------------------------------------------------
# Utility Functions
# ---------------------------------------------------------------------------


def compute_sha256(content: str) -> str:
    """Compute SHA-256 hash of string content."""
    return hashlib.sha256(content.encode("utf-8")).hexdigest()


def is_binary_file(file_path: str) -> bool:
    """Check if a file appears to be binary by reading its first bytes."""
    try:
        with open(file_path, "rb") as f:
            chunk = f.read(BINARY_CHECK_BYTES)
        # Files with null bytes are likely binary
        if b"\x00" in chunk:
            return True
        # Check for high ratio of non-text bytes
        text_chars = bytearray(
            {7, 8, 9, 10, 12, 13, 27} | set(range(0x20, 0x100)) - {0x7F}
        )
        non_text = sum(1 for byte in chunk if byte not in text_chars)
        return non_text / max(len(chunk), 1) > 0.30
    except (OSError, IOError):
        return True


def should_exclude(path: str, exclude_patterns: Set[str]) -> bool:
    """Check if a path matches any exclusion pattern."""
    name = os.path.basename(path)
    for pattern in exclude_patterns:
        if fnmatch.fnmatch(name, pattern):
            return True
    return False


def should_include(path: str, include_patterns: Optional[List[str]]) -> bool:
    """Check if a path matches inclusion patterns (if specified)."""
    if not include_patterns:
        return True
    name = os.path.basename(path)
    return any(fnmatch.fnmatch(name, p) for p in include_patterns)


# ---------------------------------------------------------------------------
# Core Replacement Engine
# ---------------------------------------------------------------------------


class ReplacementEngine:
    """
    Strict-execution engine for replacing all occurrences of a pattern.

    Provides file-level and directory-level replacement with full audit
    trails, backup management, and comprehensive error handling.
    """

    def __init__(self) -> None:
        self._audit_log: List[Dict[str, Any]] = []

    @property
    def audit_log(self) -> List[Dict[str, Any]]:
        """Return a copy of the audit log."""
        return list(self._audit_log)

    def _log_audit(self, action: str, details: Dict[str, Any]) -> None:
        """Record an audit entry."""
        entry = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "action": action,
            **details,
        }
        self._audit_log.append(entry)
        logger.debug("AUDIT: %s – %s", action, details)

    # ------------------------------------------------------------------
    # Pattern compilation
    # ------------------------------------------------------------------

    @staticmethod
    def _compile_pattern(config: ReplaceConfig) -> Pattern:
        """Compile the search pattern based on configuration."""
        flags = 0 if config.case_sensitive else re.IGNORECASE

        if config.match_mode == MatchMode.REGEX:
            return re.compile(config.find_pattern, flags)
        elif config.match_mode == MatchMode.WORD_BOUNDARY:
            escaped = re.escape(config.find_pattern)
            return re.compile(rf"\b{escaped}\b", flags)
        else:  # LITERAL
            escaped = re.escape(config.find_pattern)
            return re.compile(escaped, flags)

    # ------------------------------------------------------------------
    # Text-level replacement
    # ------------------------------------------------------------------

    def replace_in_text(
        self, text: str, config: ReplaceConfig
    ) -> Tuple[str, List[Occurrence]]:
        """
        Replace all occurrences in a text string.

        Returns:
            Tuple of (modified_text, list_of_occurrences)
        """
        pattern = self._compile_pattern(config)
        occurrences: List[Occurrence] = []
        lines = text.splitlines(keepends=True)

        modified_lines: List[str] = []
        for line_num, line in enumerate(lines, start=1):
            matches = list(pattern.finditer(line))
            if matches:
                new_line = pattern.sub(config.replace_with, line)
                for m in matches:
                    occ = Occurrence(
                        line_number=line_num,
                        column_start=m.start() + 1,
                        column_end=m.end(),
                        original_line=line.rstrip("\n\r"),
                        replaced_line=new_line.rstrip("\n\r"),
                        match_text=m.group(),
                    )
                    occurrences.append(occ)
                modified_lines.append(new_line)
            else:
                modified_lines.append(line)

        return "".join(modified_lines), occurrences

    # ------------------------------------------------------------------
    # File-level replacement
    # ------------------------------------------------------------------

    def replace_in_file(
        self,
        file_path: str,
        config: ReplaceConfig,
    ) -> FileResult:
        """
        Replace all occurrences of the pattern in a single file.

        Args:
            file_path: Path to the target file.
            config: Replacement configuration.

        Returns:
            FileResult with details of the operation.
        """
        start_time = time.monotonic()
        abs_path = os.path.abspath(file_path)

        self._log_audit("file_replace_start", {"file": abs_path, "dry_run": config.dry_run})

        # --- Validation ---
        if not os.path.isfile(abs_path):
            return self._error_result(
                abs_path, f"File not found: {abs_path}", start_time
            )

        file_size = os.path.getsize(abs_path)
        if file_size > config.max_file_size:
            return self._error_result(
                abs_path,
                f"File too large ({file_size} bytes > {config.max_file_size} limit)",
                start_time,
            )

        if is_binary_file(abs_path):
            return FileResult(
                file_path=abs_path,
                status=ReplacementStatus.SKIPPED,
                error_message="Binary file skipped",
                elapsed_ms=self._elapsed_ms(start_time),
            )

        # --- Read ---
        try:
            with open(abs_path, "r", encoding=config.encoding) as f:
                original_content = f.read()
        except UnicodeDecodeError as e:
            return self._error_result(abs_path, f"Encoding error: {e}", start_time)
        except OSError as e:
            return self._error_result(abs_path, f"Read error: {e}", start_time)

        original_hash = compute_sha256(original_content)

        # --- Replace ---
        modified_content, occurrences = self.replace_in_text(original_content, config)

        if not occurrences:
            return FileResult(
                file_path=abs_path,
                status=ReplacementStatus.NO_MATCHES,
                original_hash=original_hash,
                encoding=config.encoding,
                elapsed_ms=self._elapsed_ms(start_time),
            )

        modified_hash = compute_sha256(modified_content)

        # --- Dry run ---
        if config.dry_run:
            result = FileResult(
                file_path=abs_path,
                status=ReplacementStatus.DRY_RUN,
                occurrences=occurrences,
                original_hash=original_hash,
                modified_hash=modified_hash,
                encoding=config.encoding,
                elapsed_ms=self._elapsed_ms(start_time),
            )
            self._log_audit(
                "file_replace_dry_run",
                {"file": abs_path, "occurrences": len(occurrences)},
            )
            return result

        # --- Backup ---
        backup_path = None
        if config.create_backup:
            backup_path = abs_path + config.backup_suffix
            try:
                shutil.copy2(abs_path, backup_path)
                self._log_audit("backup_created", {"original": abs_path, "backup": backup_path})
            except OSError as e:
                return self._error_result(
                    abs_path, f"Backup failed: {e}", start_time
                )

        # --- Write ---
        try:
            with open(abs_path, "w", encoding=config.encoding) as f:
                f.write(modified_content)
        except OSError as e:
            # Attempt to restore from backup
            if backup_path and os.path.exists(backup_path):
                try:
                    shutil.copy2(backup_path, abs_path)
                    logger.warning("Restored %s from backup after write failure", abs_path)
                except OSError:
                    logger.error("CRITICAL: Failed to restore %s from backup!", abs_path)
            return self._error_result(abs_path, f"Write error: {e}", start_time)

        result = FileResult(
            file_path=abs_path,
            status=ReplacementStatus.SUCCESS,
            occurrences=occurrences,
            backup_path=backup_path,
            original_hash=original_hash,
            modified_hash=modified_hash,
            encoding=config.encoding,
            elapsed_ms=self._elapsed_ms(start_time),
        )

        self._log_audit(
            "file_replace_success",
            {
                "file": abs_path,
                "occurrences": len(occurrences),
                "original_hash": original_hash,
                "modified_hash": modified_hash,
            },
        )

        return result

    # ------------------------------------------------------------------
    # Directory-level replacement
    # ------------------------------------------------------------------

    def replace_in_directory(
        self,
        directory: str,
        config: ReplaceConfig,
    ) -> ReplacementReport:
        """
        Replace all occurrences across all eligible files in a directory.

        Args:
            directory: Path to the target directory.
            config: Replacement configuration.

        Returns:
            ReplacementReport with aggregate results.
        """
        report = ReplacementReport(
            find_pattern=config.find_pattern,
            replace_with=config.replace_with,
            match_mode=config.match_mode,
            case_sensitive=config.case_sensitive,
            dry_run=config.dry_run,
            started_at=datetime.now(timezone.utc),
        )

        abs_dir = os.path.abspath(directory)

        if not os.path.isdir(abs_dir):
            raise FileNotFoundError(f"Directory not found: {abs_dir}")

        self._log_audit(
            "directory_replace_start",
            {"directory": abs_dir, "recursive": config.recursive, "dry_run": config.dry_run},
        )

        file_paths = self._collect_files(abs_dir, config)

        for file_path in sorted(file_paths):
            result = self.replace_in_file(file_path, config)
            report.file_results.append(result)

        report.completed_at = datetime.now(timezone.utc)

        self._log_audit(
            "directory_replace_complete",
            {
                "directory": abs_dir,
                "files_scanned": report.total_files_scanned,
                "files_modified": report.total_files_modified,
                "total_occurrences": report.total_occurrences,
                "errors": report.total_errors,
                "elapsed_s": report.elapsed_seconds,
            },
        )

        return report

    # ------------------------------------------------------------------
    # Convenience methods
    # ------------------------------------------------------------------

    def find_all(
        self, text: str, config: ReplaceConfig
    ) -> List[Occurrence]:
        """Find all occurrences without replacing (read-only scan)."""
        pattern = self._compile_pattern(config)
        occurrences: List[Occurrence] = []
        lines = text.splitlines(keepends=True)
        for line_num, line in enumerate(lines, start=1):
            for m in pattern.finditer(line):
                occ = Occurrence(
                    line_number=line_num,
                    column_start=m.start() + 1,
                    column_end=m.end(),
                    original_line=line.rstrip("\n\r"),
                    replaced_line="",
                    match_text=m.group(),
                )
                occurrences.append(occ)
        return occurrences

    def count_occurrences(self, text: str, config: ReplaceConfig) -> int:
        """Count occurrences of the pattern in text."""
        pattern = self._compile_pattern(config)
        return len(pattern.findall(text))

    def preview_replacement(
        self, text: str, config: ReplaceConfig, context_lines: int = 2
    ) -> str:
        """
        Generate a diff-style preview of what would be replaced.

        Args:
            text: Source text.
            config: Replacement configuration.
            context_lines: Number of context lines around each change.

        Returns:
            Human-readable diff preview string.
        """
        _, occurrences = self.replace_in_text(text, config)
        if not occurrences:
            return "No matches found."

        lines = text.splitlines()
        changed_line_nums = {occ.line_number for occ in occurrences}

        output_lines: List[str] = []
        output_lines.append(f"Preview: '{config.find_pattern}' -> '{config.replace_with}'")
        output_lines.append(f"Total matches: {len(occurrences)}")
        output_lines.append("-" * 50)

        # Group consecutive changes
        visible_lines: Set[int] = set()
        for ln in changed_line_nums:
            for ctx in range(
                max(1, ln - context_lines), min(len(lines) + 1, ln + context_lines + 1)
            ):
                visible_lines.add(ctx)

        prev_line = 0
        for ln in sorted(visible_lines):
            if ln - prev_line > 1:
                output_lines.append("  ...")
            if ln in changed_line_nums:
                # Find occurrences on this line
                line_occs = [o for o in occurrences if o.line_number == ln]
                output_lines.append(f"- {ln:>4} | {line_occs[0].original_line}")
                output_lines.append(f"+ {ln:>4} | {line_occs[0].replaced_line}")
            else:
                output_lines.append(f"  {ln:>4} | {lines[ln - 1]}")
            prev_line = ln

        return "\n".join(output_lines)

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _collect_files(
        self, directory: str, config: ReplaceConfig
    ) -> List[str]:
        """Collect all eligible files from a directory."""
        files: List[str] = []
        exclude = config.exclude_patterns or set()

        if config.recursive:
            for root, dirs, filenames in os.walk(
                directory, followlinks=config.follow_symlinks
            ):
                # Prune excluded directories
                dirs[:] = [
                    d for d in dirs if not should_exclude(d, exclude)
                ]
                for fname in filenames:
                    fpath = os.path.join(root, fname)
                    if should_exclude(fname, exclude):
                        continue
                    if not should_include(fname, config.include_patterns):
                        continue
                    files.append(fpath)
        else:
            for entry in os.scandir(directory):
                if entry.is_file(follow_symlinks=config.follow_symlinks):
                    if should_exclude(entry.name, exclude):
                        continue
                    if not should_include(entry.name, config.include_patterns):
                        continue
                    files.append(entry.path)

        return files

    @staticmethod
    def _elapsed_ms(start: float) -> float:
        return (time.monotonic() - start) * 1000

    @staticmethod
    def _error_result(file_path: str, message: str, start: float) -> FileResult:
        logger.error("Replacement error [%s]: %s", file_path, message)
        return FileResult(
            file_path=file_path,
            status=ReplacementStatus.ERROR,
            error_message=message,
            elapsed_ms=(time.monotonic() - start) * 1000,
        )


# ---------------------------------------------------------------------------
# CLI Interface
# ---------------------------------------------------------------------------


def build_argument_parser() -> argparse.ArgumentParser:
    """Build the CLI argument parser."""
    parser = argparse.ArgumentParser(
        prog="replace_all",
        description="Replace all occurrences of a pattern in files.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Literal replacement in a single file
  python replace_all.py --path myfile.txt --find "old" --replace "new"

  # Regex replacement across a directory
  python replace_all.py --path ./src --find "log\\(.*\\)" --replace "logger.info()" --mode regex

  # Case-insensitive dry run
  python replace_all.py --path . --find "TODO" --replace "DONE" --no-case --dry-run

  # Word-boundary matching with include filter
  python replace_all.py --path . --find "var" --replace "const" --mode word --include "*.js"
        """,
    )

    parser.add_argument(
        "--path",
        required=True,
        help="File or directory to process.",
    )
    parser.add_argument(
        "--find",
        required=True,
        help="Pattern to search for.",
    )
    parser.add_argument(
        "--replace",
        required=True,
        help="Replacement string.",
    )
    parser.add_argument(
        "--mode",
        choices=["literal", "regex", "word"],
        default="literal",
        help="Matching mode (default: literal).",
    )
    parser.add_argument(
        "--no-case",
        action="store_true",
        help="Case-insensitive matching.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview changes without modifying files.",
    )
    parser.add_argument(
        "--no-backup",
        action="store_true",
        help="Skip creating backup files.",
    )
    parser.add_argument(
        "--encoding",
        default=DEFAULT_ENCODING,
        help=f"File encoding (default: {DEFAULT_ENCODING}).",
    )
    parser.add_argument(
        "--include",
        nargs="*",
        help="File patterns to include (e.g., '*.py' '*.txt').",
    )
    parser.add_argument(
        "--exclude",
        nargs="*",
        help="Additional file patterns to exclude.",
    )
    parser.add_argument(
        "--no-recursive",
        action="store_true",
        help="Do not recurse into subdirectories.",
    )
    parser.add_argument(
        "--follow-symlinks",
        action="store_true",
        help="Follow symbolic links.",
    )
    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Enable verbose output.",
    )

    return parser


def _parse_match_mode(mode_str: str) -> MatchMode:
    """Convert CLI mode string to MatchMode enum."""
    return {
        "literal": MatchMode.LITERAL,
        "regex": MatchMode.REGEX,
        "word": MatchMode.WORD_BOUNDARY,
    }[mode_str]


def main(argv: Optional[List[str]] = None) -> int:
    """CLI entry point."""
    parser = build_argument_parser()
    args = parser.parse_args(argv)

    if args.verbose:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.WARNING)

    # Build config
    exclude = set(DEFAULT_EXCLUDE_PATTERNS)
    if args.exclude:
        exclude.update(args.exclude)

    try:
        config = ReplaceConfig(
            find_pattern=args.find,
            replace_with=args.replace,
            match_mode=_parse_match_mode(args.mode),
            case_sensitive=not args.no_case,
            dry_run=args.dry_run,
            create_backup=not args.no_backup,
            encoding=args.encoding,
            include_patterns=args.include,
            exclude_patterns=exclude,
            follow_symlinks=args.follow_symlinks,
            recursive=not args.no_recursive,
        )
    except ValueError as e:
        print(f"Configuration error: {e}", file=sys.stderr)
        return 1

    engine = ReplacementEngine()
    target = os.path.abspath(args.path)

    try:
        if os.path.isfile(target):
            result = engine.replace_in_file(target, config)
            # Wrap single file result in a report
            report = ReplacementReport(
                find_pattern=config.find_pattern,
                replace_with=config.replace_with,
                match_mode=config.match_mode,
                case_sensitive=config.case_sensitive,
                dry_run=config.dry_run,
                file_results=[result],
                started_at=datetime.now(timezone.utc),
                completed_at=datetime.now(timezone.utc),
            )
        elif os.path.isdir(target):
            report = engine.replace_in_directory(target, config)
        else:
            print(f"Error: '{target}' is not a valid file or directory.", file=sys.stderr)
            return 1
    except Exception as e:
        print(f"Execution error: {e}", file=sys.stderr)
        return 1

    print(report.summary())

    if report.total_errors > 0:
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
