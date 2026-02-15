"""Tests for filesystem utilities."""

from __future__ import annotations

from pathlib import Path

from ironforge.utils.fs import (
    clean_dir,
    collect_files,
    ensure_dir,
    file_size_human,
    is_inside,
    safe_copy,
)


class TestEnsureDir:
    def test_creates_dir(self, tmp_path: Path) -> None:
        target = tmp_path / "a" / "b" / "c"
        result = ensure_dir(target)
        assert result.is_dir()
        assert result == target

    def test_existing_dir_is_ok(self, tmp_path: Path) -> None:
        target = tmp_path / "existing"
        target.mkdir()
        result = ensure_dir(target)
        assert result.is_dir()


class TestCleanDir:
    def test_cleans_and_recreates(self, tmp_path: Path) -> None:
        target = tmp_path / "output"
        target.mkdir()
        (target / "old_file.txt").write_text("old")
        clean_dir(target)
        assert target.is_dir()
        assert list(target.iterdir()) == []

    def test_creates_if_missing(self, tmp_path: Path) -> None:
        target = tmp_path / "new_dir"
        clean_dir(target)
        assert target.is_dir()


class TestSafeCopy:
    def test_copies_file(self, tmp_path: Path) -> None:
        src = tmp_path / "source.txt"
        src.write_text("content")
        dst = tmp_path / "sub" / "dest.txt"
        result = safe_copy(src, dst)
        assert result.exists()
        assert result.read_text() == "content"


class TestCollectFiles:
    def test_collects_all(self, tmp_path: Path) -> None:
        (tmp_path / "a.py").write_text("")
        (tmp_path / "b.txt").write_text("")
        sub = tmp_path / "sub"
        sub.mkdir()
        (sub / "c.py").write_text("")
        files = collect_files(tmp_path)
        assert len(files) == 3

    def test_filter_by_extension(self, tmp_path: Path) -> None:
        (tmp_path / "a.py").write_text("")
        (tmp_path / "b.txt").write_text("")
        files = collect_files(tmp_path, extensions=[".py"])
        assert len(files) == 1
        assert files[0].suffix == ".py"

    def test_excludes_dirs(self, tmp_path: Path) -> None:
        (tmp_path / "a.py").write_text("")
        cache = tmp_path / "__pycache__"
        cache.mkdir()
        (cache / "x.pyc").write_text("")
        files = collect_files(tmp_path)
        assert all("__pycache__" not in str(f) for f in files)

    def test_nonexistent_root(self, tmp_path: Path) -> None:
        files = collect_files(tmp_path / "does_not_exist")
        assert files == []


class TestFileSizeHuman:
    def test_small_file(self, tmp_path: Path) -> None:
        f = tmp_path / "small.txt"
        f.write_text("hello")
        result = file_size_human(f)
        assert "B" in result

    def test_empty_file(self, tmp_path: Path) -> None:
        f = tmp_path / "empty.txt"
        f.touch()
        result = file_size_human(f)
        assert result == "0.0 B"


class TestIsInside:
    def test_child_is_inside(self, tmp_path: Path) -> None:
        child = tmp_path / "sub" / "file.txt"
        assert is_inside(child, tmp_path) is True

    def test_not_inside(self, tmp_path: Path) -> None:
        assert is_inside(Path("/etc"), tmp_path) is False

    def test_same_dir(self, tmp_path: Path) -> None:
        assert is_inside(tmp_path, tmp_path) is True
