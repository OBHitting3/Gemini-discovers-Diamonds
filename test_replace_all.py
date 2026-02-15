#!/usr/bin/env python3
"""
Comprehensive Test Suite for All-Occurrences Replacement Engine
================================================================

Tests cover:
    - Text-level replacement (literal, regex, word-boundary)
    - Case-sensitive and case-insensitive matching
    - File-level replacement with backup management
    - Directory-level recursive replacement
    - Dry-run mode
    - Edge cases (empty files, binary files, large files, encoding)
    - Configuration validation
    - Audit logging
    - CLI interface
    - Error handling and recovery
"""

import os
import shutil
import tempfile
import textwrap
import unittest
from pathlib import Path
from unittest.mock import patch

from replace_all import (
    DEFAULT_EXCLUDE_PATTERNS,
    FileResult,
    MatchMode,
    Occurrence,
    ReplaceConfig,
    ReplacementEngine,
    ReplacementReport,
    ReplacementStatus,
    compute_sha256,
    is_binary_file,
    main,
    should_exclude,
    should_include,
)


class TestComputeSHA256(unittest.TestCase):
    """Tests for the SHA-256 hashing utility."""

    def test_deterministic(self):
        h1 = compute_sha256("hello world")
        h2 = compute_sha256("hello world")
        self.assertEqual(h1, h2)

    def test_different_inputs(self):
        h1 = compute_sha256("hello")
        h2 = compute_sha256("world")
        self.assertNotEqual(h1, h2)

    def test_empty_string(self):
        h = compute_sha256("")
        self.assertIsInstance(h, str)
        self.assertEqual(len(h), 64)  # SHA-256 hex digest length


class TestIsBinaryFile(unittest.TestCase):
    """Tests for binary file detection."""

    def setUp(self):
        self.tmpdir = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self.tmpdir)

    def test_text_file(self):
        path = os.path.join(self.tmpdir, "text.txt")
        with open(path, "w") as f:
            f.write("Hello, this is plain text.\n")
        self.assertFalse(is_binary_file(path))

    def test_binary_file(self):
        path = os.path.join(self.tmpdir, "binary.bin")
        with open(path, "wb") as f:
            f.write(b"\x00\x01\x02\x03\x04\x05\xff\xfe")
        self.assertTrue(is_binary_file(path))

    def test_nonexistent_file(self):
        self.assertTrue(is_binary_file("/nonexistent/path/file.txt"))


class TestShouldExclude(unittest.TestCase):
    """Tests for path exclusion logic."""

    def test_matches_pattern(self):
        self.assertTrue(should_exclude("file.pyc", {"*.pyc"}))

    def test_no_match(self):
        self.assertFalse(should_exclude("file.py", {"*.pyc"}))

    def test_directory_match(self):
        self.assertTrue(should_exclude("__pycache__", {"__pycache__"}))

    def test_empty_patterns(self):
        self.assertFalse(should_exclude("anything.txt", set()))


class TestShouldInclude(unittest.TestCase):
    """Tests for path inclusion logic."""

    def test_no_patterns_includes_all(self):
        self.assertTrue(should_include("file.py", None))
        self.assertTrue(should_include("file.py", []))

    def test_matches_pattern(self):
        self.assertTrue(should_include("file.py", ["*.py"]))

    def test_no_match(self):
        self.assertFalse(should_include("file.txt", ["*.py"]))

    def test_multiple_patterns(self):
        self.assertTrue(should_include("file.js", ["*.py", "*.js"]))


class TestReplaceConfig(unittest.TestCase):
    """Tests for ReplaceConfig validation."""

    def test_valid_config(self):
        config = ReplaceConfig(find_pattern="old", replace_with="new")
        self.assertEqual(config.find_pattern, "old")
        self.assertEqual(config.replace_with, "new")
        self.assertTrue(config.case_sensitive)
        self.assertEqual(config.match_mode, MatchMode.LITERAL)

    def test_empty_pattern_raises(self):
        with self.assertRaises(ValueError):
            ReplaceConfig(find_pattern="", replace_with="new")

    def test_same_pattern_raises(self):
        with self.assertRaises(ValueError):
            ReplaceConfig(find_pattern="same", replace_with="same")

    def test_invalid_regex_raises(self):
        with self.assertRaises(ValueError):
            ReplaceConfig(
                find_pattern="[invalid",
                replace_with="x",
                match_mode=MatchMode.REGEX,
            )

    def test_negative_max_file_size_raises(self):
        with self.assertRaises(ValueError):
            ReplaceConfig(find_pattern="a", replace_with="b", max_file_size=-1)

    def test_default_exclude_patterns(self):
        config = ReplaceConfig(find_pattern="a", replace_with="b")
        self.assertIsNotNone(config.exclude_patterns)
        self.assertIn("*.pyc", config.exclude_patterns)


class TestOccurrence(unittest.TestCase):
    """Tests for the Occurrence data class."""

    def test_str_representation(self):
        occ = Occurrence(
            line_number=5,
            column_start=10,
            column_end=15,
            original_line="hello old world",
            replaced_line="hello new world",
            match_text="old",
        )
        s = str(occ)
        self.assertIn("Line 5", s)
        self.assertIn("Col 10-15", s)
        self.assertIn("'old'", s)


class TestFileResult(unittest.TestCase):
    """Tests for FileResult."""

    def test_occurrence_count(self):
        result = FileResult(
            file_path="/test.txt",
            status=ReplacementStatus.SUCCESS,
            occurrences=[
                Occurrence(1, 1, 3, "old", "new", "old"),
                Occurrence(2, 1, 3, "old", "new", "old"),
            ],
        )
        self.assertEqual(result.occurrence_count, 2)

    def test_summary(self):
        result = FileResult(
            file_path="/test.txt",
            status=ReplacementStatus.SUCCESS,
            elapsed_ms=12.5,
        )
        s = result.summary()
        self.assertIn("/test.txt", s)
        self.assertIn("SUCCESS", s)
        self.assertIn("12.50ms", s)


class TestReplacementReport(unittest.TestCase):
    """Tests for ReplacementReport."""

    def test_aggregate_properties(self):
        report = ReplacementReport(
            find_pattern="old",
            replace_with="new",
            match_mode=MatchMode.LITERAL,
            case_sensitive=True,
            dry_run=False,
            file_results=[
                FileResult(
                    file_path="/a.txt",
                    status=ReplacementStatus.SUCCESS,
                    occurrences=[Occurrence(1, 1, 3, "old", "new", "old")],
                ),
                FileResult(
                    file_path="/b.txt",
                    status=ReplacementStatus.NO_MATCHES,
                ),
                FileResult(
                    file_path="/c.txt",
                    status=ReplacementStatus.ERROR,
                    error_message="Read error",
                ),
            ],
        )
        self.assertEqual(report.total_files_scanned, 3)
        self.assertEqual(report.total_files_modified, 1)
        self.assertEqual(report.total_occurrences, 1)
        self.assertEqual(report.total_errors, 1)

    def test_summary_output(self):
        report = ReplacementReport(
            find_pattern="foo",
            replace_with="bar",
            match_mode=MatchMode.LITERAL,
            case_sensitive=True,
            dry_run=True,
        )
        s = report.summary()
        self.assertIn("foo", s)
        self.assertIn("bar", s)
        self.assertIn("REPLACEMENT REPORT", s)


# ---------------------------------------------------------------------------
# Core Engine Tests: Text-Level Replacement
# ---------------------------------------------------------------------------


class TestReplaceInTextLiteral(unittest.TestCase):
    """Tests for literal text replacement."""

    def setUp(self):
        self.engine = ReplacementEngine()

    def test_single_occurrence(self):
        config = ReplaceConfig(find_pattern="world", replace_with="Python")
        text = "Hello world!"
        result, occs = self.engine.replace_in_text(text, config)
        self.assertEqual(result, "Hello Python!")
        self.assertEqual(len(occs), 1)
        self.assertEqual(occs[0].match_text, "world")

    def test_multiple_occurrences_same_line(self):
        config = ReplaceConfig(find_pattern="ab", replace_with="XY")
        text = "ab cd ab ef ab"
        result, occs = self.engine.replace_in_text(text, config)
        self.assertEqual(result, "XY cd XY ef XY")
        self.assertEqual(len(occs), 3)

    def test_multiple_occurrences_multiple_lines(self):
        config = ReplaceConfig(find_pattern="old", replace_with="new")
        text = "old line one\nold line two\nno match\nold line four\n"
        result, occs = self.engine.replace_in_text(text, config)
        self.assertEqual(len(occs), 3)
        self.assertIn("new line one\n", result)
        self.assertIn("new line two\n", result)
        self.assertIn("no match\n", result)
        self.assertIn("new line four\n", result)

    def test_no_occurrences(self):
        config = ReplaceConfig(find_pattern="xyz", replace_with="abc")
        text = "Hello world!"
        result, occs = self.engine.replace_in_text(text, config)
        self.assertEqual(result, text)
        self.assertEqual(len(occs), 0)

    def test_special_regex_characters_escaped(self):
        config = ReplaceConfig(find_pattern="func()", replace_with="method()")
        text = "call func() here and func() there"
        result, occs = self.engine.replace_in_text(text, config)
        self.assertEqual(result, "call method() here and method() there")
        self.assertEqual(len(occs), 2)

    def test_multiline_preserved(self):
        config = ReplaceConfig(find_pattern="X", replace_with="Y")
        text = "line1 X\nline2\nline3 X\n"
        result, occs = self.engine.replace_in_text(text, config)
        self.assertEqual(result, "line1 Y\nline2\nline3 Y\n")

    def test_empty_text(self):
        config = ReplaceConfig(find_pattern="a", replace_with="b")
        result, occs = self.engine.replace_in_text("", config)
        self.assertEqual(result, "")
        self.assertEqual(len(occs), 0)

    def test_replace_with_empty_string(self):
        config = ReplaceConfig(find_pattern="remove_me", replace_with="")
        text = "keep remove_me keep"
        result, occs = self.engine.replace_in_text(text, config)
        self.assertEqual(result, "keep  keep")
        self.assertEqual(len(occs), 1)

    def test_overlapping_patterns(self):
        config = ReplaceConfig(find_pattern="aa", replace_with="X")
        text = "aaa"
        result, occs = self.engine.replace_in_text(text, config)
        # Regex findall is non-overlapping: finds "aa" at pos 0, then "a" at pos 2
        self.assertEqual(result, "Xa")
        self.assertEqual(len(occs), 1)


class TestReplaceInTextCaseInsensitive(unittest.TestCase):
    """Tests for case-insensitive replacement."""

    def setUp(self):
        self.engine = ReplacementEngine()

    def test_case_insensitive_literal(self):
        config = ReplaceConfig(
            find_pattern="hello", replace_with="HI", case_sensitive=False
        )
        text = "Hello HELLO hello hElLo"
        result, occs = self.engine.replace_in_text(text, config)
        self.assertEqual(result, "HI HI HI HI")
        self.assertEqual(len(occs), 4)

    def test_case_sensitive_by_default(self):
        config = ReplaceConfig(find_pattern="Hello", replace_with="HI")
        text = "Hello hello HELLO"
        result, occs = self.engine.replace_in_text(text, config)
        self.assertEqual(result, "HI hello HELLO")
        self.assertEqual(len(occs), 1)


class TestReplaceInTextRegex(unittest.TestCase):
    """Tests for regex-based replacement."""

    def setUp(self):
        self.engine = ReplacementEngine()

    def test_simple_regex(self):
        config = ReplaceConfig(
            find_pattern=r"\d+", replace_with="NUM", match_mode=MatchMode.REGEX
        )
        text = "item 1, item 23, item 456"
        result, occs = self.engine.replace_in_text(text, config)
        self.assertEqual(result, "item NUM, item NUM, item NUM")
        self.assertEqual(len(occs), 3)

    def test_regex_group_replacement(self):
        config = ReplaceConfig(
            find_pattern=r"(\w+)@(\w+)\.com",
            replace_with=r"\1@REDACTED.com",
            match_mode=MatchMode.REGEX,
        )
        text = "Contact alice@example.com or bob@test.com"
        result, occs = self.engine.replace_in_text(text, config)
        self.assertIn("alice@REDACTED.com", result)
        self.assertIn("bob@REDACTED.com", result)
        self.assertEqual(len(occs), 2)

    def test_regex_case_insensitive(self):
        config = ReplaceConfig(
            find_pattern=r"todo|fixme",
            replace_with="DONE",
            match_mode=MatchMode.REGEX,
            case_sensitive=False,
        )
        text = "TODO: fix this\nFIXME: and this\ntodo: also"
        result, occs = self.engine.replace_in_text(text, config)
        self.assertEqual(occs[0].match_text, "TODO")
        self.assertEqual(len(occs), 3)


class TestReplaceInTextWordBoundary(unittest.TestCase):
    """Tests for word-boundary matching."""

    def setUp(self):
        self.engine = ReplacementEngine()

    def test_word_boundary_match(self):
        config = ReplaceConfig(
            find_pattern="var", replace_with="const", match_mode=MatchMode.WORD_BOUNDARY
        )
        text = "var x = 1; variable = 2; var y = 3;"
        result, occs = self.engine.replace_in_text(text, config)
        self.assertEqual(result, "const x = 1; variable = 2; const y = 3;")
        self.assertEqual(len(occs), 2)

    def test_word_boundary_no_partial(self):
        config = ReplaceConfig(
            find_pattern="log", replace_with="print", match_mode=MatchMode.WORD_BOUNDARY
        )
        text = "log this dialog blog log"
        result, occs = self.engine.replace_in_text(text, config)
        self.assertEqual(result, "print this dialog blog print")
        self.assertEqual(len(occs), 2)


# ---------------------------------------------------------------------------
# Core Engine Tests: File-Level Replacement
# ---------------------------------------------------------------------------


class TestReplaceInFile(unittest.TestCase):
    """Tests for file-level replacement."""

    def setUp(self):
        self.tmpdir = tempfile.mkdtemp()
        self.engine = ReplacementEngine()

    def tearDown(self):
        shutil.rmtree(self.tmpdir)

    def _create_file(self, name: str, content: str) -> str:
        path = os.path.join(self.tmpdir, name)
        with open(path, "w", encoding="utf-8") as f:
            f.write(content)
        return path

    def test_successful_replacement(self):
        path = self._create_file("test.txt", "Hello old world\nold and new\n")
        config = ReplaceConfig(find_pattern="old", replace_with="new")
        result = self.engine.replace_in_file(path, config)

        self.assertEqual(result.status, ReplacementStatus.SUCCESS)
        self.assertEqual(result.occurrence_count, 2)
        with open(path) as f:
            content = f.read()
        self.assertEqual(content, "Hello new world\nnew and new\n")

    def test_backup_created(self):
        path = self._create_file("test.txt", "replace me")
        config = ReplaceConfig(find_pattern="me", replace_with="you", create_backup=True)
        result = self.engine.replace_in_file(path, config)

        self.assertIsNotNone(result.backup_path)
        self.assertTrue(os.path.exists(result.backup_path))
        with open(result.backup_path) as f:
            self.assertEqual(f.read(), "replace me")

    def test_no_backup_when_disabled(self):
        path = self._create_file("test.txt", "replace me")
        config = ReplaceConfig(
            find_pattern="me", replace_with="you", create_backup=False
        )
        result = self.engine.replace_in_file(path, config)

        self.assertIsNone(result.backup_path)
        self.assertFalse(os.path.exists(path + ".bak"))

    def test_no_matches_returns_no_matches_status(self):
        path = self._create_file("test.txt", "nothing here")
        config = ReplaceConfig(find_pattern="xyz", replace_with="abc")
        result = self.engine.replace_in_file(path, config)

        self.assertEqual(result.status, ReplacementStatus.NO_MATCHES)
        self.assertEqual(result.occurrence_count, 0)

    def test_dry_run_no_modification(self):
        original = "keep old text"
        path = self._create_file("test.txt", original)
        config = ReplaceConfig(find_pattern="old", replace_with="new", dry_run=True)
        result = self.engine.replace_in_file(path, config)

        self.assertEqual(result.status, ReplacementStatus.DRY_RUN)
        self.assertEqual(result.occurrence_count, 1)
        with open(path) as f:
            self.assertEqual(f.read(), original)

    def test_nonexistent_file(self):
        config = ReplaceConfig(find_pattern="a", replace_with="b")
        result = self.engine.replace_in_file("/nonexistent/file.txt", config)
        self.assertEqual(result.status, ReplacementStatus.ERROR)
        self.assertIn("not found", result.error_message)

    def test_binary_file_skipped(self):
        path = os.path.join(self.tmpdir, "binary.bin")
        with open(path, "wb") as f:
            f.write(b"\x00\x01\x02" * 1000)
        config = ReplaceConfig(find_pattern="a", replace_with="b")
        result = self.engine.replace_in_file(path, config)
        self.assertEqual(result.status, ReplacementStatus.SKIPPED)

    def test_file_too_large(self):
        path = self._create_file("test.txt", "some content")
        config = ReplaceConfig(find_pattern="some", replace_with="any", max_file_size=5)
        result = self.engine.replace_in_file(path, config)
        self.assertEqual(result.status, ReplacementStatus.ERROR)
        self.assertIn("too large", result.error_message)

    def test_hash_values_set(self):
        path = self._create_file("test.txt", "Hello old!")
        config = ReplaceConfig(find_pattern="old", replace_with="new")
        result = self.engine.replace_in_file(path, config)

        self.assertIsNotNone(result.original_hash)
        self.assertIsNotNone(result.modified_hash)
        self.assertNotEqual(result.original_hash, result.modified_hash)

    def test_empty_file(self):
        path = self._create_file("empty.txt", "")
        config = ReplaceConfig(find_pattern="a", replace_with="b")
        result = self.engine.replace_in_file(path, config)
        self.assertEqual(result.status, ReplacementStatus.NO_MATCHES)


# ---------------------------------------------------------------------------
# Core Engine Tests: Directory-Level Replacement
# ---------------------------------------------------------------------------


class TestReplaceInDirectory(unittest.TestCase):
    """Tests for directory-level recursive replacement."""

    def setUp(self):
        self.tmpdir = tempfile.mkdtemp()
        self.engine = ReplacementEngine()

    def tearDown(self):
        shutil.rmtree(self.tmpdir)

    def _create_structure(self):
        """Create a sample directory structure for testing."""
        # Root files
        self._write(os.path.join(self.tmpdir, "root.txt"), "replace old here\n")
        self._write(os.path.join(self.tmpdir, "other.py"), "old = True\nold_value = old\n")

        # Subdirectory
        subdir = os.path.join(self.tmpdir, "sub")
        os.makedirs(subdir)
        self._write(os.path.join(subdir, "deep.txt"), "old in subdirectory\n")
        self._write(os.path.join(subdir, "no_match.txt"), "nothing here\n")

        # Excluded directory
        excluded = os.path.join(self.tmpdir, "__pycache__")
        os.makedirs(excluded)
        self._write(os.path.join(excluded, "cached.pyc"), "old should be skipped\n")

    @staticmethod
    def _write(path: str, content: str):
        with open(path, "w", encoding="utf-8") as f:
            f.write(content)

    def test_recursive_replacement(self):
        self._create_structure()
        config = ReplaceConfig(
            find_pattern="old",
            replace_with="new",
            create_backup=False,
            exclude_patterns=set(DEFAULT_EXCLUDE_PATTERNS),
        )
        report = self.engine.replace_in_directory(self.tmpdir, config)

        self.assertGreaterEqual(report.total_files_scanned, 3)
        self.assertGreaterEqual(report.total_files_modified, 3)
        self.assertGreaterEqual(report.total_occurrences, 4)

    def test_non_recursive(self):
        self._create_structure()
        config = ReplaceConfig(
            find_pattern="old",
            replace_with="new",
            recursive=False,
            create_backup=False,
        )
        report = self.engine.replace_in_directory(self.tmpdir, config)

        # Should only process root-level files
        for fr in report.file_results:
            self.assertEqual(os.path.dirname(fr.file_path), self.tmpdir)

    def test_include_filter(self):
        self._create_structure()
        config = ReplaceConfig(
            find_pattern="old",
            replace_with="new",
            include_patterns=["*.py"],
            create_backup=False,
        )
        report = self.engine.replace_in_directory(self.tmpdir, config)

        for fr in report.file_results:
            self.assertTrue(fr.file_path.endswith(".py"))

    def test_exclude_filter(self):
        self._create_structure()
        config = ReplaceConfig(
            find_pattern="old",
            replace_with="new",
            exclude_patterns={"*.pyc", "__pycache__"},
            create_backup=False,
        )
        report = self.engine.replace_in_directory(self.tmpdir, config)

        for fr in report.file_results:
            self.assertNotIn("__pycache__", fr.file_path)
            self.assertFalse(fr.file_path.endswith(".pyc"))

    def test_dry_run_directory(self):
        self._create_structure()
        config = ReplaceConfig(
            find_pattern="old",
            replace_with="new",
            dry_run=True,
        )
        report = self.engine.replace_in_directory(self.tmpdir, config)

        self.assertTrue(report.dry_run)
        # Verify files were not actually modified
        with open(os.path.join(self.tmpdir, "root.txt")) as f:
            self.assertIn("old", f.read())

    def test_nonexistent_directory_raises(self):
        config = ReplaceConfig(find_pattern="a", replace_with="b")
        with self.assertRaises(FileNotFoundError):
            self.engine.replace_in_directory("/nonexistent/dir", config)

    def test_report_summary_contains_data(self):
        self._create_structure()
        config = ReplaceConfig(
            find_pattern="old",
            replace_with="new",
            create_backup=False,
        )
        report = self.engine.replace_in_directory(self.tmpdir, config)
        summary = report.summary()

        self.assertIn("old", summary)
        self.assertIn("new", summary)
        self.assertIn("REPLACEMENT REPORT", summary)


# ---------------------------------------------------------------------------
# Convenience Method Tests
# ---------------------------------------------------------------------------


class TestFindAll(unittest.TestCase):
    """Tests for the find_all method (read-only scan)."""

    def setUp(self):
        self.engine = ReplacementEngine()

    def test_find_all_occurrences(self):
        config = ReplaceConfig(find_pattern="the", replace_with="X")
        text = "the cat and the dog met the bird"
        occs = self.engine.find_all(text, config)
        self.assertEqual(len(occs), 3)
        for occ in occs:
            self.assertEqual(occ.match_text, "the")

    def test_find_all_no_match(self):
        config = ReplaceConfig(find_pattern="xyz", replace_with="X")
        occs = self.engine.find_all("hello world", config)
        self.assertEqual(len(occs), 0)


class TestCountOccurrences(unittest.TestCase):
    """Tests for the count_occurrences method."""

    def setUp(self):
        self.engine = ReplacementEngine()

    def test_count(self):
        config = ReplaceConfig(find_pattern="a", replace_with="b")
        self.assertEqual(self.engine.count_occurrences("a b a c a", config), 3)

    def test_count_zero(self):
        config = ReplaceConfig(find_pattern="z", replace_with="y")
        self.assertEqual(self.engine.count_occurrences("hello", config), 0)

    def test_count_regex(self):
        config = ReplaceConfig(
            find_pattern=r"\d+", replace_with="N", match_mode=MatchMode.REGEX
        )
        self.assertEqual(self.engine.count_occurrences("1 22 333", config), 3)


class TestPreviewReplacement(unittest.TestCase):
    """Tests for the preview_replacement method."""

    def setUp(self):
        self.engine = ReplacementEngine()

    def test_preview_shows_changes(self):
        config = ReplaceConfig(find_pattern="old", replace_with="new")
        text = "line 1\nold line 2\nline 3\nold line 4\nline 5"
        preview = self.engine.preview_replacement(text, config)
        self.assertIn("old", preview)
        self.assertIn("new", preview)
        self.assertIn("Preview:", preview)

    def test_preview_no_matches(self):
        config = ReplaceConfig(find_pattern="xyz", replace_with="abc")
        preview = self.engine.preview_replacement("hello world", config)
        self.assertEqual(preview, "No matches found.")


# ---------------------------------------------------------------------------
# Audit Log Tests
# ---------------------------------------------------------------------------


class TestAuditLog(unittest.TestCase):
    """Tests for the audit logging system."""

    def setUp(self):
        self.tmpdir = tempfile.mkdtemp()
        self.engine = ReplacementEngine()

    def tearDown(self):
        shutil.rmtree(self.tmpdir)

    def test_audit_entries_created(self):
        path = os.path.join(self.tmpdir, "test.txt")
        with open(path, "w") as f:
            f.write("old data")
        config = ReplaceConfig(
            find_pattern="old", replace_with="new", create_backup=False
        )
        self.engine.replace_in_file(path, config)

        audit = self.engine.audit_log
        self.assertGreater(len(audit), 0)
        actions = [e["action"] for e in audit]
        self.assertIn("file_replace_start", actions)
        self.assertIn("file_replace_success", actions)

    def test_audit_log_immutable_copy(self):
        path = os.path.join(self.tmpdir, "test.txt")
        with open(path, "w") as f:
            f.write("old")
        config = ReplaceConfig(
            find_pattern="old", replace_with="new", create_backup=False
        )
        self.engine.replace_in_file(path, config)

        log1 = self.engine.audit_log
        log2 = self.engine.audit_log
        self.assertEqual(len(log1), len(log2))
        # Modifying the copy should not affect the original
        log1.clear()
        self.assertGreater(len(self.engine.audit_log), 0)


# ---------------------------------------------------------------------------
# CLI Tests
# ---------------------------------------------------------------------------


class TestCLI(unittest.TestCase):
    """Tests for the command-line interface."""

    def setUp(self):
        self.tmpdir = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self.tmpdir)

    def _create_file(self, name: str, content: str) -> str:
        path = os.path.join(self.tmpdir, name)
        with open(path, "w") as f:
            f.write(content)
        return path

    def test_cli_file_replacement(self):
        path = self._create_file("test.txt", "old text old")
        exit_code = main(["--path", path, "--find", "old", "--replace", "new", "--no-backup"])
        self.assertEqual(exit_code, 0)
        with open(path) as f:
            self.assertEqual(f.read(), "new text new")

    def test_cli_dry_run(self):
        path = self._create_file("test.txt", "old text")
        exit_code = main(
            ["--path", path, "--find", "old", "--replace", "new", "--dry-run"]
        )
        self.assertEqual(exit_code, 0)
        with open(path) as f:
            self.assertEqual(f.read(), "old text")

    def test_cli_directory_replacement(self):
        self._create_file("a.txt", "hello old world")
        self._create_file("b.txt", "old again old")
        exit_code = main(
            ["--path", self.tmpdir, "--find", "old", "--replace", "new", "--no-backup"]
        )
        self.assertEqual(exit_code, 0)

    def test_cli_regex_mode(self):
        path = self._create_file("test.txt", "item 1, item 23, item 456")
        exit_code = main(
            [
                "--path", path,
                "--find", r"\d+",
                "--replace", "N",
                "--mode", "regex",
                "--no-backup",
            ]
        )
        self.assertEqual(exit_code, 0)
        with open(path) as f:
            self.assertEqual(f.read(), "item N, item N, item N")

    def test_cli_word_boundary_mode(self):
        path = self._create_file("test.txt", "var x; variable y; var z;")
        exit_code = main(
            [
                "--path", path,
                "--find", "var",
                "--replace", "const",
                "--mode", "word",
                "--no-backup",
            ]
        )
        self.assertEqual(exit_code, 0)
        with open(path) as f:
            self.assertEqual(f.read(), "const x; variable y; const z;")

    def test_cli_case_insensitive(self):
        path = self._create_file("test.txt", "Hello HELLO hello")
        exit_code = main(
            [
                "--path", path,
                "--find", "hello",
                "--replace", "HI",
                "--no-case",
                "--no-backup",
            ]
        )
        self.assertEqual(exit_code, 0)
        with open(path) as f:
            self.assertEqual(f.read(), "HI HI HI")

    def test_cli_nonexistent_path(self):
        exit_code = main(
            ["--path", "/nonexistent/path", "--find", "a", "--replace", "b"]
        )
        self.assertEqual(exit_code, 1)

    def test_cli_include_filter(self):
        self._create_file("a.py", "old code")
        self._create_file("b.txt", "old text")
        exit_code = main(
            [
                "--path", self.tmpdir,
                "--find", "old",
                "--replace", "new",
                "--include", "*.py",
                "--no-backup",
            ]
        )
        self.assertEqual(exit_code, 0)
        # Only .py file should be modified
        with open(os.path.join(self.tmpdir, "a.py")) as f:
            self.assertEqual(f.read(), "new code")
        with open(os.path.join(self.tmpdir, "b.txt")) as f:
            self.assertEqual(f.read(), "old text")


# ---------------------------------------------------------------------------
# Edge Cases
# ---------------------------------------------------------------------------


class TestEdgeCases(unittest.TestCase):
    """Tests for various edge cases."""

    def setUp(self):
        self.tmpdir = tempfile.mkdtemp()
        self.engine = ReplacementEngine()

    def tearDown(self):
        shutil.rmtree(self.tmpdir)

    def test_replace_with_longer_string(self):
        config = ReplaceConfig(find_pattern="X", replace_with="XXXXX")
        text = "aXbXc"
        result, occs = self.engine.replace_in_text(text, config)
        self.assertEqual(result, "aXXXXXbXXXXXc")
        self.assertEqual(len(occs), 2)

    def test_replace_with_shorter_string(self):
        config = ReplaceConfig(find_pattern="XXXXX", replace_with="X")
        text = "aXXXXXbXXXXXc"
        result, occs = self.engine.replace_in_text(text, config)
        self.assertEqual(result, "aXbXc")
        self.assertEqual(len(occs), 2)

    def test_unicode_content(self):
        config = ReplaceConfig(find_pattern="café", replace_with="coffee")
        text = "I love café and café mocha"
        result, occs = self.engine.replace_in_text(text, config)
        self.assertEqual(result, "I love coffee and coffee mocha")
        self.assertEqual(len(occs), 2)

    def test_unicode_in_file(self):
        path = os.path.join(self.tmpdir, "unicode.txt")
        with open(path, "w", encoding="utf-8") as f:
            f.write("Héllo wörld café\n")
        config = ReplaceConfig(find_pattern="café", replace_with="tea", create_backup=False)
        result = self.engine.replace_in_file(path, config)
        self.assertEqual(result.status, ReplacementStatus.SUCCESS)
        with open(path, encoding="utf-8") as f:
            self.assertIn("tea", f.read())

    def test_newline_only_file(self):
        path = os.path.join(self.tmpdir, "newlines.txt")
        with open(path, "w") as f:
            f.write("\n\n\n")
        config = ReplaceConfig(find_pattern="x", replace_with="y")
        result = self.engine.replace_in_file(path, config)
        self.assertEqual(result.status, ReplacementStatus.NO_MATCHES)

    def test_very_long_line(self):
        config = ReplaceConfig(find_pattern="X", replace_with="Y")
        long_line = "a" * 10000 + "X" + "b" * 10000
        result, occs = self.engine.replace_in_text(long_line, config)
        self.assertEqual(len(occs), 1)
        self.assertIn("Y", result)
        self.assertNotIn("X", result)

    def test_consecutive_replacements(self):
        """Multiple replacement operations on the same engine instance."""
        path = os.path.join(self.tmpdir, "multi.txt")
        with open(path, "w") as f:
            f.write("alpha beta gamma")

        config1 = ReplaceConfig(
            find_pattern="alpha", replace_with="ALPHA", create_backup=False
        )
        self.engine.replace_in_file(path, config1)

        config2 = ReplaceConfig(
            find_pattern="beta", replace_with="BETA", create_backup=False
        )
        self.engine.replace_in_file(path, config2)

        with open(path) as f:
            content = f.read()
        self.assertEqual(content, "ALPHA BETA gamma")

    def test_pattern_at_start_and_end(self):
        config = ReplaceConfig(find_pattern="X", replace_with="Y")
        text = "X middle X"
        result, occs = self.engine.replace_in_text(text, config)
        self.assertEqual(result, "Y middle Y")
        self.assertEqual(len(occs), 2)

    def test_entire_content_is_pattern(self):
        config = ReplaceConfig(find_pattern="all", replace_with="none")
        text = "all"
        result, occs = self.engine.replace_in_text(text, config)
        self.assertEqual(result, "none")
        self.assertEqual(len(occs), 1)


if __name__ == "__main__":
    unittest.main()
