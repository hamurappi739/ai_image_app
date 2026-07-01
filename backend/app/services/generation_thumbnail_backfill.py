"""Helpers for backfilling missing generation gallery thumbnails."""

from __future__ import annotations

from datetime import datetime, timezone
from urllib.parse import urlparse

from app.services.generation_image_url import should_persist_generation_image_url
from app.services.image_proxy_service import (
    ImageProxyValidationError,
    allowed_generated_images_path_prefix,
    validate_image_proxy_url,
)


def object_path_from_generated_image_url(image_url: str) -> str | None:
    """Return storage object path (folder/file) inside the generated-images bucket."""
    trimmed = (image_url or "").strip()
    if not should_persist_generation_image_url(trimmed):
        return None
    try:
        validate_image_proxy_url(trimmed)
    except ImageProxyValidationError:
        return None

    path = urlparse(trimmed).path or ""
    prefix = allowed_generated_images_path_prefix()
    if not path.startswith(prefix):
        return None
    object_path = path[len(prefix) :].lstrip("/")
    return object_path or None


def build_backfill_thumbnail_storage_path(
    full_object_path: str,
    *,
    timestamp: str | None = None,
) -> str:
    """Place thumb JPEG next to the full image in the same user folder."""
    normalized = "/".join(
        segment for segment in (full_object_path or "").split("/") if segment
    )
    if "/" not in normalized:
        raise ValueError("full_object_path must include folder and filename")
    folder, _filename = normalized.rsplit("/", 1)
    ts = timestamp or datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    return f"{folder}/thumb-{ts}.jpg"


def is_backfill_eligible_generation_row(row: dict) -> bool:
    thumbnail_url = row.get("thumbnail_url")
    if isinstance(thumbnail_url, str) and thumbnail_url.strip():
        return False
    image_url = str(row.get("image_url") or "")
    return object_path_from_generated_image_url(image_url) is not None
