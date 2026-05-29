"""Photoshoot generation service (placeholder for future Gemini img2img flow)."""

from __future__ import annotations

from fastapi import HTTPException

from app.config import settings
from app.services.photoshoot_styles import PhotoshootStyle

_GEMINI_NOT_IMPLEMENTED_DETAIL = "Photoshoot Gemini generation is not implemented yet"


class GeminiPhotoshootProvider:
    """Placeholder provider: uploaded photo + style instruction → image data URLs."""

    def __init__(self, output_count: int | None = None) -> None:
        self._output_count = output_count if output_count is not None else settings.photoshoot_output_count

    @property
    def output_count(self) -> int:
        return self._output_count

    def generate(
        self,
        style: PhotoshootStyle,
        photo_bytes: bytes,
        photo_content_type: str,
    ) -> list[str]:
        """Generate photoshoot images via Gemini (not implemented).

        Runtime limit: ``settings.photoshoot_output_count`` (1–3, default 1 for dev tests).
        Product target in style catalog: ``style.output_count`` (typically 3).

        Future flow:
        - build prompt from ``style.instruction``
        - send uploaded photo + instruction to Gemini image model
        - request ``self.output_count`` output images
        - return image data URLs
        - (orchestrated by ``PhotoshootService``) upload results to Supabase Storage
        - save results to generations / photoshoot history
        """
        _ = style
        _ = photo_bytes
        _ = photo_content_type
        target_count = self._output_count

        # TODO: build prompt from style.instruction
        # TODO: send uploaded photo + instruction to Gemini image model
        # TODO: request target_count images (settings.photoshoot_output_count, max 3)
        # TODO: return image data URLs (len == target_count)
        # TODO: upload results to Supabase Storage (in PhotoshootService)
        # TODO: save results to generations / photoshoot history (in PhotoshootService)
        _ = target_count

        raise HTTPException(status_code=501, detail=_GEMINI_NOT_IMPLEMENTED_DETAIL)


class PhotoshootService:
    """Orchestrates photoshoot generation: style + user photo → result image URLs."""

    def __init__(self) -> None:
        self._provider = GeminiPhotoshootProvider()

    def generate_photoshoot(
        self,
        user_id: str,
        style: PhotoshootStyle,
        photo_bytes: bytes,
        photo_content_type: str,
    ) -> list[str]:
        """Generate photoshoot images for the given style and uploaded photo.

        Returns a list of result image URLs (Storage ``public_url`` in future).
        Output count is limited by ``settings.photoshoot_output_count`` (1–3).
        Currently delegates to ``GeminiPhotoshootProvider`` which raises **501**.
        """
        _ = user_id

        # TODO: after provider returns data URLs → upload to Supabase Storage
        # TODO: save Storage URLs in generations / photoshoot history

        return self._provider.generate(
            style=style,
            photo_bytes=photo_bytes,
            photo_content_type=photo_content_type,
        )


photoshoot_service = PhotoshootService()
