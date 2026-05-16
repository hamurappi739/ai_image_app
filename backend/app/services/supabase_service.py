import httpx

from app.config import settings


def check_supabase_connection() -> bool:
    # Service role key is backend-only; never expose it to the Flutter frontend.
    if not settings.supabase_url:
        raise RuntimeError("SUPABASE_URL is not configured")
    if not settings.supabase_service_role_key:
        raise RuntimeError("SUPABASE_SERVICE_ROLE_KEY is not configured")

    base_url = settings.supabase_url.rstrip("/")
    url = f"{base_url}/rest/v1/profiles?select=id&limit=1"
    headers = {
        "apikey": settings.supabase_service_role_key,
        "Authorization": f"Bearer {settings.supabase_service_role_key}",
    }

    response = httpx.get(url, headers=headers, timeout=10.0)
    if response.status_code in (200, 206):
        return True
    raise RuntimeError("Supabase connection failed")
