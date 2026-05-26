from app.config import settings

MOCK_IMAGE_URL = "https://placehold.co/1024x1024?text=Generated+Image"


class GeminiNotImplementedError(Exception):
    """Raised when IMAGE_PROVIDER=gemini but API integration is not ready."""


class UnsupportedImageProviderError(Exception):
    """Raised when IMAGE_PROVIDER is not mock or gemini."""


def generate_mock_image(prompt: str) -> str:
    return MOCK_IMAGE_URL


def generate_image(prompt: str) -> str:
    provider = settings.image_provider.strip().lower()

    if provider == "mock":
        return generate_mock_image(prompt)

    if provider == "gemini":
        raise GeminiNotImplementedError(
            "Gemini image generation is not implemented yet"
        )

    raise UnsupportedImageProviderError(f"Unsupported image provider: {provider}")


def generate_image_with_gemini(prompt: str) -> str:
    """Reserved for a future Gemini implementation. Do not call the external API yet."""
    raise GeminiNotImplementedError(
        "Gemini image generation is not implemented yet"
    )
