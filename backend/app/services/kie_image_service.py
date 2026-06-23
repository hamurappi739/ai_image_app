"""Kie API image-to-image task client (createTask + poll + download)."""

from __future__ import annotations

import json
import threading
import time
from typing import Any

import httpx
from fastapi import HTTPException

from app.config import settings
from app.services.kie_logging import kie_log
from app.services.kie_rate_limiter import acquire_kie_create_task_slot

_PENDING_STATES = frozenset({"waiting", "queuing", "generating"})
_SUCCESS_STATE = "success"
_FAIL_STATE = "fail"
_NON_RETRYABLE_HTTP_STATUSES = frozenset({401, 402, 422})
_RETRYABLE_HTTP_STATUSES = frozenset({429, 455, 500, 503})
_SENSITIVE_LOG_TOKENS = (
    "api key",
    "api_key",
    "authorization",
    "bearer",
    "secret",
    "token",
    "signed",
    "http://",
    "https://",
)


class KieImageGenerationError(Exception):
    """Terminal Kie image generation failure (safe to map to HTTP 502)."""


class KieRetryableCreateTaskError(Exception):
    """Transient createTask failure eligible for retry within attempt budget."""


class KieImageTaskClient:
    """Stateful Kie jobs client with HTTP and generation-task counters."""

    def __init__(self) -> None:
        self.http_calls_count = 0
        self.created_tasks_count = 0
        self._counter_lock = threading.Lock()

    def _check_task_cap(self, max_created_tasks: int | None) -> None:
        if max_created_tasks is None:
            return
        with self._counter_lock:
            if self.created_tasks_count >= max_created_tasks:
                raise KieImageGenerationError("kie_tasks_cap_exceeded")

    def _record_http_call(self) -> None:
        with self._counter_lock:
            self.http_calls_count += 1

    def _record_create_task_attempt(self) -> int:
        with self._counter_lock:
            self.http_calls_count += 1
            self.created_tasks_count += 1
            return self.created_tasks_count

    def generate_image_bytes(
        self,
        prompt: str,
        input_urls: list[str],
        *,
        style_id: str | None = None,
        photoshoot_id: str | None = None,
        frame_index: int | None = None,
        max_created_tasks: int | None = None,
    ) -> tuple[bytes, str]:
        if not settings.kie_configured():
            raise HTTPException(status_code=500, detail="KIE_API_KEY is not configured")
        if not input_urls:
            raise KieImageGenerationError("kie_missing_input_urls")

        task_id = self._create_task_with_retries(
            prompt=prompt,
            input_urls=input_urls,
            style_id=style_id,
            photoshoot_id=photoshoot_id,
            frame_index=frame_index,
            max_created_tasks=max_created_tasks,
        )
        result_url = self._poll_until_result(
            task_id,
            style_id=style_id,
            photoshoot_id=photoshoot_id,
            frame_index=frame_index,
        )
        content, content_type = self._download_result_image(
            result_url,
            style_id=style_id,
            photoshoot_id=photoshoot_id,
            frame_index=frame_index,
        )
        kie_log.info(
            "Kie generate_image_bytes done: style_id=%s photoshoot_id=%s frame_index=%s "
            "http_calls_count=%s created_tasks_count=%s",
            style_id,
            photoshoot_id,
            frame_index,
            self.http_calls_count,
            self.created_tasks_count,
        )
        return content, content_type

    def _create_task_with_retries(
        self,
        *,
        prompt: str,
        input_urls: list[str],
        style_id: str | None,
        photoshoot_id: str | None,
        frame_index: int | None,
        max_created_tasks: int | None,
    ) -> str:
        max_attempts = max(1, int(settings.kie_max_create_task_attempts))
        last_error: Exception | None = None
        for attempt in range(1, max_attempts + 1):
            self._check_task_cap(max_created_tasks)
            try:
                return self._create_task(
                    prompt=prompt,
                    input_urls=input_urls,
                    style_id=style_id,
                    photoshoot_id=photoshoot_id,
                    frame_index=frame_index,
                    attempt=attempt,
                )
            except KieImageGenerationError:
                raise
            except KieRetryableCreateTaskError as exc:
                last_error = exc
                if attempt >= max_attempts:
                    break
            except Exception as exc:
                last_error = exc
                if attempt >= max_attempts:
                    break
        raise KieImageGenerationError(
            f"kie_create_task_failed:{type(last_error).__name__ if last_error else 'unknown'}"
        ) from last_error

    def _create_task(
        self,
        *,
        prompt: str,
        input_urls: list[str],
        style_id: str | None,
        photoshoot_id: str | None,
        frame_index: int | None,
        attempt: int,
    ) -> str:
        base_url = (settings.kie_api_base_url or "").rstrip("/")
        url = f"{base_url}/api/v1/jobs/createTask"
        payload = {
            "model": settings.kie_image_model,
            "input": {
                "prompt": prompt,
                "input_urls": input_urls,
                "aspect_ratio": settings.kie_image_aspect_ratio,
                "resolution": settings.kie_image_resolution,
            },
        }
        headers = {
            "Authorization": f"Bearer {settings.kie_api_key.strip()}",
            "Content-Type": "application/json",
        }
        started = time.monotonic()
        acquire_kie_create_task_slot()
        created_tasks_count = self._record_create_task_attempt()
        kie_log.info(
            "Kie create_task start: model=%s style_id=%s photoshoot_id=%s "
            "frame_index=%s attempt=%s created_tasks_count=%s",
            settings.kie_image_model,
            style_id,
            photoshoot_id,
            frame_index,
            attempt,
            created_tasks_count,
        )
        try:
            response = httpx.post(url, headers=headers, json=payload, timeout=120.0)
        except httpx.HTTPError as exc:
            self._log_kie_event(
                event="create_task",
                style_id=style_id,
                photoshoot_id=photoshoot_id,
                frame_index=frame_index,
                task_id=None,
                attempt=attempt,
                state="network_error",
                elapsed_ms=int((time.monotonic() - started) * 1000),
            )
            raise KieRetryableCreateTaskError("kie_create_task_network") from exc

        elapsed_ms = int((time.monotonic() - started) * 1000)
        if response.status_code in _NON_RETRYABLE_HTTP_STATUSES:
            self._log_kie_event(
                event="create_task",
                style_id=style_id,
                photoshoot_id=photoshoot_id,
                frame_index=frame_index,
                task_id=None,
                attempt=attempt,
                state=f"http_{response.status_code}",
                elapsed_ms=elapsed_ms,
            )
            raise KieImageGenerationError(f"kie_create_task_http_{response.status_code}")

        if response.status_code in _RETRYABLE_HTTP_STATUSES:
            self._log_kie_event(
                event="create_task",
                style_id=style_id,
                photoshoot_id=photoshoot_id,
                frame_index=frame_index,
                task_id=None,
                attempt=attempt,
                state=f"http_{response.status_code}",
                elapsed_ms=elapsed_ms,
            )
            raise KieRetryableCreateTaskError(
                f"kie_create_task_http_{response.status_code}"
            )

        if response.status_code >= 400:
            self._log_kie_event(
                event="create_task",
                style_id=style_id,
                photoshoot_id=photoshoot_id,
                frame_index=frame_index,
                task_id=None,
                attempt=attempt,
                state=f"http_{response.status_code}",
                elapsed_ms=elapsed_ms,
            )
            raise KieImageGenerationError(f"kie_create_task_http_{response.status_code}")

        body = response.json()
        task_id = _extract_task_id(body)
        if not task_id:
            raise KieImageGenerationError("kie_create_task_missing_task_id")

        self._log_kie_event(
            event="create_task",
            style_id=style_id,
            photoshoot_id=photoshoot_id,
            frame_index=frame_index,
            task_id=task_id,
            attempt=attempt,
            state="created",
            elapsed_ms=elapsed_ms,
        )
        return task_id

    def _poll_until_result(
        self,
        task_id: str,
        *,
        style_id: str | None,
        photoshoot_id: str | None,
        frame_index: int | None,
    ) -> str:
        deadline = time.monotonic() + float(settings.kie_task_timeout_seconds)
        delay = float(settings.kie_poll_initial_delay_seconds)
        max_delay = float(settings.kie_poll_max_delay_seconds)
        poll_attempt = 0

        while time.monotonic() < deadline:
            time.sleep(delay)
            poll_attempt += 1
            started = time.monotonic()
            state, result_urls = self._poll_task_once(
                task_id,
                style_id=style_id,
                photoshoot_id=photoshoot_id,
                frame_index=frame_index,
                attempt=poll_attempt,
            )
            elapsed_ms = int((time.monotonic() - started) * 1000)

            if state in _PENDING_STATES:
                if poll_attempt % 5 == 0:
                    self._log_kie_event(
                        event="poll",
                        style_id=style_id,
                        photoshoot_id=photoshoot_id,
                        frame_index=frame_index,
                        task_id=task_id,
                        attempt=poll_attempt,
                        state=state,
                        elapsed_ms=elapsed_ms,
                    )
                delay = min(delay * 2, max_delay)
                continue

            if state == _SUCCESS_STATE:
                if not result_urls:
                    self._log_kie_event(
                        event="poll",
                        style_id=style_id,
                        photoshoot_id=photoshoot_id,
                        frame_index=frame_index,
                        task_id=task_id,
                        attempt=poll_attempt,
                        state="success_empty_results",
                        elapsed_ms=elapsed_ms,
                    )
                    raise KieImageGenerationError("kie_empty_result_urls")
                self._log_kie_event(
                    event="poll",
                    style_id=style_id,
                    photoshoot_id=photoshoot_id,
                    frame_index=frame_index,
                    task_id=task_id,
                    attempt=poll_attempt,
                    state=state,
                    elapsed_ms=elapsed_ms,
                )
                return result_urls[0]

            if state == _FAIL_STATE:
                self._log_kie_event(
                    event="poll",
                    style_id=style_id,
                    photoshoot_id=photoshoot_id,
                    frame_index=frame_index,
                    task_id=task_id,
                    attempt=poll_attempt,
                    state=state,
                    elapsed_ms=elapsed_ms,
                )
                raise KieImageGenerationError("kie_task_failed")

            if poll_attempt % 5 == 0:
                self._log_kie_event(
                    event="poll",
                    style_id=style_id,
                    photoshoot_id=photoshoot_id,
                    frame_index=frame_index,
                    task_id=task_id,
                    attempt=poll_attempt,
                    state=state or "unknown",
                    elapsed_ms=elapsed_ms,
                )
            delay = min(delay * 2, max_delay)

        self._log_kie_event(
            event="poll",
            style_id=style_id,
            photoshoot_id=photoshoot_id,
            frame_index=frame_index,
            task_id=task_id,
            attempt=poll_attempt,
            state="timeout",
            elapsed_ms=0,
        )
        raise KieImageGenerationError("kie_task_timeout")

    def _poll_task_once(
        self,
        task_id: str,
        *,
        style_id: str | None,
        photoshoot_id: str | None,
        frame_index: int | None,
        attempt: int,
    ) -> tuple[str, list[str]]:
        base_url = (settings.kie_api_base_url or "").rstrip("/")
        url = f"{base_url}/api/v1/jobs/recordInfo"
        headers = {"Authorization": f"Bearer {settings.kie_api_key.strip()}"}
        self._record_http_call()
        try:
            response = httpx.get(
                url,
                headers=headers,
                params={"taskId": task_id},
                timeout=60.0,
            )
        except httpx.HTTPError as exc:
            self._log_kie_event(
                event="poll",
                style_id=style_id,
                photoshoot_id=photoshoot_id,
                frame_index=frame_index,
                task_id=task_id,
                attempt=attempt,
                state="network_error",
                elapsed_ms=0,
            )
            raise KieImageGenerationError("kie_poll_network") from exc

        if response.status_code in _NON_RETRYABLE_HTTP_STATUSES:
            raise KieImageGenerationError(f"kie_poll_http_{response.status_code}")
        if response.status_code >= 400:
            raise KieImageGenerationError(f"kie_poll_http_{response.status_code}")

        body = response.json()
        state = _extract_task_state(body)
        result_urls = _extract_result_urls(body) if state == _SUCCESS_STATE else []
        return state, result_urls

    def _download_result_image(
        self,
        result_url: str,
        *,
        style_id: str | None = None,
        photoshoot_id: str | None = None,
        frame_index: int | None = None,
    ) -> tuple[bytes, str]:
        self._record_http_call()
        try:
            response = httpx.get(result_url, timeout=120.0, follow_redirects=True)
        except httpx.HTTPError as exc:
            raise KieImageGenerationError("kie_result_download_network") from exc

        if response.status_code >= 400:
            raise KieImageGenerationError(f"kie_result_download_http_{response.status_code}")

        content = response.content
        if not content:
            raise KieImageGenerationError("kie_result_download_empty")

        content_type = (response.headers.get("content-type") or "image/png").split(";")[0].strip()
        if not content_type.startswith("image/"):
            content_type = "image/png"
        kie_log.info(
            "Kie result download done: style_id=%s photoshoot_id=%s frame_index=%s "
            "content_type=%s bytes=%s http_calls_count=%s",
            style_id,
            photoshoot_id,
            frame_index,
            content_type,
            len(content),
            self.http_calls_count,
        )
        return content, content_type

    def _log_kie_event(
        self,
        *,
        event: str,
        style_id: str | None,
        photoshoot_id: str | None,
        frame_index: int | None,
        task_id: str | None,
        attempt: int,
        state: str,
        elapsed_ms: int,
    ) -> None:
        kie_log.info(
            "Kie %s: model=%s style_id=%s photoshoot_id=%s frame_index=%s "
            "task_id=%s attempt=%s state=%s elapsed_ms=%s "
            "http_calls_count=%s created_tasks_count=%s",
            event,
            settings.kie_image_model,
            style_id,
            photoshoot_id,
            frame_index,
            task_id,
            attempt,
            _sanitize_log_value(state),
            elapsed_ms,
            self.http_calls_count,
            self.created_tasks_count,
        )


def bytes_to_data_url(content: bytes, content_type: str) -> str:
    import base64

    encoded = base64.b64encode(content).decode("ascii")
    return f"data:{content_type};base64,{encoded}"


def _extract_task_id(body: Any) -> str | None:
    if not isinstance(body, dict):
        return None
    data = body.get("data")
    if isinstance(data, dict):
        task_id = data.get("taskId") or data.get("task_id")
        if isinstance(task_id, str) and task_id.strip():
            return task_id.strip()
    task_id = body.get("taskId") or body.get("task_id")
    if isinstance(task_id, str) and task_id.strip():
        return task_id.strip()
    return None


def _extract_task_state(body: Any) -> str:
    if not isinstance(body, dict):
        return ""
    data = body.get("data")
    if isinstance(data, dict):
        state = data.get("state") or data.get("status")
        if isinstance(state, str):
            return state.strip().lower()
    state = body.get("state") or body.get("status")
    if isinstance(state, str):
        return state.strip().lower()
    return ""


def _extract_result_urls(body: Any) -> list[str]:
    if not isinstance(body, dict):
        return []
    data = body.get("data")
    if not isinstance(data, dict):
        return []
    result_json = data.get("resultJson") or data.get("result_json")
    if isinstance(result_json, str):
        try:
            parsed = json.loads(result_json)
        except json.JSONDecodeError:
            return []
        return _urls_from_result_payload(parsed)
    if isinstance(result_json, dict):
        return _urls_from_result_payload(result_json)
    return []


def _urls_from_result_payload(payload: Any) -> list[str]:
    if not isinstance(payload, dict):
        return []
    urls = payload.get("resultUrls") or payload.get("result_urls")
    if not isinstance(urls, list):
        return []
    return [url.strip() for url in urls if isinstance(url, str) and url.strip()]


def _sanitize_log_value(value: str) -> str:
    lowered = value.lower()
    for token in _SENSITIVE_LOG_TOKENS:
        if token in lowered:
            return "redacted"
    return value
