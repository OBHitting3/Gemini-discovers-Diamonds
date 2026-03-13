"""Shopify integration for content validation."""

from __future__ import annotations

import logging

import httpx

from content_shield.schema.content import Content

logger = logging.getLogger(__name__)


class ShopifyIntegration:
    """Validates Shopify product and page content."""

    def __init__(self, shop_url: str, access_token: str) -> None:
        self.shop_url = shop_url.rstrip("/")
        self._client = httpx.Client(
            base_url=f"{self.shop_url}/admin/api/2024-01",
            headers={"X-Shopify-Access-Token": access_token},
        )

    def fetch_product(self, product_id: int) -> Content:
        """Fetch a Shopify product description."""
        response = self._client.get(f"/products/{product_id}.json")
        response.raise_for_status()
        product = response.json()["product"]
        return Content(
            text=product.get("body_html", ""),
            content_type="product",
            metadata={"source": "shopify", "product_id": product_id, "title": product.get("title", "")},
        )

    def fetch_products(self, limit: int = 10) -> list[Content]:
        """Fetch multiple products for batch validation."""
        response = self._client.get("/products.json", params={"limit": limit})
        response.raise_for_status()
        return [
            Content(
                text=p.get("body_html", ""),
                content_type="product",
                metadata={"source": "shopify", "product_id": p["id"], "title": p.get("title", "")},
            )
            for p in response.json().get("products", [])
        ]

    def close(self) -> None:
        """Close the HTTP client."""
        self._client.close()
