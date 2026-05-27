import httpx
from fastapi import Header, HTTPException

from app.config import settings


def get_current_user_id(authorization: str | None = Header(default=None)) -> str:
    """Resolve current user id from Bearer token or development fallback.

    TODO: later replace/finalize with full authenticated user id flow from Authorization Bearer token.
    """
    if authorization:
        return _get_user_id_from_authorization_header(authorization)

    if settings.environment.strip().lower() != "development":
        raise HTTPException(status_code=401, detail="Authorization required")

    if settings.test_user_id and settings.test_user_id.strip():
        return settings.test_user_id.strip()

    raise HTTPException(
        status_code=500,
        detail="TEST_USER_ID is not configured for development mode",
    )


def _get_user_id_from_authorization_header(authorization: str) -> str:
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
    return user_id


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
