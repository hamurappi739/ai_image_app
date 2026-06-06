"""Single-image generation from uploaded photo + user description."""

from __future__ import annotations

import logging
from urllib.parse import quote

from fastapi import HTTPException
from google import genai
from google.genai import types

from app.config import settings
from app.services.image_service import (
    _extract_gemini_error_status,
    _extract_gemini_safe_message,
    _extract_image_data_url,
)

logger = logging.getLogger(__name__)

_PHOTO_GENERATION_RULES = (
    "Generate exactly ONE standalone final image based on the uploaded photo "
    "and the user description. "
    "Do not create a collage, grid, contact sheet, storyboard, split-screen, "
    "before/after comparison, or multiple variants in one image. "
    "Do not place multiple versions of the subject in the same image. "
    "Preserve the recognizable identity of the person or object from the uploaded photo. "
    "Improve quality, lighting, color, and realism with natural proportions. "
    "Avoid extra fingers, extra hands, distorted faces, or extra faces. "
    "Return a single high-quality realistic image only."
)


def _build_photo_generation_instruction(description: str) -> str:
    return (
        f"User description: {description.strip()}\n\n"
        f"{_PHOTO_GENERATION_RULES}\n\n"
        "Do not create NSFW content. Return an image only."
    )


def _photo_gemini_error_detail(exc: Exception) -> str:
    status = _extract_gemini_error_status(exc)
    message = _extract_gemini_safe_message(exc)
    if status is not None and message:
        return f"Gemini photo generation failed: status={status}, message={message}"
    if status is not None:
        return f"Gemini photo generation failed: status={status}"
    if message:
        return f"Gemini photo generation failed: message={message}"
    return "Gemini photo generation failed"


class MockPhotoGenerationProvider:
    def generate(
        self,
        description: str,
        photo_bytes: bytes,
        photo_content_type: str,
    ) -> str:
        _ = photo_bytes, photo_content_type
        label = quote("Photo generation", safe="")
        return f"https://placehold.co/1024x1024?text={label}"


class GeminiPhotoGenerationProvider:
    def generate(
        self,
        description: str,
        photo_bytes: bytes,
        photo_content_type: str,
    ) -> str:
        api_key = settings.gemini_api_key
        if not api_key or not api_key.strip():
            raise HTTPException(
                status_code=500,
                detail="GEMINI_API_KEY is not configured",
            )

        instruction = _build_photo_generation_instruction(description)
        try:
            client = genai.Client(api_key=api_key.strip())
            response = client.models.generate_content(
                model=settings.gemini_model,
                contents=[
                    types.Content(
                        role="user",
                        parts=[
                            types.Part.from_text(text=instruction),
                            types.Part.from_bytes(
                                data=photo_bytes,
                                mime_type=photo_content_type,
                            ),
                        ],
                    )
                ],
                config=types.GenerateContentConfig(
                    response_modalities=["Image"],
                ),
            )
        except HTTPException:
            raise
        except Exception as exc:
            status = _extract_gemini_error_status(exc)
            logger.warning(
                "Gemini photo generation failed: status=%s, error=%s",
                status,
                type(exc).__name__,
            )
            raise HTTPException(
                status_code=502,
                detail=_photo_gemini_error_detail(exc),
            ) from exc

        return _extract_image_data_url(response)


class PhotoGenerationService:
    def _get_provider(self) -> MockPhotoGenerationProvider | GeminiPhotoGenerationProvider:
        provider_name = settings.image_provider.strip().lower()
        if provider_name == "mock":
            return MockPhotoGenerationProvider()
        if provider_name == "gemini":
            return GeminiPhotoGenerationProvider()
        raise HTTPException(status_code=500, detail="Unsupported image provider")

    def generate(
        self,
        description: str,
        photo_bytes: bytes,
        photo_content_type: str,
    ) -> str:
        provider = self._get_provider()
        return provider.generate(
            description=description,
            photo_bytes=photo_bytes,
            photo_content_type=photo_content_type,
        )


photo_generation_service = PhotoGenerationService()
