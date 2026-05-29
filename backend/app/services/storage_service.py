"""Supabase Storage REST helper (httpx only, no Python supabase package).

Prepared for future persistence of **generated** images in the configured bucket.
After upload, URLs should be stored in `generations.image_url`.

User-uploaded photoshoot source photos are **not** intended for long-term storage
unless a future product decision requires it.

``upload_generated_image_data_url`` decodes Gemini-style data URLs and uploads
bytes to Storage. Wired into ``POST /generate`` when the provider returns a
data URL; ordinary URLs (mock placeholder) pass through unchanged.
"""

from __future__ import annotations

import base64
import binascii
import logging
import re
from datetime import datetime, timezone
from urllib.parse import quote

import httpx
from fastapi import HTTPException

from app.config import settings

logger = logging.getLogger(__name__)

_UPLOAD_SUCCESS_STATUSES = (200, 201)
_MAX_ERROR_MESSAGE_LEN = 300
_STORAGE_UNAVAILABLE_DETAIL = "Supabase Storage is temporarily unavailable"
_DATA_URL_PATTERN = re.compile(
    r"^data:(image/[a-zA-Z0-9.+-]+);base64,(?P<payload>[A-Za-z0-9+/=\s]+)$"
)
_MIME_TO_EXTENSION = {
    "image/png": "png",
    "image/jpeg": "jpg",
    "image/webp": "webp",
}
_ALLOWED_IMAGE_CONTENT_TYPES = frozenset(_MIME_TO_EXTENSION)
_MAX_GENERATED_IMAGE_SIZE_BYTES = 10 * 1024 * 1024


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


def _short_response_message(response: httpx.Response) -> str:
    text = (response.text or "").strip().replace("\n", " ").replace("\r", " ")
    if not text:
        return "empty response body"
    if len(text) <= _MAX_ERROR_MESSAGE_LEN:
        return text
    return text[:_MAX_ERROR_MESSAGE_LEN] + "..."


def _raise_storage_unavailable(exc: httpx.HTTPError) -> None:
    logger.warning("Supabase Storage request failed: %s", exc.__class__.__name__)
    raise HTTPException(
        status_code=503,
        detail=_STORAGE_UNAVAILABLE_DETAIL,
    ) from exc


def _raise_storage_upload_failed(response: httpx.Response) -> None:
    message = _short_response_message(response)
    logger.warning(
        "Supabase Storage upload failed: HTTP %s",
        response.status_code,
    )
    raise HTTPException(
        status_code=500,
        detail=(
            f"Supabase Storage upload failed: status={response.status_code}, "
            f"message={message}"
        ),
    )


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
        try:
            base_url = _require_storage_config()
        except RuntimeError as exc:
            raise HTTPException(status_code=500, detail=str(exc)) from exc

        bucket = (self._bucket or "").strip()
        if not bucket:
            raise HTTPException(
                status_code=500,
                detail="SUPABASE_STORAGE_BUCKET is not configured",
            )

        object_path = _encode_object_path(path)
        url = f"{base_url}/storage/v1/object/{quote(bucket, safe='')}/{object_path}"

        headers = {
            "apikey": settings.supabase_service_role_key,
            "Authorization": f"Bearer {settings.supabase_service_role_key}",
            "Content-Type": content_type,
            "x-upsert": "true",
        }

        try:
            response = httpx.put(
                url, headers=headers, content=content, timeout=60.0
            )
        except httpx.HTTPError as exc:
            _raise_storage_unavailable(exc)

        if response.status_code not in _UPLOAD_SUCCESS_STATUSES:
            _raise_storage_upload_failed(response)

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

    def _parse_generated_image_data_url(self, data_url: str) -> tuple[str, bytes]:
        match = _DATA_URL_PATTERN.match(data_url.strip())
        if not match:
            raise HTTPException(status_code=400, detail="Invalid image data")

        content_type = match.group(1)
        if content_type not in _ALLOWED_IMAGE_CONTENT_TYPES:
            raise HTTPException(status_code=400, detail="Unsupported image format")

        try:
            content = base64.b64decode(match.group("payload"), validate=True)
        except (ValueError, binascii.Error) as exc:
            raise HTTPException(status_code=400, detail="Invalid image data") from exc

        if not content:
            raise HTTPException(status_code=400, detail="Invalid image data")

        if len(content) > _MAX_GENERATED_IMAGE_SIZE_BYTES:
            raise HTTPException(status_code=400, detail="Image is too large")

        return content_type, content

    def _upload_decoded_image(
        self,
        user_id: str,
        content: bytes,
        content_type: str,
        folder: str = "generations",
    ) -> tuple[str, str]:
        extension = _MIME_TO_EXTENSION[content_type]
        timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        filename = f"generated-{timestamp}.{extension}"
        path = self.build_storage_path(
            user_id=user_id, filename=filename, folder=folder
        )
        public_url = self.upload_bytes(path, content, content_type)
        return path, public_url

    def upload_generated_image_data_url(
        self, user_id: str, data_url: str, folder: str = "generations"
    ) -> str:
        """Decode a generated image data URL, upload to Storage, return public URL."""
        content_type, content = self._parse_generated_image_data_url(data_url)
        _, public_url = self._upload_decoded_image(
            user_id, content, content_type, folder=folder
        )
        return public_url

    def persist_generated_image(self, user_id: str, image_url: str) -> tuple[str, str | None]:
        """Upload a generated image when ``image_url`` is a base64 data URL.

        Returns ``(final_url, storage_path)``. External URLs pass through with
        ``storage_path=None``.
        """
        if not _DATA_URL_PATTERN.match(image_url.strip()):
            return image_url, None

        content_type, content = self._parse_generated_image_data_url(image_url)
        path, public_url = self._upload_decoded_image(
            user_id, content, content_type
        )
        return public_url, path


storage_service = SupabaseStorageService()
