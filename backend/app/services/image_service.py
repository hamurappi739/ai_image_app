from fastapi import HTTPException

from app.config import settings

MOCK_IMAGE_URL = "https://placehold.co/1024x1024?text=Generated+Image"


class MockImageProvider:
    def generate(self, prompt: str) -> str:
        return MOCK_IMAGE_URL


class GeminiImageProvider:
    def generate(self, prompt: str) -> str:
        raise HTTPException(
            status_code=501,
            detail="Gemini image generation is not implemented yet",
        )


class ImageService:
    def generate(self, prompt: str) -> str:
        return self._get_provider().generate(prompt)

    def _get_provider(self) -> MockImageProvider | GeminiImageProvider:
        provider_name = settings.image_provider.strip().lower()

        if provider_name == "mock":
            return MockImageProvider()

        if provider_name == "gemini":
            return GeminiImageProvider()

        raise HTTPException(status_code=500, detail="Unsupported image provider")


_image_service = ImageService()


def generate_image(prompt: str) -> str:
    return _image_service.generate(prompt)


def generate_mock_image(prompt: str) -> str:
    """Backward-compatible helper for mock URL."""
    return MockImageProvider().generate(prompt)
