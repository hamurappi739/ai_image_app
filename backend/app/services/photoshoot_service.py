"""Photoshoot generation service: uploaded photo + style → mock or Gemini → history."""

from __future__ import annotations

import logging
import re
import time
from dataclasses import dataclass
from typing import TypeAlias
from uuid import uuid4

import httpx
from fastapi import HTTPException
from google import genai
from google.genai import types

from app.config import settings
from app.services.image_service import (
    _blob_to_data_url,
    _extract_gemini_error_status,
    _extract_gemini_safe_message,
    _iter_response_parts,
)
from app.services.mock_placeholder_urls import build_mock_photoshoot_image_urls
from app.services.photoshoot_prompts import build_photoshoot_frame_prompt
from app.services.photoshoot_styles import PhotoshootStyle
from app.services.storage_service import storage_service
from app.services.supabase_service import (
    create_generation_record,
    delete_generations_by_photoshoot_id,
)

logger = logging.getLogger(__name__)

_MAX_PHOTOSHOOT_DIAGNOSTIC_TEXT_LEN = 200
_MAX_GEMINI_FRAME_ATTEMPTS = 3
_GEMINI_FRAME_RETRY_DELAY_SECONDS = 1.75
_PHOTOSHOOT_FAILURE_MESSAGE = "Photoshoot generation failed, please retry"
_RETRYABLE_GEMINI_HTTP_STATUS_CODES = frozenset({429, 500, 502, 503, 504})
_NON_RETRYABLE_GEMINI_HTTP_STATUS_CODES = frozenset({400, 401, 403})
_RETRYABLE_TRANSPORT_ERRORS = (
    httpx.TimeoutException,
    httpx.ConnectError,
    httpx.TransportError,
)
ReferenceImage: TypeAlias = tuple[bytes, str]
_MULTI_IMAGE_400_HINTS = (
    "multi-image",
    "multiple image",
    "too many image",
    "image count",
    "too many parts",
    "number of images",
    "reference image",
    "only one image",
    "payload",
    "request too large",
    "input size",
    "request size",
)
_NON_FALLBACK_400_HINTS = (
    "location is not supported",
    "api key",
    "authentication",
    "authorization",
    "quota",
    "rate limit",
    "resource exhausted",
    "safety",
    "blocked",
    "policy",
)


def _extract_http_status_code(exc: Exception) -> int | None:
    response = getattr(exc, "response", None)
    if response is not None:
        response_status = getattr(response, "status_code", None)
        if response_status is not None:
            return int(response_status)

    direct_status = getattr(exc, "status_code", None)
    if direct_status is not None:
        return int(direct_status)

    raw = _extract_gemini_error_status(exc)
    if raw is not None:
        text = str(raw).strip()
        if text.isdigit():
            return int(text)
    return None


def _is_retryable_http_status_code(status_code: int) -> bool:
    if status_code in _NON_RETRYABLE_GEMINI_HTTP_STATUS_CODES:
        return False
    if status_code in _RETRYABLE_GEMINI_HTTP_STATUS_CODES or status_code >= 500:
        return True
    if status_code == 429:
        return True
    if 400 <= status_code < 500:
        return False
    return True


def _is_retryable_gemini_photoshoot_error(exc: Exception) -> bool:
    if isinstance(exc, HTTPException):
        return _is_retryable_http_status_code(exc.status_code)

    status_code = _extract_http_status_code(exc)
    if status_code is not None:
        return _is_retryable_http_status_code(status_code)

    if isinstance(exc, _RETRYABLE_TRANSPORT_ERRORS):
        return True

    if type(exc).__name__ == "ServerError":
        return True
    if type(exc).__name__ == "ClientError":
        return False
    return True


def _gemini_frame_failure_reason(exc: Exception) -> str:
    if isinstance(exc, HTTPException):
        return _normalize_diagnostic_text(str(exc.detail))

    status = _extract_gemini_error_status(exc)
    message = _extract_gemini_safe_message(exc)
    if status and message:
        return _normalize_diagnostic_text(f"status={status} message={message}")
    if status:
        return _normalize_diagnostic_text(f"status={status}")
    if message:
        return _normalize_diagnostic_text(f"message={message}")
    return type(exc).__name__


def _raise_photoshoot_failure(
    *,
    style_id: str,
    stage: str,
    reason: str,
    photoshoot_id: str | None = None,
) -> None:
    logger.error(
        "Photoshoot aborted: style_id=%s photoshoot_id=%s stage=%s reason=%s",
        style_id,
        photoshoot_id,
        stage,
        reason,
    )
    raise HTTPException(status_code=502, detail=_PHOTOSHOOT_FAILURE_MESSAGE)


def _build_photoshoot_instruction(
    style: PhotoshootStyle,
    *,
    client_style_id: str,
    user_description: str | None = None,
    frame_index: int = 0,
    output_count: int = 1,
    series_reference_mode: str | None = None,
) -> str:
    mode = (
        series_reference_mode
        if series_reference_mode is not None
        else settings.photoshoot_series_reference_mode
    )
    return build_photoshoot_frame_prompt(
        client_style_id,
        style,
        frame_index=frame_index,
        output_count=output_count,
        user_description=user_description,
        series_reference_mode=mode,
    )


def _decode_generated_image_data_url(data_url: str) -> ReferenceImage:
    content_type, content = storage_service._parse_generated_image_data_url(data_url)
    return content, content_type


def _is_anchor_only_fallback_eligible(exc: Exception) -> bool:
    if _extract_http_status_code(exc) != 400:
        return False
    reason = _gemini_frame_failure_reason(exc).lower()
    if any(hint in reason for hint in _NON_FALLBACK_400_HINTS):
        return False
    return any(hint in reason for hint in _MULTI_IMAGE_400_HINTS)


def _normalize_diagnostic_text(value: str, max_len: int = _MAX_PHOTOSHOOT_DIAGNOSTIC_TEXT_LEN) -> str:
    text = re.sub(r"\s+", " ", value.strip())
    if len(text) <= max_len:
        return text
    return text[:max_len] + "..."


def _collect_response_parts(response) -> list:
    seen: set[int] = set()
    parts: list = []
    for part in _iter_response_parts(response):
        part_id = id(part)
        if part_id in seen:
            continue
        seen.add(part_id)
        parts.append(part)
    return parts


def _classify_part(part) -> str:
    if getattr(part, "text", None):
        return "text"
    if getattr(part, "inline_data", None) is not None:
        return "inline_data"
    if getattr(part, "function_call", None) is not None:
        return "function_call"
    return "unknown"


def _build_photoshoot_response_summary(response) -> str:
    candidates = getattr(response, "candidates", None) or []
    parts = _collect_response_parts(response)

    type_counts = {"text": 0, "inline_data": 0, "function_call": 0, "unknown": 0}
    text_preview: str | None = None

    for part in parts:
        kind = _classify_part(part)
        type_counts[kind] += 1
        if kind == "text" and text_preview is None:
            text_preview = _normalize_diagnostic_text(part.text)

    found_types = [name for name, count in type_counts.items() if count > 0]
    types_label = ", ".join(found_types) if found_types else "none"

    summary_parts = [
        f"candidates={len(candidates)}",
        f"parts={len(parts)}",
        f"part_types={types_label}",
    ]
    if text_preview:
        summary_parts.append(f'text_preview="{text_preview}"')

    return "; ".join(summary_parts)


def _extract_photoshoot_image_data_url(response) -> str:
    parts = _collect_response_parts(response)

    for part in parts:
        inline_data = getattr(part, "inline_data", None)
        if inline_data is None or inline_data.data is None:
            continue

        mime_type = inline_data.mime_type or "image/png"
        if not mime_type.startswith("image/"):
            raise HTTPException(
                status_code=502,
                detail="Gemini returned inline data but not an image",
            )
        return _blob_to_data_url(inline_data)

    summary = _build_photoshoot_response_summary(response)
    raise HTTPException(
        status_code=502,
        detail=f"Gemini did not return a photoshoot image: {summary}",
    )


def _photoshoot_history_prompt(
    style: PhotoshootStyle,
    user_description: str | None = None,
) -> str:
    if user_description:
        return f"Своя фотосессия: {user_description}"
    return f"Фотосессия: {style.title}"


def _photoshoot_payment_type(style: PhotoshootStyle) -> str:
    return "free" if style.is_free else "paid"


@dataclass(frozen=True)
class PhotoshootGenerateResult:
    image_urls: list[str]
    photoshoot_id: str
    storage_paths: list[str]


def _rollback_photoshoot_storage(
    storage_paths: list[str],
    *,
    client_style_id: str,
    photoshoot_id: str,
    stage: str,
) -> None:
    if not storage_paths:
        return
    logger.warning(
        "Photoshoot storage rollback start: style_id=%s photoshoot_id=%s "
        "stage=%s paths=%s",
        client_style_id,
        photoshoot_id,
        stage,
        len(storage_paths),
    )
    storage_service.delete_objects_best_effort(storage_paths)
    logger.warning(
        "Photoshoot storage rollback done: style_id=%s photoshoot_id=%s stage=%s",
        client_style_id,
        photoshoot_id,
        stage,
    )


def rollback_persisted_photoshoot(
    *,
    photoshoot_id: str,
    storage_paths: list[str],
    client_style_id: str,
) -> None:
    """Undo DB rows and uploaded storage files after a post-save pipeline failure."""
    normalized_id = photoshoot_id.strip()
    if normalized_id:
        try:
            delete_generations_by_photoshoot_id(normalized_id)
            logger.warning(
                "Photoshoot DB rollback ok: style_id=%s photoshoot_id=%s stage=debit_failure",
                client_style_id,
                normalized_id,
            )
        except Exception:
            logger.exception(
                "Photoshoot DB rollback failed: style_id=%s photoshoot_id=%s stage=debit_failure",
                client_style_id,
                normalized_id,
            )
    _rollback_photoshoot_storage(
        storage_paths,
        client_style_id=client_style_id,
        photoshoot_id=normalized_id or photoshoot_id,
        stage="debit_failure",
    )


def _save_photoshoot_results_to_history(
    user_id: str,
    style: PhotoshootStyle,
    image_urls: list[str],
    *,
    client_style_id: str,
    user_description: str | None = None,
    photoshoot_id: str | None = None,
    storage_paths: list[str] | None = None,
) -> str:
    if not image_urls:
        _raise_photoshoot_failure(
            style_id=client_style_id,
            stage="db_save",
            reason="empty_image_urls",
            photoshoot_id=photoshoot_id,
        )

    prompt = _photoshoot_history_prompt(style, user_description)
    payment_type = _photoshoot_payment_type(style)
    batch_id = photoshoot_id or str(uuid4())
    saved_frames = 0

    try:
        for index, image_url in enumerate(image_urls):
            logger.info(
                "Photoshoot DB save start: style_id=%s photoshoot_id=%s "
                "frame_index=%s frame=%s/%s",
                client_style_id,
                batch_id,
                index,
                index + 1,
                len(image_urls),
            )
            create_generation_record(
                user_id=user_id,
                prompt=prompt,
                image_url=image_url,
                payment_type=payment_type,
                photoshoot_id=batch_id,
            )
            saved_frames += 1
            logger.info(
                "Photoshoot DB save ok: style_id=%s photoshoot_id=%s "
                "frame_index=%s frame=%s/%s",
                client_style_id,
                batch_id,
                index,
                index + 1,
                len(image_urls),
            )
    except HTTPException as exc:
        logger.exception(
            "Photoshoot DB save failed: style_id=%s photoshoot_id=%s "
            "frame_index=%s saved_frames=%s",
            client_style_id,
            batch_id,
            saved_frames,
            saved_frames,
        )
        if saved_frames > 0:
            try:
                delete_generations_by_photoshoot_id(batch_id)
                logger.warning(
                    "Photoshoot DB rollback ok: style_id=%s photoshoot_id=%s",
                    client_style_id,
                    batch_id,
                )
            except Exception:
                logger.exception(
                    "Photoshoot DB rollback failed: style_id=%s photoshoot_id=%s",
                    client_style_id,
                    batch_id,
                )
        if storage_paths:
            _rollback_photoshoot_storage(
                storage_paths,
                client_style_id=client_style_id,
                photoshoot_id=batch_id,
                stage="db_save",
            )
        _raise_photoshoot_failure(
            style_id=client_style_id,
            stage="db_save",
            reason=str(exc.detail),
            photoshoot_id=batch_id,
        )
    except Exception as exc:
        logger.exception(
            "Photoshoot DB save failed: style_id=%s photoshoot_id=%s saved_frames=%s",
            client_style_id,
            batch_id,
            saved_frames,
        )
        if saved_frames > 0:
            try:
                delete_generations_by_photoshoot_id(batch_id)
            except Exception:
                logger.exception(
                    "Photoshoot DB rollback failed: style_id=%s photoshoot_id=%s",
                    client_style_id,
                    batch_id,
                )
        if storage_paths:
            _rollback_photoshoot_storage(
                storage_paths,
                client_style_id=client_style_id,
                photoshoot_id=batch_id,
                stage="db_save",
            )
        _raise_photoshoot_failure(
            style_id=client_style_id,
            stage="db_save",
            reason=type(exc).__name__,
            photoshoot_id=batch_id,
        )

    return batch_id


def _upload_photoshoot_frames_to_storage(
    *,
    user_id: str,
    client_style_id: str,
    data_urls: list[str],
    photoshoot_id: str,
) -> tuple[list[str], list[str]]:
    uploaded_urls: list[str] = []
    uploaded_paths: list[str] = []
    try:
        for index, data_url in enumerate(data_urls):
            logger.info(
                "Photoshoot storage upload start: style_id=%s photoshoot_id=%s "
                "frame_index=%s frame=%s/%s",
                client_style_id,
                photoshoot_id,
                index,
                index + 1,
                len(data_urls),
            )
            storage_path, public_url = storage_service.upload_generated_image_data_url_with_path(
                user_id=user_id,
                data_url=data_url,
                folder="photoshoots",
            )
            uploaded_paths.append(storage_path)
            uploaded_urls.append(public_url)
            logger.info(
                "Photoshoot storage upload ok: style_id=%s photoshoot_id=%s "
                "frame_index=%s frame=%s/%s",
                client_style_id,
                photoshoot_id,
                index,
                index + 1,
                len(data_urls),
            )
    except HTTPException as exc:
        logger.exception(
            "Photoshoot storage upload failed: style_id=%s photoshoot_id=%s "
            "uploaded_frames=%s/%s",
            client_style_id,
            photoshoot_id,
            len(uploaded_urls),
            len(data_urls),
        )
        _rollback_photoshoot_storage(
            uploaded_paths,
            client_style_id=client_style_id,
            photoshoot_id=photoshoot_id,
            stage="storage_upload",
        )
        _raise_photoshoot_failure(
            style_id=client_style_id,
            stage="storage_upload",
            reason=str(exc.detail),
            photoshoot_id=photoshoot_id,
        )
    except Exception as exc:
        logger.exception(
            "Photoshoot storage upload failed: style_id=%s photoshoot_id=%s",
            client_style_id,
            photoshoot_id,
        )
        _rollback_photoshoot_storage(
            uploaded_paths,
            client_style_id=client_style_id,
            photoshoot_id=photoshoot_id,
            stage="storage_upload",
        )
        _raise_photoshoot_failure(
            style_id=client_style_id,
            stage="storage_upload",
            reason=type(exc).__name__,
            photoshoot_id=photoshoot_id,
        )

    if len(uploaded_urls) != len(data_urls):
        _rollback_photoshoot_storage(
            uploaded_paths,
            client_style_id=client_style_id,
            photoshoot_id=photoshoot_id,
            stage="storage_upload",
        )
        _raise_photoshoot_failure(
            style_id=client_style_id,
            stage="storage_upload",
            reason=f"partial_upload:{len(uploaded_urls)}/{len(data_urls)}",
            photoshoot_id=photoshoot_id,
        )

    return uploaded_urls, uploaded_paths


class MockPhotoshootProvider:
    """Development mock: placeholder URLs without Gemini or Storage upload."""

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
        *,
        user_description: str | None = None,
    ) -> list[str]:
        _ = photo_bytes, photo_content_type
        return build_mock_photoshoot_image_urls(
            style_id=style.id,
            style_title=style.title,
            output_count=self._output_count,
            user_description=user_description,
        )


class GeminiPhotoshootProvider:
    """Uploaded photo + style instruction → Gemini image data URLs (in memory only)."""

    def __init__(self, output_count: int | None = None) -> None:
        self._output_count = output_count if output_count is not None else settings.photoshoot_output_count

    @property
    def output_count(self) -> int:
        return self._output_count

    def _call_gemini_frame(
        self,
        client: genai.Client,
        *,
        instruction: str,
        reference_images: list[ReferenceImage],
    ) -> str:
        parts: list[types.Part] = [types.Part.from_text(text=instruction)]
        for image_bytes, image_mime in reference_images:
            parts.append(
                types.Part.from_bytes(
                    data=image_bytes,
                    mime_type=image_mime,
                )
            )
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
        summary = _build_photoshoot_response_summary(response)
        logger.info(
            "Gemini frame response: reference_count=%s %s",
            len(reference_images),
            summary,
        )
        return _extract_photoshoot_image_data_url(response)

    def _invoke_gemini_frame_with_optional_fallback(
        self,
        client: genai.Client,
        *,
        client_style_id: str,
        photoshoot_id: str,
        frame_index: int,
        instruction: str,
        reference_images: list[ReferenceImage],
        fallback_reference_images: list[ReferenceImage] | None = None,
    ) -> str:
        try:
            return self._call_gemini_frame(
                client,
                instruction=instruction,
                reference_images=reference_images,
            )
        except Exception as exc:
            if (
                fallback_reference_images
                and reference_images != fallback_reference_images
                and _is_anchor_only_fallback_eligible(exc)
            ):
                logger.info(
                    "Photoshoot frame multi-image fallback: style_id=%s photoshoot_id=%s "
                    "frame_index=%s from=%s to=anchor_only reason=%s",
                    client_style_id,
                    photoshoot_id,
                    frame_index,
                    len(reference_images),
                    _normalize_diagnostic_text(_gemini_frame_failure_reason(exc)),
                )
                return self._call_gemini_frame(
                    client,
                    instruction=instruction,
                    reference_images=fallback_reference_images,
                )
            raise

    def _generate_frame_with_retries(
        self,
        client: genai.Client,
        *,
        client_style_id: str,
        photoshoot_id: str,
        instruction: str,
        reference_images: list[ReferenceImage],
        frame_index: int,
        reference_mode: str,
        fallback_reference_images: list[ReferenceImage] | None = None,
    ) -> str:
        last_failure_reason = "unknown"

        for attempt in range(1, _MAX_GEMINI_FRAME_ATTEMPTS + 1):
            logger.info(
                "Photoshoot frame start: style_id=%s photoshoot_id=%s "
                "frame_index=%s frame=%s/%s attempt=%s reference_mode=%s "
                "reference_count=%s",
                client_style_id,
                photoshoot_id,
                frame_index,
                frame_index + 1,
                self._output_count,
                attempt,
                reference_mode,
                len(reference_images),
            )
            try:
                data_url = self._invoke_gemini_frame_with_optional_fallback(
                    client,
                    client_style_id=client_style_id,
                    photoshoot_id=photoshoot_id,
                    frame_index=frame_index,
                    instruction=instruction,
                    reference_images=reference_images,
                    fallback_reference_images=fallback_reference_images,
                )
            except HTTPException as exc:
                last_failure_reason = _gemini_frame_failure_reason(exc)
                logger.warning(
                    "Photoshoot frame failed: style_id=%s photoshoot_id=%s "
                    "frame_index=%s attempt=%s reason=%s retryable=%s",
                    client_style_id,
                    photoshoot_id,
                    frame_index,
                    attempt,
                    last_failure_reason,
                    _is_retryable_gemini_photoshoot_error(exc),
                )
                if not _is_retryable_gemini_photoshoot_error(exc):
                    logger.error(
                        "Photoshoot frame non-retryable failure: style_id=%s photoshoot_id=%s "
                        "frame_index=%s reason=%s",
                        client_style_id,
                        photoshoot_id,
                        frame_index,
                        last_failure_reason,
                    )
                    _raise_photoshoot_failure(
                        style_id=client_style_id,
                        stage="gemini_frame",
                        reason=last_failure_reason,
                        photoshoot_id=photoshoot_id,
                    )
            except Exception as exc:
                last_failure_reason = _gemini_frame_failure_reason(exc)
                retryable = _is_retryable_gemini_photoshoot_error(exc)
                logger.warning(
                    "Photoshoot frame failed: style_id=%s photoshoot_id=%s "
                    "frame_index=%s attempt=%s error_type=%s reason=%s retryable=%s",
                    client_style_id,
                    photoshoot_id,
                    frame_index,
                    attempt,
                    type(exc).__name__,
                    last_failure_reason,
                    retryable,
                )
                if not retryable:
                    logger.error(
                        "Photoshoot frame non-retryable failure: style_id=%s photoshoot_id=%s "
                        "frame_index=%s reason=%s",
                        client_style_id,
                        photoshoot_id,
                        frame_index,
                        last_failure_reason,
                    )
                    _raise_photoshoot_failure(
                        style_id=client_style_id,
                        stage="gemini_frame",
                        reason=last_failure_reason,
                        photoshoot_id=photoshoot_id,
                    )
            else:
                logger.info(
                    "Photoshoot frame success: style_id=%s photoshoot_id=%s "
                    "frame_index=%s attempt=%s",
                    client_style_id,
                    photoshoot_id,
                    frame_index,
                    attempt,
                )
                return data_url

            if attempt < _MAX_GEMINI_FRAME_ATTEMPTS:
                time.sleep(_GEMINI_FRAME_RETRY_DELAY_SECONDS)

        logger.error(
            "Photoshoot frame exhausted retries: style_id=%s photoshoot_id=%s "
            "frame_index=%s attempts=%s reason=%s",
            client_style_id,
            photoshoot_id,
            frame_index,
            _MAX_GEMINI_FRAME_ATTEMPTS,
            _normalize_diagnostic_text(last_failure_reason),
        )
        _raise_photoshoot_failure(
            style_id=client_style_id,
            stage="gemini_frame",
            reason=last_failure_reason,
            photoshoot_id=photoshoot_id,
        )

    def generate(
        self,
        style: PhotoshootStyle,
        photo_bytes: bytes,
        photo_content_type: str,
        *,
        client_style_id: str,
        photoshoot_id: str,
        user_description: str | None = None,
    ) -> list[str]:
        api_key = settings.gemini_api_key
        if not api_key or not api_key.strip():
            raise HTTPException(
                status_code=500,
                detail="GEMINI_API_KEY is not configured",
            )

        data_urls: list[str] = []
        client = genai.Client(api_key=api_key.strip())
        series_mode = settings.photoshoot_series_reference_mode.strip().lower()
        identity_reference: ReferenceImage = (photo_bytes, photo_content_type)

        logger.info(
            "Gemini photoshoot start: style_id=%s photoshoot_id=%s output_count=%s "
            "series_reference_mode=%s",
            client_style_id,
            photoshoot_id,
            self._output_count,
            series_mode,
        )

        for index in range(self._output_count):
            instruction = _build_photoshoot_instruction(
                style,
                client_style_id=client_style_id,
                user_description=user_description,
                frame_index=index,
                output_count=self._output_count,
                series_reference_mode=series_mode,
            )
            if index == 0 or series_mode == "legacy":
                reference_images = [identity_reference]
                reference_mode = "identity_only"
                fallback_reference_images = None
            elif series_mode == "anchor_only":
                if not data_urls:
                    _raise_photoshoot_failure(
                        style_id=client_style_id,
                        stage="gemini_batch",
                        reason="missing_series_anchor",
                        photoshoot_id=photoshoot_id,
                    )
                reference_images = [_decode_generated_image_data_url(data_urls[0])]
                reference_mode = "anchor_only"
                fallback_reference_images = None
            else:
                if not data_urls:
                    _raise_photoshoot_failure(
                        style_id=client_style_id,
                        stage="gemini_batch",
                        reason="missing_series_anchor",
                        photoshoot_id=photoshoot_id,
                    )
                anchor_reference = _decode_generated_image_data_url(data_urls[0])
                reference_images = [identity_reference, anchor_reference]
                reference_mode = "identity_anchor"
                fallback_reference_images = [anchor_reference]

            data_urls.append(
                self._generate_frame_with_retries(
                    client,
                    client_style_id=client_style_id,
                    photoshoot_id=photoshoot_id,
                    instruction=instruction,
                    reference_images=reference_images,
                    frame_index=index,
                    reference_mode=reference_mode,
                    fallback_reference_images=fallback_reference_images,
                )
            )

        if len(data_urls) != self._output_count:
            _raise_photoshoot_failure(
                style_id=client_style_id,
                stage="gemini_batch",
                reason=f"frame_count_mismatch:{len(data_urls)}/{self._output_count}",
                photoshoot_id=photoshoot_id,
            )

        logger.info(
            "Gemini photoshoot complete: style_id=%s photoshoot_id=%s frames=%s",
            client_style_id,
            photoshoot_id,
            len(data_urls),
        )
        return data_urls


class PhotoshootService:
    """Orchestrates photoshoot generation: style + user photo → public URLs + history."""

    def _get_provider(self) -> MockPhotoshootProvider | GeminiPhotoshootProvider:
        provider_name = settings.image_provider.strip().lower()
        if provider_name == "mock":
            return MockPhotoshootProvider()
        if provider_name == "gemini":
            return GeminiPhotoshootProvider()
        raise HTTPException(status_code=500, detail="Unsupported image provider")

    def generate_photoshoot(
        self,
        user_id: str,
        style: PhotoshootStyle,
        photo_bytes: bytes,
        photo_content_type: str,
        *,
        client_style_id: str,
        user_description: str | None = None,
    ) -> PhotoshootGenerateResult:
        provider = self._get_provider()
        provider_name = settings.image_provider.strip().lower()
        output_count = provider.output_count
        pending_photoshoot_id = str(uuid4())

        logger.info(
            "Photoshoot generation start: style_id=%s photoshoot_id=%s "
            "provider=%s output_count=%s",
            client_style_id,
            pending_photoshoot_id,
            provider_name,
            output_count,
        )

        if isinstance(provider, MockPhotoshootProvider):
            image_urls = provider.generate(
                style=style,
                photo_bytes=photo_bytes,
                photo_content_type=photo_content_type,
                user_description=user_description,
            )
            storage_paths: list[str] = []
            if len(image_urls) != output_count:
                _raise_photoshoot_failure(
                    style_id=client_style_id,
                    stage="mock_batch",
                    reason=f"frame_count_mismatch:{len(image_urls)}/{output_count}",
                    photoshoot_id=pending_photoshoot_id,
                )
        else:
            data_urls = provider.generate(
                style=style,
                photo_bytes=photo_bytes,
                photo_content_type=photo_content_type,
                client_style_id=client_style_id,
                photoshoot_id=pending_photoshoot_id,
                user_description=user_description,
            )
            if len(data_urls) != output_count:
                _raise_photoshoot_failure(
                    style_id=client_style_id,
                    stage="gemini_batch",
                    reason=f"frame_count_mismatch:{len(data_urls)}/{output_count}",
                    photoshoot_id=pending_photoshoot_id,
                )
            image_urls, storage_paths = _upload_photoshoot_frames_to_storage(
                user_id=user_id,
                client_style_id=client_style_id,
                data_urls=data_urls,
                photoshoot_id=pending_photoshoot_id,
            )

        photoshoot_id = _save_photoshoot_results_to_history(
            user_id=user_id,
            style=style,
            image_urls=image_urls,
            client_style_id=client_style_id,
            user_description=user_description,
            photoshoot_id=pending_photoshoot_id,
            storage_paths=storage_paths,
        )

        if len(image_urls) != output_count:
            _raise_photoshoot_failure(
                style_id=client_style_id,
                stage="finalize",
                reason=f"frame_count_mismatch:{len(image_urls)}/{output_count}",
                photoshoot_id=photoshoot_id,
            )

        logger.info(
            "Photoshoot generation success: style_id=%s photoshoot_id=%s frames=%s",
            client_style_id,
            photoshoot_id,
            len(image_urls),
        )
        return PhotoshootGenerateResult(
            image_urls=image_urls,
            photoshoot_id=photoshoot_id,
            storage_paths=storage_paths,
        )


photoshoot_service = PhotoshootService()
