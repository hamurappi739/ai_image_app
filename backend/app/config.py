from pathlib import Path

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

_BACKEND_DIR = Path(__file__).resolve().parent.parent

_PHOTOSHOOT_OUTPUT_COUNT_MIN = 1
_PHOTOSHOOT_OUTPUT_COUNT_MAX = 3
_PHOTOSHOOT_OUTPUT_COUNT_DEFAULT = 3
_DEFAULT_APP_VERSION = "0.1.0"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=_BACKEND_DIR / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_name: str = "AI Image Generator Backend"
    app_version: str = _DEFAULT_APP_VERSION
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
    # Comma-separated trusted origins for CORS (e.g. https://app.example.com).
    # Development: empty → allow all origins. Production: empty → deny browser CORS.
    allowed_origins: str | None = None
    port: int = 8000

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

    @property
    def is_development(self) -> bool:
        return self.environment.strip().lower() == "development"

    @property
    def is_production(self) -> bool:
        return self.environment.strip().lower() == "production"

    def cors_origins_list(self) -> list[str]:
        if not self.allowed_origins or not str(self.allowed_origins).strip():
            return []
        return [
            origin.strip()
            for origin in str(self.allowed_origins).split(",")
            if origin.strip()
        ]

    @staticmethod
    def _env_value_configured(value: str | None) -> bool:
        return bool(value and str(value).strip())

    def supabase_configured(self) -> bool:
        return (
            self._env_value_configured(self.supabase_url)
            and self._env_value_configured(self.supabase_service_role_key)
        )

    def supabase_auth_configured(self) -> bool:
        return (
            self._env_value_configured(self.supabase_url)
            and self._env_value_configured(self.supabase_anon_key)
        )

    def gemini_configured(self) -> bool:
        return self._env_value_configured(self.gemini_api_key)

    def production_safety_ok(self) -> bool:
        """True when production env has no development-only misconfiguration."""
        if not self.is_production:
            return True
        return not self._env_value_configured(self.test_user_id)


settings = Settings()
