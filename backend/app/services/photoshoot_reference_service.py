"""Resolve catalog photoshoot preview references for Kie frame generation."""

from __future__ import annotations

import logging
import mimetypes
from dataclasses import dataclass
from pathlib import Path

from app.services.catalog_preview_urls import (
    catalog_preview_object_path_from_url,
    is_allowed_catalog_preview_url,
)
from app.services.catalog_service import get_photoshoot_catalog_item
from app.services.photoshoot_style_locks import CUSTOM_PHOTOSHOOT_STYLE_ID
from app.services.storage_service import storage_service

logger = logging.getLogger(__name__)

_ALLOWED_PHOTOSHOOT_ASSET_PREFIX = "assets/previews/photoshoots/"
_REPO_ROOT = Path(__file__).resolve().parent.parent.parent.parent
_FRONTEND_ROOT = _REPO_ROOT / "frontend"
_MAX_REFERENCE_BYTES = 10 * 1024 * 1024
_PHOTOSHOOT_OBJECT_PREFIX = "photoshoots/"


@dataclass(frozen=True)
class PhotoshootFramePreviewReference:
    input_url: str | None
    source: str
    temp_path: str | None = None


def is_custom_photoshoot_style(style_id: str) -> bool:
    return (style_id or "").strip() == CUSTOM_PHOTOSHOOT_STYLE_ID


def is_allowed_photoshoot_preview_url(url: str) -> bool:
    if not is_allowed_catalog_preview_url(url):
        return False
    object_path = catalog_preview_object_path_from_url(url)
    return object_path is not None and object_path.startswith(_PHOTOSHOOT_OBJECT_PREFIX)


def normalize_photoshoot_preview_asset_path(raw: str | None) -> str | None:
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
    if not normalized.startswith(_ALLOWED_PHOTOSHOOT_ASSET_PREFIX):
        return None
    return normalized


def preview_url_for_frame(item: dict, frame_index: int) -> str | None:
    preview_urls = item.get("previewUrls")
    if not isinstance(preview_urls, list) or frame_index < 0 or frame_index >= len(preview_urls):
        return None
    candidate = preview_urls[frame_index]
    if not isinstance(candidate, str):
        return None
    trimmed = candidate.strip()
    return trimmed or None


def preview_asset_for_frame(item: dict, frame_index: int) -> str | None:
    preview_assets = item.get("previewAssets")
    if not isinstance(preview_assets, list) or frame_index < 0 or frame_index >= len(preview_assets):
        return None
    candidate = preview_assets[frame_index]
    if not isinstance(candidate, str):
        return None
    trimmed = candidate.strip()
    return trimmed or None


def _content_type_for_path(file_path: Path) -> str:
    guessed, _ = mimetypes.guess_type(file_path.name)
    if guessed in {"image/jpeg", "image/png", "image/webp"}:
        return guessed
    return "image/jpeg"


def load_photoshoot_preview_asset(asset_path: str) -> tuple[bytes, str] | None:
    normalized = normalize_photoshoot_preview_asset_path(asset_path)
    if normalized is None:
        logger.warning(
            "Photoshoot preview asset rejected by path policy: %s",
            asset_path,
        )
        return None

    file_path = (_FRONTEND_ROOT / normalized).resolve()
    try:
        file_path.relative_to(_FRONTEND_ROOT.resolve())
    except ValueError:
        logger.warning(
            "Photoshoot preview asset escaped frontend root: %s",
            asset_path,
        )
        return None

    if not file_path.is_file():
        logger.warning(
            "Photoshoot preview asset file not found: %s",
            normalized,
        )
        return None

    content = file_path.read_bytes()
    if not content:
        logger.warning(
            "Photoshoot preview asset is empty: %s",
            normalized,
        )
        return None
    if len(content) > _MAX_REFERENCE_BYTES:
        logger.warning(
            "Photoshoot preview asset exceeds size limit: %s",
            normalized,
        )
        return None

    return content, _content_type_for_path(file_path)


def resolve_photoshoot_frame_preview_reference(
    *,
    style_id: str,
    frame_index: int,
    user_id: str,
    ttl_seconds: int,
) -> PhotoshootFramePreviewReference:
    normalized_style_id = (style_id or "").strip()
    if is_custom_photoshoot_style(normalized_style_id):
        return PhotoshootFramePreviewReference(None, "custom", None)

    item = get_photoshoot_catalog_item(normalized_style_id)
    if item is None:
        logger.warning(
            "Photoshoot preview reference missing: style_id=%s frame_index=%s",
            normalized_style_id,
            frame_index,
        )
        return PhotoshootFramePreviewReference(None, "missing", None)

    preview_url = preview_url_for_frame(item, frame_index)
    if preview_url and is_allowed_photoshoot_preview_url(preview_url):
        logger.info(
            "Photoshoot preview reference resolved: style_id=%s frame_index=%s source=preview_url",
            normalized_style_id,
            frame_index,
        )
        return PhotoshootFramePreviewReference(preview_url, "preview_url", None)

    preview_asset = preview_asset_for_frame(item, frame_index)
    if preview_asset:
        loaded = load_photoshoot_preview_asset(preview_asset)
        if loaded is not None:
            content, content_type = loaded
            try:
                temp_path, signed_url = storage_service.upload_temp_input_bytes(
                    user_id,
                    content,
                    content_type,
                    ttl_seconds=ttl_seconds,
                )
            except Exception:
                logger.warning(
                    "Photoshoot preview reference missing: style_id=%s frame_index=%s",
                    normalized_style_id,
                    frame_index,
                )
                return PhotoshootFramePreviewReference(None, "missing", None)

            logger.info(
                "Photoshoot preview reference resolved: style_id=%s frame_index=%s source=preview_asset",
                normalized_style_id,
                frame_index,
            )
            return PhotoshootFramePreviewReference(
                signed_url,
                "preview_asset",
                temp_path,
            )

    logger.warning(
        "Photoshoot preview reference missing: style_id=%s frame_index=%s",
        normalized_style_id,
        frame_index,
    )
    return PhotoshootFramePreviewReference(None, "missing", None)


def resolve_photoshoot_preview_references_for_session(
    *,
    style_id: str,
    output_count: int,
    user_id: str,
    ttl_seconds: int,
) -> list[PhotoshootFramePreviewReference]:
    return [
        resolve_photoshoot_frame_preview_reference(
            style_id=style_id,
            frame_index=frame_index,
            user_id=user_id,
            ttl_seconds=ttl_seconds,
        )
        for frame_index in range(output_count)
    ]
