from fastapi import HTTPException

from app.config import settings


def get_current_user_id() -> str:
    """Development fallback for current user id.

    TODO: later replace with authenticated user id from Authorization Bearer token.
    """
    if settings.test_user_id and settings.test_user_id.strip():
        return settings.test_user_id.strip()

    raise HTTPException(
        status_code=500,
        detail="TEST_USER_ID is not configured for development mode",
    )
