import logging
import os
from pathlib import Path

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

_BACKEND_DIR = Path(__file__).resolve().parent.parent
ENV_FILE_PATH = _BACKEND_DIR / ".env"

_PHOTOSHOOT_OUTPUT_COUNT_MIN = 1
_PHOTOSHOOT_OUTPUT_COUNT_MAX = 3
_PHOTOSHOOT_OUTPUT_COUNT_DEFAULT = 3
_PHOTOSHOOT_SERIES_REFERENCE_MODES = frozenset(
    {"identity_anchor", "legacy", "anchor_only"}
)
_PHOTOSHOOT_SERIES_REFERENCE_MODE_DEFAULT = "identity_anchor"
_DEFAULT_APP_VERSION = "0.1.0"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=ENV_FILE_PATH,
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
    photoshoot_series_reference_mode: str = _PHOTOSHOOT_SERIES_REFERENCE_MODE_DEFAULT
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

    @field_validator("photoshoot_series_reference_mode", mode="before")
    @classmethod
    def normalize_photoshoot_series_reference_mode(cls, value: object) -> str:
        if value is None:
            return _PHOTOSHOOT_SERIES_REFERENCE_MODE_DEFAULT
        normalized = str(value).strip().lower()
        if normalized in _PHOTOSHOOT_SERIES_REFERENCE_MODES:
            return normalized
        return _PHOTOSHOOT_SERIES_REFERENCE_MODE_DEFAULT

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


def read_dotenv_value(key: str) -> str | None:
    """Read a single key from backend/.env without logging secrets elsewhere."""
    if not ENV_FILE_PATH.is_file():
        return None
    for raw_line in ENV_FILE_PATH.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        env_key, _, value = line.partition("=")
        if env_key.strip() != key:
            continue
        cleaned = value.strip().strip('"').strip("'")
        return cleaned or None
    return None


def log_settings_diagnostics(logger: logging.Logger | None = None) -> None:
    """Log safe settings diagnostics at startup (no secrets)."""
    log = logger or logging.getLogger("uvicorn.error")
    env_file_image_provider = read_dotenv_value("IMAGE_PROVIDER")
    os_image_provider = os.environ.get("IMAGE_PROVIDER")
    log.info(
        "Settings diagnostics: image_provider=%s environment=%s "
        "env_file=%s env_file_exists=%s env_file_IMAGE_PROVIDER=%s "
        "os.environ_IMAGE_PROVIDER=%s enable_photoshoot_generation=%s "
        "enable_credit_consumption=%s",
        settings.image_provider,
        settings.environment.strip().lower(),
        ENV_FILE_PATH,
        ENV_FILE_PATH.is_file(),
        env_file_image_provider,
        os_image_provider,
        settings.enable_photoshoot_generation,
        settings.enable_credit_consumption,
    )
    if (
        env_file_image_provider is not None
        and env_file_image_provider != settings.image_provider
    ):
        log.warning(
            "backend/.env IMAGE_PROVIDER=%s but loaded settings.image_provider=%s — "
            "restart uvicorn after .env changes (Settings loads once at import)",
            env_file_image_provider,
            settings.image_provider,
        )
    if os_image_provider is not None and os_image_provider != settings.image_provider:
        log.warning(
            "os.environ IMAGE_PROVIDER=%s overrides .env; loaded image_provider=%s",
            os_image_provider,
            settings.image_provider,
        )
