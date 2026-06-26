"""Validate generation image URLs before persisting to Supabase."""

from __future__ import annotations

from urllib.parse import urlparse

from app.services.image_proxy_service import (
    ImageProxyValidationError,
    validate_image_proxy_url,
)

_BLOCKED_HOSTS = frozenset(
    {
        "cdn.example.com",
        "cdn.example",
        "example.com",
        "localhost",
        "127.0.0.1",
        "0.0.0.0",
        "[::1]",
    }
)


def is_blocked_generation_placeholder_url(image_url: str) -> bool:
    """True for mock/dev placeholder URLs that must not be stored in ``generations``."""
    trimmed = (image_url or "").strip()
    if not trimmed:
        return True

    lower = trimmed.lower()
    if lower.startswith("mock://"):
        return True
    if lower.startswith("data:image/"):
        return True

    parsed = urlparse(trimmed)
    scheme = (parsed.scheme or "").lower()
    if scheme not in ("http", "https"):
        return True

    host = (parsed.hostname or "").lower()
    if not host:
        return True

    if host in _BLOCKED_HOSTS:
        return True
    if host.endswith(".example.com") or host.endswith(".example"):
        return True
    if host == "placehold.co" or host.endswith(".placehold.co"):
        return True
    if "placeholder" in host:
        return True
    if host.endswith(".localhost"):
        return True

    return False


def is_supabase_generated_images_public_url(image_url: str) -> bool:
    try:
        validate_image_proxy_url(image_url)
        return True
    except ImageProxyValidationError:
        return False


def should_persist_generation_image_url(image_url: str) -> bool:
    """Only Supabase public ``generated-images`` URLs may be saved to the gallery."""
    trimmed = (image_url or "").strip()
    if not trimmed:
        return False
    if is_blocked_generation_placeholder_url(trimmed):
        return False
    return is_supabase_generated_images_public_url(trimmed)


def filter_persistable_generation_rows(rows: list[dict]) -> list[dict]:
    """Drop legacy mock/placeholder rows from API responses."""
    return [
        row
        for row in rows
        if should_persist_generation_image_url(str(row.get("image_url") or ""))
    ]
