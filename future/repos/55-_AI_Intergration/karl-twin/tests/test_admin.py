"""Admin kill-switch CLI."""

from pathlib import Path

from karl_twin.admin.__main__ import main as admin_main, PAUSE_FLAG


def test_pause_creates_flag():
    if PAUSE_FLAG.exists():
        PAUSE_FLAG.unlink()
    rc = admin_main(["pause"])
    assert rc == 0
    assert PAUSE_FLAG.exists()


def test_resume_removes_flag():
    PAUSE_FLAG.parent.mkdir(parents=True, exist_ok=True)
    PAUSE_FLAG.write_text("paused")
    rc = admin_main(["resume"])
    assert rc == 0
    assert not PAUSE_FLAG.exists()


def test_status_runs_clean(capsys):
    rc = admin_main(["status"])
    assert rc == 0
    out = capsys.readouterr().out
    assert "paused:" in out
