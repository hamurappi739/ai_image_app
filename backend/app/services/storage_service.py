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
import time
from datetime import datetime, timezone
from uuid import uuid4
from urllib.parse import quote

import httpx
from fastapi import HTTPException

from app.config import settings
from app.services.image_optimize import optimize_generated_image_bytes

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
_TEMP_STORAGE_RETRY_BACKOFF_SECONDS = (1.0, 2.0, 4.0)
_RETRIABLE_STORAGE_HTTP_STATUSES = frozenset({500, 502, 503})


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
    logger.warning(
        "Supabase Storage request failed: error_type=%s",
        exc.__class__.__name__,
    )
    raise HTTPException(
        status_code=503,
        detail=_STORAGE_UNAVAILABLE_DETAIL,
    ) from exc


def _temp_storage_max_attempts() -> int:
    return max(1, int(settings.kie_temp_storage_max_attempts))


def _sleep_temp_storage_backoff(attempt: int) -> None:
    index = attempt - 1
    delays = _TEMP_STORAGE_RETRY_BACKOFF_SECONDS
    if 0 <= index < len(delays):
        time.sleep(delays[index])


def _is_retriable_storage_exception(exc: Exception) -> bool:
    return isinstance(
        exc,
        (
            httpx.TimeoutException,
            httpx.ConnectError,
            httpx.TransportError,
        ),
    )


def _is_retriable_storage_http_exception(exc: HTTPException) -> bool:
    return exc.status_code in _RETRIABLE_STORAGE_HTTP_STATUSES


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
        if folder in {"generations", "photoshoots"}:
            content, content_type = optimize_generated_image_bytes(
                content, content_type
            )
        extension = _MIME_TO_EXTENSION.get(content_type)
        if extension is None:
            raise HTTPException(status_code=400, detail="Unsupported image format")
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
        _, public_url = self.upload_generated_image_data_url_with_path(
            user_id, data_url, folder=folder
        )
        return public_url

    def upload_generated_image_data_url_with_path(
        self, user_id: str, data_url: str, folder: str = "generations"
    ) -> tuple[str, str]:
        """Upload a data URL; return ``(storage_path, public_url)`` for rollback flows."""
        content_type, content = self._parse_generated_image_data_url(data_url)
        return self._upload_decoded_image(
            user_id, content, content_type, folder=folder
        )

    def delete_object_best_effort(self, path: str) -> bool:
        """Best-effort delete for photoshoot rollback; logs failures without raising."""
        try:
            base_url = _require_storage_config()
        except RuntimeError as exc:
            logger.warning("Storage delete skipped (config): reason=%s", exc)
            return False

        bucket = (self._bucket or "").strip()
        if not bucket:
            logger.warning("Storage delete skipped (bucket not configured)")
            return False

        try:
            object_path = _encode_object_path(path)
        except ValueError as exc:
            logger.warning("Storage delete skipped (invalid path): reason=%s", exc)
            return False

        url = f"{base_url}/storage/v1/object/{quote(bucket, safe='')}/{object_path}"
        headers = {
            "apikey": settings.supabase_service_role_key,
            "Authorization": f"Bearer {settings.supabase_service_role_key}",
        }
        try:
            response = httpx.delete(url, headers=headers, timeout=60.0)
        except httpx.HTTPError:
            logger.exception("Storage delete request failed")
            return False

        if response.status_code in (200, 204):
            logger.info("Storage delete ok")
            return True

        logger.warning(
            "Storage delete failed: status=%s",
            response.status_code,
        )
        return False

    def delete_objects_best_effort(self, paths: list[str]) -> None:
        """Delete multiple storage objects; never raises (photoshoot rollback only)."""
        for path in paths:
            self.delete_object_best_effort(path)

    def upload_temp_input_bytes(
        self,
        user_id: str,
        content: bytes,
        content_type: str,
        *,
        ttl_seconds: int,
    ) -> tuple[str, str]:
        """Upload to private temp bucket; return ``(storage_path, signed_url)``."""
        if content_type not in _ALLOWED_IMAGE_CONTENT_TYPES:
            raise HTTPException(status_code=400, detail="Unsupported image format")
        if len(content) > _MAX_GENERATED_IMAGE_SIZE_BYTES:
            raise HTTPException(status_code=400, detail="Image is too large")

        extension = _MIME_TO_EXTENSION[content_type]
        timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        filename = f"kie-input-{timestamp}-{uuid4().hex[:12]}.{extension}"
        path = self.build_storage_path(
            user_id=user_id,
            filename=filename,
            folder="kie-inputs",
        )
        bucket = (settings.supabase_temp_storage_bucket or "").strip()
        if not bucket:
            raise HTTPException(
                status_code=500,
                detail="SUPABASE temp storage bucket is not configured",
            )
        self._upload_temp_bytes_with_retry(bucket, path, content, content_type)
        signed_url = self._create_temp_signed_url_with_retry(
            path,
            ttl_seconds=ttl_seconds,
            bucket=bucket,
        )
        return path, signed_url

    def _upload_temp_bytes_with_retry(
        self,
        bucket: str,
        path: str,
        content: bytes,
        content_type: str,
    ) -> None:
        max_attempts = _temp_storage_max_attempts()
        pipeline_log = logging.getLogger("uvicorn.error")
        last_exc: Exception | None = None
        for attempt in range(1, max_attempts + 1):
            pipeline_log.info(
                "Template Kie temp_upload start attempt=%s/%s",
                attempt,
                max_attempts,
            )
            try:
                self._upload_bytes_to_bucket(bucket, path, content, content_type)
                pipeline_log.info(
                    "Template Kie temp_upload done attempt=%s/%s",
                    attempt,
                    max_attempts,
                )
                return
            except HTTPException as exc:
                last_exc = exc
                if not _is_retriable_storage_http_exception(exc) or attempt >= max_attempts:
                    pipeline_log.warning(
                        "Template Kie temp_upload failed stage=temp_storage_upload "
                        "attempt=%s/%s status=%s error_type=HTTPException",
                        attempt,
                        max_attempts,
                        exc.status_code,
                    )
                    raise
                pipeline_log.warning(
                    "Template Kie temp_upload retry stage=temp_storage_upload "
                    "attempt=%s/%s status=%s",
                    attempt,
                    max_attempts,
                    exc.status_code,
                )
                _sleep_temp_storage_backoff(attempt)
        if last_exc is not None:
            raise last_exc

    def _create_temp_signed_url_with_retry(
        self,
        path: str,
        *,
        ttl_seconds: int,
        bucket: str,
    ) -> str:
        max_attempts = _temp_storage_max_attempts()
        pipeline_log = logging.getLogger("uvicorn.error")
        last_exc: Exception | None = None
        for attempt in range(1, max_attempts + 1):
            pipeline_log.info(
                "Template Kie signed_url start attempt=%s/%s",
                attempt,
                max_attempts,
            )
            try:
                signed_url = self.create_signed_url(
                    path,
                    ttl_seconds=ttl_seconds,
                    bucket=bucket,
                )
                pipeline_log.info(
                    "Template Kie signed_url done attempt=%s/%s",
                    attempt,
                    max_attempts,
                )
                return signed_url
            except HTTPException as exc:
                last_exc = exc
                if not _is_retriable_storage_http_exception(exc) or attempt >= max_attempts:
                    pipeline_log.warning(
                        "Template Kie signed_url failed stage=temp_signed_url "
                        "attempt=%s/%s status=%s error_type=HTTPException",
                        attempt,
                        max_attempts,
                        exc.status_code,
                    )
                    raise
                pipeline_log.warning(
                    "Template Kie signed_url retry stage=temp_signed_url "
                    "attempt=%s/%s status=%s",
                    attempt,
                    max_attempts,
                    exc.status_code,
                )
                _sleep_temp_storage_backoff(attempt)
        if last_exc is not None:
            raise last_exc

    def upload_temp_input_data_url(
        self,
        user_id: str,
        data_url: str,
        *,
        ttl_seconds: int,
    ) -> tuple[str, str]:
        content_type, content = self._parse_generated_image_data_url(data_url)
        return self.upload_temp_input_bytes(
            user_id,
            content,
            content_type,
            ttl_seconds=ttl_seconds,
        )

    def _upload_bytes_to_bucket(
        self,
        bucket: str,
        path: str,
        content: bytes,
        content_type: str,
    ) -> None:
        try:
            base_url = _require_storage_config()
        except RuntimeError as exc:
            raise HTTPException(status_code=500, detail=str(exc)) from exc

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

    def create_signed_url(
        self,
        path: str,
        *,
        ttl_seconds: int,
        bucket: str | None = None,
    ) -> str:
        try:
            base_url = _require_storage_config()
        except RuntimeError as exc:
            raise HTTPException(status_code=500, detail=str(exc)) from exc

        target_bucket = (bucket or self._bucket or "").strip()
        if not target_bucket:
            raise HTTPException(
                status_code=500,
                detail="SUPABASE_STORAGE_BUCKET is not configured",
            )

        object_path = _encode_object_path(path)
        url = (
            f"{base_url}/storage/v1/object/sign/"
            f"{quote(target_bucket, safe='')}/{object_path}"
        )
        headers = {
            "apikey": settings.supabase_service_role_key,
            "Authorization": f"Bearer {settings.supabase_service_role_key}",
            "Content-Type": "application/json",
        }
        payload = {"expiresIn": max(60, int(ttl_seconds))}
        try:
            response = httpx.post(url, headers=headers, json=payload, timeout=60.0)
        except httpx.HTTPError as exc:
            _raise_storage_unavailable(exc)

        if response.status_code not in _UPLOAD_SUCCESS_STATUSES:
            _raise_storage_upload_failed(response)

        body = response.json()
        signed = body.get("signedURL") or body.get("signedUrl")
        if not isinstance(signed, str) or not signed.strip():
            raise HTTPException(
                status_code=500,
                detail="Supabase Storage signed URL response invalid",
            )
        signed = signed.strip()
        if signed.startswith("http://") or signed.startswith("https://"):
            return signed
        return f"{base_url}/storage/v1{signed}"

    def delete_temp_object_best_effort(self, path: str) -> bool:
        bucket = (settings.supabase_temp_storage_bucket or "").strip()
        if not bucket:
            logger.warning("Temp storage delete skipped (bucket not configured)")
            return False
        ok, _ = self._delete_object_in_bucket(
            bucket,
            path,
            compact_temp_log=True,
        )
        return ok

    def delete_temp_objects_best_effort(self, paths: list[str]) -> None:
        if not paths:
            return
        bucket = (settings.supabase_temp_storage_bucket or "").strip()
        if not bucket:
            logger.warning("Temp storage delete skipped (bucket not configured)")
            return
        failed_count = 0
        last_error_type: str | None = None
        for path in paths:
            ok, error_type = self._delete_object_in_bucket(
                bucket,
                path,
                compact_temp_log=True,
            )
            if not ok:
                failed_count += 1
                if error_type:
                    last_error_type = error_type
        if failed_count:
            logger.warning(
                "Kie temp cleanup failed: object_count=%s failed_count=%s error_type=%s",
                len(paths),
                failed_count,
                last_error_type or "delete_failed",
            )

    def _delete_object_in_bucket(
        self,
        bucket: str,
        path: str,
        *,
        compact_temp_log: bool = False,
    ) -> tuple[bool, str | None]:
        try:
            base_url = _require_storage_config()
        except RuntimeError as exc:
            logger.warning("Storage delete skipped (config): reason=%s", exc)
            return False, type(exc).__name__

        try:
            object_path = _encode_object_path(path)
        except ValueError as exc:
            logger.warning("Storage delete skipped (invalid path): reason=%s", exc)
            return False, type(exc).__name__

        url = f"{base_url}/storage/v1/object/{quote(bucket, safe='')}/{object_path}"
        headers = {
            "apikey": settings.supabase_service_role_key,
            "Authorization": f"Bearer {settings.supabase_service_role_key}",
        }
        try:
            response = httpx.delete(url, headers=headers, timeout=60.0)
        except httpx.HTTPError as exc:
            error_type = exc.__class__.__name__
            if compact_temp_log:
                logger.warning(
                    "Temp storage delete request failed: error_type=%s",
                    error_type,
                )
            else:
                logger.exception("Storage delete request failed")
            return False, error_type

        if response.status_code in (200, 204):
            if compact_temp_log:
                logger.info("Temp storage delete ok")
            else:
                logger.info("Storage delete ok")
            return True, None

        logger.warning(
            "Temp storage delete failed: status=%s",
            response.status_code,
        )
        return False, f"http_{response.status_code}"

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
