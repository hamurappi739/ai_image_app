"""Tests for catalog preview JPEG optimization."""

from __future__ import annotations

import io
import random
import unittest

from PIL import Image

from app.services.image_optimize import optimize_catalog_preview_bytes


def _make_png_bytes(width: int, height: int) -> bytes:
    data = bytes(random.randrange(256) for _ in range(width * height * 3))
    image = Image.frombytes("RGB", (width, height), data)
    buffer = io.BytesIO()
    image.save(buffer, format="PNG", compress_level=1)
    return buffer.getvalue()


class CatalogPreviewOptimizeTests(unittest.TestCase):
    def test_large_preview_downscales_to_720px_jpeg(self) -> None:
        png_bytes = _make_png_bytes(1800, 2400)
        self.assertGreater(len(png_bytes), 200_000)

        optimized, content_type = optimize_catalog_preview_bytes(png_bytes, "image/png")

        self.assertEqual(content_type, "image/jpeg")
        self.assertLess(len(optimized), len(png_bytes))
        with Image.open(io.BytesIO(optimized)) as image:
            self.assertEqual(image.format, "JPEG")
            self.assertLessEqual(max(image.size), 720)

    def test_small_preview_still_returns_jpeg(self) -> None:
        image = Image.new("RGB", (640, 800), color=(120, 80, 40))
        buffer = io.BytesIO()
        image.save(buffer, format="JPEG", quality=90)
        original = buffer.getvalue()

        optimized, content_type = optimize_catalog_preview_bytes(original, "image/jpeg")

        self.assertEqual(content_type, "image/jpeg")
        with Image.open(io.BytesIO(optimized)) as result:
            self.assertEqual(result.format, "JPEG")
            self.assertLessEqual(max(result.size), 720)


if __name__ == "__main__":
    unittest.main()
