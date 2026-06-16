"""CORS policy: permissive in development, env-driven in production."""

from __future__ import annotations

from app.config import settings


def cors_allow_origins() -> list[str]:
    explicit = settings.cors_origins_list()
    if explicit:
        return explicit
    if settings.is_development:
        return ["*"]
    return []
