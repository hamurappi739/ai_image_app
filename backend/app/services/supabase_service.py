import logging
from collections.abc import Callable
from urllib.parse import quote

import httpx
from fastapi import HTTPException

from app.config import settings

logger = logging.getLogger(__name__)

_SUCCESS_STATUSES = (200, 201, 204, 206)
_DEFAULT_TIMEOUT = 10.0
_SUPABASE_UNAVAILABLE_DETAIL = "Supabase is temporarily unavailable"

# Transport-layer failures (timeout, connection, TLS handshake, etc.).
_HTTPX_TRANSPORT_ERRORS = (
    httpx.ConnectTimeout,
    httpx.ReadTimeout,
    httpx.TimeoutException,
    httpx.ConnectError,
    httpx.HTTPError,
)


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


def _raise_supabase_unavailable(exc: httpx.HTTPError) -> None:
    # Log only exception type — never headers, tokens, or keys.
    logger.warning("Supabase request failed: %s", exc.__class__.__name__)
    raise HTTPException(
        status_code=503,
        detail=_SUPABASE_UNAVAILABLE_DETAIL,
    ) from exc


def _execute_supabase_request(request: Callable[[], httpx.Response]) -> httpx.Response:
    try:
        return request()
    except _HTTPX_TRANSPORT_ERRORS as exc:
        _raise_supabase_unavailable(exc)


def _supabase_get(url: str) -> httpx.Response:
    return _execute_supabase_request(
        lambda: httpx.get(url, headers=_supabase_headers(), timeout=_DEFAULT_TIMEOUT)
    )


def _supabase_post(url: str, *, json: dict) -> httpx.Response:
    return _execute_supabase_request(
        lambda: httpx.post(
            url, headers=_supabase_write_headers(), json=json, timeout=_DEFAULT_TIMEOUT
        )
    )


def _supabase_patch(url: str, *, json: dict) -> httpx.Response:
    return _execute_supabase_request(
        lambda: httpx.patch(
            url, headers=_supabase_write_headers(), json=json, timeout=_DEFAULT_TIMEOUT
        )
    )


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

    response = _supabase_get(url)
    if response.status_code in (200, 206):
        return True
    raise RuntimeError("Supabase connection failed")


def _fetch_supabase_list(url: str, error_message: str) -> list[dict]:
    response = _supabase_get(url)
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

    response = _supabase_get(url)
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


def insert_profile(data: dict) -> dict:
    base_url = _require_supabase_config()
    url = f"{base_url}/rest/v1/profiles"
    response = _supabase_post(url, json=data)
    return _parse_supabase_response(response, "Failed to create profile")


def ensure_profile_exists(user_id: str, email: str | None = None) -> dict:
    """Ensure a row exists in profiles for user_id; create if missing."""
    normalized_id = user_id.strip()
    if not normalized_id:
        raise RuntimeError("User id is required")

    profile = get_profile_by_id(normalized_id)
    normalized_email = email.strip() if email and email.strip() else None

    if profile is not None:
        if normalized_email and not profile.get("email"):
            return update_profile(normalized_id, {"email": normalized_email})
        return profile

    payload: dict = {
        "id": normalized_id,
        "free_generations_used": 0,
        "paid_credits": 0,
    }
    if normalized_email:
        payload["email"] = normalized_email

    try:
        return insert_profile(payload)
    except RuntimeError:
        profile = get_profile_by_id(normalized_id)
        if profile is None:
            raise RuntimeError("Failed to create profile") from None
        if normalized_email and not profile.get("email"):
            return update_profile(normalized_id, {"email": normalized_email})
        return profile


def update_profile(user_id: str, data: dict) -> dict:
    base_url = _require_supabase_config()
    url = f"{base_url}/rest/v1/profiles?id=eq.{quote(user_id, safe='')}"
    response = _supabase_patch(url, json=data)
    return _parse_supabase_response(response, "Failed to update profile")


def insert_generation(data: dict) -> dict:
    base_url = _require_supabase_config()
    url = f"{base_url}/rest/v1/generations"
    response = _supabase_post(url, json=data)
    return _parse_supabase_response(response, "Failed to insert generation")


def create_generation_record(
    user_id: str,
    prompt: str,
    image_url: str,
    payment_type: str,
) -> dict:
    """Insert a row into ``generations`` without consuming credits."""
    return insert_generation(
        {
            "user_id": user_id,
            "prompt": prompt,
            "image_url": image_url,
            "payment_type": payment_type,
        }
    )


def insert_credit_transaction(data: dict) -> dict:
    base_url = _require_supabase_config()
    url = f"{base_url}/rest/v1/credit_transactions"
    response = _supabase_post(url, json=data)
    return _parse_supabase_response(response, "Failed to insert credit transaction")
