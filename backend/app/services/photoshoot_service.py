"""Photoshoot generation service: uploaded photo + style instruction → Gemini → Storage."""

from __future__ import annotations

import logging
import re

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
from app.services.photoshoot_styles import PhotoshootStyle
from app.services.storage_service import storage_service

logger = logging.getLogger(__name__)

_MAX_PHOTOSHOOT_DIAGNOSTIC_TEXT_LEN = 200


def _build_photoshoot_instruction(style: PhotoshootStyle) -> str:
    return (
        f"{style.instruction}\n\n"
        "Use the uploaded user photo as identity/reference. "
        "Preserve the person's identity, face structure, age, and key facial features. "
        "Improve lighting, background, color, and composition. "
        "Create a polished portrait in the selected photoshoot style. "
        "Do not create NSFW content. Return an image only."
    )


def _photoshoot_gemini_error_detail(exc: Exception) -> str:
    status = _extract_gemini_error_status(exc)
    message = _extract_gemini_safe_message(exc)
    if status is not None and message:
        return f"Gemini photoshoot generation failed: status={status}, message={message}"
    if status is not None:
        return f"Gemini photoshoot generation failed: status={status}"
    if message:
        return f"Gemini photoshoot generation failed: message={message}"
    return "Gemini photoshoot generation failed"


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
    logger.warning("Gemini photoshoot response missing image: %s", summary)
    raise HTTPException(
        status_code=502,
        detail=f"Gemini did not return a photoshoot image: {summary}",
    )


class GeminiPhotoshootProvider:
    """Uploaded photo + style instruction → Gemini image data URLs."""

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
        api_key = settings.gemini_api_key
        if not api_key or not api_key.strip():
            raise HTTPException(
                status_code=500,
                detail="GEMINI_API_KEY is not configured",
            )

        instruction = _build_photoshoot_instruction(style)
        client = genai.Client(api_key=api_key.strip())
        data_urls: list[str] = []

        for _ in range(self._output_count):
            try:
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
                    "Gemini photoshoot generation failed: status=%s, error=%s",
                    status,
                    type(exc).__name__,
                )
                raise HTTPException(
                    status_code=502,
                    detail=_photoshoot_gemini_error_detail(exc),
                ) from exc

            data_urls.append(_extract_photoshoot_image_data_url(response))

        return data_urls


class PhotoshootService:
    """Orchestrates photoshoot generation: style + user photo → Storage public URLs."""

    def __init__(self) -> None:
        self._provider = GeminiPhotoshootProvider()

    def generate_photoshoot(
        self,
        user_id: str,
        style: PhotoshootStyle,
        photo_bytes: bytes,
        photo_content_type: str,
    ) -> list[str]:
        data_urls = self._provider.generate(
            style=style,
            photo_bytes=photo_bytes,
            photo_content_type=photo_content_type,
        )
        return [
            storage_service.upload_generated_image_data_url(
                user_id=user_id,
                data_url=data_url,
                folder="photoshoots",
            )
            for data_url in data_urls
        ]


photoshoot_service = PhotoshootService()
