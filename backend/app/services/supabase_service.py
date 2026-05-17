from urllib.parse import quote

import httpx

from app.config import settings


def _require_supabase_config() -> str:
    # Service role key is backend-only; never expose it to the Flutter frontend.
    if not settings.supabase_url:
        raise RuntimeError("SUPABASE_URL is not configured")
    if not settings.supabase_service_role_key:
        raise RuntimeError("SUPABASE_SERVICE_ROLE_KEY is not configured")
    return settings.supabase_url.rstrip("/")


def _supabase_headers() -> dict[str, str]:
    return {
        "apikey": settings.supabase_service_role_key,
        "Authorization": f"Bearer {settings.supabase_service_role_key}",
    }


def check_supabase_connection() -> bool:
    base_url = _require_supabase_config()
    url = f"{base_url}/rest/v1/profiles?select=id&limit=1"

    response = httpx.get(url, headers=_supabase_headers(), timeout=10.0)
    if response.status_code in (200, 206):
        return True
    raise RuntimeError("Supabase connection failed")


def get_profile_by_id(user_id: str) -> dict | None:
    base_url = _require_supabase_config()
    url = (
        f"{base_url}/rest/v1/profiles"
        f"?id=eq.{quote(user_id, safe='')}"
        "&select=id,email,free_generations_used,paid_credits"
        "&limit=1"
    )

    response = httpx.get(url, headers=_supabase_headers(), timeout=10.0)
    if response.status_code not in (200, 206):
        raise RuntimeError("Failed to fetch profile")

    rows = response.json()
    if not rows:
        return None
    return rows[0]
