"""Lossy re-encode for persisted gallery images (generations and photoshoots)."""

from __future__ import annotations

import logging
from io import BytesIO

from PIL import Image, ImageOps

logger = logging.getLogger(__name__)

_GENERATED_JPEG_QUALITY = 90
_GENERATED_JPEG_QUALITY_FLOOR = 82
_GENERATED_TARGET_MAX_BYTES = 1_500_000
_SKIP_OPTIMIZE_UNDER_BYTES = 450_000
_MAX_LONG_EDGE = 2048
_MIN_LONG_EDGE = 720


def optimize_generated_image_bytes(
    content: bytes,
    content_type: str,
) -> tuple[bytes, str]:
    """Convert heavy PNG/WebP outputs to JPEG for faster gallery loads.

    Used when persisting single photos and photoshoot frames to Storage.
    Keeps aspect ratio (including 3:4 portraits). Only downscales when the
    JPEG is still above the size target after quality reduction.
    """
    normalized_type = (content_type or "").strip().lower()
    if (
        normalized_type == "image/jpeg"
        and len(content) <= _SKIP_OPTIMIZE_UNDER_BYTES
    ):
        return content, "image/jpeg"

    try:
        image = Image.open(BytesIO(content))
        image = ImageOps.exif_transpose(image)
        if image.mode in ("RGBA", "LA") or (
            image.mode == "P" and "transparency" in image.info
        ):
            background = Image.new("RGB", image.size, (255, 255, 255))
            alpha = image.convert("RGBA")
            background.paste(alpha, mask=alpha.split()[-1])
            image = background
        else:
            image = image.convert("RGB")

        working = image
        quality = _GENERATED_JPEG_QUALITY
        encoded = _encode_jpeg(working, quality)

        while len(encoded) > _GENERATED_TARGET_MAX_BYTES and quality > _GENERATED_JPEG_QUALITY_FLOOR:
            quality -= 4
            encoded = _encode_jpeg(working, quality)

        long_edge = max(working.size)
        while (
            len(encoded) > _GENERATED_TARGET_MAX_BYTES
            and long_edge > _MIN_LONG_EDGE
        ):
            scale = 0.9
            new_size = (
                max(1, int(working.size[0] * scale)),
                max(1, int(working.size[1] * scale)),
            )
            working = working.resize(new_size, Image.Resampling.LANCZOS)
            long_edge = max(working.size)
            encoded = _encode_jpeg(working, quality)

        if long_edge > _MAX_LONG_EDGE:
            working.thumbnail(
                (_MAX_LONG_EDGE, _MAX_LONG_EDGE),
                Image.Resampling.LANCZOS,
            )
            encoded = _encode_jpeg(working, quality)

        if len(encoded) >= len(content) and normalized_type == "image/jpeg":
            return content, "image/jpeg"

        return encoded, "image/jpeg"
    except Exception:
        logger.exception("Generated image optimization failed; storing original bytes")
        return content, normalized_type or "application/octet-stream"


def _encode_jpeg(image: Image.Image, quality: int) -> bytes:
    buffer = BytesIO()
    image.save(
        buffer,
        format="JPEG",
        quality=quality,
        optimize=True,
        progressive=True,
    )
    return buffer.getvalue()
