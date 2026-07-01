#!/usr/bin/env python3
"""Backfill missing gallery thumbnails for persisted Supabase generations.

Usage (from repo root, with backend/.env configured):

    python backend/tools/backfill_generation_thumbnails.py --dry-run
    python backend/tools/backfill_generation_thumbnails.py --limit 50
"""

from __future__ import annotations

import argparse
import logging
import sys
from pathlib import Path

import httpx

_BACKEND_ROOT = Path(__file__).resolve().parent.parent
if str(_BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(_BACKEND_ROOT))

from app.config import settings  # noqa: E402
from app.services.generation_thumbnail_backfill import (  # noqa: E402
    build_backfill_thumbnail_storage_path,
    is_backfill_eligible_generation_row,
    object_path_from_generated_image_url,
)
from app.services.image_optimize import generate_thumbnail_bytes  # noqa: E402
from app.services.storage_service import storage_service  # noqa: E402
from app.services.supabase_service import (  # noqa: E402
    list_generations_missing_thumbnails,
    update_generation_thumbnail_url,
)

logger = logging.getLogger("backfill_generation_thumbnails")


def _configure_logging() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format="%(levelname)s %(message)s",
    )


def _download_image_bytes(image_url: str) -> tuple[bytes, str]:
    response = httpx.get(image_url, timeout=60.0, follow_redirects=True)
    response.raise_for_status()
    content_type = (
        response.headers.get("content-type", "image/jpeg").split(";", 1)[0].strip()
    )
    return response.content, content_type or "image/jpeg"


def backfill_generation_thumbnails(
    *,
    dry_run: bool = False,
    limit: int = 100,
) -> tuple[int, int, int]:
    if not settings.supabase_url or not settings.supabase_service_role_key:
        raise RuntimeError("SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required")

    rows = list_generations_missing_thumbnails(limit=limit)
    eligible = [row for row in rows if is_backfill_eligible_generation_row(row)]
    processed = 0
    updated = 0
    skipped = 0

    logger.info(
        "Backfill start: fetched=%s eligible=%s dry_run=%s limit=%s",
        len(rows),
        len(eligible),
        dry_run,
        limit,
    )

    for row in eligible:
        generation_id = str(row.get("id") or "").strip()
        image_url = str(row.get("image_url") or "").strip()
        object_path = object_path_from_generated_image_url(image_url)
        if not generation_id or object_path is None:
            skipped += 1
            continue

        thumb_path = build_backfill_thumbnail_storage_path(object_path)
        processed += 1
        if dry_run:
            logger.info(
                "[dry-run] generation_id=%s object_path=%s thumb_path=%s",
                generation_id,
                object_path,
                thumb_path,
            )
            continue

        try:
            content, content_type = _download_image_bytes(image_url)
            thumb_bytes, thumb_type = generate_thumbnail_bytes(content, content_type)
            if not thumb_bytes:
                logger.warning(
                    "Skip generation_id=%s reason=thumbnail_generation_failed",
                    generation_id,
                )
                skipped += 1
                continue
            thumb_url = storage_service.upload_bytes(
                thumb_path,
                thumb_bytes,
                thumb_type,
            )
            update_generation_thumbnail_url(generation_id, thumb_url)
            updated += 1
            logger.info(
                "Backfill ok: generation_id=%s thumb_path=%s",
                generation_id,
                thumb_path,
            )
        except Exception:
            logger.exception(
                "Backfill failed: generation_id=%s object_path=%s",
                generation_id,
                object_path,
            )
            skipped += 1

    return processed, updated, skipped


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Log planned updates without downloading or uploading",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=100,
        help="Max generations to inspect (default: 100)",
    )
    args = parser.parse_args()
    _configure_logging()

    processed, updated, skipped = backfill_generation_thumbnails(
        dry_run=args.dry_run,
        limit=max(1, args.limit),
    )
    logger.info(
        "Backfill done: processed=%s updated=%s skipped=%s dry_run=%s",
        processed,
        updated,
        skipped,
        args.dry_run,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
