"""Tests for catalog photoshoot preview reference resolution."""

from __future__ import annotations

import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch

from app.config import settings
from app.services.catalog_service import invalidate_photoshoot_catalog_cache
from app.services.photoshoot_reference_service import (
    PhotoshootFramePreviewReference,
    is_allowed_photoshoot_preview_url,
    load_photoshoot_preview_asset,
    normalize_photoshoot_preview_asset_path,
    resolve_photoshoot_frame_preview_reference,
)
from app.services.storage_service import storage_service

_SUPABASE_BASE = "https://cvzzceastvlbcxsckoqd.supabase.co"
_BUCKET = "catalog-previews"
_PREVIEW_URL_0 = (
    f"{_SUPABASE_BASE}/storage/v1/object/public/"
    f"{_BUCKET}/photoshoots/studio_portrait_1_v2.jpg"
)
_FRONTEND_ROOT = Path(__file__).resolve().parent.parent.parent / "frontend"


class PhotoshootPreviewUrlPolicyTests(unittest.TestCase):
    def setUp(self) -> None:
        self._saved_url = settings.supabase_url
        self._saved_bucket = settings.supabase_catalog_previews_bucket
        settings.supabase_url = _SUPABASE_BASE
        settings.supabase_catalog_previews_bucket = _BUCKET

    def tearDown(self) -> None:
        settings.supabase_url = self._saved_url
        settings.supabase_catalog_previews_bucket = self._saved_bucket

    def test_allowed_photoshoot_preview_url(self) -> None:
        self.assertTrue(is_allowed_photoshoot_preview_url(_PREVIEW_URL_0))

    def test_rejects_template_preview_url(self) -> None:
        template_url = (
            f"{_SUPABASE_BASE}/storage/v1/object/public/"
            f"{_BUCKET}/templates/business_portrait_v2.jpg"
        )
        self.assertFalse(is_allowed_photoshoot_preview_url(template_url))


class PhotoshootPreviewAssetPolicyTests(unittest.TestCase):
    def test_normalize_accepts_photoshoot_asset_path(self) -> None:
        normalized = normalize_photoshoot_preview_asset_path(
            "assets/previews/photoshoots/studio_portrait_1.jpg"
        )
        self.assertEqual(
            normalized,
            "assets/previews/photoshoots/studio_portrait_1.jpg",
        )

    def test_normalize_rejects_template_asset_path(self) -> None:
        self.assertIsNone(
            normalize_photoshoot_preview_asset_path(
                "assets/previews/templates/business_portrait.jpg"
            )
        )

    def test_load_existing_preview_asset(self) -> None:
        asset_path = "assets/previews/photoshoots/studio_portrait_1.jpg"
        file_path = _FRONTEND_ROOT / asset_path
        if not file_path.is_file():
            self.skipTest("studio_portrait preview asset not present locally")

        loaded = load_photoshoot_preview_asset(asset_path)
        self.assertIsNotNone(loaded)
        assert loaded is not None
        content, content_type = loaded
        self.assertTrue(content)
        self.assertIn(content_type, {"image/jpeg", "image/png", "image/webp"})


class PhotoshootPreviewReferenceResolveTests(unittest.TestCase):
    def setUp(self) -> None:
        self._saved_url = settings.supabase_url
        self._saved_bucket = settings.supabase_catalog_previews_bucket
        settings.supabase_url = _SUPABASE_BASE
        settings.supabase_catalog_previews_bucket = _BUCKET
        invalidate_photoshoot_catalog_cache()

    def tearDown(self) -> None:
        settings.supabase_url = self._saved_url
        settings.supabase_catalog_previews_bucket = self._saved_bucket
        invalidate_photoshoot_catalog_cache()

    def test_resolve_preview_url_for_frame_zero(self) -> None:
        ref = resolve_photoshoot_frame_preview_reference(
            style_id="studio_portrait",
            frame_index=0,
            user_id="user-1",
            ttl_seconds=3600,
        )
        self.assertEqual(ref.source, "preview_url")
        self.assertEqual(ref.input_url, _PREVIEW_URL_0)
        self.assertIsNone(ref.temp_path)

    def test_resolve_preview_url_for_each_frame_index(self) -> None:
        for frame_index in range(3):
            ref = resolve_photoshoot_frame_preview_reference(
                style_id="studio_portrait",
                frame_index=frame_index,
                user_id="user-1",
                ttl_seconds=3600,
            )
            self.assertEqual(ref.source, "preview_url")
            self.assertIn(f"studio_portrait_{frame_index + 1}_v2.jpg", ref.input_url or "")

    def test_custom_photoshoot_has_no_preview_reference(self) -> None:
        ref = resolve_photoshoot_frame_preview_reference(
            style_id="custom_photoshoot",
            frame_index=0,
            user_id="user-1",
            ttl_seconds=3600,
        )
        self.assertEqual(ref.source, "custom")
        self.assertIsNone(ref.input_url)

    @patch.object(storage_service, "upload_temp_input_bytes")
    def test_missing_preview_urls_falls_back_to_preview_asset_upload(
        self,
        mock_upload_bytes: MagicMock,
    ) -> None:
        asset_path = "assets/previews/photoshoots/studio_portrait_1.jpg"
        file_path = _FRONTEND_ROOT / asset_path
        if not file_path.is_file():
            self.skipTest("studio_portrait preview asset not present locally")

        mock_upload_bytes.return_value = ("temp/preview-0", "https://signed/preview-0")
        item = {
            "id": "test_preview_asset_style",
            "previewUrls": [],
            "previewAssets": [asset_path, asset_path, asset_path],
        }
        with patch(
            "app.services.photoshoot_reference_service.get_photoshoot_catalog_item",
            return_value=item,
        ):
            ref = resolve_photoshoot_frame_preview_reference(
                style_id="test_preview_asset_style",
                frame_index=0,
                user_id="user-1",
                ttl_seconds=3600,
            )

        self.assertEqual(ref.source, "preview_asset")
        self.assertEqual(ref.input_url, "https://signed/preview-0")
        self.assertEqual(ref.temp_path, "temp/preview-0")
        mock_upload_bytes.assert_called_once()

    def test_missing_preview_urls_and_assets_logs_warning_and_falls_back(self) -> None:
        item = {
            "id": "test_missing_preview_style",
            "previewUrls": [],
            "previewAssets": [],
        }
        with patch(
            "app.services.photoshoot_reference_service.get_photoshoot_catalog_item",
            return_value=item,
        ):
            with self.assertLogs("app.services.photoshoot_reference_service", level="WARNING") as logs:
                ref = resolve_photoshoot_frame_preview_reference(
                    style_id="test_missing_preview_style",
                    frame_index=0,
                    user_id="user-1",
                    ttl_seconds=3600,
                )

        self.assertEqual(ref.source, "missing")
        self.assertIsNone(ref.input_url)
        self.assertTrue(
            any("Photoshoot preview reference missing" in message for message in logs.output)
        )


if __name__ == "__main__":
    unittest.main()
