from dataclasses import dataclass

import httpx
from fastapi import Header, HTTPException

from app.config import settings


@dataclass(frozen=True)
class CurrentUser:
    id: str
    email: str | None = None


def get_current_user(authorization: str | None = Header(default=None)) -> CurrentUser:
    """Resolve current user from Bearer token or development fallback."""
    if authorization:
        return _resolve_user_from_authorization_header(authorization)

    if settings.environment.strip().lower() != "development":
        raise HTTPException(status_code=401, detail="Authorization required")

    if settings.test_user_id and settings.test_user_id.strip():
        return CurrentUser(id=settings.test_user_id.strip(), email=None)

    raise HTTPException(
        status_code=500,
        detail="TEST_USER_ID is not configured for development mode",
    )


def get_current_user_id(authorization: str | None = Header(default=None)) -> str:
    """Resolve current user id (compat wrapper for Depends and direct calls)."""
    return get_current_user(authorization=authorization).id


def _resolve_user_from_authorization_header(authorization: str) -> CurrentUser:
    if not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=401, detail="Invalid or expired authorization token"
        )

    token = authorization[len("Bearer ") :].strip()
    if not token:
        raise HTTPException(
            status_code=401, detail="Invalid or expired authorization token"
        )

    user = _fetch_user_from_supabase_auth(token)
    user_id = user.get("id")
    if not user_id or not isinstance(user_id, str):
        raise HTTPException(
            status_code=401, detail="Invalid or expired authorization token"
        )

    email = user.get("email")
    if email is not None and not isinstance(email, str):
        email = None
    elif email is not None:
        email = email.strip() or None

    return CurrentUser(id=user_id, email=email)


def _fetch_user_from_supabase_auth(token: str) -> dict:
    if not settings.supabase_url or not settings.supabase_url.strip():
        raise HTTPException(status_code=500, detail="Supabase auth is not configured")
    if not settings.supabase_anon_key or not settings.supabase_anon_key.strip():
        raise HTTPException(status_code=500, detail="Supabase auth is not configured")

    url = f"{settings.supabase_url.rstrip('/')}/auth/v1/user"
    headers = {
        "apikey": settings.supabase_anon_key,
        "Authorization": f"Bearer {token}",
    }

    try:
        response = httpx.get(url, headers=headers, timeout=10.0)
    except httpx.HTTPError as exc:
        raise HTTPException(
            status_code=401, detail="Invalid or expired authorization token"
        ) from exc

    if response.status_code != 200:
        raise HTTPException(
            status_code=401, detail="Invalid or expired authorization token"
        )

    data = response.json()
    if not isinstance(data, dict):
        raise HTTPException(
            status_code=401, detail="Invalid or expired authorization token"
        )
    return data
