"""Single-image generation from uploaded photo + user description."""

from __future__ import annotations

import logging
from fastapi import HTTPException
from google import genai
from google.genai import types

from app.config import settings
from app.services.gemini_quality_instructions import build_photo_edit_instruction
from app.services.photoshoot_prompts import append_kie_vertical_portrait_instruction
from app.services.image_provider_resolver import (
    KIE_IMAGE_PROVIDER,
    resolve_template_image_provider,
)
from app.services.image_service import (
    _extract_gemini_error_status,
    _extract_gemini_safe_message,
    _extract_image_data_url,
)
from app.services.kie_image_service import (
    KieImageGenerationError,
    KieImageTaskClient,
    bytes_to_data_url,
)
from app.services.mock_placeholder_urls import build_mock_photo_image_url
from app.services.storage_service import storage_service

logger = logging.getLogger(__name__)


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
        *,
        user_id: str | None = None,
    ) -> str:
        _ = photo_bytes, photo_content_type, user_id
        return build_mock_photo_image_url(description)


class GeminiPhotoGenerationProvider:
    def generate(
        self,
        description: str,
        photo_bytes: bytes,
        photo_content_type: str,
        *,
        user_id: str | None = None,
    ) -> str:
        _ = user_id
        api_key = settings.gemini_api_key
        if not api_key or not api_key.strip():
            raise HTTPException(
                status_code=500,
                detail="GEMINI_API_KEY is not configured",
            )

        instruction = build_photo_edit_instruction(description)
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


class KiePhotoGenerationProvider:
    def generate(
        self,
        description: str,
        photo_bytes: bytes,
        photo_content_type: str,
        *,
        user_id: str | None = None,
    ) -> str:
        if not user_id or not str(user_id).strip():
            raise HTTPException(
                status_code=500,
                detail="Kie photo generation requires user_id for temp storage",
            )

        temp_paths: list[str] = []
        kie_client = KieImageTaskClient()
        ttl_seconds = int(settings.kie_temp_signed_url_ttl_seconds)
        instruction = append_kie_vertical_portrait_instruction(
            build_photo_edit_instruction(description)
        )

        try:
            temp_path, signed_url = storage_service.upload_temp_input_bytes(
                user_id,
                photo_bytes,
                photo_content_type,
                ttl_seconds=ttl_seconds,
            )
            temp_paths.append(temp_path)
            try:
                image_bytes, content_type = kie_client.generate_image_bytes(
                    instruction,
                    [signed_url],
                )
            except KieImageGenerationError as exc:
                logger.warning(
                    "Kie photo generation failed: error=%s created_tasks_count=%s",
                    type(exc).__name__,
                    kie_client.created_tasks_count,
                )
                raise HTTPException(
                    status_code=502,
                    detail="Kie photo generation failed",
                ) from exc
            return bytes_to_data_url(image_bytes, content_type)
        finally:
            storage_service.delete_temp_objects_best_effort(temp_paths)


class PhotoGenerationService:
    def _get_provider(
        self,
    ) -> MockPhotoGenerationProvider | GeminiPhotoGenerationProvider | KiePhotoGenerationProvider:
        provider_name = resolve_template_image_provider()
        if provider_name == "mock":
            return MockPhotoGenerationProvider()
        if provider_name == "gemini":
            return GeminiPhotoGenerationProvider()
        if provider_name == KIE_IMAGE_PROVIDER:
            return KiePhotoGenerationProvider()
        raise HTTPException(status_code=500, detail="Unsupported image provider")

    def generate(
        self,
        description: str,
        photo_bytes: bytes,
        photo_content_type: str,
        *,
        user_id: str | None = None,
    ) -> str:
        provider = self._get_provider()
        return provider.generate(
            description=description,
            photo_bytes=photo_bytes,
            photo_content_type=photo_content_type,
            user_id=user_id,
        )


photo_generation_service = PhotoGenerationService()
