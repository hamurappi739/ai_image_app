from app.config import settings

MOCK_IMAGE_URL = "https://placehold.co/1024x1024?text=Generated+Image"


def generate_mock_image(prompt: str) -> str:
    return MOCK_IMAGE_URL


def generate_image_with_gemini(prompt: str) -> str:
    if not settings.gemini_api_key:
        raise RuntimeError("GEMINI_API_KEY is not configured")
    # TODO: call Gemini API here (model: settings.gemini_model)
    return MOCK_IMAGE_URL
