"""Tests for uploaded photo byte validation."""

from __future__ import annotations

import io
import unittest
from unittest.mock import MagicMock, patch

from fastapi import HTTPException
from fastapi.testclient import TestClient

from app.auth import CurrentUser, get_current_user
from app.main import app
from app.services.upload_photo_validation import validate_upload_image_bytes
from tests.valid_upload_test_bytes import (
    TINY_TEST_PNG_BYTES,
    VALID_TEST_JPEG_BYTES,
    VALID_TEST_PNG_BYTES,
    make_test_png_bytes,
)

_TEST_USER = CurrentUser(
    id="ce38d11c-2319-4eac-adfe-46ac6d176e47",
    email="test@example.com",
)


class UploadPhotoValidationHelperTests(unittest.TestCase):
    def test_valid_jpeg_bytes_accepted(self) -> None:
        width, height = validate_upload_image_bytes(VALID_TEST_JPEG_BYTES)
        self.assertGreaterEqual(min(width, height), 256)

    def test_valid_png_bytes_accepted(self) -> None:
        width, height = validate_upload_image_bytes(VALID_TEST_PNG_BYTES)
        self.assertGreaterEqual(min(width, height), 256)

    def test_1x1_png_rejected_as_too_small(self) -> None:
        with self.assertRaises(HTTPException) as ctx:
            validate_upload_image_bytes(TINY_TEST_PNG_BYTES)
        self.assertEqual(ctx.exception.status_code, 400)
        self.assertEqual(ctx.exception.detail, "Photo is too small")

    def test_empty_bytes_rejected_as_invalid(self) -> None:
        with self.assertRaises(HTTPException) as ctx:
            validate_upload_image_bytes(b"")
        self.assertEqual(ctx.exception.status_code, 400)
        self.assertEqual(ctx.exception.detail, "Invalid photo")

    def test_corrupt_bytes_rejected_as_invalid(self) -> None:
        with self.assertRaises(HTTPException) as ctx:
            validate_upload_image_bytes(b"not-an-image")
        self.assertEqual(ctx.exception.status_code, 400)
        self.assertEqual(ctx.exception.detail, "Invalid photo")

    def test_small_but_valid_dimensions_rejected(self) -> None:
        small_png = make_test_png_bytes(255, 400)
        with self.assertRaises(HTTPException) as ctx:
            validate_upload_image_bytes(small_png)
        self.assertEqual(ctx.exception.detail, "Photo is too small")


class PhotoshootUploadValidationEndpointTests(unittest.TestCase):
    def setUp(self) -> None:
        app.dependency_overrides[get_current_user] = lambda: _TEST_USER
        self.client = TestClient(app)

    def tearDown(self) -> None:
        app.dependency_overrides.clear()

    @patch("app.main.photoshoot_service.generate_photoshoot")
    @patch("app.main.settings")
    def test_photoshoot_generate_rejects_1x1_png(
        self,
        mock_settings: MagicMock,
        mock_generate: MagicMock,
    ) -> None:
        mock_settings.enable_photoshoot_generation = True
        mock_settings.enable_credit_consumption = False

        response = self.client.post(
            "/photoshoots/generate",
            data={"style_id": "studio_portrait"},
            files={
                "photo": ("demo-photoshoot.png", io.BytesIO(TINY_TEST_PNG_BYTES), "image/png"),
            },
        )

        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.json()["detail"], "Photo is too small")
        mock_generate.assert_not_called()

    @patch("app.main.photoshoot_service.generate_photoshoot")
    @patch("app.main.settings")
    def test_photoshoot_generate_accepts_valid_jpeg(
        self,
        mock_settings: MagicMock,
        mock_generate: MagicMock,
    ) -> None:
        from app.services.photoshoot_service import PhotoshootGenerateResult

        mock_settings.enable_photoshoot_generation = True
        mock_settings.enable_credit_consumption = False
        mock_generate.return_value = PhotoshootGenerateResult(
            image_urls=["https://cdn/1.png", "https://cdn/2.png", "https://cdn/3.png"],
            photoshoot_id="ps-valid-photo",
            storage_paths=["a", "b", "c"],
        )

        response = self.client.post(
            "/photoshoots/generate",
            data={"style_id": "studio_portrait"},
            files={
                "photo": ("photo.jpg", io.BytesIO(VALID_TEST_JPEG_BYTES), "image/jpeg"),
            },
        )

        self.assertEqual(response.status_code, 200)
        mock_generate.assert_called_once()
