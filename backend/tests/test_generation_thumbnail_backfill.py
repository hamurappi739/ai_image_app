"""Tests for generation thumbnail backfill helpers."""

from __future__ import annotations

import unittest
from unittest.mock import patch

from app.services.generation_thumbnail_backfill import (
    build_backfill_thumbnail_storage_path,
    is_backfill_eligible_generation_row,
    object_path_from_generated_image_url,
)

_HOST = "cvzzceastvlbcxsckoqd.supabase.co"
_IMAGE_URL = (
    f"https://{_HOST}/storage/v1/object/public/"
    "generated-images/generations/user-1/generated-20260529T120000Z.jpg"
)


class GenerationThumbnailBackfillTests(unittest.TestCase):
    @patch("app.services.image_proxy_service.settings")
    def test_object_path_from_generated_image_url(self, mock_settings) -> None:
        mock_settings.supabase_url = f"https://{_HOST}"
        mock_settings.supabase_storage_bucket = "generated-images"

        self.assertEqual(
            object_path_from_generated_image_url(_IMAGE_URL),
            "generations/user-1/generated-20260529T120000Z.jpg",
        )
        self.assertIsNone(object_path_from_generated_image_url("https://cdn.example.com/a.jpg"))

    def test_build_backfill_thumbnail_storage_path(self) -> None:
        self.assertEqual(
            build_backfill_thumbnail_storage_path(
                "generations/user-1/generated-20260529T120000Z.jpg",
                timestamp="20260529T150000Z",
            ),
            "generations/user-1/thumb-20260529T150000Z.jpg",
        )

    @patch("app.services.image_proxy_service.settings")
    def test_is_backfill_eligible_generation_row(self, mock_settings) -> None:
        mock_settings.supabase_url = f"https://{_HOST}"
        mock_settings.supabase_storage_bucket = "generated-images"

        self.assertTrue(
            is_backfill_eligible_generation_row(
                {"id": "g1", "image_url": _IMAGE_URL, "thumbnail_url": None},
            )
        )
        self.assertFalse(
            is_backfill_eligible_generation_row(
                {
                    "id": "g2",
                    "image_url": _IMAGE_URL,
                    "thumbnail_url": "https://example.com/thumb.jpg",
                },
            )
        )


if __name__ == "__main__":
    unittest.main()
