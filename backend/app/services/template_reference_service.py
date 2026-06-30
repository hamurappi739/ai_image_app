"""Load hidden template reference preview images for generation."""

from __future__ import annotations

import logging
import mimetypes
from pathlib import Path

import httpx

from app.services.catalog_preview_urls import is_allowed_catalog_preview_url

logger = logging.getLogger(__name__)

_ALLOWED_PREFIX = "assets/previews/templates/"
_REPO_ROOT = Path(__file__).resolve().parent.parent.parent.parent
_FRONTEND_ROOT = _REPO_ROOT / "frontend"
_MAX_REFERENCE_BYTES = 10 * 1024 * 1024
_REFERENCE_DOWNLOAD_TIMEOUT_SECONDS = 20.0


def normalize_reference_asset_path(raw: str | None) -> str | None:
    if raw is None:
        return None
    path = str(raw).strip().replace("\\", "/")
    if not path:
        return None
    if path.startswith("/") or path.startswith("file:"):
        return None
    if len(path) >= 2 and path[1] == ":":
        return None
    parts = [part for part in path.split("/") if part not in ("", ".")]
    if ".." in parts:
        return None
    normalized = "/".join(parts)
    if not normalized.startswith(_ALLOWED_PREFIX):
        return None
    return normalized


def reference_url_for_template(template: dict) -> str | None:
    reference = template.get("referenceUrl")
    if isinstance(reference, str) and reference.strip():
        return reference.strip()
    preview = template.get("previewUrl")
    if isinstance(preview, str) and preview.strip():
        return preview.strip()
    return None


def reference_asset_for_template(template: dict) -> str | None:
    reference = template.get("referenceAsset")
    if isinstance(reference, str) and reference.strip():
        return reference.strip()
    preview = template.get("previewAsset")
    if isinstance(preview, str) and preview.strip():
        return preview.strip()
    return None


def _content_type_for_path(file_path: Path) -> str:
    guessed, _ = mimetypes.guess_type(file_path.name)
    if guessed in {"image/jpeg", "image/png", "image/webp"}:
        return guessed
    return "image/jpeg"


def _content_type_for_bytes(content_type_header: str | None, url: str) -> str:
    if content_type_header:
        normalized = content_type_header.split(";", 1)[0].strip().lower()
        if normalized in {"image/jpeg", "image/png", "image/webp"}:
            return normalized
    guessed, _ = mimetypes.guess_type(url)
    if guessed in {"image/jpeg", "image/png", "image/webp"}:
        return guessed
    return "image/jpeg"


def load_template_reference_image(reference_asset: str) -> tuple[bytes, str] | None:
    normalized = normalize_reference_asset_path(reference_asset)
    if normalized is None:
        logger.warning(
            "Template reference asset rejected by path policy: %s",
            reference_asset,
        )
        return None

    file_path = (_FRONTEND_ROOT / normalized).resolve()
    try:
        file_path.relative_to(_FRONTEND_ROOT.resolve())
    except ValueError:
        logger.warning(
            "Template reference asset escaped frontend root: %s",
            reference_asset,
        )
        return None

    if not file_path.is_file():
        logger.warning(
            "Template reference asset file not found: %s",
            normalized,
        )
        return None

    try:
        file_bytes = file_path.read_bytes()
    except OSError as exc:
        logger.warning(
            "Template reference asset read failed: %s reason=%s",
            normalized,
            exc,
        )
        return None

    if len(file_bytes) > _MAX_REFERENCE_BYTES:
        logger.warning(
            "Template reference asset too large: %s bytes=%s",
            normalized,
            len(file_bytes),
        )
        return None

    return file_bytes, _content_type_for_path(file_path)


def load_template_reference_from_url(reference_url: str) -> tuple[bytes, str] | None:
    trimmed = (reference_url or "").strip()
    if not is_allowed_catalog_preview_url(trimmed):
        logger.warning(
            "Template reference URL rejected by allowlist policy: %s",
            reference_url,
        )
        return None

    try:
        response = httpx.get(trimmed, timeout=_REFERENCE_DOWNLOAD_TIMEOUT_SECONDS)
    except httpx.HTTPError as exc:
        logger.warning(
            "Template reference URL download failed: %s reason=%s",
            trimmed,
            exc,
        )
        return None

    if response.status_code != 200:
        logger.warning(
            "Template reference URL download failed: %s status=%s",
            trimmed,
            response.status_code,
        )
        return None

    file_bytes = response.content
    if not file_bytes:
        logger.warning("Template reference URL returned empty body: %s", trimmed)
        return None

    if len(file_bytes) > _MAX_REFERENCE_BYTES:
        logger.warning(
            "Template reference URL payload too large: %s bytes=%s",
            trimmed,
            len(file_bytes),
        )
        return None

    content_type = _content_type_for_bytes(response.headers.get("content-type"), trimmed)
    return file_bytes, content_type


def load_template_reference_for_catalog_item(template: dict) -> tuple[bytes, str] | None:
    reference_url = reference_url_for_template(template)
    if reference_url is not None:
        remote_reference = load_template_reference_from_url(reference_url)
        if remote_reference is not None:
            return remote_reference

    reference_asset = reference_asset_for_template(template)
    if reference_asset is None:
        return None
    return load_template_reference_image(reference_asset)
