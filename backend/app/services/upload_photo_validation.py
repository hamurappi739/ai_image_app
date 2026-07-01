"""Validate uploaded photo bytes (dimensions and decodability)."""

from __future__ import annotations

from io import BytesIO

from fastapi import HTTPException
from PIL import Image, UnidentifiedImageError

MIN_UPLOAD_PHOTO_DIMENSION = 256


def validate_upload_image_bytes(file_bytes: bytes) -> tuple[int, int]:
    """Verify image bytes and enforce minimum dimensions."""
    if not file_bytes:
        raise HTTPException(status_code=400, detail="Invalid photo")

    try:
        with Image.open(BytesIO(file_bytes)) as image:
            image.verify()
    except (UnidentifiedImageError, OSError, SyntaxError, ValueError):
        raise HTTPException(status_code=400, detail="Invalid photo") from None

    try:
        with Image.open(BytesIO(file_bytes)) as image:
            image.load()
            width, height = image.size
    except (UnidentifiedImageError, OSError, SyntaxError, ValueError):
        raise HTTPException(status_code=400, detail="Invalid photo") from None

    if min(width, height) < MIN_UPLOAD_PHOTO_DIMENSION:
        raise HTTPException(status_code=400, detail="Photo is too small")

    return width, height
