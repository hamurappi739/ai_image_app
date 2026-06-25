"""Single-image generation from uploaded photo + user description."""

from __future__ import annotations

import logging
import time

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
    KieCreateTaskNetworkError,
    KieImageGenerationError,
    KieImageTaskClient,
    KiePollNetworkExhaustedError,
    bytes_to_data_url,
)
from app.services.mock_placeholder_urls import build_mock_photo_image_url
from app.services.storage_service import storage_service
from app.services.template_generation_service import ExtraPhotoInput

logger = logging.getLogger(__name__)
pipeline_log = logging.getLogger("uvicorn.error")

_KIE_CREATE_TASK_NETWORK_DETAIL = (
    "Kie create task network error. Retry manually; Kie API has no idempotency key support."
)

def _safe_error_reason(detail: object) -> str:
    text = str(detail).strip() if detail is not None else "unknown"
    if len(text) > 200:
        return text[:200] + "..."
    return text


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
        extra_photos: list[ExtraPhotoInput] | None = None,
        template_id: str | None = None,
    ) -> str:
        _ = photo_bytes, photo_content_type, user_id, extra_photos, template_id
        return build_mock_photo_image_url(description)


class GeminiPhotoGenerationProvider:
    def generate(
        self,
        description: str,
        photo_bytes: bytes,
        photo_content_type: str,
        *,
        user_id: str | None = None,
        extra_photos: list[ExtraPhotoInput] | None = None,
        template_id: str | None = None,
    ) -> str:
        _ = user_id, template_id
        api_key = settings.gemini_api_key
        if not api_key or not api_key.strip():
            raise HTTPException(
                status_code=500,
                detail="GEMINI_API_KEY is not configured",
            )

        instruction = build_photo_edit_instruction(
            description,
            extra_photos_count=len(extra_photos or []),
        )
        parts: list[types.Part] = [
            types.Part.from_text(text=instruction),
            types.Part.from_bytes(
                data=photo_bytes,
                mime_type=photo_content_type,
            ),
        ]
        for extra in extra_photos or []:
            parts.append(
                types.Part.from_bytes(
                    data=extra.photo_bytes,
                    mime_type=extra.photo_content_type,
                )
            )
        try:
            client = genai.Client(api_key=api_key.strip())
            response = client.models.generate_content(
                model=settings.gemini_model,
                contents=[
                    types.Content(
                        role="user",
                        parts=parts,
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
            safe_message = _extract_gemini_safe_message(exc)
            logger.warning(
                "Gemini photo generation failed: status=%s error_type=%s reason=%s "
                "extra_photos_count=%s",
                status,
                type(exc).__name__,
                safe_message or "unknown",
                len(extra_photos or []),
            )
            raise HTTPException(
                status_code=502,
                detail=_photo_gemini_error_detail(exc),
            ) from exc

        try:
            return _extract_image_data_url(response)
        except HTTPException as exc:
            if exc.status_code == 502:
                logger.warning(
                    "Gemini photo generation failed: error_type=no_image_in_response "
                    "extra_photos_count=%s reason=%s",
                    len(extra_photos or []),
                    _safe_error_reason(exc.detail),
                )
            raise


class KiePhotoGenerationProvider:
    def generate(
        self,
        description: str,
        photo_bytes: bytes,
        photo_content_type: str,
        *,
        user_id: str | None = None,
        extra_photos: list[ExtraPhotoInput] | None = None,
        template_id: str | None = None,
    ) -> str:
        if not user_id or not str(user_id).strip():
            raise HTTPException(
                status_code=500,
                detail="Kie photo generation requires user_id for temp storage",
            )

        flow_started = time.monotonic()
        temp_paths: list[str] = []
        ttl_seconds = int(settings.kie_temp_signed_url_ttl_seconds)
        instruction = append_kie_vertical_portrait_instruction(
            build_photo_edit_instruction(
                description,
                extra_photos_count=len(extra_photos or []),
            )
        )
        normalized_template_id = (template_id or "").strip() or None
        extra_count = len(extra_photos or [])

        pipeline_log.info(
            "Template Kie flow start: template_id=%s extra_photos_count=%s",
            normalized_template_id or "(none)",
            extra_count,
        )

        try:
            input_urls: list[str] = []
            uploads = [(photo_bytes, photo_content_type)]
            uploads.extend(
                (extra.photo_bytes, extra.photo_content_type)
                for extra in (extra_photos or [])
            )
            for index, (upload_bytes, upload_content_type) in enumerate(uploads, start=1):
                pipeline_log.info(
                    "Template Kie temp_upload queued: template_id=%s file_index=%s/%s",
                    normalized_template_id or "(none)",
                    index,
                    len(uploads),
                )
                temp_path, signed_url = storage_service.upload_temp_input_bytes(
                    user_id,
                    upload_bytes,
                    upload_content_type,
                    ttl_seconds=ttl_seconds,
                )
                temp_paths.append(temp_path)
                input_urls.append(signed_url)

            kie_client = KieImageTaskClient()
            pipeline_log.info(
                "Template Kie kie_create_task queued: template_id=%s input_count=%s",
                normalized_template_id or "(none)",
                len(input_urls),
            )
            try:
                image_bytes, content_type = kie_client.generate_image_bytes(
                    instruction,
                    input_urls,
                    template_id=normalized_template_id,
                )
            except KieCreateTaskNetworkError as exc:
                pipeline_log.warning(
                    "Template Kie flow failed: template_id=%s stage=kie_create_task "
                    "error_type=%s reason=network_error created_tasks_count=%s "
                    "http_calls_count=%s total_elapsed_ms=%s",
                    normalized_template_id or "(none)",
                    type(exc).__name__,
                    kie_client.created_tasks_count,
                    kie_client.http_calls_count,
                    int((time.monotonic() - flow_started) * 1000),
                )
                raise HTTPException(
                    status_code=503,
                    detail=_KIE_CREATE_TASK_NETWORK_DETAIL,
                ) from exc
            except KiePollNetworkExhaustedError as exc:
                pipeline_log.warning(
                    "Template Kie flow failed: template_id=%s stage=kie_poll "
                    "error_type=%s reason=poll_network_exhausted created_tasks_count=%s "
                    "http_calls_count=%s total_elapsed_ms=%s",
                    normalized_template_id or "(none)",
                    type(exc).__name__,
                    kie_client.created_tasks_count,
                    kie_client.http_calls_count,
                    int((time.monotonic() - flow_started) * 1000),
                )
                raise HTTPException(
                    status_code=503,
                    detail=(
                        "Kie poll network error. Retry manually; "
                        "Kie API has no idempotency key support."
                    ),
                ) from exc
            except KieImageGenerationError as exc:
                pipeline_log.warning(
                    "Template Kie flow failed: template_id=%s stage=kie_generate "
                    "error_type=%s reason=%s created_tasks_count=%s "
                    "http_calls_count=%s total_elapsed_ms=%s",
                    normalized_template_id or "(none)",
                    type(exc).__name__,
                    _safe_error_reason(exc),
                    kie_client.created_tasks_count,
                    kie_client.http_calls_count,
                    int((time.monotonic() - flow_started) * 1000),
                )
                raise HTTPException(
                    status_code=502,
                    detail="Kie photo generation failed",
                ) from exc

            pipeline_log.info(
                "Template Kie final_save done: template_id=%s created_tasks_count=%s "
                "http_calls_count=%s total_elapsed_ms=%s",
                normalized_template_id or "(none)",
                kie_client.created_tasks_count,
                kie_client.http_calls_count,
                int((time.monotonic() - flow_started) * 1000),
            )
            return bytes_to_data_url(image_bytes, content_type)
        except HTTPException as exc:
            if exc.status_code == 503:
                pipeline_log.warning(
                    "Template Kie flow failed: template_id=%s stage=temp_storage "
                    "status=503 total_elapsed_ms=%s",
                    normalized_template_id or "(none)",
                    int((time.monotonic() - flow_started) * 1000),
                )
            raise
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
        extra_photos: list[ExtraPhotoInput] | None = None,
        template_id: str | None = None,
    ) -> str:
        provider = self._get_provider()
        return provider.generate(
            description=description,
            photo_bytes=photo_bytes,
            photo_content_type=photo_content_type,
            user_id=user_id,
            extra_photos=extra_photos,
            template_id=template_id,
        )

photo_generation_service = PhotoGenerationService()
