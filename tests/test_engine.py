"""Tests for the Iron Forge core engine."""

from __future__ import annotations

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from pathlib import Path

from ironforge.core.engine import (
    BuildResult,
    CleanResult,
    ProjectStatus,
    build_project,
    clean_project,
    get_project_status,
    init_project,
)


class TestInitProject:
    """Tests for the init_project engine function."""

    def test_creates_directories(self, tmp_path: Path):
        proj = tmp_path / "newproj"
        config = init_project(proj, "newproj")
        assert (proj / "src").is_dir()
        assert (proj / "dist").is_dir()
        assert (proj / "ironforge.toml").is_file()
        assert config.name == "newproj"

    def test_creates_main_file(self, tmp_path: Path):
        proj = tmp_path / "mainproj"
        init_project(proj, "mainproj")
        main = proj / "src" / "main.py"
        assert main.is_file()
        content = main.read_text()
        assert "mainproj" in content

    def test_custom_params(self, tmp_path: Path):
        proj = tmp_path / "custom"
        config = init_project(
            proj, "custom", version="5.0.0", description="desc", author="Auth", license_id="GPL-3.0"
        )
        assert config.version == "5.0.0"
        assert config.description == "desc"
        assert config.author == "Auth"
        assert config.license == "GPL-3.0"


class TestBuildProject:
    """Tests for the build_project engine function."""

    def test_build_success(self, tmp_path: Path):
        proj = tmp_path / "buildproj"
        init_project(proj, "buildproj")
        result = build_project(proj)
        assert isinstance(result, BuildResult)
        assert result.success is True
        assert len(result.artifacts) >= 1
        assert result.duration_seconds >= 0

    def test_build_no_config(self, tmp_path: Path):
        result = build_project(tmp_path)
        assert result.success is False
        assert any("ironforge.toml" in e for e in result.errors)

    def test_build_copies_to_output(self, tmp_path: Path):
        proj = tmp_path / "copyproj"
        init_project(proj, "copyproj")
        build_project(proj)
        assert (proj / "dist" / "main.py").is_file()


class TestGetProjectStatus:
    """Tests for the get_project_status engine function."""

    def test_status_with_project(self, tmp_path: Path):
        proj = tmp_path / "statusproj"
        init_project(proj, "statusproj")
        st = get_project_status(proj)
        assert isinstance(st, ProjectStatus)
        assert st.name == "statusproj"
        assert st.config_present is True
        assert st.src_dir_exists is True
        assert st.src_file_count >= 1

    def test_status_without_project(self, tmp_path: Path):
        st = get_project_status(tmp_path)
        assert st.config_present is False

    def test_status_after_build(self, tmp_path: Path):
        proj = tmp_path / "built"
        init_project(proj, "built")
        build_project(proj)
        st = get_project_status(proj)
        assert st.artifact_count >= 1


class TestCleanProject:
    """Tests for the clean_project engine function."""

    def test_clean_removes_files(self, tmp_path: Path):
        proj = tmp_path / "cleanproj"
        init_project(proj, "cleanproj")
        build_project(proj)
        result = clean_project(proj)
        assert isinstance(result, CleanResult)
        assert result.success is True
        assert result.files_removed >= 1

    def test_clean_full(self, tmp_path: Path):
        proj = tmp_path / "fullclean"
        init_project(proj, "fullclean")
        build_project(proj)
        result = clean_project(proj, full=True)
        assert result.success is True
        assert not (proj / "dist").exists()

    def test_clean_no_project(self, tmp_path: Path):
        result = clean_project(tmp_path)
        assert result.success is False

    def test_clean_idempotent(self, tmp_path: Path):
        proj = tmp_path / "idempotent"
        init_project(proj, "idempotent")
        clean_project(proj)
        result = clean_project(proj)
        assert result.success is True
        assert result.files_removed == 0
