"""Health and readiness probes for deploy / load balancers."""

from __future__ import annotations

from fastapi import APIRouter

from app.config import settings
from app.schemas import HealthResponse, ReadyChecks, ReadyResponse
from app.services.image_provider_resolver import (
    is_kie_provider,
    resolve_photoshoot_image_provider,
    resolve_template_image_provider,
)

router = APIRouter(tags=["health"])


@router.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    """Liveness probe — no secrets, no external calls."""
    return HealthResponse(
        status="ok",
        environment=settings.environment.strip().lower(),
        version=settings.app_version,
    )


@router.get("/ready", response_model=ReadyResponse)
def ready() -> ReadyResponse:
    """Readiness probe — config flags only, no secret values, no heavy Supabase queries."""
    template_provider = resolve_template_image_provider()
    photoshoot_provider = resolve_photoshoot_image_provider()
    gemini_required = template_provider == "gemini" or photoshoot_provider == "gemini"
    kie_required = is_kie_provider(template_provider) or is_kie_provider(
        photoshoot_provider
    )
    checks = ReadyChecks(
        config_loaded=True,
        supabase_configured=settings.supabase_configured(),
        supabase_auth_configured=settings.supabase_auth_configured(),
        gemini_required=gemini_required,
        gemini_configured=settings.gemini_configured(),
        kie_required=kie_required,
        kie_configured=settings.kie_configured(),
        production_safe=settings.production_safety_ok(),
    )
    is_ready = (
        checks.config_loaded
        and checks.production_safe
        and checks.supabase_configured
        and checks.supabase_auth_configured
        and (not checks.gemini_required or checks.gemini_configured)
        and (not checks.kie_required or checks.kie_configured)
    )
    return ReadyResponse(
        status="ready" if is_ready else "not_ready",
        environment=settings.environment.strip().lower(),
        checks=checks,
    )
