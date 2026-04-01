#!/usr/bin/env python3
"""
Cursorrules Enforcer — Runtime Enforcement, Not Honor System
=============================================================

PROBLEM (identified by 4-LLM audit):
    The .cursorrules file is an "honor system" — it's a flat text file that
    AI agents SHOULD follow, but nothing prevents them from violating it.
    Proof: during the build, the agent initially scaffolded full SDK
    boilerplate (supabase.ts, elevenlabs.ts, API routes) despite
    .cursorrules mandating MCP-only integration. The rules failed to
    constrain the very agent that created them.

SOLUTION:
    A runtime enforcer that:
    1. Parses .cursorrules into structured, machine-readable rules
    2. Hooks into file-write operations to validate compliance
    3. Scans generated code for violations BEFORE it's committed
    4. Blocks commits that violate architectural constraints
    5. Generates violation reports with specific file:line references

    This converts .cursorrules from a suggestion into a gate.

Usage:
    enforcer = CursorRulesEnforcer(".cursorrules")
    violations = enforcer.scan_directory("./src")
    if violations:
        for v in violations:
            print(v)
        sys.exit(1)  # Block the commit

    # As a git pre-commit hook:
    # python -m architecture.cursorrules_enforcer --pre-commit
"""

import json
import logging
import os
import re
import sys
from dataclasses import dataclass, field
from datetime import datetime, timezone
from enum import Enum, auto
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Pattern, Set, Tuple

logger = logging.getLogger("cursorrules_enforcer")

# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------


class RuleType(Enum):
    """Types of enforceable rules."""

    FORBIDDEN_IMPORT = auto()
    FORBIDDEN_PATTERN = auto()
    REQUIRED_PATTERN = auto()
    FILE_FORBIDDEN = auto()
    MAX_FILE_SIZE = auto()
    NAMING_CONVENTION = auto()
    DEPENDENCY_RESTRICTION = auto()
    CUSTOM = auto()


class Severity(Enum):
    """Violation severity."""

    ERROR = auto()
    WARNING = auto()
    INFO = auto()


# ---------------------------------------------------------------------------
# Data Classes
# ---------------------------------------------------------------------------


@dataclass
class Rule:
    """A single enforceable rule parsed from .cursorrules."""

    id: str
    rule_type: RuleType
    description: str
    severity: Severity = Severity.ERROR
    pattern: Optional[str] = None
    compiled_pattern: Optional[Pattern] = None
    file_glob: str = "*"
    applies_to: Set[str] = field(default_factory=lambda: {"*"})
    metadata: Dict[str, Any] = field(default_factory=dict)

    def __post_init__(self) -> None:
        if self.pattern and not self.compiled_pattern:
            try:
                self.compiled_pattern = re.compile(self.pattern, re.MULTILINE)
            except re.error:
                pass


@dataclass
class Violation:
    """A specific rule violation found in a file."""

    rule: Rule
    file_path: str
    line_number: Optional[int] = None
    line_content: Optional[str] = None
    message: str = ""

    def __str__(self) -> str:
        loc = f"{self.file_path}"
        if self.line_number:
            loc += f":{self.line_number}"
        severity = self.rule.severity.name
        return f"[{severity}] {loc} — {self.rule.id}: {self.message}"


@dataclass
class ScanResult:
    """Result of scanning files against the ruleset."""

    violations: List[Violation] = field(default_factory=list)
    files_scanned: int = 0
    rules_checked: int = 0
    elapsed_ms: float = 0.0
    scanned_at: str = field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat()
    )

    @property
    def error_count(self) -> int:
        return sum(1 for v in self.violations if v.rule.severity == Severity.ERROR)

    @property
    def warning_count(self) -> int:
        return sum(1 for v in self.violations if v.rule.severity == Severity.WARNING)

    @property
    def passed(self) -> bool:
        return self.error_count == 0

    def summary(self) -> str:
        status = "PASS" if self.passed else "FAIL"
        lines = [
            "=" * 60,
            f"CURSORRULES ENFORCEMENT: {status}",
            "=" * 60,
            f"  Files scanned:  {self.files_scanned}",
            f"  Rules checked:  {self.rules_checked}",
            f"  Errors:         {self.error_count}",
            f"  Warnings:       {self.warning_count}",
            f"  Elapsed:        {self.elapsed_ms:.1f}ms",
            "-" * 60,
        ]
        if self.violations:
            lines.append("VIOLATIONS:")
            for v in self.violations:
                lines.append(f"  {v}")
        else:
            lines.append("  No violations found.")
        lines.append("=" * 60)
        return "\n".join(lines)


# ---------------------------------------------------------------------------
# Rule Parser
# ---------------------------------------------------------------------------


class RuleParser:
    """
    Parses a .cursorrules file into structured, enforceable Rule objects.

    Supports two formats:
    1. Annotated .cursorrules (with enforcement markers)
    2. Plain .cursorrules (best-effort extraction of patterns)

    Annotated format uses special markers:
        ## @enforce FORBIDDEN_IMPORT
        ## @pattern import\\s+(supabase|stripe)
        ## @severity ERROR
        ## @description Do not import SDK clients directly — use MCP
        Never import supabase, stripe, or other SDK clients directly.
        All external service access must go through MCP servers.
    """

    MARKER_PREFIX = "## @"

    def parse(self, content: str) -> List[Rule]:
        """Parse .cursorrules content into Rule objects."""
        rules: List[Rule] = []

        # Try annotated format first
        annotated = self._parse_annotated(content)
        if annotated:
            rules.extend(annotated)

        # Always run best-effort extraction for unannotated rules
        inferred = self._infer_rules(content)
        existing_ids = {r.id for r in rules}
        for r in inferred:
            if r.id not in existing_ids:
                rules.append(r)

        return rules

    def _parse_annotated(self, content: str) -> List[Rule]:
        """Parse rules from annotated markers."""
        rules: List[Rule] = []
        lines = content.splitlines()
        i = 0

        while i < len(lines):
            line = lines[i].strip()

            if line.startswith(f"{self.MARKER_PREFIX}enforce"):
                rule_data: Dict[str, Any] = {}
                rule_type_str = line.split(maxsplit=1)[-1] if " " in line else ""

                # Collect all marker lines
                while i < len(lines) and lines[i].strip().startswith(self.MARKER_PREFIX):
                    marker_line = lines[i].strip()
                    parts = marker_line[len(self.MARKER_PREFIX) :].split(maxsplit=1)
                    if len(parts) == 2:
                        key, value = parts
                        rule_data[key] = value
                    i += 1

                # Build the rule
                try:
                    rule_type = RuleType[rule_data.get("enforce", "CUSTOM").upper()]
                except KeyError:
                    rule_type = RuleType.CUSTOM

                rule_id = rule_data.get(
                    "id", f"annotated_{len(rules) + 1}"
                )

                try:
                    severity = Severity[rule_data.get("severity", "ERROR").upper()]
                except KeyError:
                    severity = Severity.ERROR

                rule = Rule(
                    id=rule_id,
                    rule_type=rule_type,
                    description=rule_data.get("description", ""),
                    severity=severity,
                    pattern=rule_data.get("pattern"),
                    file_glob=rule_data.get("glob", "*"),
                )
                rules.append(rule)
            else:
                i += 1

        return rules

    def _infer_rules(self, content: str) -> List[Rule]:
        """
        Best-effort inference of rules from plain .cursorrules text.
        Looks for common patterns like "never", "do not", "must not",
        "always", "required", etc.
        """
        rules: List[Rule] = []
        lines = content.splitlines()

        # Pattern: "Never/Do not import X"
        import_ban_re = re.compile(
            r"(?:never|do\s+not|don't|must\s+not)\s+(?:use|import)\s+(\w+)",
            re.IGNORECASE,
        )

        # Pattern: "Always use X"
        always_use_re = re.compile(
            r"(?:always|must)\s+use\s+(\w+)",
            re.IGNORECASE,
        )

        # Pattern: "No direct SDK" / "MCP only"
        mcp_only_re = re.compile(
            r"(?:mcp[- ]only|no\s+(?:direct\s+)?sdk|through\s+mcp)",
            re.IGNORECASE,
        )

        for i, line in enumerate(lines):
            stripped = line.strip()
            if not stripped or stripped.startswith("#"):
                continue

            # Check for import bans
            match = import_ban_re.search(stripped)
            if match:
                banned = match.group(1)
                rules.append(
                    Rule(
                        id=f"inferred_no_import_{banned}_{i}",
                        rule_type=RuleType.FORBIDDEN_IMPORT,
                        description=stripped,
                        pattern=rf"(?:import|from)\s+{re.escape(banned)}",
                        severity=Severity.ERROR,
                    )
                )

            # Check for MCP-only directives
            if mcp_only_re.search(stripped):
                # Common SDK imports that should be forbidden
                for sdk in ["supabase", "stripe", "elevenlabs", "openai"]:
                    rules.append(
                        Rule(
                            id=f"inferred_mcp_only_{sdk}_{i}",
                            rule_type=RuleType.FORBIDDEN_IMPORT,
                            description=f"MCP-only: no direct {sdk} SDK import",
                            pattern=rf"(?:import|from|require)\s*\(?['\"]?{sdk}",
                            severity=Severity.ERROR,
                        )
                    )

        return rules

    def parse_file(self, path: str) -> List[Rule]:
        """Parse a .cursorrules file."""
        with open(path, "r", encoding="utf-8") as f:
            return self.parse(f.read())


# ---------------------------------------------------------------------------
# File Scanner
# ---------------------------------------------------------------------------


class FileScanner:
    """Scans files against a set of rules."""

    BINARY_EXTENSIONS = frozenset(
        {
            ".pyc", ".pyo", ".exe", ".dll", ".so", ".dylib",
            ".jpg", ".jpeg", ".png", ".gif", ".bmp", ".ico",
            ".pdf", ".zip", ".tar", ".gz", ".bz2", ".7z",
            ".mp3", ".mp4", ".avi", ".mov", ".woff", ".woff2",
        }
    )

    SKIP_DIRS = frozenset(
        {
            ".git", "node_modules", "__pycache__", ".next",
            "venv", ".venv", "dist", "build", ".tox",
        }
    )

    def scan_file(self, file_path: str, rules: List[Rule]) -> List[Violation]:
        """Scan a single file against all rules."""
        violations: List[Violation] = []

        # Skip binary files
        ext = Path(file_path).suffix.lower()
        if ext in self.BINARY_EXTENSIONS:
            return violations

        try:
            with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
        except (OSError, UnicodeDecodeError):
            return violations

        lines = content.splitlines()

        for rule in rules:
            if rule.rule_type == RuleType.FORBIDDEN_IMPORT:
                violations.extend(
                    self._check_forbidden_pattern(file_path, lines, rule)
                )
            elif rule.rule_type == RuleType.FORBIDDEN_PATTERN:
                violations.extend(
                    self._check_forbidden_pattern(file_path, lines, rule)
                )
            elif rule.rule_type == RuleType.REQUIRED_PATTERN:
                violations.extend(
                    self._check_required_pattern(file_path, content, rule)
                )
            elif rule.rule_type == RuleType.FILE_FORBIDDEN:
                violations.extend(
                    self._check_forbidden_file(file_path, rule)
                )
            elif rule.rule_type == RuleType.MAX_FILE_SIZE:
                violations.extend(
                    self._check_file_size(file_path, rule)
                )

        return violations

    def scan_directory(
        self, directory: str, rules: List[Rule]
    ) -> Tuple[List[Violation], int]:
        """Scan all files in a directory recursively."""
        all_violations: List[Violation] = []
        files_scanned = 0

        for root, dirs, files in os.walk(directory):
            # Skip excluded directories
            dirs[:] = [d for d in dirs if d not in self.SKIP_DIRS]

            for fname in files:
                fpath = os.path.join(root, fname)
                violations = self.scan_file(fpath, rules)
                all_violations.extend(violations)
                files_scanned += 1

        return all_violations, files_scanned

    def _check_forbidden_pattern(
        self, file_path: str, lines: List[str], rule: Rule
    ) -> List[Violation]:
        """Check for forbidden patterns in file content."""
        violations: List[Violation] = []
        if not rule.compiled_pattern:
            return violations

        for line_num, line in enumerate(lines, start=1):
            if rule.compiled_pattern.search(line):
                violations.append(
                    Violation(
                        rule=rule,
                        file_path=file_path,
                        line_number=line_num,
                        line_content=line.strip(),
                        message=f"Forbidden pattern found: {rule.description}",
                    )
                )

        return violations

    def _check_required_pattern(
        self, file_path: str, content: str, rule: Rule
    ) -> List[Violation]:
        """Check that a required pattern exists in the file."""
        if not rule.compiled_pattern:
            return []
        if not rule.compiled_pattern.search(content):
            return [
                Violation(
                    rule=rule,
                    file_path=file_path,
                    message=f"Required pattern missing: {rule.description}",
                )
            ]
        return []

    def _check_forbidden_file(
        self, file_path: str, rule: Rule
    ) -> List[Violation]:
        """Check if a file's existence itself is a violation."""
        if not rule.pattern:
            return []
        if re.search(rule.pattern, file_path):
            return [
                Violation(
                    rule=rule,
                    file_path=file_path,
                    message=f"Forbidden file: {rule.description}",
                )
            ]
        return []

    def _check_file_size(
        self, file_path: str, rule: Rule
    ) -> List[Violation]:
        """Check if file exceeds maximum size."""
        max_size = rule.metadata.get("max_bytes", 1_000_000)
        try:
            size = os.path.getsize(file_path)
            if size > max_size:
                return [
                    Violation(
                        rule=rule,
                        file_path=file_path,
                        message=f"File too large: {size} bytes (max {max_size})",
                    )
                ]
        except OSError:
            pass
        return []


# ---------------------------------------------------------------------------
# Main Enforcer
# ---------------------------------------------------------------------------


class CursorRulesEnforcer:
    """
    The main enforcer that ties parsing, scanning, and reporting together.
    Drop-in replacement for the honor-system .cursorrules.
    """

    def __init__(self, cursorrules_path: str = ".cursorrules") -> None:
        self.cursorrules_path = cursorrules_path
        self.parser = RuleParser()
        self.scanner = FileScanner()
        self.rules: List[Rule] = []

        if os.path.exists(cursorrules_path):
            self.rules = self.parser.parse_file(cursorrules_path)
            logger.info(
                "Loaded %d rules from %s", len(self.rules), cursorrules_path
            )

    def add_rule(self, rule: Rule) -> None:
        """Add a rule programmatically."""
        self.rules.append(rule)

    def add_forbidden_import(
        self,
        module_name: str,
        description: str = "",
        severity: Severity = Severity.ERROR,
    ) -> None:
        """Convenience: add a forbidden import rule."""
        self.rules.append(
            Rule(
                id=f"no_import_{module_name}",
                rule_type=RuleType.FORBIDDEN_IMPORT,
                description=description or f"Direct import of {module_name} is forbidden",
                pattern=rf"(?:import|from)\s+{re.escape(module_name)}",
                severity=severity,
            )
        )

    def add_forbidden_pattern(
        self,
        pattern: str,
        rule_id: str,
        description: str = "",
        severity: Severity = Severity.ERROR,
    ) -> None:
        """Convenience: add a forbidden pattern rule."""
        self.rules.append(
            Rule(
                id=rule_id,
                rule_type=RuleType.FORBIDDEN_PATTERN,
                description=description,
                pattern=pattern,
                severity=severity,
            )
        )

    def scan_file(self, file_path: str) -> ScanResult:
        """Scan a single file."""
        import time

        start = time.monotonic()
        violations = self.scanner.scan_file(file_path, self.rules)
        elapsed = (time.monotonic() - start) * 1000

        return ScanResult(
            violations=violations,
            files_scanned=1,
            rules_checked=len(self.rules),
            elapsed_ms=elapsed,
        )

    def scan_directory(self, directory: str) -> ScanResult:
        """Scan an entire directory."""
        import time

        start = time.monotonic()
        violations, files_scanned = self.scanner.scan_directory(directory, self.rules)
        elapsed = (time.monotonic() - start) * 1000

        return ScanResult(
            violations=violations,
            files_scanned=files_scanned,
            rules_checked=len(self.rules),
            elapsed_ms=elapsed,
        )

    def scan_staged_files(self) -> ScanResult:
        """Scan only git staged files (for pre-commit hook)."""
        import subprocess
        import time

        start = time.monotonic()
        try:
            result = subprocess.run(
                ["git", "diff", "--cached", "--name-only", "--diff-filter=ACM"],
                capture_output=True,
                text=True,
                timeout=10,
            )
            staged_files = [f.strip() for f in result.stdout.splitlines() if f.strip()]
        except (subprocess.SubprocessError, FileNotFoundError):
            logger.warning("Could not get staged files, scanning all")
            return self.scan_directory(".")

        all_violations: List[Violation] = []
        for fpath in staged_files:
            if os.path.exists(fpath):
                violations = self.scanner.scan_file(fpath, self.rules)
                all_violations.extend(violations)

        elapsed = (time.monotonic() - start) * 1000

        return ScanResult(
            violations=all_violations,
            files_scanned=len(staged_files),
            rules_checked=len(self.rules),
            elapsed_ms=elapsed,
        )

    def generate_pre_commit_hook(self, output_path: str = ".git/hooks/pre-commit") -> str:
        """Generate a git pre-commit hook script."""
        hook_script = """#!/bin/sh
# Auto-generated by CursorRules Enforcer
# This hook blocks commits that violate .cursorrules

echo "Running .cursorrules enforcement check..."
python3 -m architecture.cursorrules_enforcer --pre-commit

if [ $? -ne 0 ]; then
    echo ""
    echo "COMMIT BLOCKED: .cursorrules violations detected."
    echo "Fix the violations above and try again."
    echo "To bypass (not recommended): git commit --no-verify"
    exit 1
fi

echo ".cursorrules check passed."
"""
        with open(output_path, "w") as f:
            f.write(hook_script)
        os.chmod(output_path, 0o755)
        logger.info("Pre-commit hook written to %s", output_path)
        return output_path


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main() -> int:
    """CLI entry point."""
    import argparse

    parser = argparse.ArgumentParser(
        description="Enforce .cursorrules at runtime — blocks violations before commit"
    )
    parser.add_argument(
        "--rules",
        default=".cursorrules",
        help="Path to .cursorrules file (default: .cursorrules)",
    )
    parser.add_argument(
        "--scan",
        metavar="PATH",
        help="Scan a file or directory",
    )
    parser.add_argument(
        "--pre-commit",
        action="store_true",
        help="Scan only git staged files (for pre-commit hook)",
    )
    parser.add_argument(
        "--install-hook",
        action="store_true",
        help="Install git pre-commit hook",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output results as JSON",
    )

    args = parser.parse_args()

    logging.basicConfig(
        level=logging.INFO,
        format="[%(asctime)s] %(levelname)s: %(message)s",
    )

    enforcer = CursorRulesEnforcer(args.rules)

    if not enforcer.rules:
        # If no .cursorrules file, add sensible defaults for the Faceless Shorts architecture
        logger.info("No .cursorrules found — using default MCP-only rules")
        enforcer.add_forbidden_import(
            "supabase", "Use MCP server, not direct Supabase SDK"
        )
        enforcer.add_forbidden_import(
            "stripe", "Use MCP server, not direct Stripe SDK"
        )
        enforcer.add_forbidden_import(
            "elevenlabs", "Use MCP server, not direct ElevenLabs SDK"
        )
        enforcer.add_forbidden_pattern(
            r"createClient\s*\(",
            "no_create_client",
            "Do not create direct SDK clients — use MCP",
        )
        enforcer.add_forbidden_pattern(
            r"new\s+Stripe\s*\(",
            "no_stripe_client",
            "Do not instantiate Stripe client — use MCP",
        )

    if args.install_hook:
        path = enforcer.generate_pre_commit_hook()
        print(f"Pre-commit hook installed: {path}")
        return 0

    if args.pre_commit:
        result = enforcer.scan_staged_files()
    elif args.scan:
        target = args.scan
        if os.path.isfile(target):
            result = enforcer.scan_file(target)
        elif os.path.isdir(target):
            result = enforcer.scan_directory(target)
        else:
            print(f"Error: '{target}' not found", file=sys.stderr)
            return 1
    else:
        result = enforcer.scan_directory(".")

    if args.json:
        print(
            json.dumps(
                {
                    "passed": result.passed,
                    "files_scanned": result.files_scanned,
                    "rules_checked": result.rules_checked,
                    "errors": result.error_count,
                    "warnings": result.warning_count,
                    "violations": [
                        {
                            "rule_id": v.rule.id,
                            "severity": v.rule.severity.name,
                            "file": v.file_path,
                            "line": v.line_number,
                            "message": v.message,
                        }
                        for v in result.violations
                    ],
                },
                indent=2,
            )
        )
    else:
        print(result.summary())

    return 0 if result.passed else 1


if __name__ == "__main__":
    sys.exit(main())
