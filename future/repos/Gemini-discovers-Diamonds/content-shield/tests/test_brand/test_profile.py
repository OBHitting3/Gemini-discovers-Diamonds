"""Tests for BrandProfile."""

import json
import tempfile
from pathlib import Path

import pytest

from content_shield.brand.profile import BrandProfile


class TestBrandProfileCreation:
    """Tests for creating BrandProfile instances."""

    def test_create_with_defaults(self):
        profile = BrandProfile(name="TestCo")
        assert profile.name == "TestCo"
        assert profile.tone == "neutral"
        assert profile.voice_attributes == []
        assert profile.banned_words == []
        assert profile.target_audience == "general"

    def test_create_with_all_fields(self, sample_brand_profile):
        assert sample_brand_profile.name == "TestBrand"
        assert "professional" in sample_brand_profile.voice_attributes
        assert "cheap" in sample_brand_profile.banned_words
        assert sample_brand_profile.required_terminology["website"] == "platform"


class TestBrandProfileSerialization:
    """Tests for JSON serialization and deserialization."""

    def test_round_trip_json_file(self, sample_brand_profile):
        with tempfile.TemporaryDirectory() as tmpdir:
            path = Path(tmpdir) / "profile.json"
            sample_brand_profile.to_json(path)
            loaded = BrandProfile.from_json(path)
            assert loaded.name == sample_brand_profile.name
            assert loaded.banned_words == sample_brand_profile.banned_words

    def test_model_dump_roundtrip(self, sample_brand_profile):
        data = sample_brand_profile.model_dump()
        restored = BrandProfile.model_validate(data)
        assert restored == sample_brand_profile

    def test_from_json_file_not_found(self):
        with pytest.raises(FileNotFoundError):
            BrandProfile.from_json("/nonexistent/path.json")
