"""Unit tests for Kie image service and photoshoot atomicity (no real Kie API)."""

from __future__ import annotations

import io
import json
import logging
import unittest
from unittest.mock import MagicMock, patch

import httpx
from fastapi import HTTPException

from app.auth import CurrentUser, get_current_user
from app.config import settings
from app.main import app
from app.services.kie_image_service import (
    KieImageGenerationError,
    KieImageTaskClient,
    bytes_to_data_url,
)
from app.services.kie_photoshoot_provider import KiePhotoshootProvider
from app.services.photoshoot_service import (
    PhotoshootGenerateResult,
    PhotoshootService,
    _PHOTOSHOOT_FAILURE_MESSAGE,
)
from app.services.photoshoot_styles import get_photoshoot_style
from app.services.storage_service import storage_service
from fastapi.testclient import TestClient

_TEST_PHOTO_BYTES = b"fake-photo"
_TEST_PHOTO_TYPE = "image/jpeg"
_TEST_DATA_URL = "data:image/png;base64,iVBORw0KGgo="
_TEST_DATA_URL_2 = "data:image/png;base64,QUJDRA=="
_TEST_DATA_URL_3 = "data:image/png;base64,QUJDREVG"
_RESULT_IMAGE_BYTES = b"\x89PNG\r\n\x1a\n" + b"\x00" * 32
_RESULT_URL = "https://cdn.example.com/result.png"
_SIGNED_URL_A = "https://supabase.example.com/signed/a"
_SIGNED_URL_B = "https://supabase.example.com/signed/b"
_SIGNED_URL_C = "https://supabase.example.com/signed/c"


def _distinct_result_image_bytes(frame_index: int) -> bytes:
    return _RESULT_IMAGE_BYTES + bytes([frame_index % 256])


def _sequential_kie_temp_uploads() -> list[tuple[str, str]]:
    return [
        ("temp/b", _SIGNED_URL_B),
        ("temp/c", _SIGNED_URL_C),
    ]


def _download_response_for_frame(frame_index: int) -> httpx.Response:
    return httpx.Response(
        200,
        content=_distinct_result_image_bytes(frame_index),
        request=httpx.Request("GET", _RESULT_URL),
    )


def _kie_settings_patch(mock_settings: MagicMock) -> None:
    mock_settings.kie_api_key = "test-kie-key"
    mock_settings.kie_api_base_url = "https://api.kie.ai"
    mock_settings.kie_image_model = "gpt-image-2-image-to-image"
    mock_settings.kie_image_resolution = "2K"
    mock_settings.kie_image_aspect_ratio = "3:4"
    mock_settings.kie_task_timeout_seconds = 30
    mock_settings.kie_poll_initial_delay_seconds = 0.01
    mock_settings.kie_poll_max_delay_seconds = 0.02
    mock_settings.kie_temp_signed_url_ttl_seconds = 3600
    mock_settings.kie_max_create_task_attempts = 3
    mock_settings.kie_create_task_timeout_seconds = 25.0
    mock_settings.kie_temp_storage_max_attempts = 3
    mock_settings.kie_max_photoshoot_tasks = 5
    mock_settings.supabase_temp_storage_bucket = "ai-temp-inputs"
    mock_settings.photoshoot_output_count = 3
    mock_settings.photoshoot_series_reference_mode = "identity_anchor"

    def configured() -> bool:
        return bool(mock_settings.kie_api_key and str(mock_settings.kie_api_key).strip())

    mock_settings.kie_configured = configured


def _create_task_response(task_id: str = "task-123") -> httpx.Response:
    return httpx.Response(
        200,
        json={"code": 200, "data": {"taskId": task_id}},
        request=httpx.Request("POST", "https://api.kie.ai/api/v1/jobs/createTask"),
    )


def _poll_response(
    state: str,
    result_urls: list[str] | None = None,
    *,
    empty_results: bool = False,
) -> httpx.Response:
    payload: dict = {"code": 200, "data": {"taskId": "task-123", "state": state}}
    if state == "success":
        if empty_results:
            payload["data"]["resultJson"] = json.dumps({"resultUrls": []})
        else:
            payload["data"]["resultJson"] = json.dumps(
                {"resultUrls": result_urls if result_urls is not None else [_RESULT_URL]}
            )
    return httpx.Response(
        200,
        json=payload,
        request=httpx.Request("GET", "https://api.kie.ai/api/v1/jobs/recordInfo"),
    )


def _download_response() -> httpx.Response:
    return httpx.Response(
        200,
        content=_RESULT_IMAGE_BYTES,
        headers={"content-type": "image/png"},
        request=httpx.Request("GET", _RESULT_URL),
    )


def _http_response(
    status_code: int,
    *,
    method: str = "POST",
    url: str = "https://api.kie.ai/api/v1/jobs/createTask",
) -> httpx.Response:
    return httpx.Response(
        status_code,
        json={"code": status_code, "message": "error"},
        request=httpx.Request(method, url),
    )


class KieImageTaskClientTests(unittest.TestCase):
    @patch("app.services.kie_image_service.settings")
    @patch("app.services.kie_image_service.httpx.post")
    @patch("app.services.kie_image_service.httpx.get")
    @patch("app.services.kie_image_service.time.sleep")
    def test_create_task_and_poll_success_downloads_image(
        self,
        mock_sleep: MagicMock,
        mock_get: MagicMock,
        mock_post: MagicMock,
        mock_settings: MagicMock,
    ) -> None:
        _kie_settings_patch(mock_settings)
        mock_post.return_value = _create_task_response()
        mock_get.side_effect = [
            _poll_response("waiting"),
            _poll_response("generating"),
            _poll_response("success"),
            _download_response(),
        ]

        client = KieImageTaskClient()
        content, content_type = client.generate_image_bytes(
            "test prompt",
            [_SIGNED_URL_A],
            style_id="summer_photoshoot",
            photoshoot_id="ps-1",
            frame_index=0,
        )

        self.assertEqual(content, _RESULT_IMAGE_BYTES)
        self.assertEqual(content_type, "image/png")
        self.assertGreaterEqual(client.http_calls_count, 3)
        self.assertEqual(client.created_tasks_count, 1)
        mock_post.assert_called_once()
        create_payload = mock_post.call_args.kwargs["json"]
        self.assertEqual(create_payload["model"], "gpt-image-2-image-to-image")
        self.assertEqual(create_payload["input"]["input_urls"], [_SIGNED_URL_A])
        self.assertEqual(create_payload["input"]["aspect_ratio"], "3:4")
        self.assertTrue(
            mock_post.call_args.kwargs["headers"]["Authorization"].startswith("Bearer ")
        )

    @patch("app.services.kie_image_service.settings")
    @patch("app.services.kie_image_service.httpx.post")
    @patch("app.services.kie_image_service.httpx.get")
    @patch("app.services.kie_image_service.time.sleep")
    def test_poll_waiting_then_success(
        self,
        mock_sleep: MagicMock,
        mock_get: MagicMock,
        mock_post: MagicMock,
        mock_settings: MagicMock,
    ) -> None:
        _kie_settings_patch(mock_settings)
        mock_post.return_value = _create_task_response()
        mock_get.side_effect = [
            _poll_response("waiting"),
            _poll_response("success"),
            _download_response(),
        ]

        client = KieImageTaskClient()
        client.generate_image_bytes("prompt", [_SIGNED_URL_A])
        self.assertEqual(mock_get.call_count, 3)

    @patch("app.services.kie_image_service.settings")
    @patch("app.services.kie_image_service.httpx.post")
    @patch("app.services.kie_image_service.httpx.get")
    @patch("app.services.kie_image_service.time.sleep")
    def test_poll_fail_raises(
        self,
        mock_sleep: MagicMock,
        mock_get: MagicMock,
        mock_post: MagicMock,
        mock_settings: MagicMock,
    ) -> None:
        _kie_settings_patch(mock_settings)
        mock_post.return_value = _create_task_response()
        mock_get.return_value = _poll_response("fail")

        client = KieImageTaskClient()
        with self.assertRaises(KieImageGenerationError) as ctx:
            client.generate_image_bytes("prompt", [_SIGNED_URL_A])
        self.assertIn("kie_task_failed", str(ctx.exception))

    @patch("app.services.kie_image_service.acquire_kie_create_task_slot")
    @patch("app.services.kie_image_service.settings")
    @patch("app.services.kie_image_service.httpx.post")
    @patch("app.services.kie_image_service.httpx.get")
    @patch("app.services.kie_image_service.time.monotonic")
    @patch("app.services.kie_image_service.time.sleep")
    def test_timeout_raises(
        self,
        mock_sleep: MagicMock,
        mock_monotonic: MagicMock,
        mock_get: MagicMock,
        mock_post: MagicMock,
        mock_settings: MagicMock,
        mock_acquire_slot: MagicMock,
    ) -> None:
        _kie_settings_patch(mock_settings)
        mock_settings.kie_task_timeout_seconds = 0
        mock_post.return_value = _create_task_response()
        mock_get.return_value = _poll_response("generating")
        clock = iter([0.0, 0.0, 0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0])
        mock_monotonic.side_effect = lambda: next(clock, 100.0)

        client = KieImageTaskClient()
        with self.assertRaises(KieImageGenerationError) as ctx:
            client.generate_image_bytes("prompt", [_SIGNED_URL_A])
        self.assertIn("kie_task_timeout", str(ctx.exception))

    @patch("app.services.kie_image_service.settings")
    @patch("app.services.kie_image_service.httpx.post")
    @patch("app.services.kie_image_service.httpx.get")
    @patch("app.services.kie_image_service.time.sleep")
    def test_empty_result_urls_raises(
        self,
        mock_sleep: MagicMock,
        mock_get: MagicMock,
        mock_post: MagicMock,
        mock_settings: MagicMock,
    ) -> None:
        _kie_settings_patch(mock_settings)
        mock_post.return_value = _create_task_response()
        mock_get.return_value = _poll_response("success", empty_results=True)

        client = KieImageTaskClient()
        with self.assertRaises(KieImageGenerationError) as ctx:
            client.generate_image_bytes("prompt", [_SIGNED_URL_A])
        self.assertIn("kie_empty_result_urls", str(ctx.exception))

    @patch("app.services.kie_image_service.settings")
    @patch("app.services.kie_image_service.httpx.post")
    @patch("app.services.kie_logging.kie_log")
    def test_logs_do_not_include_secrets(
        self,
        mock_kie_log: MagicMock,
        mock_post: MagicMock,
        mock_settings: MagicMock,
    ) -> None:
        _kie_settings_patch(mock_settings)
        mock_post.return_value = _create_task_response("task-secret-test")

        client = KieImageTaskClient()
        with patch.object(client, "_poll_until_result", return_value=_RESULT_URL):
            with patch.object(
                client,
                "_download_result_image",
                return_value=(_RESULT_IMAGE_BYTES, "image/png"),
            ):
                client.generate_image_bytes(
                    "secret prompt with api key bearer token",
                    [_SIGNED_URL_A],
                )

        combined_logs = " ".join(
            str(call.args) + str(call.kwargs)
            for call in mock_kie_log.info.call_args_list
        )
        self.assertNotIn("test-kie-key", combined_logs)
        self.assertNotIn(_SIGNED_URL_A, combined_logs)
        self.assertNotIn("secret prompt", combined_logs)

    @patch("app.services.kie_image_service.settings")
    @patch("app.services.kie_image_service.httpx.post")
    @patch("app.services.kie_image_service.httpx.get")
    @patch("app.services.kie_image_service.time.sleep")
    def test_create_task_503_then_200_retries(
        self,
        mock_sleep: MagicMock,
        mock_get: MagicMock,
        mock_post: MagicMock,
        mock_settings: MagicMock,
    ) -> None:
        _kie_settings_patch(mock_settings)
        mock_post.side_effect = [
            _http_response(503),
            _create_task_response(),
        ]
        mock_get.side_effect = [
            _poll_response("success"),
            _download_response(),
        ]

        client = KieImageTaskClient()
        client.generate_image_bytes("prompt", [_SIGNED_URL_A])

        self.assertEqual(mock_post.call_count, 2)
        self.assertEqual(client.created_tasks_count, 1)

    @patch("app.services.kie_image_service.settings")
    @patch("app.services.kie_image_service.httpx.post")
    @patch("app.services.kie_image_service.time.sleep")
    def test_create_task_429_exhausts_retries(
        self,
        mock_sleep: MagicMock,
        mock_post: MagicMock,
        mock_settings: MagicMock,
    ) -> None:
        _kie_settings_patch(mock_settings)
        mock_post.return_value = _http_response(429)

        client = KieImageTaskClient()
        with self.assertRaises(KieImageGenerationError):
            client.generate_image_bytes("prompt", [_SIGNED_URL_A])

        self.assertEqual(mock_post.call_count, 3)
        self.assertEqual(client.created_tasks_count, 0)

    @patch("app.services.kie_image_service.settings")
    @patch("app.services.kie_image_service.httpx.post")
    @patch("app.services.kie_image_service.time.sleep")
    def test_create_task_401_no_retry(
        self,
        mock_sleep: MagicMock,
        mock_post: MagicMock,
        mock_settings: MagicMock,
    ) -> None:
        _kie_settings_patch(mock_settings)
        mock_post.return_value = _http_response(401)

        client = KieImageTaskClient()
        with self.assertRaises(KieImageGenerationError) as ctx:
            client.generate_image_bytes("prompt", [_SIGNED_URL_A])

        self.assertIn("kie_create_task_http_401", str(ctx.exception))
        self.assertEqual(mock_post.call_count, 1)
        self.assertEqual(client.created_tasks_count, 0)

    @patch("app.services.kie_image_service.settings")
    @patch("app.services.kie_image_service.httpx.post")
    @patch("app.services.kie_image_service.httpx.get")
    @patch("app.services.kie_image_service.time.sleep")
    def test_many_poll_calls_do_not_increment_created_tasks_count(
        self,
        mock_sleep: MagicMock,
        mock_get: MagicMock,
        mock_post: MagicMock,
        mock_settings: MagicMock,
    ) -> None:
        _kie_settings_patch(mock_settings)
        mock_post.return_value = _create_task_response()
        mock_get.side_effect = [
            _poll_response("waiting"),
            _poll_response("queuing"),
            _poll_response("generating"),
            _poll_response("success"),
            _download_response(),
        ]

        client = KieImageTaskClient()
        client.generate_image_bytes("prompt", [_SIGNED_URL_A])

        self.assertEqual(client.created_tasks_count, 1)
        self.assertGreaterEqual(client.http_calls_count, 5)

    @patch("app.services.kie_image_service.settings")
    @patch("app.services.kie_image_service.httpx.post")
    @patch("app.services.kie_image_service.time.sleep")
    def test_hard_cap_stops_create_task_retry_at_limit(
        self,
        mock_sleep: MagicMock,
        mock_post: MagicMock,
        mock_settings: MagicMock,
    ) -> None:
        _kie_settings_patch(mock_settings)
        mock_post.return_value = _http_response(503)

        client = KieImageTaskClient()
        client.created_tasks_count = 5

        with self.assertRaises(KieImageGenerationError) as ctx:
            client.generate_image_bytes(
                "prompt",
                [_SIGNED_URL_A],
                max_created_tasks=5,
            )

        self.assertIn("kie_tasks_cap_exceeded", str(ctx.exception))
        self.assertEqual(mock_post.call_count, 0)
        self.assertEqual(client.created_tasks_count, 5)

    @patch("app.services.kie_image_service.settings")
    @patch("app.services.kie_image_service.httpx.post")
    @patch("app.services.kie_image_service.httpx.get")
    @patch("app.services.kie_image_service.time.sleep")
    def test_hard_cap_allows_three_frames_with_cap_five(
        self,
        mock_sleep: MagicMock,
        mock_get: MagicMock,
        mock_post: MagicMock,
        mock_settings: MagicMock,
    ) -> None:
        _kie_settings_patch(mock_settings)
        mock_post.return_value = _create_task_response()
        mock_get.side_effect = [
            _poll_response("success"),
            _download_response(),
        ] * 3

        client = KieImageTaskClient()
        for frame_index in range(3):
            content, content_type = client.generate_image_bytes(
                f"prompt-{frame_index}",
                [_SIGNED_URL_A],
                frame_index=frame_index,
                max_created_tasks=5,
            )
            self.assertEqual(content, _RESULT_IMAGE_BYTES)
            self.assertEqual(content_type, "image/png")

        self.assertEqual(client.created_tasks_count, 3)
        self.assertEqual(mock_post.call_count, 3)


class KiePhotoshootAtomicityTests(unittest.TestCase):
    @patch("app.services.photoshoot_service.resolve_photoshoot_image_provider")
    @patch("app.services.kie_photoshoot_provider.KieImageTaskClient")
    @patch.object(storage_service, "upload_temp_input_bytes")
    @patch.object(storage_service, "upload_temp_input_data_url")
    @patch.object(storage_service, "create_signed_url")
    @patch.object(storage_service, "delete_temp_objects_best_effort")
    @patch("app.services.photoshoot_service._upload_photoshoot_frames_to_storage")
    @patch("app.services.photoshoot_service._save_photoshoot_results_to_history")
    def test_frame_two_failure_skips_permanent_storage_and_db(
        self,
        mock_save_history: MagicMock,
        mock_upload_frames: MagicMock,
        mock_delete_temp: MagicMock,
        mock_signed_url: MagicMock,
        mock_upload_data_url: MagicMock,
        mock_upload_bytes: MagicMock,
        mock_kie_client_cls: MagicMock,
        mock_resolve_provider: MagicMock,
    ) -> None:
        mock_resolve_provider.return_value = "kie_gpt_image_2"
        mock_upload_bytes.return_value = ("temp/a", _SIGNED_URL_A)
        mock_upload_data_url.return_value = ("temp/b", _SIGNED_URL_B)
        mock_signed_url.side_effect = (
            lambda *args, **kwargs: _SIGNED_URL_B
            if args and args[0] == "temp/b"
            else _SIGNED_URL_A
        )

        kie_client = MagicMock()
        kie_client.http_calls_count = 0
        kie_client.created_tasks_count = 0
        kie_client.generate_image_bytes.side_effect = [
            (_RESULT_IMAGE_BYTES, "image/png"),
            KieImageGenerationError("kie_task_failed"),
            KieImageGenerationError("kie_task_failed"),
        ]
        mock_kie_client_cls.return_value = kie_client

        style = get_photoshoot_style("studio_portrait")
        service = PhotoshootService()

        with self.assertRaises(HTTPException) as ctx:
            service.generate_photoshoot(
                user_id="user-1",
                style=style,
                photo_bytes=_TEST_PHOTO_BYTES,
                photo_content_type=_TEST_PHOTO_TYPE,
                client_style_id=style.id,
            )

        self.assertEqual(ctx.exception.status_code, 502)
        self.assertEqual(ctx.exception.detail, _PHOTOSHOOT_FAILURE_MESSAGE)
        mock_upload_frames.assert_not_called()
        mock_save_history.assert_not_called()
        mock_delete_temp.assert_called()

    @patch("app.services.photoshoot_service.resolve_photoshoot_image_provider")
    @patch("app.services.kie_photoshoot_provider.KieImageTaskClient")
    @patch.object(storage_service, "upload_temp_input_bytes")
    @patch.object(storage_service, "upload_temp_input_data_url")
    @patch.object(storage_service, "create_signed_url")
    @patch.object(storage_service, "delete_temp_objects_best_effort")
    def test_temp_cleanup_on_success(
        self,
        mock_delete_temp: MagicMock,
        mock_signed_url: MagicMock,
        mock_upload_data_url: MagicMock,
        mock_upload_bytes: MagicMock,
        mock_kie_client_cls: MagicMock,
        mock_resolve_provider: MagicMock,
    ) -> None:
        mock_resolve_provider.return_value = "kie_gpt_image_2"
        mock_upload_bytes.return_value = ("temp/a", _SIGNED_URL_A)
        mock_upload_data_url.side_effect = _sequential_kie_temp_uploads()
        mock_signed_url.side_effect = lambda path, **kwargs: {
            "temp/a": _SIGNED_URL_A,
            "temp/b": _SIGNED_URL_B,
            "temp/c": _SIGNED_URL_C,
        }.get(path, _SIGNED_URL_A)

        kie_client = MagicMock()
        kie_client.http_calls_count = 0
        kie_client.created_tasks_count = 0
        kie_client.generate_image_bytes.side_effect = [
            (_distinct_result_image_bytes(0), "image/png"),
            (_distinct_result_image_bytes(1), "image/png"),
            (_distinct_result_image_bytes(2), "image/png"),
        ]
        mock_kie_client_cls.return_value = kie_client

        provider = KiePhotoshootProvider(output_count=3)
        with patch("app.services.photoshoot_service._upload_photoshoot_frames_to_storage") as mock_upload:
            with patch(
                "app.services.photoshoot_service._save_photoshoot_results_to_history",
                return_value="ps-done",
            ):
                mock_upload.return_value = (
                    ["https://public/1", "https://public/2", "https://public/3"],
                    [None, None, None],
                    ["p1", "p2", "p3"],
                )
                service = PhotoshootService()
                result = service.generate_photoshoot(
                    user_id="user-1",
                    style=get_photoshoot_style("studio_portrait"),
                    photo_bytes=_TEST_PHOTO_BYTES,
                    photo_content_type=_TEST_PHOTO_TYPE,
                    client_style_id="studio_portrait",
                )

        self.assertIsInstance(result, PhotoshootGenerateResult)
        mock_delete_temp.assert_called()
        deleted_paths = mock_delete_temp.call_args.args[0]
        self.assertIn("temp/a", deleted_paths)
        self.assertNotIn("temp/b", deleted_paths)
        self.assertNotIn("temp/c", deleted_paths)
        mock_upload_data_url.assert_not_called()

    @patch("app.services.photoshoot_service.resolve_photoshoot_image_provider")
    @patch.object(storage_service, "upload_temp_input_bytes")
    @patch.object(storage_service, "upload_temp_input_data_url")
    @patch.object(storage_service, "create_signed_url")
    @patch.object(storage_service, "delete_temp_objects_best_effort")
    @patch("app.services.photoshoot_service._upload_photoshoot_frames_to_storage")
    @patch("app.services.photoshoot_service._save_photoshoot_results_to_history")
    @patch("app.services.kie_photoshoot_provider.settings")
    @patch("app.services.kie_image_service.settings")
    @patch("app.services.kie_image_service.httpx.post")
    @patch("app.services.kie_image_service.httpx.get")
    @patch("app.services.kie_image_service.time.sleep")
    def test_three_frame_photoshoot_succeeds_with_cap_five(
        self,
        mock_sleep: MagicMock,
        mock_get: MagicMock,
        mock_post: MagicMock,
        mock_kie_settings: MagicMock,
        mock_provider_settings: MagicMock,
        mock_save_history: MagicMock,
        mock_upload_frames: MagicMock,
        mock_delete_temp: MagicMock,
        mock_signed_url: MagicMock,
        mock_upload_data_url: MagicMock,
        mock_upload_bytes: MagicMock,
        mock_resolve_provider: MagicMock,
    ) -> None:
        _kie_settings_patch(mock_kie_settings)
        mock_provider_settings.kie_max_photoshoot_tasks = 5
        mock_provider_settings.kie_temp_signed_url_ttl_seconds = 3600
        mock_provider_settings.supabase_temp_storage_bucket = "ai-temp-inputs"
        mock_provider_settings.photoshoot_series_reference_mode = "identity_anchor"
        mock_provider_settings.photoshoot_output_count = 3
        mock_resolve_provider.return_value = "kie_gpt_image_2"
        mock_upload_bytes.return_value = ("temp/a", _SIGNED_URL_A)
        mock_upload_data_url.side_effect = _sequential_kie_temp_uploads()
        mock_signed_url.side_effect = lambda path, **kwargs: {
            "temp/a": _SIGNED_URL_A,
            "temp/b": _SIGNED_URL_B,
            "temp/c": _SIGNED_URL_C,
        }.get(path, _SIGNED_URL_A)
        mock_post.return_value = _create_task_response()
        mock_get.side_effect = [
            _poll_response("success"),
            _download_response_for_frame(0),
            _poll_response("success"),
            _download_response_for_frame(1),
            _poll_response("success"),
            _download_response_for_frame(2),
        ]
        mock_upload_frames.return_value = (
            ["https://public/1", "https://public/2", "https://public/3"],
            [None, None, None],
            ["p1", "p2", "p3"],
        )
        mock_save_history.return_value = "ps-done"

        service = PhotoshootService()
        result = service.generate_photoshoot(
            user_id="user-1",
            style=get_photoshoot_style("studio_portrait"),
            photo_bytes=_TEST_PHOTO_BYTES,
            photo_content_type=_TEST_PHOTO_TYPE,
            client_style_id="studio_portrait",
        )

        self.assertIsInstance(result, PhotoshootGenerateResult)
        self.assertEqual(mock_post.call_count, 3)
        mock_upload_frames.assert_called_once()
        mock_save_history.assert_called_once()

    @patch("app.services.photoshoot_service.resolve_photoshoot_image_provider")
    @patch.object(storage_service, "upload_temp_input_bytes")
    @patch.object(storage_service, "upload_temp_input_data_url")
    @patch.object(storage_service, "create_signed_url")
    @patch.object(storage_service, "delete_temp_objects_best_effort")
    @patch("app.services.photoshoot_service._upload_photoshoot_frames_to_storage")
    @patch("app.services.photoshoot_service._save_photoshoot_results_to_history")
    @patch("app.services.kie_photoshoot_provider.settings")
    @patch("app.services.kie_image_service.settings")
    @patch("app.services.kie_image_service.httpx.post")
    @patch("app.services.kie_image_service.httpx.get")
    @patch("app.services.kie_image_service.time.sleep")
    def test_hard_cap_exceeded_on_frame_two_no_permanent_persist(
        self,
        mock_sleep: MagicMock,
        mock_get: MagicMock,
        mock_post: MagicMock,
        mock_kie_settings: MagicMock,
        mock_provider_settings: MagicMock,
        mock_save_history: MagicMock,
        mock_upload_frames: MagicMock,
        mock_delete_temp: MagicMock,
        mock_signed_url: MagicMock,
        mock_upload_data_url: MagicMock,
        mock_upload_bytes: MagicMock,
        mock_resolve_provider: MagicMock,
    ) -> None:
        _kie_settings_patch(mock_kie_settings)
        mock_provider_settings.kie_max_photoshoot_tasks = 5
        mock_provider_settings.kie_temp_signed_url_ttl_seconds = 3600
        mock_provider_settings.supabase_temp_storage_bucket = "ai-temp-inputs"
        mock_provider_settings.photoshoot_series_reference_mode = "identity_anchor"
        mock_provider_settings.photoshoot_output_count = 3
        mock_resolve_provider.return_value = "kie_gpt_image_2"
        mock_upload_bytes.return_value = ("temp/a", _SIGNED_URL_A)
        mock_upload_data_url.return_value = ("temp/b", _SIGNED_URL_B)
        mock_signed_url.side_effect = (
            lambda *args, **kwargs: _SIGNED_URL_B
            if args and args[0] == "temp/b"
            else _SIGNED_URL_A
        )
        post_responses = [
            _create_task_response("task-f0"),
            _http_response(503),
            _http_response(503),
            _create_task_response("task-f1"),
            _http_response(503),
        ]
        post_iter = iter(post_responses)

        def _post_side_effect(*args, **kwargs):
            try:
                return next(post_iter)
            except StopIteration:
                return _http_response(503)

        mock_post.side_effect = _post_side_effect

        def _get_side_effect(*args, **kwargs):
            if "recordInfo" in str(args[0] if args else kwargs.get("url", "")):
                return _poll_response("success")
            return _download_response()

        mock_get.side_effect = _get_side_effect

        service = PhotoshootService()
        with self.assertRaises(HTTPException) as ctx:
            service.generate_photoshoot(
                user_id="user-1",
                style=get_photoshoot_style("studio_portrait"),
                photo_bytes=_TEST_PHOTO_BYTES,
                photo_content_type=_TEST_PHOTO_TYPE,
                client_style_id="studio_portrait",
            )

        self.assertEqual(ctx.exception.status_code, 502)
        self.assertGreaterEqual(mock_post.call_count, 5)
        mock_upload_frames.assert_not_called()
        mock_save_history.assert_not_called()

    @patch("app.services.photoshoot_service.resolve_photoshoot_image_provider")
    @patch.object(storage_service, "upload_temp_input_bytes")
    @patch.object(storage_service, "upload_temp_input_data_url")
    @patch.object(storage_service, "create_signed_url")
    @patch.object(storage_service, "delete_temp_objects_best_effort")
    @patch("app.services.photoshoot_service._upload_photoshoot_frames_to_storage")
    @patch("app.services.photoshoot_service._save_photoshoot_results_to_history")
    @patch("app.services.kie_photoshoot_provider.settings")
    @patch("app.services.kie_image_service.settings")
    @patch("app.services.kie_image_service.httpx.post")
    @patch("app.services.kie_image_service.httpx.get")
    @patch("app.services.kie_image_service.time.sleep")
    def test_create_task_cap_aborts_before_permanent_persist(
        self,
        mock_sleep: MagicMock,
        mock_get: MagicMock,
        mock_post: MagicMock,
        mock_kie_settings: MagicMock,
        mock_provider_settings: MagicMock,
        mock_save_history: MagicMock,
        mock_upload_frames: MagicMock,
        mock_delete_temp: MagicMock,
        mock_signed_url: MagicMock,
        mock_upload_data_url: MagicMock,
        mock_upload_bytes: MagicMock,
        mock_resolve_provider: MagicMock,
    ) -> None:
        _kie_settings_patch(mock_kie_settings)
        mock_provider_settings.kie_max_photoshoot_tasks = 2
        mock_provider_settings.kie_temp_signed_url_ttl_seconds = 3600
        mock_provider_settings.supabase_temp_storage_bucket = "ai-temp-inputs"
        mock_provider_settings.photoshoot_series_reference_mode = "identity_anchor"
        mock_provider_settings.photoshoot_output_count = 3
        mock_resolve_provider.return_value = "kie_gpt_image_2"
        mock_upload_bytes.return_value = ("temp/a", _SIGNED_URL_A)
        mock_upload_data_url.return_value = ("temp/b", _SIGNED_URL_B)
        mock_signed_url.side_effect = (
            lambda *args, **kwargs: _SIGNED_URL_B
            if args and args[0] == "temp/b"
            else _SIGNED_URL_A
        )
        mock_post.return_value = _create_task_response()
        mock_get.side_effect = [
            _poll_response("success"),
            _download_response(),
        ] * 2

        service = PhotoshootService()
        with self.assertRaises(HTTPException) as ctx:
            service.generate_photoshoot(
                user_id="user-1",
                style=get_photoshoot_style("studio_portrait"),
                photo_bytes=_TEST_PHOTO_BYTES,
                photo_content_type=_TEST_PHOTO_TYPE,
                client_style_id="studio_portrait",
            )

        self.assertEqual(ctx.exception.status_code, 502)
        self.assertEqual(mock_post.call_count, 2)
        mock_upload_frames.assert_not_called()
        mock_save_history.assert_not_called()


class KiePhotoshootEndpointTests(unittest.TestCase):
    def setUp(self) -> None:
        def _override_user() -> CurrentUser:
            return CurrentUser(id="endpoint-test-user", email="u@example.com")

        app.dependency_overrides[get_current_user] = _override_user
        self.client = TestClient(app)

    def tearDown(self) -> None:
        app.dependency_overrides.clear()

    @patch("app.main.consume_photoshoot")
    @patch("app.services.photoshoot_service.create_generation_record")
    @patch("app.services.photoshoot_service._upload_photoshoot_frames_to_storage")
    @patch.object(storage_service, "upload_temp_input_bytes")
    @patch("app.main.settings")
    @patch("app.services.photoshoot_service.settings")
    @patch("app.services.photoshoot_service.resolve_photoshoot_image_provider")
    def test_kie_temp_upload_failure_returns_unified_502_json(
        self,
        mock_resolve_provider: MagicMock,
        mock_service_settings: MagicMock,
        mock_main_settings: MagicMock,
        mock_upload_temp: MagicMock,
        mock_upload_frames: MagicMock,
        mock_create_record: MagicMock,
        mock_consume: MagicMock,
    ) -> None:
        mock_main_settings.enable_photoshoot_generation = True
        mock_main_settings.enable_credit_consumption = False
        mock_service_settings.photoshoot_output_count = 3
        mock_resolve_provider.return_value = "kie_gpt_image_2"
        mock_upload_temp.side_effect = HTTPException(
            status_code=503,
            detail="Supabase Storage is temporarily unavailable",
        )

        response = self.client.post(
            "/photoshoots/generate",
            data={"style_id": "studio_portrait"},
            files={
                "photo": ("photo.jpg", io.BytesIO(b"\xff\xd8\xff\xe0" + b"\x00" * 16), "image/jpeg"),
            },
        )

        self.assertEqual(response.status_code, 502)
        self.assertEqual(
            response.json(),
            {"status": "error", "message": "Photoshoot generation failed"},
        )
        self.assertNotIn("Supabase", response.text)
        mock_upload_frames.assert_not_called()
        mock_create_record.assert_not_called()
        mock_consume.assert_not_called()


class TempStorageFilenameTests(unittest.TestCase):
    @patch.object(storage_service, "create_signed_url", return_value=_SIGNED_URL_A)
    @patch.object(storage_service, "_upload_bytes_to_bucket")
    @patch("app.services.storage_service.uuid4")
    def test_sequential_temp_uploads_use_unique_paths(
        self,
        mock_uuid4: MagicMock,
        mock_upload_bucket: MagicMock,
        mock_signed_url: MagicMock,
    ) -> None:
        mock_uuid4.side_effect = [
            MagicMock(hex="aaaaaaaaaaaa"),
            MagicMock(hex="bbbbbbbbbbbb"),
        ]
        with patch.object(
            storage_service,
            "build_storage_path",
            side_effect=lambda user_id, filename, folder="kie-inputs": (
                f"{folder}/{user_id}/{filename}"
            ),
        ):
            path_one, _ = storage_service.upload_temp_input_bytes(
                "user-1",
                _TEST_PHOTO_BYTES,
                _TEST_PHOTO_TYPE,
                ttl_seconds=3600,
            )
            path_two, _ = storage_service.upload_temp_input_bytes(
                "user-1",
                _TEST_PHOTO_BYTES,
                _TEST_PHOTO_TYPE,
                ttl_seconds=3600,
            )

        self.assertNotEqual(path_one, path_two)
        self.assertIn("aaaaaaaaaaaa", path_one)
        self.assertIn("bbbbbbbbbbbb", path_two)


class DebugConfigKieTests(unittest.TestCase):
    def test_debug_config_exposes_kie_flags_not_api_key(self) -> None:
        client = TestClient(app)
        with patch.object(settings, "environment", "development"):
            with patch.object(settings, "kie_api_key", "super-secret-kie-key"):
                with patch.object(settings, "kie_image_model", "gpt-image-2-image-to-image"):
                    response = client.get("/debug/config")

        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertEqual(body["kie_image_model"], "gpt-image-2-image-to-image")
        self.assertTrue(body["kie_api_key_configured"])
        self.assertEqual(body["kie_image_resolution"], settings.kie_image_resolution)
        self.assertEqual(body["kie_image_aspect_ratio"], settings.kie_image_aspect_ratio)
        self.assertEqual(
            body["supabase_temp_storage_bucket"],
            settings.supabase_temp_storage_bucket,
        )
        self.assertEqual(body["kie_max_photoshoot_tasks"], settings.kie_max_photoshoot_tasks)
        self.assertNotIn("super-secret-kie-key", response.text)
        self.assertNotIn("kie_api_key", body)


class KiePhotoshootPromptFormatTests(unittest.TestCase):
    def test_kie_photoshoot_prompts_include_vertical_portrait_instruction(self) -> None:
        from app.services.photoshoot_prompts import build_kie_photoshoot_frame_prompt

        style = get_photoshoot_style("studio_portrait")
        for frame_index in (0, 1, 2):
            prompt = build_kie_photoshoot_frame_prompt(
                "studio_portrait",
                style,
                frame_index=frame_index,
                output_count=3,
                series_reference_mode="identity_anchor",
            )
            lower = prompt.lower()
            self.assertIn("vertical portrait", lower, msg=f"frame_index={frame_index}")
            self.assertIn("3:4", prompt, msg=f"frame_index={frame_index}")
            self.assertIn("horizontal", lower, msg=f"frame_index={frame_index}")
            self.assertIn(
                "use image 1 only as the identity reference",
                prompt.lower(),
                msg=f"frame_index={frame_index}",
            )
            self.assertNotIn(
                "image 2: the first generated frame",
                prompt.lower(),
                msg=f"frame_index={frame_index}",
            )


class KieBytesToDataUrlTests(unittest.TestCase):
    def test_bytes_to_data_url_roundtrip_prefix(self) -> None:
        data_url = bytes_to_data_url(_RESULT_IMAGE_BYTES, "image/png")
        self.assertTrue(data_url.startswith("data:image/png;base64,"))


if __name__ == "__main__":
    unittest.main()
