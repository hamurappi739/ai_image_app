"""Proxy Supabase generated-images for gallery clients."""

from __future__ import annotations

import logging
from urllib.parse import urlparse

import httpx
from fastapi import HTTPException

from app.config import settings

logger = logging.getLogger(__name__)

_ALLOWED_IMAGE_MEDIA_TYPES = frozenset({"image/jpeg", "image/png", "image/webp"})
_PUBLIC_STORAGE_PREFIX = "/storage/v1/object/public/"
_UPSTREAM_TIMEOUT_SECONDS = 30.0
_CACHE_CONTROL = "public, max-age=86400"
_FALLBACK_SUPABASE_HOST = "cvzzceastvlbcxsckoqd.supabase.co"


class ImageProxyValidationError(Exception):
    def __init__(self, detail: str = "Invalid image URL") -> None:
        self.detail = detail
        super().__init__(detail)


def allowed_supabase_storage_host() -> str:
    configured = (settings.supabase_url or "").strip()
    if configured:
        host = urlparse(configured).hostname
        if host:
            return host.lower()
    return _FALLBACK_SUPABASE_HOST


def allowed_generated_images_path_prefix() -> str:
    bucket = (settings.supabase_storage_bucket or "generated-images").strip()
    return f"{_PUBLIC_STORAGE_PREFIX}{bucket}/"


def validate_image_proxy_url(url: str) -> str:
    """Return normalized URL when safe to proxy."""
    trimmed = (url or "").strip()
    if not trimmed:
        raise ImageProxyValidationError()

    parsed = urlparse(trimmed)
    if parsed.scheme != "https":
        raise ImageProxyValidationError()

    host = (parsed.hostname or "").lower()
    if not host or host != allowed_supabase_storage_host():
        raise ImageProxyValidationError()

    path = parsed.path or ""
    if not path.startswith(allowed_generated_images_path_prefix()):
        raise ImageProxyValidationError()

    return trimmed


def fetch_image_for_proxy(url: str) -> tuple[bytes, str]:
    """Download image bytes and validated content type from upstream."""
    try:
        response = httpx.get(
            url,
            timeout=_UPSTREAM_TIMEOUT_SECONDS,
            follow_redirects=True,
        )
    except httpx.HTTPError:
        logger.warning("image-proxy upstream request failed")
        raise HTTPException(status_code=502, detail="Image unavailable") from None

    if response.status_code >= 400:
        logger.warning("image-proxy upstream status=%s", response.status_code)
        raise HTTPException(status_code=502, detail="Image unavailable")

    content_type = (
        response.headers.get("content-type", "").split(";", 1)[0].strip().lower()
    )
    if content_type not in _ALLOWED_IMAGE_MEDIA_TYPES:
        logger.warning("image-proxy upstream unsupported content-type")
        raise HTTPException(status_code=502, detail="Image unavailable")

    body = response.content
    if not body:
        logger.warning("image-proxy upstream empty body")
        raise HTTPException(status_code=502, detail="Image unavailable")

    return body, content_type


def image_proxy_cache_control() -> str:
    return _CACHE_CONTROL
