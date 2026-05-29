"""Supabase Storage REST helper (httpx only, no Python supabase package).

Prepared for future persistence of **generated** images in the configured bucket.
After upload, URLs should be stored in `generations.image_url`.

User-uploaded photoshoot source photos are **not** intended for long-term storage
unless a future product decision requires it.

Not wired into `/generate` or `/photoshoots/generate` yet.
"""

from __future__ import annotations

from urllib.parse import quote

import httpx

from app.config import settings

_UPLOAD_SUCCESS_STATUSES = (200, 201)


def _require_storage_config() -> str:
    if not settings.supabase_url or not settings.supabase_url.strip():
        raise RuntimeError("SUPABASE_URL is not configured")
    if not settings.supabase_service_role_key or not settings.supabase_service_role_key.strip():
        raise RuntimeError("SUPABASE_SERVICE_ROLE_KEY is not configured")
    bucket = (settings.supabase_storage_bucket or "").strip()
    if not bucket:
        raise RuntimeError("SUPABASE_STORAGE_BUCKET is not configured")
    return settings.supabase_url.rstrip("/")


def _normalize_path_segment(value: str, label: str) -> str:
    normalized = value.strip().strip("/")
    if not normalized:
        raise ValueError(f"{label} cannot be empty")
    if ".." in normalized or "/" in normalized or "\\" in normalized:
        raise ValueError(f"{label} contains invalid path characters")
    return normalized


def _encode_object_path(path: str) -> str:
    segments = [segment for segment in path.split("/") if segment]
    if not segments:
        raise ValueError("Storage path cannot be empty")
    return "/".join(quote(segment, safe="") for segment in segments)


class SupabaseStorageService:
    """Upload and resolve URLs for objects in Supabase Storage via REST API."""

    def __init__(self) -> None:
        self._bucket = settings.supabase_storage_bucket

    @property
    def bucket(self) -> str:
        return self._bucket

    def build_storage_path(
        self, user_id: str, filename: str, folder: str = "generations"
    ) -> str:
        """Build a stable object key: `{folder}/{user_id}/{filename}`."""
        safe_folder = _normalize_path_segment(folder, "folder")
        safe_user_id = _normalize_path_segment(user_id, "user_id")
        safe_filename = _normalize_path_segment(filename, "filename")
        return f"{safe_folder}/{safe_user_id}/{safe_filename}"

    def upload_bytes(self, path: str, content: bytes, content_type: str) -> str:
        """Upload bytes to Storage; returns a public object URL (see get_public_url)."""
        base_url = _require_storage_config()
        bucket = (self._bucket or "").strip()
        if not bucket:
            raise RuntimeError("SUPABASE_STORAGE_BUCKET is not configured")

        object_path = _encode_object_path(path)
        url = f"{base_url}/storage/v1/object/{quote(bucket, safe='')}/{object_path}"

        headers = {
            "apikey": settings.supabase_service_role_key,
            "Authorization": f"Bearer {settings.supabase_service_role_key}",
            "Content-Type": content_type,
            "x-upsert": "true",
        }

        response = httpx.put(url, headers=headers, content=content, timeout=60.0)
        if response.status_code not in _UPLOAD_SUCCESS_STATUSES:
            raise RuntimeError(
                f"Failed to upload to Supabase Storage (HTTP {response.status_code})"
            )

        return self.get_public_url(path)

    def get_public_url(self, path: str) -> str:
        """Public URL when the bucket is public.

        TODO: for private buckets use Storage REST signed URLs, e.g.
        POST `/storage/v1/object/sign/{bucket}/{path}` with `expiresIn`, then return
        the signed URL instead of `/object/public/...`.
        """
        base_url = _require_storage_config()
        bucket = (self._bucket or "").strip()
        if not bucket:
            raise RuntimeError("SUPABASE_STORAGE_BUCKET is not configured")

        object_path = _encode_object_path(path)
        return (
            f"{base_url}/storage/v1/object/public/"
            f"{quote(bucket, safe='')}/{object_path}"
        )


storage_service = SupabaseStorageService()
