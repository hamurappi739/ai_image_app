"""Kie API photoshoot provider (parallel frames 1/2 after anchor frame 0)."""

from __future__ import annotations

import threading
from collections.abc import Callable
from concurrent.futures import ThreadPoolExecutor, as_completed
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
    resolve_prompt_source,
)
from app.services.photoshoot_styles import PhotoshootStyle
from app.services.storage_service import storage_service

FrameStatusCallback: TypeAlias = Callable[[int, str], None]

_PHOTOSHOOT_FAILURE_MESSAGE = "Photoshoot generation failed, please retry"


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
            "model=%s series_reference_mode=%s prompt_source=%s",
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
            anchor_path: str | None = None

            data_urls[0] = self._generate_frame_data_url(
                frame_index=0,
                style=style,
                client_style_id=client_style_id,
                photoshoot_id=photoshoot_id,
                user_description=user_description,
                series_mode=series_mode,
                identity_path=identity_path,
                anchor_path=anchor_path,
                ttl_seconds=ttl_seconds,
                kie_client=kie_client,
                task_cap=task_cap,
                has_generated_frames=False,
                on_frame_status=on_frame_status,
            )

            if self._output_count == 1:
                return self._finalize_data_urls(
                    data_urls,
                    client_style_id=client_style_id,
                    photoshoot_id=photoshoot_id,
                    kie_client=kie_client,
                )

            if series_mode != "legacy":
                kie_log.info(
                    "Kie temp anchor upload start: style_id=%s photoshoot_id=%s frame_index=%s",
                    client_style_id,
                    photoshoot_id,
                    0,
                )
                try:
                    anchor_path, _anchor_signed = storage_service.upload_temp_input_data_url(
                        user_id,
                        data_urls[0],
                        ttl_seconds=ttl_seconds,
                    )
                except HTTPException as exc:
                    _map_storage_http_failure(
                        exc,
                        style_id=client_style_id,
                        photoshoot_id=photoshoot_id,
                        stage="kie_temp_upload_anchor",
                    )
                temp_paths.append(anchor_path)
                kie_log.info(
                    "Kie temp anchor upload done: style_id=%s photoshoot_id=%s frame_index=%s",
                    client_style_id,
                    photoshoot_id,
                    0,
                )

            parallel_indices = list(range(1, self._output_count))
            if len(parallel_indices) == 1:
                index = parallel_indices[0]
                data_urls[index] = self._generate_frame_data_url(
                    frame_index=index,
                    style=style,
                    client_style_id=client_style_id,
                    photoshoot_id=photoshoot_id,
                    user_description=user_description,
                    series_mode=series_mode,
                    identity_path=identity_path,
                    anchor_path=anchor_path,
                    ttl_seconds=ttl_seconds,
                    kie_client=kie_client,
                    task_cap=task_cap,
                    has_generated_frames=True,
                    on_frame_status=on_frame_status,
                )
            else:
                kie_log.info(
                    "Kie parallel batch start: style_id=%s photoshoot_id=%s frame_indices=%s",
                    client_style_id,
                    photoshoot_id,
                    parallel_indices,
                )
                errors: list[BaseException] = []
                with ThreadPoolExecutor(max_workers=2) as executor:
                    futures = {
                        executor.submit(
                            self._generate_frame_data_url,
                            frame_index=index,
                            style=style,
                            client_style_id=client_style_id,
                            photoshoot_id=photoshoot_id,
                            user_description=user_description,
                            series_mode=series_mode,
                            identity_path=identity_path,
                            anchor_path=anchor_path,
                            ttl_seconds=ttl_seconds,
                            kie_client=kie_client,
                            task_cap=task_cap,
                            has_generated_frames=True,
                            on_frame_status=on_frame_status,
                        ): index
                        for index in parallel_indices
                    }
                    for future in as_completed(futures):
                        index = futures[future]
                        try:
                            data_urls[index] = future.result()
                        except BaseException as exc:
                            errors.append(exc)
                if errors:
                    if isinstance(errors[0], HTTPException):
                        raise errors[0]
                    if isinstance(errors[0], KieImageGenerationError):
                        _raise_kie_photoshoot_failure(
                            style_id=client_style_id,
                            stage="kie_batch",
                            reason=str(errors[0]),
                            photoshoot_id=photoshoot_id,
                        )
                    raise errors[0]
                kie_log.info(
                    "Kie parallel batch done: style_id=%s photoshoot_id=%s frames=%s",
                    client_style_id,
                    photoshoot_id,
                    parallel_indices,
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
        anchor_path: str | None,
        ttl_seconds: int,
        kie_client: KieImageTaskClient,
        task_cap: int,
        has_generated_frames: bool,
        on_frame_status: FrameStatusCallback | None,
    ) -> str:
        self._notify_frame_status(on_frame_status, frame_index, "generating")

        instruction = build_kie_photoshoot_frame_prompt(
            client_style_id,
            style,
            frame_index=frame_index,
            output_count=self._output_count,
            user_description=user_description,
            series_reference_mode=series_mode,
        )
        input_urls = self._build_input_urls(
            series_mode=series_mode,
            frame_index=frame_index,
            identity_path=identity_path,
            anchor_path=anchor_path,
            ttl_seconds=ttl_seconds,
            client_style_id=client_style_id,
            photoshoot_id=photoshoot_id,
            has_frames=has_generated_frames,
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
        except KieImageGenerationError as exc:
            self._notify_frame_status(on_frame_status, frame_index, "error")
            _raise_kie_photoshoot_failure(
                style_id=client_style_id,
                stage="kie_batch",
                reason=str(exc),
                photoshoot_id=photoshoot_id,
            )
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
        series_mode: str,
        frame_index: int,
        identity_path: str,
        anchor_path: str | None,
        ttl_seconds: int,
        client_style_id: str,
        photoshoot_id: str,
        has_frames: bool,
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

        if frame_index == 0 or series_mode == "legacy":
            return [identity_signed]

        if not has_frames or anchor_path is None:
            _raise_kie_photoshoot_failure(
                style_id=client_style_id,
                stage="kie_batch",
                reason="missing_series_anchor",
                photoshoot_id=photoshoot_id,
            )

        try:
            if series_mode == "anchor_only":
                anchor_signed = storage_service.create_signed_url(
                    anchor_path,
                    ttl_seconds=ttl_seconds,
                    bucket=bucket,
                )
                return [anchor_signed]

            anchor_signed = storage_service.create_signed_url(
                anchor_path,
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

        return [identity_signed, anchor_signed]
