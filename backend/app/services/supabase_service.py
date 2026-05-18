from urllib.parse import quote

import httpx

from app.config import settings

_SUCCESS_STATUSES = (200, 201, 204, 206)


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


def _supabase_write_headers() -> dict[str, str]:
    return {
        **_supabase_headers(),
        "Content-Type": "application/json",
        "Prefer": "return=representation",
    }


def _parse_supabase_response(response: httpx.Response, error_message: str) -> dict:
    if response.status_code not in _SUCCESS_STATUSES:
        raise RuntimeError(error_message)
    if not response.content:
        return {}
    data = response.json()
    if isinstance(data, list):
        return data[0] if data else {}
    if isinstance(data, dict):
        return data
    return {}


def check_supabase_connection() -> bool:
    base_url = _require_supabase_config()
    url = f"{base_url}/rest/v1/profiles?select=id&limit=1"

    response = httpx.get(url, headers=_supabase_headers(), timeout=10.0)
    if response.status_code in (200, 206):
        return True
    raise RuntimeError("Supabase connection failed")


def _fetch_supabase_list(url: str, error_message: str) -> list[dict]:
    response = httpx.get(url, headers=_supabase_headers(), timeout=10.0)
    if response.status_code not in (200, 206):
        raise RuntimeError(error_message)
    data = response.json()
    return data if isinstance(data, list) else []


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


def get_generations_by_user_id(user_id: str, limit: int = 10) -> list[dict]:
    base_url = _require_supabase_config()
    url = (
        f"{base_url}/rest/v1/generations"
        f"?user_id=eq.{quote(user_id, safe='')}"
        "&select=id,prompt,image_url,payment_type,created_at"
        "&order=created_at.desc"
        f"&limit={limit}"
    )
    return _fetch_supabase_list(url, "Failed to fetch generations")


def get_credit_transactions_by_user_id(user_id: str, limit: int = 10) -> list[dict]:
    base_url = _require_supabase_config()
    url = (
        f"{base_url}/rest/v1/credit_transactions"
        f"?user_id=eq.{quote(user_id, safe='')}"
        "&select=id,amount,transaction_type,source,description,created_at"
        "&order=created_at.desc"
        f"&limit={limit}"
    )
    return _fetch_supabase_list(url, "Failed to fetch credit transactions")


def update_profile(user_id: str, data: dict) -> dict:
    base_url = _require_supabase_config()
    url = f"{base_url}/rest/v1/profiles?id=eq.{quote(user_id, safe='')}"
    response = httpx.patch(
        url, headers=_supabase_write_headers(), json=data, timeout=10.0
    )
    return _parse_supabase_response(response, "Failed to update profile")


def insert_generation(data: dict) -> dict:
    base_url = _require_supabase_config()
    url = f"{base_url}/rest/v1/generations"
    response = httpx.post(
        url, headers=_supabase_write_headers(), json=data, timeout=10.0
    )
    return _parse_supabase_response(response, "Failed to insert generation")


def insert_credit_transaction(data: dict) -> dict:
    base_url = _require_supabase_config()
    url = f"{base_url}/rest/v1/credit_transactions"
    response = httpx.post(
        url, headers=_supabase_write_headers(), json=data, timeout=10.0
    )
    return _parse_supabase_response(response, "Failed to insert credit transaction")
