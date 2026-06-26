"""Gallery image proxy — serves Supabase public generated-images via backend."""

from __future__ import annotations

from fastapi import APIRouter, HTTPException, Query
from starlette.responses import Response

from app.services.image_proxy_service import (
    ImageProxyValidationError,
    fetch_image_for_proxy,
    image_proxy_cache_control,
    validate_image_proxy_url,
)

router = APIRouter(tags=["gallery"])


@router.get("/image-proxy")
def image_proxy(url: str = Query(..., min_length=1)) -> Response:
    try:
        validated_url = validate_image_proxy_url(url)
    except ImageProxyValidationError as exc:
        raise HTTPException(status_code=400, detail=exc.detail) from exc

    body, content_type = fetch_image_for_proxy(validated_url)
    return Response(
        content=body,
        media_type=content_type,
        headers={"Cache-Control": image_proxy_cache_control()},
    )
