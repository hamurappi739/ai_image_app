"""Reusable valid/invalid upload bytes for HTTP multipart tests."""

from __future__ import annotations

import io
import random

from PIL import Image


def make_test_jpeg_bytes(width: int = 512, height: int = 512) -> bytes:
    data = bytes(random.randrange(256) for _ in range(width * height * 3))
    image = Image.frombytes("RGB", (width, height), data)
    buffer = io.BytesIO()
    image.save(buffer, format="JPEG", quality=85)
    return buffer.getvalue()


def make_test_png_bytes(width: int, height: int) -> bytes:
    data = bytes(random.randrange(256) for _ in range(width * height * 3))
    image = Image.frombytes("RGB", (width, height), data)
    buffer = io.BytesIO()
    image.save(buffer, format="PNG")
    return buffer.getvalue()


VALID_TEST_JPEG_BYTES = make_test_jpeg_bytes()
VALID_TEST_PNG_BYTES = make_test_png_bytes(512, 512)
TINY_TEST_PNG_BYTES = make_test_png_bytes(1, 1)
