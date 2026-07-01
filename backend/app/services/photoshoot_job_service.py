"""Background photoshoot job runner with per-frame progress updates."""

from __future__ import annotations

import logging
import threading
from typing import Any

from fastapi import HTTPException

from app.config import settings
from app.services.balance_service import (
    build_balance_response,
    consume_photoshoot,
    determine_photoshoot_payment,
)
from app.services.photoshoot_job_store import (
    PhotoshootJobRecord,
    PhotoshootJobStartPayload,
    photoshoot_job_store,
)
from app.services.photoshoot_service import (
    PhotoshootService,
    rollback_persisted_photoshoot,
)
from app.services.photoshoot_styles import get_photoshoot_style
from app.services.supabase_service import ensure_profile_exists

logger = logging.getLogger("uvicorn.error")

_PHOTOSHOOT_JOB_ERROR_MESSAGE = "Photoshoot generation failed"
_photoshoot_service = PhotoshootService()


def start_photoshoot_job(
    *,
    user_id: str,
    user_email: str | None,
    style_id: str,
    style_title: str,
    photo_bytes: bytes,
    photo_content_type: str,
    user_description: str | None,
    output_count: int,
) -> str:
    job = photoshoot_job_store.create_job(
        user_id=user_id,
        style_id=style_id,
        style_title=style_title or style_id,
        output_count=output_count,
    )
    photoshoot_job_store.put_start_payload(
        job.job_id,
        PhotoshootJobStartPayload(
            user_id=user_id,
            user_email=user_email,
            style_id=style_id,
            style_title=style_title or style_id,
            photo_bytes=photo_bytes,
            photo_content_type=photo_content_type,
            user_description=user_description,
            output_count=output_count,
        ),
    )
    thread = threading.Thread(
        target=_run_photoshoot_job,
        args=(job.job_id,),
        name=f"photoshoot-job-{job.job_id}",
        daemon=True,
    )
    thread.start()
    return job.job_id


def get_photoshoot_job_status(job_id: str, *, user_id: str) -> dict[str, Any]:
    job = photoshoot_job_store.get_job(job_id)
    if job is None or job.user_id != user_id:
        raise HTTPException(status_code=404, detail="Photoshoot job not found")
    return job.to_status_payload()


def _run_photoshoot_job(job_id: str) -> None:
    job = photoshoot_job_store.get_job(job_id)
    payload = photoshoot_job_store.get_start_payload(job_id)
    if job is None or payload is None:
        return

    job.status = "running"
    job.message = "Photoshoot generation in progress"
    photoshoot_job_store.save_job(job)

    profile = None
    try:
        if not settings.enable_photoshoot_generation:
            raise HTTPException(
                status_code=501,
                detail="Photoshoot generation is disabled in development mode",
            )

        style = get_photoshoot_style(payload.style_id)

        if settings.enable_credit_consumption:
            profile = ensure_profile_exists(payload.user_id, payload.user_email)
            decision = determine_photoshoot_payment(
                profile,
                settings.free_generations_limit,
            )
            if not decision["allowed"]:
                raise HTTPException(status_code=402, detail=decision["reason"])

        def on_frame_status(frame_index: int, status: str) -> None:
            current = photoshoot_job_store.get_job(job_id)
            if current is None:
                return
            if 0 <= frame_index < len(current.frames):
                current.frames[frame_index].status = status  # type: ignore[assignment]
            current.status = "running"
            current.message = "Photoshoot generation in progress"
            photoshoot_job_store.save_job(current)

        result = _photoshoot_service.generate_photoshoot(
            user_id=payload.user_id,
            style=style,
            photo_bytes=payload.photo_bytes,
            photo_content_type=payload.photo_content_type,
            client_style_id=payload.style_id,
            user_description=payload.user_description,
            on_frame_status=on_frame_status,
        )

        balance_payload = None
        if settings.enable_credit_consumption and profile is not None:
            try:
                updated_profile = consume_photoshoot(
                    profile,
                    settings.free_generations_limit,
                )
                balance_payload = _balance_to_dict(updated_profile)
            except (HTTPException, RuntimeError):
                rollback_persisted_photoshoot(
                    photoshoot_id=result.photoshoot_id,
                    storage_paths=result.storage_paths,
                    client_style_id=payload.style_id,
                )
                raise

        finished = photoshoot_job_store.get_job(job_id)
        if finished is None:
            return
        finished.status = "success"
        finished.message = "Photoshoot ready"
        finished.images = list(result.image_urls)
        finished.thumbnail_urls = list(result.thumbnail_urls)
        finished.photoshoot_id = result.photoshoot_id
        finished.storage_paths = list(result.storage_paths)
        finished.balance = balance_payload
        finished.description = payload.user_description
        photoshoot_job_store.save_job(finished)
        logger.info(
            "Photoshoot job success: job_id=%s photoshoot_id=%s frames=%s",
            job_id,
            result.photoshoot_id,
            len(result.image_urls),
        )
    except HTTPException as exc:
        _mark_job_error(job_id, _photoshoot_job_error_message(exc))
    except Exception:
        logger.exception("Photoshoot job failed: job_id=%s", job_id)
        _mark_job_error(job_id, _PHOTOSHOOT_JOB_ERROR_MESSAGE)


def _mark_job_error(job_id: str, message: str) -> None:
    job = photoshoot_job_store.get_job(job_id)
    if job is None:
        return
    job.status = "error"
    job.message = message
    for frame in job.frames:
        if frame.status in ("queued", "generating"):
            frame.status = "error"
    photoshoot_job_store.save_job(job)


def _photoshoot_job_error_message(exc: HTTPException) -> str:
    if exc.status_code == 402:
        return str(exc.detail)
    return _PHOTOSHOOT_JOB_ERROR_MESSAGE


def _balance_to_dict(profile: dict) -> dict:
    return build_balance_response(
        profile,
        settings.free_generations_limit,
        consumption_enabled=settings.enable_credit_consumption,
    )
