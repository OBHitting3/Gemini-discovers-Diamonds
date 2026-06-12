"""Worker handler tests (file.write only — code.execute requires E2B)."""

import os
import tempfile
from pathlib import Path

import pytest

from karl_twin.worker.handlers import file_write


def test_file_write_inside_output_dir(tmp_path):
    os.environ["OUTPUT_DIR"] = str(tmp_path)
    res = file_write({"path": "hello.txt", "content": "hello world"})
    assert Path(res["path"]).read_text(encoding="utf-8") == "hello world"
    assert res["bytes_written"] == len("hello world")


def test_file_write_outside_output_dir_rejected(tmp_path):
    os.environ["OUTPUT_DIR"] = str(tmp_path)
    with pytest.raises(PermissionError):
        file_write({"path": str(Path(tempfile.gettempdir()) / "evil.txt"), "content": "x"})


def test_file_write_missing_path():
    with pytest.raises(ValueError):
        file_write({"content": "x"})


def test_file_write_append_mode(tmp_path):
    os.environ["OUTPUT_DIR"] = str(tmp_path)
    file_write({"path": "log.txt", "content": "one\n", "mode": "w"})
    file_write({"path": "log.txt", "content": "two\n", "mode": "a"})
    assert (tmp_path / "log.txt").read_text(encoding="utf-8") == "one\ntwo\n"
