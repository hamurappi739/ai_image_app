import base64
import logging
import re

from fastapi import HTTPException
from google import genai
from google.genai import types

from app.config import settings
from app.services.gemini_quality_instructions import build_text_to_image_instruction
from app.services.image_provider_resolver import (
    KIE_IMAGE_PROVIDER,
    resolve_template_image_provider,
)
from app.services.kie_image_service import KieImageGenerationError, KieImageTaskClient
from app.services.mock_placeholder_urls import (
    DEFAULT_MOCK_IMAGE_URL,
    build_mock_text_image_url,
)

logger = logging.getLogger(__name__)

MOCK_IMAGE_URL = DEFAULT_MOCK_IMAGE_URL
_MAX_GEMINI_ERROR_MESSAGE_LEN = 300
_SENSITIVE_GEMINI_MESSAGE_TOKENS = (
    "api key",
    "api_key",
    "authorization",
    "bearer",
    "secret",
    "token",
    "x-goog-api-key",
)


class MockImageProvider:
    def generate(self, prompt: str) -> str:
        return build_mock_text_image_url(prompt)


class GeminiImageProvider:
    def generate(self, prompt: str) -> str:
        api_key = settings.gemini_api_key
        if not api_key or not api_key.strip():
            raise HTTPException(
                status_code=500,
                detail="GEMINI_API_KEY is not configured",
            )

        instruction = build_text_to_image_instruction(prompt)
        try:
            client = genai.Client(api_key=api_key.strip())
            response = client.models.generate_content(
                model=settings.gemini_model,
                contents=[instruction],
                config=types.GenerateContentConfig(
                    response_modalities=["Image"],
                ),
            )
        except HTTPException:
            raise
        except Exception as exc:
            status = _extract_gemini_error_status(exc)
            logger.warning(
                "Gemini image generation failed: status=%s, error=%s",
                status,
                type(exc).__name__,
            )
            raise HTTPException(
                status_code=502,
                detail=_gemini_error_detail(exc),
            ) from exc

        return _extract_image_data_url(response)


class KieImageProvider:
    """Text-only template generation is not supported for Kie image-to-image."""

    def generate(self, prompt: str) -> str:
        _ = prompt
        raise HTTPException(
            status_code=500,
            detail=(
                "Kie gpt-image-2-image-to-image requires a source image; "
                "use generate-with-photo or set TEMPLATE_IMAGE_PROVIDER=gemini"
            ),
        )


class ImageService:
    def generate(self, prompt: str) -> str:
        return self._get_provider().generate(prompt)

    def _get_provider(
        self,
    ) -> MockImageProvider | GeminiImageProvider | KieImageProvider:
        provider_name = resolve_template_image_provider()

        if provider_name == "mock":
            return MockImageProvider()

        if provider_name == "gemini":
            return GeminiImageProvider()

        if provider_name == KIE_IMAGE_PROVIDER:
            return KieImageProvider()

        raise HTTPException(status_code=500, detail="Unsupported image provider")


_image_service = ImageService()


def generate_image(prompt: str) -> str:
    return _image_service.generate(prompt)


def generate_mock_image(prompt: str) -> str:
    """Backward-compatible helper for mock URL."""
    return MockImageProvider().generate(prompt)


def _gemini_error_detail(exc: Exception) -> str:
    status = _extract_gemini_error_status(exc)
    message = _extract_gemini_safe_message(exc)
    if status is not None and message:
        return f"Gemini image generation failed: status={status}, message={message}"
    if status is not None:
        return f"Gemini image generation failed: status={status}"
    if message:
        return f"Gemini image generation failed: message={message}"
    return "Gemini image generation failed"


def _extract_gemini_error_status(exc: Exception) -> str | None:
    code = getattr(exc, "code", None)
    if code is not None:
        return str(code)

    status = getattr(exc, "status", None)
    if status is not None and str(status).strip():
        return str(status).strip()

    status_code = getattr(exc, "status_code", None)
    if status_code is not None:
        return str(status_code)

    return type(exc).__name__


def _extract_gemini_safe_message(exc: Exception) -> str | None:
    raw_message = getattr(exc, "message", None)
    if raw_message is not None and str(raw_message).strip():
        text = _normalize_gemini_error_text(str(raw_message))
    else:
        text = _normalize_gemini_error_text(str(exc))

    if not text:
        return None

    lowered = text.lower()
    if any(token in lowered for token in _SENSITIVE_GEMINI_MESSAGE_TOKENS):
        return _redact_sensitive_gemini_message(lowered)

    return _truncate_gemini_error_message(text)


def _normalize_gemini_error_text(value: str) -> str:
    return re.sub(r"\s+", " ", value.strip())


def _truncate_gemini_error_message(value: str) -> str:
    if len(value) <= _MAX_GEMINI_ERROR_MESSAGE_LEN:
        return value
    return value[:_MAX_GEMINI_ERROR_MESSAGE_LEN] + "..."


def _redact_sensitive_gemini_message(lowered: str) -> str:
    if any(
        token in lowered
        for token in ("api key", "api_key", "unauthorized", "permission", "401", "403")
    ):
        return "Gemini API authentication failed"
    if any(token in lowered for token in ("quota", "rate limit", "429", "resource exhausted")):
        return "Gemini API rate limit or quota exceeded"
    if any(token in lowered for token in ("safety", "blocked", "policy")):
        return "Gemini blocked the request"
    return "Gemini API request failed"


def _extract_image_data_url(response) -> str:
    for part in _iter_response_parts(response):
        if part.inline_data and part.inline_data.data is not None:
            return _blob_to_data_url(part.inline_data)

    if _response_has_text_only(response):
        raise HTTPException(status_code=502, detail="Gemini did not return an image")

    raise HTTPException(status_code=502, detail="Gemini did not return an image")


def _iter_response_parts(response):
    parts = getattr(response, "parts", None)
    if parts:
        yield from parts

    candidates = getattr(response, "candidates", None) or []
    for candidate in candidates:
        content = getattr(candidate, "content", None)
        if content and content.parts:
            yield from content.parts


def _response_has_text_only(response) -> bool:
    for part in _iter_response_parts(response):
        if part.text:
            return True
    return False


def _blob_to_data_url(blob) -> str:
    mime_type = blob.mime_type or "image/png"
    raw = blob.data

    if isinstance(raw, bytes):
        encoded = base64.b64encode(raw).decode("ascii")
    elif isinstance(raw, str):
        encoded = raw.strip()
    else:
        raise HTTPException(status_code=502, detail="Gemini did not return an image")

    return f"data:{mime_type};base64,{encoded}"
