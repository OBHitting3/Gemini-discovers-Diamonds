"""Qdrant client wrapper for the personal memory spine.

Letter-spine schema: each memory record is a single 'letter' addressed to
Karl. Payload always carries provenance + approval status; the LLM is never
allowed to write a memory that lacks provenance (schema validation gate).

Hybrid search = dense embedding + sparse (BM25-style) + metadata filter.
We use Qdrant's named vectors (one dense, one sparse) and combine via the
client's `query_points` with prefetch + fusion.
"""

from __future__ import annotations

import os
import time
import uuid
from datetime import datetime, timezone
from typing import Any, Iterable, Optional

from pydantic import BaseModel, Field, field_validator

from qdrant_client import QdrantClient
from qdrant_client.http import models as qmodels


COLLECTION = "karl_letters"
DENSE_VECTOR = "dense"
SPARSE_VECTOR = "sparse"
DENSE_SIZE = 1024  # voyage-3 / cohere-3 default; configurable per-deployment


class MemoryRecord(BaseModel):
    """Letter-memory schema. Schema validation gates on write (per spec)."""

    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    content: str
    provenance: str  # required: which run / which input / which approver
    source: str  # 'voice', 'text', 'web', 'sandbox', 'system'
    timestamp: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    confidence: float = Field(ge=0.0, le=1.0, default=1.0)
    approval_status: str = Field(default="approved")  # 'approved'|'pending'|'rejected'
    cac_score: Optional[dict[str, Any]] = None
    tags: list[str] = Field(default_factory=list)

    @field_validator("provenance")
    @classmethod
    def _provenance_required(cls, v: str) -> str:
        if not v or not v.strip():
            raise ValueError("memory provenance is required (no anonymous writes).")
        return v


def _client() -> QdrantClient:
    url = os.environ.get("QDRANT_URL", "http://localhost:6333")
    api_key = os.environ.get("QDRANT_API_KEY")
    if not api_key:
        raise RuntimeError("QDRANT_API_KEY missing; refusing to connect to Qdrant.")
    return QdrantClient(url=url, api_key=api_key, prefer_grpc=False)


def ensure_collection(dense_size: int = DENSE_SIZE) -> None:
    c = _client()
    if c.collection_exists(COLLECTION):
        return
    c.create_collection(
        collection_name=COLLECTION,
        vectors_config={
            DENSE_VECTOR: qmodels.VectorParams(
                size=dense_size,
                distance=qmodels.Distance.COSINE,
            ),
        },
        sparse_vectors_config={
            SPARSE_VECTOR: qmodels.SparseVectorParams(
                index=qmodels.SparseIndexParams(on_disk=False),
            ),
        },
    )
    # Indexes for metadata filters.
    for field, schema in [
        ("source", qmodels.PayloadSchemaType.KEYWORD),
        ("approval_status", qmodels.PayloadSchemaType.KEYWORD),
        ("tags", qmodels.PayloadSchemaType.KEYWORD),
        ("timestamp", qmodels.PayloadSchemaType.DATETIME),
    ]:
        try:
            c.create_payload_index(collection_name=COLLECTION, field_name=field, field_schema=schema)
        except Exception:
            pass


def upsert(
    record: MemoryRecord,
    dense_vector: list[float],
    sparse_vector: dict[int, float],
) -> str:
    """Schema-validated write. Caller supplies pre-computed vectors."""
    if record.approval_status not in ("approved", "pending", "rejected"):
        raise ValueError(f"invalid approval_status: {record.approval_status}")
    c = _client()
    payload = record.model_dump(mode="json")
    c.upsert(
        collection_name=COLLECTION,
        points=[
            qmodels.PointStruct(
                id=record.id,
                vector={
                    DENSE_VECTOR: dense_vector,
                    SPARSE_VECTOR: qmodels.SparseVector(
                        indices=list(sparse_vector.keys()),
                        values=list(sparse_vector.values()),
                    ),
                },
                payload=payload,
            )
        ],
    )
    return record.id


def hybrid_search(
    dense_vector: list[float],
    sparse_vector: dict[int, float],
    *,
    limit: int = 10,
    metadata_filter: Optional[dict[str, Any]] = None,
    only_approved: bool = True,
) -> list[dict[str, Any]]:
    """Dense + sparse + metadata filter, fused with RRF."""
    c = _client()

    must: list[qmodels.FieldCondition] = []
    if only_approved:
        must.append(qmodels.FieldCondition(
            key="approval_status",
            match=qmodels.MatchValue(value="approved"),
        ))
    for k, v in (metadata_filter or {}).items():
        must.append(qmodels.FieldCondition(key=k, match=qmodels.MatchValue(value=v)))
    qfilter = qmodels.Filter(must=must) if must else None

    res = c.query_points(
        collection_name=COLLECTION,
        prefetch=[
            qmodels.Prefetch(
                query=dense_vector,
                using=DENSE_VECTOR,
                limit=limit * 4,
                filter=qfilter,
            ),
            qmodels.Prefetch(
                query=qmodels.SparseVector(
                    indices=list(sparse_vector.keys()),
                    values=list(sparse_vector.values()),
                ),
                using=SPARSE_VECTOR,
                limit=limit * 4,
                filter=qfilter,
            ),
        ],
        query=qmodels.FusionQuery(fusion=qmodels.Fusion.RRF),
        limit=limit,
        with_payload=True,
    )
    return [
        {"id": str(p.id), "score": p.score, "payload": p.payload}
        for p in res.points
    ]


def health() -> dict[str, Any]:
    c = _client()
    info = c.get_collections()
    return {"ok": True, "collections": [c.name for c in info.collections]}
