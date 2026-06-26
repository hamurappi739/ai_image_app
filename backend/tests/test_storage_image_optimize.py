"""Tests for gallery storage image optimization."""

from __future__ import annotations

import io
import random
import unittest
from unittest.mock import ANY, patch

from PIL import Image

from app.services.image_optimize import optimize_generated_image_bytes
from app.services.storage_service import storage_service


def _make_png_bytes(width: int, height: int) -> bytes:
    data = bytes(random.randrange(256) for _ in range(width * height * 3))
    image = Image.frombytes("RGB", (width, height), data)
    buffer = io.BytesIO()
    image.save(buffer, format="PNG", compress_level=1)
    return buffer.getvalue()


class StorageImageOptimizeTests(unittest.TestCase):
    def test_large_png_converts_to_jpeg_and_shrinks(self) -> None:
        png_bytes = _make_png_bytes(1536, 2048)
        self.assertGreater(len(png_bytes), 100_000)

        optimized, content_type = optimize_generated_image_bytes(
            png_bytes,
            "image/png",
        )

        self.assertEqual(content_type, "image/jpeg")
        self.assertLess(len(optimized), len(png_bytes))
        self.assertLessEqual(len(optimized), 1_500_000)
        with Image.open(io.BytesIO(optimized)) as image:
            self.assertEqual(image.format, "JPEG")
            self.assertGreater(image.size[0], 0)
            ratio = image.size[0] / image.size[1]
            self.assertAlmostEqual(ratio, 1536 / 2048, places=2)

    def test_small_jpeg_is_left_unchanged(self) -> None:
        image = Image.new("RGB", (320, 400), color=(40, 120, 200))
        buffer = io.BytesIO()
        image.save(buffer, format="JPEG", quality=88)
        original = buffer.getvalue()

        optimized, content_type = optimize_generated_image_bytes(
            original,
            "image/jpeg",
        )

        self.assertEqual(content_type, "image/jpeg")
        self.assertEqual(optimized, original)

    @patch.object(storage_service, "upload_bytes", return_value="https://cdn.example/img.jpg")
    def test_upload_decoded_image_uses_jpeg_for_generations(
        self,
        mock_upload_bytes,
    ) -> None:
        png_bytes = _make_png_bytes(1536, 2048)

        path, public_url = storage_service._upload_decoded_image(
            "user-1",
            png_bytes,
            "image/png",
            folder="generations",
        )

        self.assertTrue(path.endswith(".jpg"))
        self.assertEqual(public_url, "https://cdn.example/img.jpg")
        mock_upload_bytes.assert_called_once()
        uploaded_content = mock_upload_bytes.call_args.args[1]
        uploaded_type = mock_upload_bytes.call_args.args[2]
        self.assertEqual(uploaded_type, "image/jpeg")
        self.assertLess(len(uploaded_content), len(png_bytes))

    @patch.object(
        storage_service,
        "upload_bytes",
        return_value="https://cdn.example/photoshoot.jpg",
    )
    def test_upload_decoded_image_uses_jpeg_for_photoshoots(
        self,
        mock_upload_bytes,
    ) -> None:
        png_bytes = _make_png_bytes(1536, 2048)

        path, public_url = storage_service._upload_decoded_image(
            "user-1",
            png_bytes,
            "image/png",
            folder="photoshoots",
        )

        self.assertTrue(path.endswith(".jpg"))
        self.assertEqual(public_url, "https://cdn.example/photoshoot.jpg")
        mock_upload_bytes.assert_called_once()
        uploaded_content = mock_upload_bytes.call_args.args[1]
        uploaded_type = mock_upload_bytes.call_args.args[2]
        self.assertEqual(uploaded_type, "image/jpeg")
        self.assertLess(len(uploaded_content), len(png_bytes))

    @patch.object(storage_service, "upload_bytes", return_value="https://cdn.example/raw.png")
    @patch(
        "app.services.storage_service.optimize_generated_image_bytes",
        side_effect=lambda content, content_type: (content, content_type),
    )
    def test_upload_decoded_image_skips_optimize_for_temp_inputs(
        self,
        _mock_optimize,
        mock_upload_bytes,
    ) -> None:
        png_bytes = _make_png_bytes(800, 1066)

        path, _ = storage_service._upload_decoded_image(
            "user-1",
            png_bytes,
            "image/png",
            folder="kie-inputs",
        )

        self.assertTrue(path.endswith(".png"))
        mock_upload_bytes.assert_called_once_with(ANY, png_bytes, "image/png")

    @patch.object(storage_service, "create_signed_url", return_value="https://signed.example/temp")
    @patch.object(storage_service, "_upload_bytes_to_bucket")
    @patch(
        "app.services.storage_service.optimize_generated_image_bytes",
    )
    def test_upload_temp_input_bytes_skips_optimize(
        self,
        mock_optimize,
        mock_upload_bucket,
        _mock_signed_url,
    ) -> None:
        png_bytes = _make_png_bytes(640, 853)

        with patch.object(storage_service, "build_storage_path", return_value="kie-inputs/u1/x.png"):
            path, _ = storage_service.upload_temp_input_bytes(
                "user-1",
                png_bytes,
                "image/png",
                ttl_seconds=3600,
            )

        self.assertTrue(path.endswith(".png"))
        mock_optimize.assert_not_called()
        mock_upload_bucket.assert_called_once()
        uploaded_content = mock_upload_bucket.call_args.args[2]
        uploaded_type = mock_upload_bucket.call_args.args[3]
        self.assertEqual(uploaded_content, png_bytes)
        self.assertEqual(uploaded_type, "image/png")


if __name__ == "__main__":
    unittest.main()
