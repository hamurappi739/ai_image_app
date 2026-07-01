"""Kie API photoshoot provider (independent frames, identity-only references)."""

from __future__ import annotations

from collections.abc import Callable
from typing import TypeAlias

from fastapi import HTTPException

from app.config import settings
from app.services.kie_image_service import (
    KieImageGenerationError,
    KieImageTaskClient,
    bytes_to_data_url,
)
from app.services.kie_logging import kie_log
from app.services.photoshoot_prompts import (
    build_kie_photoshoot_frame_prompt,
    build_kie_rescue_frame_prompt,
    resolve_prompt_source,
)
from app.services.photoshoot_similarity import (
    KIE_DUPLICATE_RETRY_PROMPT_SUFFIX,
    find_generated_frame_duplicate,
    kie_generation_error_reason,
)
from app.services.photoshoot_styles import PhotoshootStyle
from app.services.storage_service import storage_service

FrameStatusCallback: TypeAlias = Callable[[int, str], None]

_PHOTOSHOOT_FAILURE_MESSAGE = "Photoshoot generation failed, please retry"
_KIE_DUPLICATE_MAX_ATTEMPTS = 2
_KIE_FRAME_FAIL_MAX_ATTEMPTS = 2


def _raise_kie_photoshoot_failure(
    *,
    style_id: str,
    stage: str,
    reason: str,
    photoshoot_id: str | None = None,
) -> None:
    kie_log.error(
        "Photoshoot aborted: style_id=%s photoshoot_id=%s stage=%s reason=%s",
        style_id,
        photoshoot_id,
        stage,
        reason,
    )
    raise HTTPException(status_code=502, detail=_PHOTOSHOOT_FAILURE_MESSAGE)


def _map_storage_http_failure(
    exc: HTTPException,
    *,
    style_id: str,
    photoshoot_id: str,
    stage: str,
) -> None:
    _raise_kie_photoshoot_failure(
        style_id=style_id,
        stage=stage,
        reason=f"http_{exc.status_code}",
        photoshoot_id=photoshoot_id,
    )


class KiePhotoshootProvider:
    """Uploaded photo + style instruction → Kie image data URLs (in memory only)."""

    def __init__(self, output_count: int | None = None) -> None:
        self._output_count = (
            output_count if output_count is not None else settings.photoshoot_output_count
        )

    @property
    def output_count(self) -> int:
        return self._output_count

    def generate(
        self,
        style: PhotoshootStyle,
        photo_bytes: bytes,
        photo_content_type: str,
        *,
        client_style_id: str,
        photoshoot_id: str,
        user_id: str | None = None,
        user_description: str | None = None,
        on_frame_status: FrameStatusCallback | None = None,
    ) -> list[str]:
        if not user_id or not str(user_id).strip():
            _raise_kie_photoshoot_failure(
                style_id=client_style_id,
                stage="kie_batch",
                reason="missing_user_id",
                photoshoot_id=photoshoot_id,
            )

        temp_paths: list[str] = []
        kie_client = KieImageTaskClient()
        ttl_seconds = int(settings.kie_temp_signed_url_ttl_seconds)
        series_mode = settings.photoshoot_series_reference_mode.strip().lower()
        task_cap = max(1, int(settings.kie_max_photoshoot_tasks))

        for index in range(self._output_count):
            self._notify_frame_status(on_frame_status, index, "queued")

        kie_log.info(
            "Kie photoshoot start: style_id=%s photoshoot_id=%s output_count=%s "
            "model=%s series_reference_mode=%s prompt_source=%s reference_strategy=independent_frames",
            client_style_id,
            photoshoot_id,
            self._output_count,
            settings.kie_image_model,
            series_mode,
            resolve_prompt_source(
                client_style_id,
                style,
                user_description=user_description,
            ),
        )

        try:
            kie_log.info(
                "Kie temp identity upload start: style_id=%s photoshoot_id=%s",
                client_style_id,
                photoshoot_id,
            )
            try:
                identity_path, _identity_signed = storage_service.upload_temp_input_bytes(
                    user_id,
                    photo_bytes,
                    photo_content_type,
                    ttl_seconds=ttl_seconds,
                )
            except HTTPException as exc:
                _map_storage_http_failure(
                    exc,
                    style_id=client_style_id,
                    photoshoot_id=photoshoot_id,
                    stage="kie_temp_upload",
                )

            temp_paths.append(identity_path)
            kie_log.info(
                "Kie temp identity upload done: style_id=%s photoshoot_id=%s",
                client_style_id,
                photoshoot_id,
            )

            data_urls: list[str | None] = [None] * self._output_count
            for frame_index in range(self._output_count):
                existing = [url for url in data_urls[:frame_index] if url]
                data_urls[frame_index] = self._generate_frame_with_fail_retry(
                    frame_index=frame_index,
                    style=style,
                    client_style_id=client_style_id,
                    photoshoot_id=photoshoot_id,
                    user_description=user_description,
                    series_mode=series_mode,
                    identity_path=identity_path,
                    existing_data_urls=existing,
                    ttl_seconds=ttl_seconds,
                    kie_client=kie_client,
                    task_cap=task_cap,
                    on_frame_status=on_frame_status,
                )

            return self._finalize_data_urls(
                data_urls,
                client_style_id=client_style_id,
                photoshoot_id=photoshoot_id,
                kie_client=kie_client,
            )
        finally:
            storage_service.delete_temp_objects_best_effort(temp_paths)
            kie_log.info(
                "Kie temp cleanup done: style_id=%s photoshoot_id=%s objects=%s",
                client_style_id,
                photoshoot_id,
                len(temp_paths),
            )

    def _generate_frame_with_fail_retry(
        self,
        *,
        frame_index: int,
        style: PhotoshootStyle,
        client_style_id: str,
        photoshoot_id: str,
        user_description: str | None,
        series_mode: str,
        identity_path: str,
        existing_data_urls: list[str],
        ttl_seconds: int,
        kie_client: KieImageTaskClient,
        task_cap: int,
        on_frame_status: FrameStatusCallback | None,
    ) -> str:
        last_reason = "kie_frame_failed"
        for fail_attempt in range(_KIE_FRAME_FAIL_MAX_ATTEMPTS):
            use_rescue_prompt = fail_attempt > 0
            try:
                return self._generate_unique_frame_data_url(
                    frame_index=frame_index,
                    style=style,
                    client_style_id=client_style_id,
                    photoshoot_id=photoshoot_id,
                    user_description=user_description,
                    series_mode=series_mode,
                    identity_path=identity_path,
                    existing_data_urls=existing_data_urls,
                    ttl_seconds=ttl_seconds,
                    kie_client=kie_client,
                    task_cap=task_cap,
                    on_frame_status=on_frame_status,
                    use_rescue_prompt=use_rescue_prompt,
                )
            except KieImageGenerationError as exc:
                last_reason = kie_generation_error_reason(exc)
                if exc.fail_code or exc.fail_message:
                    kie_log.warning(
                        "Kie frame failed: style_id=%s photoshoot_id=%s frame_index=%s "
                        "attempt=%s fail_code=%s fail_message=%s reason=%s",
                        client_style_id,
                        photoshoot_id,
                        frame_index,
                        fail_attempt + 1,
                        exc.fail_code or "",
                        exc.fail_message or "",
                        last_reason,
                    )
                if fail_attempt + 1 >= _KIE_FRAME_FAIL_MAX_ATTEMPTS:
                    break
                kie_log.warning(
                    "Kie frame failed, retrying with rescue prompt: style_id=%s "
                    "photoshoot_id=%s frame_index=%s retry=1/1 reason=%s",
                    client_style_id,
                    photoshoot_id,
                    frame_index,
                    last_reason,
                )

        self._notify_frame_status(on_frame_status, frame_index, "error")
        _raise_kie_photoshoot_failure(
            style_id=client_style_id,
            stage="kie_batch",
            reason=last_reason,
            photoshoot_id=photoshoot_id,
        )

    def _generate_unique_frame_data_url(
        self,
        *,
        frame_index: int,
        style: PhotoshootStyle,
        client_style_id: str,
        photoshoot_id: str,
        user_description: str | None,
        series_mode: str,
        identity_path: str,
        existing_data_urls: list[str],
        ttl_seconds: int,
        kie_client: KieImageTaskClient,
        task_cap: int,
        on_frame_status: FrameStatusCallback | None,
        extra_prompt_suffix: str = "",
        use_rescue_prompt: bool = False,
    ) -> str:
        for attempt in range(_KIE_DUPLICATE_MAX_ATTEMPTS):
            prompt_suffix = extra_prompt_suffix
            if attempt > 0:
                prompt_suffix = f"{prompt_suffix}\n\n{KIE_DUPLICATE_RETRY_PROMPT_SUFFIX}"
            try:
                data_url = self._generate_frame_data_url(
                    frame_index=frame_index,
                    style=style,
                    client_style_id=client_style_id,
                    photoshoot_id=photoshoot_id,
                    user_description=user_description,
                    series_mode=series_mode,
                    identity_path=identity_path,
                    ttl_seconds=ttl_seconds,
                    kie_client=kie_client,
                    task_cap=task_cap,
                    prompt_suffix=prompt_suffix,
                    on_frame_status=on_frame_status,
                    use_rescue_prompt=use_rescue_prompt,
                )
            except KieImageGenerationError:
                raise
            duplicate_match = find_generated_frame_duplicate(data_url, existing_data_urls)
            if duplicate_match is None:
                return data_url

            kie_log.warning(
                "Kie duplicate frame detected: style_id=%s photoshoot_id=%s frame_index=%s "
                "attempt=%s duplicate_check=%s duplicate_frame_index=%s duplicate_distance=%s",
                client_style_id,
                photoshoot_id,
                frame_index,
                attempt + 1,
                duplicate_match.kind,
                duplicate_match.duplicate_frame_index,
                duplicate_match.perceptual_distance,
            )

        _raise_kie_photoshoot_failure(
            style_id=client_style_id,
            stage="kie_batch",
            reason="duplicate_frame_persists",
            photoshoot_id=photoshoot_id,
        )

    def _finalize_data_urls(
        self,
        data_urls: list[str | None],
        *,
        client_style_id: str,
        photoshoot_id: str,
        kie_client: KieImageTaskClient,
    ) -> list[str]:
        finalized = [url for url in data_urls if url]
        if len(finalized) != self._output_count:
            _raise_kie_photoshoot_failure(
                style_id=client_style_id,
                stage="kie_batch",
                reason=f"frame_count_mismatch:{len(finalized)}/{self._output_count}",
                photoshoot_id=photoshoot_id,
            )
        kie_log.info(
            "Kie photoshoot complete: style_id=%s photoshoot_id=%s frames=%s "
            "created_tasks_count=%s http_calls_count=%s",
            client_style_id,
            photoshoot_id,
            len(finalized),
            kie_client.created_tasks_count,
            kie_client.http_calls_count,
        )
        return finalized

    def _generate_frame_data_url(
        self,
        *,
        frame_index: int,
        style: PhotoshootStyle,
        client_style_id: str,
        photoshoot_id: str,
        user_description: str | None,
        series_mode: str,
        identity_path: str,
        ttl_seconds: int,
        kie_client: KieImageTaskClient,
        task_cap: int,
        prompt_suffix: str = "",
        on_frame_status: FrameStatusCallback | None,
        use_rescue_prompt: bool = False,
    ) -> str:
        self._notify_frame_status(on_frame_status, frame_index, "generating")

        if use_rescue_prompt:
            instruction = build_kie_rescue_frame_prompt(style, frame_index=frame_index)
        else:
            instruction = build_kie_photoshoot_frame_prompt(
                client_style_id,
                style,
                frame_index=frame_index,
                output_count=self._output_count,
                user_description=user_description,
                series_reference_mode=series_mode,
            )
            if prompt_suffix:
                instruction = f"{instruction}{prompt_suffix}"

        input_urls = self._build_input_urls(
            identity_path=identity_path,
            ttl_seconds=ttl_seconds,
            client_style_id=client_style_id,
            photoshoot_id=photoshoot_id,
        )
        kie_log.info(
            "Kie frame start: style_id=%s photoshoot_id=%s frame_index=%s "
            "reference_count=%s",
            client_style_id,
            photoshoot_id,
            frame_index,
            len(input_urls),
        )

        try:
            image_bytes, content_type = kie_client.generate_image_bytes(
                instruction,
                input_urls,
                style_id=client_style_id,
                photoshoot_id=photoshoot_id,
                frame_index=frame_index,
                max_created_tasks=task_cap,
            )
        except KieImageGenerationError:
            self._notify_frame_status(on_frame_status, frame_index, "error")
            raise
        except HTTPException as exc:
            self._notify_frame_status(on_frame_status, frame_index, "error")
            _raise_kie_photoshoot_failure(
                style_id=client_style_id,
                stage="kie_batch",
                reason=f"http_{exc.status_code}",
                photoshoot_id=photoshoot_id,
            )

        self._notify_frame_status(on_frame_status, frame_index, "done")
        return bytes_to_data_url(image_bytes, content_type)

    @staticmethod
    def _notify_frame_status(
        callback: FrameStatusCallback | None,
        frame_index: int,
        status: str,
    ) -> None:
        if callback is None:
            return
        callback(frame_index, status)

    def _build_input_urls(
        self,
        *,
        identity_path: str,
        ttl_seconds: int,
        client_style_id: str,
        photoshoot_id: str,
    ) -> list[str]:
        bucket = settings.supabase_temp_storage_bucket

        try:
            identity_signed = storage_service.create_signed_url(
                identity_path,
                ttl_seconds=ttl_seconds,
                bucket=bucket,
            )
        except HTTPException as exc:
            _map_storage_http_failure(
                exc,
                style_id=client_style_id,
                photoshoot_id=photoshoot_id,
                stage="kie_signed_url",
            )

        return [identity_signed]
