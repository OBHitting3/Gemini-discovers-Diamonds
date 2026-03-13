"""Tests for URLValidator."""

import pytest

from content_shield.analyzers.url_validator import URLValidator


class TestURLValidatorFormat:
    """Tests for URL format validation."""

    def test_valid_https_url(self):
        assert URLValidator.validate("https://example.com") is True

    def test_valid_http_url(self):
        assert URLValidator.validate("http://example.com") is True

    def test_valid_url_with_path(self):
        assert URLValidator.validate("https://example.com/path/to/page") is True

    def test_invalid_url_no_scheme(self):
        assert URLValidator.validate("example.com") is False

    def test_invalid_url_garbage(self):
        assert URLValidator.validate("not a url") is False


class TestURLValidatorExtract:
    """Tests for URL extraction from text."""

    def test_extract_single_url(self):
        text = "Visit https://example.com for more."
        urls = URLValidator.extract_urls(text)
        assert len(urls) == 1
        assert "https://example.com" in urls[0]

    def test_extract_multiple_urls(self):
        text = "See https://a.com and http://b.com for details."
        urls = URLValidator.extract_urls(text)
        assert len(urls) == 2

    def test_extract_no_urls(self):
        text = "There are no URLs here."
        urls = URLValidator.extract_urls(text)
        assert urls == []
