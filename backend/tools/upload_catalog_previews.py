#!/usr/bin/env python3
"""Upload bundled catalog preview images to Supabase Storage and sync JSON URLs.

Usage (from repo root, with backend/.env configured):

    python backend/tools/upload_catalog_previews.py
    python backend/tools/upload_catalog_previews.py --write-json
    python backend/tools/upload_catalog_previews.py --dry-run

Creates/updates objects in the public ``catalog-previews`` bucket:

- templates/{template_id}_v2.jpg
- photoshoots/{style_id}_1_v2.jpg … _3_v2.jpg

With ``--write-json``, updates ``backend/app/catalog/templates.json``,
``photoshoots.json``, and bumps ``catalog_meta.json`` ``updatedAt``.
"""

from __future__ import annotations

import argparse
import json
import mimetypes
import sys
from datetime import datetime, timezone
from pathlib import Path

_BACKEND_ROOT = Path(__file__).resolve().parent.parent
_REPO_ROOT = _BACKEND_ROOT.parent
if str(_BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(_BACKEND_ROOT))

from app.config import settings  # noqa: E402
from app.services.catalog_preview_urls import (  # noqa: E402
    build_photoshoot_preview_urls,
    build_template_preview_url,
    photoshoot_preview_storage_path,
    template_preview_storage_path,
)
from app.services.image_optimize import optimize_catalog_preview_bytes  # noqa: E402
from app.services.storage_service import storage_service  # noqa: E402

_CATALOG_DIR = _BACKEND_ROOT / "app" / "catalog"
_FRONTEND_ROOT = _REPO_ROOT / "frontend"
_TEMPLATES_JSON = _CATALOG_DIR / "templates.json"
_PHOTOSHOOTS_JSON = _CATALOG_DIR / "photoshoots.json"
_META_JSON = _CATALOG_DIR / "catalog_meta.json"


def _content_type_for_file(path: Path) -> str:
    guessed, _ = mimetypes.guess_type(path.name)
    if guessed in {"image/jpeg", "image/png", "image/webp"}:
        return guessed
    return "image/jpeg"


def _resolve_local_template_file(item: dict) -> Path | None:
    for key in ("referenceAsset", "previewAsset"):
        raw = item.get(key)
        if not isinstance(raw, str) or not raw.strip():
            continue
        relative = raw.strip().replace("\\", "/")
        if not relative.startswith("assets/previews/templates/"):
            continue
        candidate = (_FRONTEND_ROOT / relative).resolve()
        if candidate.is_file():
            return candidate
    return None


def _resolve_local_photoshoot_file(style_id: str, frame_index: int) -> Path | None:
    preview_assets = item_preview_assets(style_id)
    if frame_index < len(preview_assets):
        relative = preview_assets[frame_index].strip().replace("\\", "/")
        candidate = (_FRONTEND_ROOT / relative).resolve()
        if candidate.is_file():
            return candidate
    fallback = (
        _FRONTEND_ROOT
        / "assets"
        / "previews"
        / "photoshoots"
        / f"{style_id}_{frame_index + 1}.jpg"
    )
    return fallback if fallback.is_file() else None


def _load_json_array(path: Path) -> list[dict]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, list):
        raise ValueError(f"{path} must contain a JSON array")
    return data


def item_preview_assets(style_id: str) -> list[str]:
    for item in _load_json_array(_PHOTOSHOOTS_JSON):
        if item.get("id") == style_id:
            previews = item.get("previewAssets")
            if isinstance(previews, list):
                return [str(value) for value in previews]
    return []


def upload_catalog_previews(*, dry_run: bool = False) -> tuple[int, int]:
    if not settings.supabase_url or not settings.supabase_service_role_key:
        raise RuntimeError("SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required")

    uploaded_templates = 0
    uploaded_photoshoot_frames = 0

    templates = _load_json_array(_TEMPLATES_JSON)
    for item in templates:
        template_id = str(item.get("id") or "").strip()
        if not template_id:
            continue
        local_file = _resolve_local_template_file(item)
        if local_file is None:
            print(f"[skip] template {template_id}: local preview not found")
            continue

        storage_path = template_preview_storage_path(template_id)
        content = optimize_catalog_preview_bytes(
            local_file.read_bytes(),
            _content_type_for_file(local_file),
        )[0]
        if dry_run:
            print(
                f"[dry-run] template {template_id}: {local_file} -> {storage_path} "
                f"({len(content)} bytes jpeg)"
            )
            uploaded_templates += 1
            continue

        public_url = storage_service.upload_catalog_preview_bytes(
            storage_path,
            content,
            "image/jpeg",
        )
        print(f"[ok] template {template_id}: {public_url}")
        uploaded_templates += 1

    photoshoots = _load_json_array(_PHOTOSHOOTS_JSON)
    for item in photoshoots:
        style_id = str(item.get("id") or "").strip()
        if not style_id:
            continue
        for frame_index in range(3):
            local_file = _resolve_local_photoshoot_file(style_id, frame_index)
            if local_file is None:
                print(
                    f"[skip] photoshoot {style_id} frame {frame_index + 1}: "
                    "local preview not found"
                )
                continue

            storage_path = photoshoot_preview_storage_path(style_id, frame_index)
            content = optimize_catalog_preview_bytes(
                local_file.read_bytes(),
                _content_type_for_file(local_file),
            )[0]
            if dry_run:
                print(
                    f"[dry-run] photoshoot {style_id} frame {frame_index + 1}: "
                    f"{local_file} -> {storage_path} ({len(content)} bytes jpeg)"
                )
                uploaded_photoshoot_frames += 1
                continue

            public_url = storage_service.upload_catalog_preview_bytes(
                storage_path,
                content,
                "image/jpeg",
            )
            print(f"[ok] photoshoot {style_id} frame {frame_index + 1}: {public_url}")
            uploaded_photoshoot_frames += 1

    return uploaded_templates, uploaded_photoshoot_frames


def write_catalog_json_urls() -> None:
    templates = _load_json_array(_TEMPLATES_JSON)
    for item in templates:
        template_id = str(item.get("id") or "").strip()
        if not template_id:
            continue
        preview_url = build_template_preview_url(template_id)
        item["previewUrl"] = preview_url
        item["referenceUrl"] = preview_url

    photoshoots = _load_json_array(_PHOTOSHOOTS_JSON)
    for item in photoshoots:
        style_id = str(item.get("id") or "").strip()
        if not style_id:
            continue
        item["previewUrls"] = build_photoshoot_preview_urls(style_id)

    _TEMPLATES_JSON.write_text(
        json.dumps(templates, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    _PHOTOSHOOTS_JSON.write_text(
        json.dumps(photoshoots, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    meta = {}
    if _META_JSON.is_file():
        try:
            loaded = json.loads(_META_JSON.read_text(encoding="utf-8"))
            if isinstance(loaded, dict):
                meta = loaded
        except json.JSONDecodeError:
            meta = {}

    meta.setdefault("catalogVersion", "1")
    meta["updatedAt"] = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
    _META_JSON.write_text(
        json.dumps(meta, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def sync_catalog_json_urls_only() -> None:
    """Update catalog JSON preview URLs from SUPABASE_URL without uploading."""
    if not settings.supabase_url:
        raise RuntimeError("SUPABASE_URL is required to build preview URLs")
    write_catalog_json_urls()
    print(f"[ok] synced catalog JSON URLs using bucket {settings.supabase_catalog_previews_bucket}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print upload plan without calling Supabase",
    )
    parser.add_argument(
        "--write-json",
        action="store_true",
        help="Persist previewUrl/previewUrls/referenceUrl into backend catalog JSON",
    )
    parser.add_argument(
        "--sync-json-only",
        action="store_true",
        help="Only rewrite catalog JSON URLs from SUPABASE_URL (no upload)",
    )
    args = parser.parse_args()

    if args.sync_json_only:
        sync_catalog_json_urls_only()
        return 0

    uploaded_templates, uploaded_frames = upload_catalog_previews(dry_run=args.dry_run)
    print(
        f"Done: {uploaded_templates} template previews, "
        f"{uploaded_frames} photoshoot frames"
    )

    if args.write_json and not args.dry_run:
        write_catalog_json_urls()
        print("[ok] catalog JSON updated")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
