"""Build public catalog preview URLs and enrich catalog JSON items."""

from __future__ import annotations

import re
from typing import Any
from urllib.parse import quote, urlparse

from app.config import settings

_CATALOG_PREVIEW_VERSION_SUFFIX = "v2"
_TEMPLATE_STORAGE_PREFIX = "templates"
_PHOTOSHOOT_STORAGE_PREFIX = "photoshoots"
_PUBLIC_OBJECT_PATH_RE = re.compile(
    r"^/storage/v1/object/public/(?P<bucket>[^/]+)/(?P<object_path>.+)$"
)


def catalog_preview_asset_version() -> str:
    return _CATALOG_PREVIEW_VERSION_SUFFIX


def template_preview_storage_path(template_id: str) -> str:
    safe_id = _normalize_catalog_id(template_id, "template_id")
    return f"{_TEMPLATE_STORAGE_PREFIX}/{safe_id}_{_CATALOG_PREVIEW_VERSION_SUFFIX}.jpg"


def photoshoot_preview_storage_path(style_id: str, frame_index: int) -> str:
    safe_id = _normalize_catalog_id(style_id, "style_id")
    if frame_index not in (0, 1, 2):
        raise ValueError("photoshoot frame_index must be 0, 1, or 2")
    return (
        f"{_PHOTOSHOOT_STORAGE_PREFIX}/"
        f"{safe_id}_{frame_index + 1}_{_CATALOG_PREVIEW_VERSION_SUFFIX}.jpg"
    )


def photoshoot_preview_storage_paths(style_id: str) -> list[str]:
    return [photoshoot_preview_storage_path(style_id, index) for index in range(3)]


def _normalize_catalog_id(value: str, label: str) -> str:
    normalized = (value or "").strip().strip("/")
    if not normalized:
        raise ValueError(f"{label} cannot be empty")
    if ".." in normalized or "/" in normalized or "\\" in normalized:
        raise ValueError(f"{label} contains invalid path characters")
    return normalized


def _catalog_previews_bucket() -> str | None:
    bucket = (settings.supabase_catalog_previews_bucket or "").strip()
    return bucket or None


def _supabase_public_base_url() -> str | None:
    base = (settings.supabase_url or "").strip().rstrip("/")
    return base or None


def build_catalog_preview_public_url(storage_path: str) -> str | None:
    base_url = _supabase_public_base_url()
    bucket = _catalog_previews_bucket()
    if base_url is None or bucket is None:
        return None

    object_path = "/".join(
        segment for segment in storage_path.split("/") if segment
    )
    if not object_path:
        return None

    encoded_path = "/".join(quote(segment, safe="") for segment in object_path.split("/"))
    return (
        f"{base_url}/storage/v1/object/public/"
        f"{quote(bucket, safe='')}/{encoded_path}"
    )


def build_template_preview_url(template_id: str) -> str | None:
    return build_catalog_preview_public_url(template_preview_storage_path(template_id))


def build_photoshoot_preview_urls(style_id: str) -> list[str]:
    urls = [
        build_catalog_preview_public_url(path)
        for path in photoshoot_preview_storage_paths(style_id)
    ]
    if any(url is None for url in urls):
        return []
    return [url for url in urls if url is not None]


def _is_non_empty_http_url(value: object) -> bool:
    if not isinstance(value, str):
        return False
    trimmed = value.strip()
    if not trimmed:
        return False
    lower = trimmed.lower()
    return lower.startswith("http://") or lower.startswith("https://")


def enrich_template_catalog_item(item: dict[str, Any]) -> dict[str, Any]:
    enriched = dict(item)
    template_id = str(item.get("id") or "").strip()
    if not template_id:
        return enriched

    preview_url = enriched.get("previewUrl")
    if not _is_current_catalog_preview_url(preview_url, template_id=template_id):
        built = build_template_preview_url(template_id)
        if built is not None:
            enriched["previewUrl"] = built

    if not _is_non_empty_http_url(enriched.get("referenceUrl")):
        reference_url = enriched.get("previewUrl")
        if _is_non_empty_http_url(reference_url):
            enriched["referenceUrl"] = reference_url

    return enriched


def enrich_photoshoot_catalog_item(item: dict[str, Any]) -> dict[str, Any]:
    enriched = dict(item)
    style_id = str(item.get("id") or "").strip()
    if not style_id:
        return enriched

    preview_urls = enriched.get("previewUrls")
    has_valid_urls = (
        isinstance(preview_urls, list)
        and len(preview_urls) >= 3
        and all(_is_non_empty_http_url(url) for url in preview_urls[:3])
        and _photoshoot_preview_urls_match_version(preview_urls[:3], style_id)
    )
    if not has_valid_urls:
        built_urls = build_photoshoot_preview_urls(style_id)
        if len(built_urls) == 3:
            enriched["previewUrls"] = built_urls

    return enriched


def _current_catalog_preview_filename_suffix() -> str:
    return f"_{_CATALOG_PREVIEW_VERSION_SUFFIX}.jpg"


def _is_current_catalog_preview_url(
    url: object,
    *,
    template_id: str | None = None,
    style_id: str | None = None,
    frame_index: int | None = None,
) -> bool:
    if not _is_non_empty_http_url(url):
        return False
    trimmed = str(url).strip()
    if not trimmed.endswith(_current_catalog_preview_filename_suffix()):
        return False
    if template_id:
        return f"/templates/{template_id}_{_CATALOG_PREVIEW_VERSION_SUFFIX}.jpg" in trimmed
    if style_id is not None and frame_index is not None:
        return (
            f"/photoshoots/{style_id}_{frame_index + 1}_"
            f"{_CATALOG_PREVIEW_VERSION_SUFFIX}.jpg"
        ) in trimmed
    return True


def _photoshoot_preview_urls_match_version(urls: list[str], style_id: str) -> bool:
    return all(
        _is_current_catalog_preview_url(
            url,
            style_id=style_id,
            frame_index=index,
        )
        for index, url in enumerate(urls[:3])
    )


def allowed_supabase_catalog_preview_host() -> str | None:
    base_url = _supabase_public_base_url()
    if base_url is None:
        return None
    parsed = urlparse(base_url)
    return parsed.hostname


def is_allowed_catalog_preview_url(url: str) -> bool:
    trimmed = (url or "").strip()
    if not _is_non_empty_http_url(trimmed):
        return False

    allowed_host = allowed_supabase_catalog_preview_host()
    if allowed_host is None:
        return False

    parsed = urlparse(trimmed)
    if parsed.scheme not in {"http", "https"}:
        return False
    if parsed.hostname != allowed_host:
        return False

    match = _PUBLIC_OBJECT_PATH_RE.match(parsed.path or "")
    if match is None:
        return False

    bucket = (settings.supabase_catalog_previews_bucket or "").strip()
    if not bucket or match.group("bucket") != bucket:
        return False

    object_path = match.group("object_path")
    if not object_path:
        return False

    allowed_prefixes = (
        f"{_TEMPLATE_STORAGE_PREFIX}/",
        f"{_PHOTOSHOOT_STORAGE_PREFIX}/",
    )
    return object_path.startswith(allowed_prefixes)


def catalog_preview_object_path_from_url(url: str) -> str | None:
    if not is_allowed_catalog_preview_url(url):
        return None
    parsed = urlparse(url.strip())
    match = _PUBLIC_OBJECT_PATH_RE.match(parsed.path or "")
    if match is None:
        return None
    return match.group("object_path")
