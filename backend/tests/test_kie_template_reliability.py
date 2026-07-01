"""Reliability tests for Kie template generation (timeouts, retries, logging)."""

from __future__ import annotations

import io
import json
import logging
import unittest
from unittest.mock import MagicMock, patch

import httpx
from fastapi import HTTPException

from app.config import settings
from app.main import app
from app.services.image_provider_resolver import KIE_IMAGE_PROVIDER
from app.services.kie_image_service import (
    KieCreateTaskNetworkError,
    KieImageGenerationError,
    KieImageTaskClient,
    KiePollNetworkExhaustedError,
    KieRetryableCreateTaskError,
)
from app.services.photo_generation_service import KiePhotoGenerationProvider
from app.services.storage_service import storage_service
from fastapi.testclient import TestClient
from tests.valid_upload_test_bytes import VALID_TEST_JPEG_BYTES

_TEST_PHOTO_BYTES = VALID_TEST_JPEG_BYTES
_TEST_PHOTO_TYPE = "image/jpeg"
_SIGNED_URL_A = "https://supabase.example.com/signed/a?token=secret-a"
_MOCK_IMAGE_URL = "data:image/png;base64,iVBORw0KGgo="


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
    mock_settings.supabase_temp_storage_bucket = "ai-temp-inputs"

    def configured() -> bool:
        return bool(mock_settings.kie_api_key and str(mock_settings.kie_api_key).strip())

    mock_settings.kie_configured = configured


def _create_task_response(task_id: str = "task-123") -> httpx.Response:
    return httpx.Response(
        200,
        json={"code": 200, "data": {"taskId": task_id}},
        request=httpx.Request("POST", "https://api.kie.ai/api/v1/jobs/createTask"),
    )


def _http_response(status_code: int) -> httpx.Response:
    return httpx.Response(
        status_code,
        json={"code": status_code, "message": "error"},
        request=httpx.Request("POST", "https://api.kie.ai/api/v1/jobs/createTask"),
    )


class KieCreateTaskReliabilityTests(unittest.TestCase):
    @patch("app.services.kie_image_service.settings")
    @patch("app.services.kie_image_service.httpx.post")
    @patch("app.services.kie_image_service.time.sleep")
    def test_network_timeout_does_not_retry_and_raises_network_error(
        self,
        mock_sleep: MagicMock,
        mock_post: MagicMock,
        mock_settings: MagicMock,
    ) -> None:
        _kie_settings_patch(mock_settings)
        mock_post.side_effect = httpx.ConnectTimeout("timed out")

        client = KieImageTaskClient()
        with self.assertRaises(KieCreateTaskNetworkError) as ctx:
            client.generate_image_bytes("prompt", [_SIGNED_URL_A])

        self.assertIn("kie_create_task_network", str(ctx.exception))
        self.assertEqual(mock_post.call_count, 1)
        self.assertEqual(client.created_tasks_count, 0)
        mock_sleep.assert_not_called()

    @patch("app.services.kie_image_service.settings")
    @patch("app.services.kie_image_service.httpx.post")
    @patch("app.services.kie_image_service.httpx.get")
    @patch("app.services.kie_image_service.time.sleep")
    def test_explicit_503_http_response_retries_when_safe(
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
            httpx.Response(
                200,
                json={"data": {"state": "success", "resultJson": '{"resultUrls":["https://cdn.example.com/r.png"]}'}},
                request=httpx.Request("GET", "https://api.kie.ai/api/v1/jobs/recordInfo"),
            ),
            httpx.Response(
                200,
                content=b"\x89PNG\r\n",
                headers={"content-type": "image/png"},
                request=httpx.Request("GET", "https://cdn.example.com/r.png"),
            ),
        ]

        client = KieImageTaskClient()
        client.generate_image_bytes("prompt", [_SIGNED_URL_A])

        self.assertEqual(mock_post.call_count, 2)
        self.assertEqual(client.created_tasks_count, 1)

    @patch("app.services.kie_image_service.settings")
    @patch("app.services.kie_image_service.httpx.post")
    def test_create_task_uses_configured_timeout(
        self,
        mock_post: MagicMock,
        mock_settings: MagicMock,
    ) -> None:
        _kie_settings_patch(mock_settings)
        mock_settings.kie_create_task_timeout_seconds = 25.0
        mock_post.return_value = _create_task_response()

        client = KieImageTaskClient()
        with patch.object(client, "_poll_until_result", return_value="https://cdn.example.com/r.png"):
            with patch.object(
                client,
                "_download_result_image",
                return_value=(b"\x89PNG\r\n", "image/png"),
            ):
                client.generate_image_bytes("prompt", [_SIGNED_URL_A])

        self.assertEqual(mock_post.call_args.kwargs["timeout"], 25.0)


class TempStorageRetryTests(unittest.TestCase):
    @patch("app.services.storage_service.time.sleep")
    @patch("app.services.storage_service.httpx.put")
    @patch("app.services.storage_service.settings")
    def test_temp_upload_connect_timeout_retries_three_times(
        self,
        mock_settings: MagicMock,
        mock_put: MagicMock,
        mock_sleep: MagicMock,
    ) -> None:
        mock_settings.kie_temp_storage_max_attempts = 3
        mock_settings.supabase_url = "https://example.supabase.co"
        mock_settings.supabase_service_role_key = "service-role-key"
        mock_settings.supabase_temp_storage_bucket = "ai-temp-inputs"
        mock_put.side_effect = [
            httpx.ConnectTimeout("connect timeout"),
            httpx.ConnectTimeout("connect timeout"),
            httpx.ConnectTimeout("connect timeout"),
        ]

        with self.assertRaises(HTTPException) as ctx:
            storage_service.upload_temp_input_bytes(
                "user-1",
                _TEST_PHOTO_BYTES,
                _TEST_PHOTO_TYPE,
                ttl_seconds=3600,
            )

        self.assertEqual(ctx.exception.status_code, 503)
        self.assertEqual(mock_put.call_count, 3)
        self.assertEqual(mock_sleep.call_count, 2)

    @patch("app.services.storage_service.time.sleep")
    @patch("app.services.storage_service.httpx.post")
    @patch("app.services.storage_service.httpx.put")
    @patch("app.services.storage_service.settings")
    def test_signed_url_connect_timeout_retries_three_times(
        self,
        mock_settings: MagicMock,
        mock_put: MagicMock,
        mock_post: MagicMock,
        mock_sleep: MagicMock,
    ) -> None:
        mock_settings.kie_temp_storage_max_attempts = 3
        mock_settings.supabase_url = "https://example.supabase.co"
        mock_settings.supabase_service_role_key = "service-role-key"
        mock_settings.supabase_temp_storage_bucket = "ai-temp-inputs"
        mock_put.return_value = httpx.Response(
            200,
            request=httpx.Request("PUT", "https://example.supabase.co/storage/v1/object/x"),
        )
        mock_post.side_effect = [
            httpx.ConnectTimeout("connect timeout"),
            httpx.ConnectTimeout("connect timeout"),
            httpx.ConnectTimeout("connect timeout"),
        ]

        with self.assertRaises(HTTPException) as ctx:
            storage_service.upload_temp_input_bytes(
                "user-1",
                _TEST_PHOTO_BYTES,
                _TEST_PHOTO_TYPE,
                ttl_seconds=3600,
            )

        self.assertEqual(ctx.exception.status_code, 503)
        self.assertEqual(mock_post.call_count, 3)
        self.assertEqual(mock_sleep.call_count, 2)


_TEST_RESULT_BYTES = b"\x89PNG\r\n\x1a\n" + b"\x00" * 32


def _poll_response(state: str = "success") -> httpx.Response:
    payload: dict = {"code": 200, "data": {"taskId": "task-123", "state": state}}
    if state == "success":
        payload["data"]["resultJson"] = json.dumps(
            {"resultUrls": ["https://cdn.example.com/result.png"]}
        )
    return httpx.Response(
        200,
        json=payload,
        request=httpx.Request("GET", "https://api.kie.ai/api/v1/jobs/recordInfo"),
    )


def _download_response() -> httpx.Response:
    return httpx.Response(
        200,
        content=_TEST_RESULT_BYTES,
        headers={"content-type": "image/png"},
        request=httpx.Request("GET", "https://cdn.example.com/result.png"),
    )


class KiePollReliabilityTests(unittest.TestCase):
    @patch("app.services.kie_image_service.settings")
    @patch("app.services.kie_image_service.httpx.post")
    @patch("app.services.kie_image_service.httpx.get")
    @patch("app.services.kie_image_service.time.sleep")
    def test_single_poll_network_error_then_success(
        self,
        mock_sleep: MagicMock,
        mock_get: MagicMock,
        mock_post: MagicMock,
        mock_settings: MagicMock,
    ) -> None:
        _kie_settings_patch(mock_settings)
        mock_post.return_value = _create_task_response()
        mock_get.side_effect = [
            httpx.ConnectTimeout("timed out"),
            _poll_response("success"),
            _download_response(),
        ]

        client = KieImageTaskClient()
        content, content_type = client.generate_image_bytes(
            "prompt",
            [_SIGNED_URL_A],
            template_id="woman_with_cat",
        )

        self.assertEqual(content, _TEST_RESULT_BYTES)
        self.assertEqual(content_type, "image/png")
        self.assertEqual(client.created_tasks_count, 1)
        self.assertEqual(mock_get.call_count, 3)

    @patch("app.services.kie_image_service.settings")
    @patch("app.services.kie_image_service.httpx.post")
    @patch("app.services.kie_image_service.httpx.get")
    @patch("app.services.kie_image_service.time.sleep")
    def test_four_poll_network_errors_then_success(
        self,
        mock_sleep: MagicMock,
        mock_get: MagicMock,
        mock_post: MagicMock,
        mock_settings: MagicMock,
    ) -> None:
        _kie_settings_patch(mock_settings)
        mock_post.return_value = _create_task_response()
        mock_get.side_effect = [
            httpx.ConnectTimeout("t1"),
            httpx.ConnectTimeout("t2"),
            httpx.ConnectTimeout("t3"),
            httpx.ConnectTimeout("t4"),
            _poll_response("generating"),
            _poll_response("success"),
            _download_response(),
        ]

        client = KieImageTaskClient()
        client.generate_image_bytes("prompt", [_SIGNED_URL_A])

        self.assertEqual(client.created_tasks_count, 1)
        self.assertGreaterEqual(mock_get.call_count, 6)

    @patch("app.services.kie_image_service.settings")
    @patch("app.services.kie_image_service.httpx.post")
    @patch("app.services.kie_image_service.httpx.get")
    @patch("app.services.kie_image_service.time.sleep")
    def test_five_consecutive_poll_network_errors_abort(
        self,
        mock_sleep: MagicMock,
        mock_get: MagicMock,
        mock_post: MagicMock,
        mock_settings: MagicMock,
    ) -> None:
        _kie_settings_patch(mock_settings)
        mock_post.return_value = _create_task_response()
        mock_get.side_effect = [httpx.ConnectTimeout("t")] * 5

        client = KieImageTaskClient()
        with self.assertRaises(KiePollNetworkExhaustedError) as ctx:
            client.generate_image_bytes("prompt", [_SIGNED_URL_A])

        self.assertIn("kie_poll_network_exhausted", str(ctx.exception))
        self.assertEqual(client.created_tasks_count, 1)
        self.assertEqual(mock_get.call_count, 5)

    @patch("app.services.kie_image_service.kie_log")
    @patch("app.services.kie_image_service.settings")
    @patch("app.services.kie_image_service.httpx.post")
    @patch("app.services.kie_image_service.httpx.get")
    @patch("app.services.kie_image_service.time.sleep")
    def test_poll_network_logs_do_not_contain_secrets(
        self,
        mock_sleep: MagicMock,
        mock_get: MagicMock,
        mock_post: MagicMock,
        mock_settings: MagicMock,
        mock_kie_log: MagicMock,
    ) -> None:
        _kie_settings_patch(mock_settings)
        mock_post.return_value = _create_task_response()
        mock_get.side_effect = [
            httpx.ConnectTimeout("timed out"),
            _poll_response("success"),
            _download_response(),
        ]

        client = KieImageTaskClient()
        client.generate_image_bytes("secret prompt", [_SIGNED_URL_A])

        combined = " ".join(
            str(call.args) + str(call.kwargs)
            for call in mock_kie_log.info.call_args_list
            + mock_kie_log.warning.call_args_list
        )
        self.assertNotIn("secret-a", combined)
        self.assertNotIn("secret prompt", combined)
        self.assertNotIn("test-kie-key", combined)


class KieTemplateProviderIntegrationTests(unittest.TestCase):
    @patch("app.services.photo_generation_service.KieImageTaskClient")
    @patch.object(storage_service, "upload_temp_input_bytes")
    def test_temp_storage_failure_does_not_call_kie_create_task(
        self,
        mock_upload_temp: MagicMock,
        mock_kie_client_cls: MagicMock,
    ) -> None:
        mock_upload_temp.side_effect = HTTPException(
            status_code=503,
            detail="Supabase Storage is temporarily unavailable",
        )
        provider = KiePhotoGenerationProvider()

        with self.assertRaises(HTTPException) as ctx:
            provider.generate(
                description="prompt",
                photo_bytes=_TEST_PHOTO_BYTES,
                photo_content_type=_TEST_PHOTO_TYPE,
                user_id="user-1",
                template_id="birthday_balloons",
            )

        self.assertEqual(ctx.exception.status_code, 503)
        mock_kie_client_cls.assert_not_called()

    @patch("app.services.photo_generation_service.KieImageTaskClient")
    @patch.object(storage_service, "upload_temp_input_bytes")
    def test_kie_network_error_returns_503(
        self,
        mock_upload_temp: MagicMock,
        mock_kie_client_cls: MagicMock,
    ) -> None:
        mock_upload_temp.return_value = ("temp/path.jpg", _SIGNED_URL_A)
        mock_kie = MagicMock()
        mock_kie.created_tasks_count = 0
        mock_kie.http_calls_count = 1
        mock_kie.generate_image_bytes.side_effect = KieCreateTaskNetworkError(
            "kie_create_task_network"
        )
        mock_kie_client_cls.return_value = mock_kie
        provider = KiePhotoGenerationProvider()

        with self.assertRaises(HTTPException) as ctx:
            provider.generate(
                description="prompt",
                photo_bytes=_TEST_PHOTO_BYTES,
                photo_content_type=_TEST_PHOTO_TYPE,
                user_id="user-1",
                template_id="birthday_balloons",
            )

        self.assertEqual(ctx.exception.status_code, 503)
        self.assertIn("no idempotency", str(ctx.exception.detail).lower())

    @patch("app.main.photo_generation_service")
    def test_endpoint_kie_network_error_returns_503(
        self,
        mock_service: MagicMock,
    ) -> None:
        mock_service.generate.side_effect = HTTPException(
            status_code=503,
            detail="Kie create task network error",
        )
        client = TestClient(app)
        with patch.object(settings, "enable_credit_consumption", False):
            response = client.post(
                "/generate-with-photo",
                data={
                    "description": "ignored",
                    "template_id": "birthday_balloons",
                    "age_number": "30",
                },
                files={"photo": ("user.jpg", io.BytesIO(_TEST_PHOTO_BYTES), _TEST_PHOTO_TYPE)},
            )
        self.assertEqual(response.status_code, 503)


class KieTemplateLoggingSafetyTests(unittest.TestCase):
    @patch("app.services.photo_generation_service.KieImageTaskClient")
    @patch.object(storage_service, "upload_temp_input_bytes")
    def test_template_kie_logs_do_not_contain_secrets(
        self,
        mock_upload_temp: MagicMock,
        mock_kie_client_cls: MagicMock,
    ) -> None:
        mock_upload_temp.return_value = ("temp/path.jpg", _SIGNED_URL_A)
        mock_kie = MagicMock()
        mock_kie.created_tasks_count = 1
        mock_kie.http_calls_count = 2
        mock_kie.generate_image_bytes.return_value = (b"\x89PNG\r\n", "image/png")
        mock_kie_client_cls.return_value = mock_kie

        captured: list[logging.LogRecord] = []

        class _CollectHandler(logging.Handler):
            def emit(self, record: logging.LogRecord) -> None:
                captured.append(record)

        handler = _CollectHandler()
        pipeline_logger = logging.getLogger("uvicorn.error")
        pipeline_logger.addHandler(handler)
        self.addCleanup(pipeline_logger.removeHandler, handler)

        provider = KiePhotoGenerationProvider()
        provider.generate(
            description="secret prompt text",
            photo_bytes=_TEST_PHOTO_BYTES,
            photo_content_type=_TEST_PHOTO_TYPE,
            user_id="secret-user-id",
            template_id="birthday_balloons",
        )

        logged = "\n".join(record.getMessage() for record in captured)
        self.assertNotIn("secret-a", logged)
        self.assertNotIn("secret-user-id", logged)
        self.assertNotIn("secret prompt", logged)
        self.assertNotIn("test-kie-key", logged)


    @patch.object(storage_service, "_delete_object_in_bucket", return_value=(False, "ConnectTimeout"))
    @patch("app.services.photo_generation_service.KieImageTaskClient")
    @patch.object(storage_service, "upload_temp_input_bytes")
    def test_cleanup_delete_failure_does_not_break_generation(
        self,
        mock_upload_temp: MagicMock,
        mock_kie_client_cls: MagicMock,
        mock_delete_bucket: MagicMock,
    ) -> None:
        mock_upload_temp.return_value = ("temp/path.jpg", _SIGNED_URL_A)
        mock_kie = MagicMock()
        mock_kie.created_tasks_count = 1
        mock_kie.http_calls_count = 3
        mock_kie.generate_image_bytes.return_value = (_TEST_RESULT_BYTES, "image/png")
        mock_kie_client_cls.return_value = mock_kie
        provider = KiePhotoGenerationProvider()

        result = provider.generate(
            description="prompt",
            photo_bytes=_TEST_PHOTO_BYTES,
            photo_content_type=_TEST_PHOTO_TYPE,
            user_id="user-1",
            template_id="woman_with_cat",
        )

        self.assertTrue(result.startswith("data:image/png;base64,"))
        mock_delete_bucket.assert_called()


if __name__ == "__main__":
    unittest.main()
