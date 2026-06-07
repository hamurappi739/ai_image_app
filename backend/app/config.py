from pathlib import Path

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

_BACKEND_DIR = Path(__file__).resolve().parent.parent

_PHOTOSHOOT_OUTPUT_COUNT_MIN = 1
_PHOTOSHOOT_OUTPUT_COUNT_MAX = 3
_PHOTOSHOOT_OUTPUT_COUNT_DEFAULT = 3


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=_BACKEND_DIR / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_name: str = "AI Image Generator Backend"
    environment: str = "development"
    image_provider: str = "mock"
    gemini_api_key: str | None = None
    gemini_model: str = "gemini-2.5-flash-image"
    free_generations_limit: int = 3
    supabase_url: str | None = None
    supabase_anon_key: str | None = None
    supabase_service_role_key: str | None = None
    supabase_storage_bucket: str = "generated-images"
    test_user_id: str | None = None
    enable_credit_consumption: bool = False
    enable_photoshoot_generation: bool = False
    photoshoot_output_count: int = _PHOTOSHOOT_OUTPUT_COUNT_DEFAULT

    @field_validator("photoshoot_output_count", mode="before")
    @classmethod
    def clamp_photoshoot_output_count(cls, value: object) -> int:
        try:
            parsed = int(value)  # type: ignore[arg-type]
        except (TypeError, ValueError):
            return _PHOTOSHOOT_OUTPUT_COUNT_DEFAULT
        return max(
            _PHOTOSHOOT_OUTPUT_COUNT_MIN,
            min(_PHOTOSHOOT_OUTPUT_COUNT_MAX, parsed),
        )


settings = Settings()
