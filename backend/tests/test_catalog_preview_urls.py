"""Catalog preview URL builders and catalog API metadata."""

from __future__ import annotations

import json
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch

from fastapi.testclient import TestClient

from app.main import app
from app.services.catalog_preview_urls import (
    build_photoshoot_preview_urls,
    build_template_preview_url,
    enrich_photoshoot_catalog_item,
    enrich_template_catalog_item,
    is_allowed_catalog_preview_url,
    photoshoot_preview_storage_path,
    template_preview_storage_path,
)
from app.services.catalog_service import load_photoshoots_catalog, load_templates_catalog
from app.services.template_reference_service import (
    load_template_reference_for_catalog_item,
    load_template_reference_from_url,
    reference_url_for_template,
)

_BACKEND_ROOT = Path(__file__).resolve().parent.parent
_FRONTEND_ROOT = _BACKEND_ROOT.parent / "frontend"
_SUPABASE_HOST = "cvzzceastvlbcxsckoqd.supabase.co"
_SUPABASE_BASE = f"https://{_SUPABASE_HOST}"
_BUCKET = "catalog-previews"


def _settings_patch(mock_settings: MagicMock) -> None:
    mock_settings.supabase_url = _SUPABASE_BASE
    mock_settings.supabase_catalog_previews_bucket = _BUCKET


class CatalogPreviewUrlBuilderTests(unittest.TestCase):
    @patch("app.services.catalog_preview_urls.settings")
    def test_template_preview_storage_path(self, mock_settings: MagicMock) -> None:
        _settings_patch(mock_settings)
        self.assertEqual(
            template_preview_storage_path("business_portrait"),
            "templates/business_portrait_v1.jpg",
        )
        self.assertEqual(
            photoshoot_preview_storage_path("studio_portrait", 0),
            "photoshoots/studio_portrait_1_v1.jpg",
        )

    @patch("app.services.catalog_preview_urls.settings")
    def test_build_template_preview_url(self, mock_settings: MagicMock) -> None:
        _settings_patch(mock_settings)
        url = build_template_preview_url("product_photo")
        self.assertEqual(
            url,
            (
                f"{_SUPABASE_BASE}/storage/v1/object/public/"
                f"{_BUCKET}/templates/product_photo_v1.jpg"
            ),
        )

    @patch("app.services.catalog_preview_urls.settings")
    def test_build_photoshoot_preview_urls(self, mock_settings: MagicMock) -> None:
        _settings_patch(mock_settings)
        urls = build_photoshoot_preview_urls("studio_portrait")
        self.assertEqual(len(urls), 3)
        self.assertTrue(all(url.startswith(_SUPABASE_BASE) for url in urls))
        self.assertTrue(all("/photoshoots/studio_portrait_" in url for url in urls))

    @patch("app.services.catalog_preview_urls.settings")
    def test_enrich_template_adds_preview_and_reference_urls(
        self,
        mock_settings: MagicMock,
    ) -> None:
        _settings_patch(mock_settings)
        enriched = enrich_template_catalog_item(
            {
                "id": "ocean_portrait",
                "previewAsset": "assets/previews/templates/ocean_portrait.jpg",
                "previewUrl": None,
            }
        )
        self.assertTrue(enriched["previewUrl"].startswith("https://"))
        self.assertEqual(enriched["referenceUrl"], enriched["previewUrl"])

    @patch("app.services.catalog_preview_urls.settings")
    def test_enrich_photoshoot_adds_three_preview_urls(
        self,
        mock_settings: MagicMock,
    ) -> None:
        _settings_patch(mock_settings)
        enriched = enrich_photoshoot_catalog_item(
            {
                "id": "studio_portrait",
                "previewAssets": [],
                "previewUrls": [],
            }
        )
        self.assertEqual(len(enriched["previewUrls"]), 3)

    @patch("app.services.catalog_preview_urls.settings")
    def test_allowlist_rejects_foreign_host(self, mock_settings: MagicMock) -> None:
        _settings_patch(mock_settings)
        allowed = (
            f"{_SUPABASE_BASE}/storage/v1/object/public/"
            f"{_BUCKET}/templates/product_photo_v1.jpg"
        )
        self.assertTrue(is_allowed_catalog_preview_url(allowed))
        self.assertFalse(
            is_allowed_catalog_preview_url(
                "https://evil.example.com/storage/v1/object/public/"
                f"{_BUCKET}/templates/product_photo_v1.jpg"
            )
        )
        self.assertFalse(
            is_allowed_catalog_preview_url(
                f"{_SUPABASE_BASE}/storage/v1/object/public/generated-images/x.jpg"
            )
        )


class CatalogApiMetadataTests(unittest.TestCase):
    def setUp(self) -> None:
        self.client = TestClient(app)

    @patch("app.services.catalog_preview_urls.settings")
    def test_catalog_endpoints_include_version_metadata(
        self,
        mock_settings: MagicMock,
    ) -> None:
        _settings_patch(mock_settings)
        templates = self.client.get("/catalog/templates")
        photoshoots = self.client.get("/catalog/photoshoots")
        self.assertEqual(templates.status_code, 200)
        self.assertEqual(photoshoots.status_code, 200)

        templates_payload = templates.json()
        photoshoots_payload = photoshoots.json()
        self.assertIn("catalogVersion", templates_payload)
        self.assertIn("updatedAt", templates_payload)
        self.assertIn("catalogVersion", photoshoots_payload)
        self.assertIn("updatedAt", photoshoots_payload)

        first_template = templates_payload["items"][0]
        self.assertIn("previewUrl", first_template)
        self.assertIn("referenceUrl", first_template)

        first_photoshoot = photoshoots_payload["items"][0]
        self.assertEqual(len(first_photoshoot["previewUrls"]), 3)

    @patch("app.services.catalog_preview_urls.settings")
    def test_all_active_templates_get_preview_urls_when_supabase_configured(
        self,
        mock_settings: MagicMock,
    ) -> None:
        _settings_patch(mock_settings)
        payload = load_templates_catalog()
        for item in payload["items"]:
            self.assertTrue(
                str(item.get("previewUrl") or "").startswith("https://"),
                item.get("id"),
            )


class TemplateReferenceUrlTests(unittest.TestCase):
    @patch("app.services.catalog_preview_urls.settings")
    def test_reference_url_prefers_reference_url_over_preview_url(
        self,
        mock_settings: MagicMock,
    ) -> None:
        _settings_patch(mock_settings)
        explicit = "https://example.com/ignored.jpg"
        preview = build_template_preview_url("business_portrait")
        self.assertEqual(
            reference_url_for_template(
                {
                    "referenceUrl": explicit,
                    "previewUrl": preview,
                }
            ),
            explicit,
        )
        self.assertEqual(
            reference_url_for_template({"previewUrl": preview}),
            preview,
        )

    @patch("app.services.template_reference_service.httpx.get")
    @patch("app.services.catalog_preview_urls.settings")
    def test_remote_reference_download_with_allowlist(
        self,
        mock_settings: MagicMock,
        mock_get: MagicMock,
    ) -> None:
        _settings_patch(mock_settings)
        url = build_template_preview_url("business_portrait")
        assert url is not None
        response = MagicMock()
        response.status_code = 200
        response.content = b"\xff\xd8\xff" + b"\x00" * 16
        response.headers = {"content-type": "image/jpeg"}
        mock_get.return_value = response

        loaded = load_template_reference_from_url(url)
        self.assertIsNotNone(loaded)
        self.assertEqual(loaded[1], "image/jpeg")
        mock_get.assert_called_once()

    @patch("app.services.template_reference_service.load_template_reference_from_url")
    @patch("app.services.template_reference_service.load_template_reference_image")
    def test_catalog_item_falls_back_to_local_reference_asset(
        self,
        mock_local: MagicMock,
        mock_remote: MagicMock,
    ) -> None:
        mock_remote.return_value = None
        mock_local.return_value = (b"local-bytes", "image/jpeg")
        template = {
            "referenceUrl": f"{_SUPABASE_BASE}/storage/v1/object/public/"
            f"{_BUCKET}/templates/missing_v1.jpg",
            "referenceAsset": "assets/previews/templates/business_portrait.jpg",
        }
        loaded = load_template_reference_for_catalog_item(template)
        self.assertEqual(loaded, (b"local-bytes", "image/jpeg"))
        mock_remote.assert_called_once()
        mock_local.assert_called_once()


class CatalogJsonShapeTests(unittest.TestCase):
    def test_backend_templates_json_has_preview_fields(self) -> None:
        path = _BACKEND_ROOT / "app" / "catalog" / "templates.json"
        items = json.loads(path.read_text(encoding="utf-8"))
        self.assertTrue(items)
        for item in items:
            self.assertIn("previewAsset", item)
            self.assertIn("previewUrl", item)

    def test_backend_photoshoots_json_has_preview_urls_field(self) -> None:
        path = _BACKEND_ROOT / "app" / "catalog" / "photoshoots.json"
        items = json.loads(path.read_text(encoding="utf-8"))
        self.assertTrue(items)
        for item in items:
            self.assertIn("previewAssets", item)
            self.assertIn("previewUrls", item)


if __name__ == "__main__":
    unittest.main()
