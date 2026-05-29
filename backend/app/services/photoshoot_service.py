"""Photoshoot generation service (placeholder for future Gemini img2img flow)."""

from __future__ import annotations

from fastapi import HTTPException

from app.services.photoshoot_styles import PhotoshootStyle

_GEMINI_NOT_IMPLEMENTED_DETAIL = "Photoshoot Gemini generation is not implemented yet"


class GeminiPhotoshootProvider:
    """Placeholder provider: uploaded photo + style instruction → image data URLs."""

    def generate(
        self,
        style: PhotoshootStyle,
        photo_bytes: bytes,
        photo_content_type: str,
    ) -> list[str]:
        """Generate photoshoot images via Gemini (not implemented).

        Future flow:
        - build prompt from ``style.instruction``
        - send uploaded photo + instruction to Gemini image model
        - request ``style.output_count`` output images (default 3)
        - return image data URLs
        - (orchestrated by ``PhotoshootService``) upload results to Supabase Storage
        - save results to generations / photoshoot history
        """
        _ = style
        _ = photo_bytes
        _ = photo_content_type

        # TODO: build prompt from style.instruction
        # TODO: send uploaded photo + instruction to Gemini image model
        # TODO: request 3 output images (see style.output_count)
        # TODO: return image data URLs
        # TODO: upload results to Supabase Storage (in PhotoshootService)
        # TODO: save results to generations / photoshoot history (in PhotoshootService)

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
