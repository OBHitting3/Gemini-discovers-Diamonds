"""Tests for Content and ContentBatch schema models."""

from uuid import UUID

import pytest
from pydantic import ValidationError

from content_shield.schema import Content, ContentBatch, ContentType


class TestContentCreation:
    """Tests for creating Content instances."""

    def test_create_with_defaults(self):
        content = Content(text="Hello world", content_type=ContentType.BLOG)
        assert content.text == "Hello world"
        assert content.language == "en"
        assert content.metadata is None

    def test_auto_uuid_generation(self):
        c1 = Content(text="First", content_type=ContentType.EMAIL)
        c2 = Content(text="Second", content_type=ContentType.EMAIL)
        assert isinstance(c1.content_id, UUID)
        assert isinstance(c2.content_id, UUID)
        assert c1.content_id != c2.content_id

    def test_created_at_auto_populated(self):
        content = Content(text="Timestamp test", content_type=ContentType.SOCIAL)
        assert content.created_at is not None


class TestContentTypeValidation:
    """Tests for ContentType enum validation."""

    def test_valid_content_types(self):
        for ct in ContentType:
            content = Content(text="test", content_type=ct)
            assert content.content_type == ct

    def test_invalid_content_type_rejected(self):
        with pytest.raises(ValidationError):
            Content(text="test", content_type="podcast")


class TestContentBatch:
    """Tests for ContentBatch model."""

    def test_create_batch(self):
        items = [
            Content(text="Item 1", content_type=ContentType.MARKETING),
            Content(text="Item 2", content_type=ContentType.BLOG),
        ]
        batch = ContentBatch(items=items)
        assert len(batch.items) == 2

    def test_empty_batch(self):
        batch = ContentBatch(items=[])
        assert len(batch.items) == 0
