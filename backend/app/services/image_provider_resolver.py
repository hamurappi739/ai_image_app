"""Resolve effective image provider per flow (template vs photoshoot)."""

from __future__ import annotations

from app.config import settings

KIE_IMAGE_PROVIDER = "kie_gpt_image_2"
VALID_IMAGE_PROVIDERS = frozenset({"mock", "gemini", KIE_IMAGE_PROVIDER})


def _normalize_provider_name(value: str | None) -> str | None:
    if value is None:
        return None
    normalized = str(value).strip().lower()
    return normalized or None


def resolve_template_image_provider() -> str:
    override = _normalize_provider_name(settings.template_image_provider)
    if override:
        return override
    return settings.image_provider.strip().lower()


def resolve_photoshoot_image_provider() -> str:
    override = _normalize_provider_name(settings.photoshoot_image_provider)
    if override:
        return override
    return settings.image_provider.strip().lower()


def is_kie_provider(provider_name: str) -> bool:
    return provider_name.strip().lower() == KIE_IMAGE_PROVIDER
