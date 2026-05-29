"""Photoshoot generation service (placeholder for future Gemini img2img flow)."""

from __future__ import annotations

from fastapi import HTTPException

from app.services.photoshoot_styles import PhotoshootStyle

_NOT_IMPLEMENTED_DETAIL = "Photoshoot image processing is not implemented yet"


class PhotoshootService:
    """Orchestrates photoshoot generation: style + user photo → result image URLs."""

    def generate_photoshoot(
        self,
        user_id: str,
        style: PhotoshootStyle,
        photo_bytes: bytes,
        photo_content_type: str,
    ) -> list[str]:
        """Generate photoshoot images for the given style and uploaded photo.

        Future flow (not implemented):
        - send ``photo_bytes`` + ``style.instruction`` to image provider (Gemini)
        - generate ``style.output_count`` images (default 3)
        - upload results to Supabase Storage
        - save URLs in ``generations`` / photoshoot history
        """
        _ = user_id
        _ = style
        _ = photo_bytes
        _ = photo_content_type

        # TODO: send photo + style instruction to image provider
        # TODO: generate 3 images (see style.output_count)
        # TODO: upload results to Supabase Storage
        # TODO: save results in generations / photoshoot history

        raise HTTPException(status_code=501, detail=_NOT_IMPLEMENTED_DETAIL)


photoshoot_service = PhotoshootService()
