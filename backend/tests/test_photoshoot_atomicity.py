"""Fault-simulation tests for atomic photoshoot generation (no real Gemini/Supabase)."""

from __future__ import annotations

import io
import unittest
from unittest.mock import MagicMock, patch

import httpx
from fastapi import HTTPException
from fastapi.testclient import TestClient

from app.auth import CurrentUser, get_current_user
from app.main import app
from app.services.photoshoot_service import (
    GeminiPhotoshootProvider,
    PhotoshootGenerateResult,
    PhotoshootService,
    _MAX_GEMINI_FRAME_ATTEMPTS,
    _PHOTOSHOOT_FAILURE_MESSAGE,
    _is_retryable_gemini_photoshoot_error,
    _upload_photoshoot_frames_to_storage,
    rollback_persisted_photoshoot,
)
from app.services.photoshoot_styles import PHOTOSHOOT_STYLES

_TEST_DATA_URL = "data:image/png;base64,iVBORw0KGgo="
_TEST_PHOTO_BYTES = b"fake-photo"
_TEST_PHOTO_TYPE = "image/jpeg"
_TEST_JPEG_BYTES = b"\xff\xd8\xff\xe0" + b"\x00" * 16


class _FakeGeminiClientError(Exception):
    """Minimal Gemini ClientError stand-in for retry classification tests."""

    def __init__(self, status_code: int, message: str) -> None:
        super().__init__(message)
        self.status_code = status_code
        self.message = message


def _httpx_status_error(status_code: int) -> httpx.HTTPStatusError:
    request = httpx.Request("POST", "https://generativelanguage.googleapis.com/test")
    response = httpx.Response(status_code, request=request)
    return httpx.HTTPStatusError(
        f"HTTP {status_code}",
        request=request,
        response=response,
    )


class PhotoshootGeminiRetryClassificationTests(unittest.TestCase):
    def test_client_error_400_is_not_retryable(self) -> None:
        exc = _FakeGeminiClientError(
            400,
            "User location is not supported for the API use.",
        )
        self.assertFalse(_is_retryable_gemini_photoshoot_error(exc))

    def test_httpx_status_error_400_is_not_retryable(self) -> None:
        self.assertFalse(_is_retryable_gemini_photoshoot_error(_httpx_status_error(400)))

    def test_httpx_status_error_503_is_retryable(self) -> None:
        self.assertTrue(_is_retryable_gemini_photoshoot_error(_httpx_status_error(503)))

    @patch("app.services.photoshoot_service.time.sleep")
    @patch("app.services.photoshoot_service.create_generation_record")
    @patch("app.services.photoshoot_service.storage_service")
    @patch("app.services.photoshoot_service.genai.Client")
    @patch.object(GeminiPhotoshootProvider, "_call_gemini_frame")
    @patch("app.services.photoshoot_service.settings")
    def test_retryable_503_attempts_max_retries_before_abort(
        self,
        mock_settings: MagicMock,
        mock_call_frame: MagicMock,
        mock_client_cls: MagicMock,
        mock_storage: MagicMock,
        mock_create_record: MagicMock,
        mock_sleep: MagicMock,
    ) -> None:
        mock_settings.image_provider = "gemini"
        mock_settings.gemini_api_key = "test-key"
        mock_settings.gemini_model = "gemini-2.5-flash-image"
        mock_settings.photoshoot_output_count = 3
        mock_call_frame.side_effect = _httpx_status_error(503)

        service = PhotoshootService()
        with self.assertRaises(HTTPException) as ctx:
            service.generate_photoshoot(
                user_id="user-1",
                style=PHOTOSHOOT_STYLES["business_portrait"],
                photo_bytes=_TEST_PHOTO_BYTES,
                photo_content_type=_TEST_PHOTO_TYPE,
                client_style_id="business_portrait",
            )

        self.assertEqual(ctx.exception.status_code, 502)
        self.assertEqual(mock_call_frame.call_count, _MAX_GEMINI_FRAME_ATTEMPTS)
        self.assertEqual(mock_sleep.call_count, _MAX_GEMINI_FRAME_ATTEMPTS - 1)
        mock_create_record.assert_not_called()
        mock_storage.upload_generated_image_data_url_with_path.assert_not_called()

    @patch("app.services.photoshoot_service.create_generation_record")
    @patch("app.services.photoshoot_service.storage_service")
    @patch("app.services.photoshoot_service.genai.Client")
    @patch.object(GeminiPhotoshootProvider, "_call_gemini_frame")
    @patch("app.services.photoshoot_service.settings")
    def test_non_retryable_gemini_400_single_attempt_no_persist(
        self,
        mock_settings: MagicMock,
        mock_call_frame: MagicMock,
        mock_client_cls: MagicMock,
        mock_storage: MagicMock,
        mock_create_record: MagicMock,
    ) -> None:
        mock_settings.image_provider = "gemini"
        mock_settings.gemini_api_key = "test-key"
        mock_settings.gemini_model = "gemini-2.5-flash-image"
        mock_settings.photoshoot_output_count = 3
        mock_call_frame.side_effect = _FakeGeminiClientError(
            400,
            "User location is not supported for the API use.",
        )

        service = PhotoshootService()
        with self.assertRaises(HTTPException) as ctx:
            service.generate_photoshoot(
                user_id="user-1",
                style=PHOTOSHOOT_STYLES["business_portrait"],
                photo_bytes=_TEST_PHOTO_BYTES,
                photo_content_type=_TEST_PHOTO_TYPE,
                client_style_id="business_portrait",
            )

        self.assertEqual(ctx.exception.status_code, 502)
        self.assertEqual(ctx.exception.detail, _PHOTOSHOOT_FAILURE_MESSAGE)
        mock_call_frame.assert_called_once()
        mock_create_record.assert_not_called()
        mock_storage.upload_generated_image_data_url_with_path.assert_not_called()
        mock_client_cls.assert_called_once_with(api_key="test-key")


class PhotoshootEndpointGeminiRetryTests(unittest.TestCase):
    def setUp(self) -> None:
        def _override_user() -> CurrentUser:
            return CurrentUser(id="endpoint-test-user", email="u@example.com")

        app.dependency_overrides[get_current_user] = _override_user
        self.client = TestClient(app)

    def tearDown(self) -> None:
        app.dependency_overrides.clear()

    @patch("app.main.consume_photoshoot")
    @patch("app.services.photoshoot_service.create_generation_record")
    @patch("app.services.photoshoot_service.storage_service")
    @patch("app.services.photoshoot_service.genai.Client")
    @patch.object(GeminiPhotoshootProvider, "_call_gemini_frame")
    @patch("app.main.settings")
    @patch("app.services.photoshoot_service.settings")
    def test_endpoint_gemini_400_returns_502_without_persist_or_debit(
        self,
        mock_service_settings: MagicMock,
        mock_main_settings: MagicMock,
        mock_call_frame: MagicMock,
        mock_client_cls: MagicMock,
        mock_storage: MagicMock,
        mock_create_record: MagicMock,
        mock_consume: MagicMock,
    ) -> None:
        mock_main_settings.enable_photoshoot_generation = True
        mock_main_settings.enable_credit_consumption = True
        mock_main_settings.free_generations_limit = 3
        mock_service_settings.image_provider = "gemini"
        mock_service_settings.gemini_api_key = "test-key"
        mock_service_settings.gemini_model = "gemini-2.5-flash-image"
        mock_service_settings.photoshoot_output_count = 3
        mock_call_frame.side_effect = _FakeGeminiClientError(
            400,
            "User location is not supported for the API use.",
        )

        with patch("app.main.ensure_profile_exists", return_value={"id": "endpoint-test-user"}), patch(
            "app.main.determine_photoshoot_payment",
            return_value={"allowed": True},
        ), patch("app.main._ensure_profile_for_user"):
            response = self.client.post(
                "/photoshoots/generate",
                data={"style_id": "business_portrait"},
                files={
                    "photo": ("photo.jpg", io.BytesIO(_TEST_JPEG_BYTES), "image/jpeg"),
                },
            )

        self.assertEqual(response.status_code, 502)
        self.assertEqual(
            response.json(),
            {"status": "error", "message": "Photoshoot generation failed"},
        )
        mock_call_frame.assert_called_once()
        mock_create_record.assert_not_called()
        mock_storage.upload_generated_image_data_url_with_path.assert_not_called()
        mock_consume.assert_not_called()


class PhotoshootAtomicityTests(unittest.TestCase):
    def setUp(self) -> None:
        self.style = PHOTOSHOOT_STYLES["studio_portrait"]
        self.service = PhotoshootService()

    @patch("app.services.photoshoot_service.create_generation_record")
    @patch("app.services.photoshoot_service.storage_service")
    @patch.object(PhotoshootService, "_get_provider")
    def test_gemini_frame_failure_aborts_without_persist(
        self,
        mock_get_provider: MagicMock,
        mock_storage: MagicMock,
        mock_create_record: MagicMock,
    ) -> None:
        provider = MagicMock()
        provider.output_count = 3
        provider.generate.side_effect = HTTPException(
            status_code=502,
            detail=_PHOTOSHOOT_FAILURE_MESSAGE,
        )
        mock_get_provider.return_value = provider

        with self.assertRaises(HTTPException) as ctx:
            self.service.generate_photoshoot(
                user_id="user-1",
                style=self.style,
                photo_bytes=_TEST_PHOTO_BYTES,
                photo_content_type=_TEST_PHOTO_TYPE,
                client_style_id="studio_portrait",
            )

        self.assertEqual(ctx.exception.status_code, 502)
        mock_create_record.assert_not_called()
        mock_storage.upload_generated_image_data_url_with_path.assert_not_called()
        mock_storage.delete_objects_best_effort.assert_not_called()

    @patch("app.services.photoshoot_service.create_generation_record")
    @patch("app.services.photoshoot_service.storage_service")
    def test_storage_upload_failure_cleans_uploaded_files(
        self,
        mock_storage: MagicMock,
        mock_create_record: MagicMock,
    ) -> None:
        mock_storage.upload_generated_image_data_url_with_path.side_effect = [
            ("photoshoots/user-1/frame-0.png", "https://cdn.example/0.png"),
            HTTPException(status_code=503, detail="storage down"),
        ]

        with self.assertRaises(HTTPException) as ctx:
            _upload_photoshoot_frames_to_storage(
                user_id="user-1",
                client_style_id="studio_portrait",
                data_urls=[_TEST_DATA_URL, _TEST_DATA_URL],
                photoshoot_id="batch-1",
            )

        self.assertEqual(ctx.exception.status_code, 502)
        mock_storage.delete_objects_best_effort.assert_called_once_with(
            ["photoshoots/user-1/frame-0.png"]
        )
        mock_create_record.assert_not_called()

    @patch("app.services.photoshoot_service.delete_generations_by_photoshoot_id")
    @patch("app.services.photoshoot_service.create_generation_record")
    @patch("app.services.photoshoot_service.storage_service")
    @patch.object(PhotoshootService, "_get_provider")
    def test_db_save_failure_rolls_back_db_and_storage(
        self,
        mock_get_provider: MagicMock,
        mock_storage: MagicMock,
        mock_create_record: MagicMock,
        mock_delete_generations: MagicMock,
    ) -> None:
        provider = MagicMock()
        provider.output_count = 3
        provider.generate.return_value = [_TEST_DATA_URL, _TEST_DATA_URL, _TEST_DATA_URL]
        mock_get_provider.return_value = provider

        mock_storage.upload_generated_image_data_url_with_path.side_effect = [
            ("photoshoots/user-1/frame-0.png", "https://cdn.example/0.png"),
            ("photoshoots/user-1/frame-1.png", "https://cdn.example/1.png"),
            ("photoshoots/user-1/frame-2.png", "https://cdn.example/2.png"),
        ]
        mock_create_record.side_effect = [
            {"id": "gen-1"},
            HTTPException(status_code=503, detail="db down"),
        ]

        with self.assertRaises(HTTPException) as ctx:
            self.service.generate_photoshoot(
                user_id="user-1",
                style=self.style,
                photo_bytes=_TEST_PHOTO_BYTES,
                photo_content_type=_TEST_PHOTO_TYPE,
                client_style_id="studio_portrait",
            )

        self.assertEqual(ctx.exception.status_code, 502)
        mock_delete_generations.assert_called_once()
        mock_storage.delete_objects_best_effort.assert_called_once_with(
            [
                "photoshoots/user-1/frame-0.png",
                "photoshoots/user-1/frame-1.png",
                "photoshoots/user-1/frame-2.png",
            ]
        )

    @patch("app.services.photoshoot_service.storage_service")
    @patch("app.services.photoshoot_service.delete_generations_by_photoshoot_id")
    def test_rollback_persisted_photoshoot_cleans_db_and_storage(
        self,
        mock_delete_generations: MagicMock,
        mock_storage: MagicMock,
    ) -> None:
        rollback_persisted_photoshoot(
            photoshoot_id="batch-rollback",
            storage_paths=["photoshoots/user-1/a.png", "photoshoots/user-1/b.png"],
            client_style_id="studio_portrait",
        )

        mock_delete_generations.assert_called_once_with("batch-rollback")
        mock_storage.delete_objects_best_effort.assert_called_once_with(
            ["photoshoots/user-1/a.png", "photoshoots/user-1/b.png"]
        )

    @patch("app.services.photoshoot_service.create_generation_record")
    @patch("app.services.photoshoot_service.storage_service")
    @patch.object(PhotoshootService, "_get_provider")
    def test_success_returns_three_urls_with_one_photoshoot_id(
        self,
        mock_get_provider: MagicMock,
        mock_storage: MagicMock,
        mock_create_record: MagicMock,
    ) -> None:
        provider = MagicMock()
        provider.output_count = 3
        provider.generate.return_value = [_TEST_DATA_URL, _TEST_DATA_URL, _TEST_DATA_URL]
        mock_get_provider.return_value = provider

        mock_storage.upload_generated_image_data_url_with_path.side_effect = [
            ("photoshoots/user-1/frame-0.png", "https://cdn.example/0.png"),
            ("photoshoots/user-1/frame-1.png", "https://cdn.example/1.png"),
            ("photoshoots/user-1/frame-2.png", "https://cdn.example/2.png"),
        ]
        mock_create_record.return_value = {"id": "gen"}

        result = self.service.generate_photoshoot(
            user_id="user-1",
            style=self.style,
            photo_bytes=_TEST_PHOTO_BYTES,
            photo_content_type=_TEST_PHOTO_TYPE,
            client_style_id="studio_portrait",
        )

        self.assertEqual(len(result.image_urls), 3)
        self.assertEqual(len(result.storage_paths), 3)
        self.assertTrue(result.photoshoot_id)
        photoshoot_ids = {
            call.kwargs.get("photoshoot_id")
            for call in mock_create_record.call_args_list
        }
        self.assertEqual(len(photoshoot_ids), 1)
        self.assertEqual(photoshoot_ids.pop(), result.photoshoot_id)


class PhotoshootEndpointDebitFailureTests(unittest.TestCase):
    _SUCCESS_RESULT = PhotoshootGenerateResult(
        image_urls=[
            "https://cdn.example/0.png",
            "https://cdn.example/1.png",
            "https://cdn.example/2.png",
        ],
        photoshoot_id="ps-batch-endpoint",
        storage_paths=[
            "photoshoots/user-1/frame-0.png",
            "photoshoots/user-1/frame-1.png",
            "photoshoots/user-1/frame-2.png",
        ],
    )

    def setUp(self) -> None:
        def _override_user() -> CurrentUser:
            return CurrentUser(id="endpoint-test-user", email="u@example.com")

        app.dependency_overrides[get_current_user] = _override_user
        self.client = TestClient(app)

    def tearDown(self) -> None:
        app.dependency_overrides.clear()

    def _post_photoshoot_generate(self):
        return self.client.post(
            "/photoshoots/generate",
            data={"style_id": "studio_portrait"},
            files={"photo": ("photo.jpg", io.BytesIO(_TEST_JPEG_BYTES), "image/jpeg")},
        )

    @patch("app.main.rollback_persisted_photoshoot")
    @patch("app.main.consume_photoshoot")
    @patch("app.main.photoshoot_service.generate_photoshoot")
    @patch("app.main.determine_photoshoot_payment")
    @patch("app.main.ensure_profile_exists")
    @patch("app.main._ensure_profile_for_user")
    @patch("app.main.settings")
    def test_endpoint_debit_http_exception_returns_502_and_rolls_back(
        self,
        mock_settings: MagicMock,
        mock_ensure_profile_for_user: MagicMock,
        mock_ensure_profile_exists: MagicMock,
        mock_determine_payment: MagicMock,
        mock_generate: MagicMock,
        mock_consume: MagicMock,
        mock_rollback: MagicMock,
    ) -> None:
        mock_settings.enable_photoshoot_generation = True
        mock_settings.enable_credit_consumption = True
        mock_settings.free_generations_limit = 3
        mock_ensure_profile_exists.return_value = {"id": "endpoint-test-user"}
        mock_determine_payment.return_value = {"allowed": True}
        mock_generate.return_value = self._SUCCESS_RESULT
        mock_consume.side_effect = HTTPException(status_code=503, detail="profile update failed")

        response = self._post_photoshoot_generate()

        self.assertEqual(response.status_code, 502)
        body = response.json()
        self.assertEqual(body, {"status": "error", "message": "Photoshoot generation failed"})
        self.assertNotIn("images", body)
        self.assertNotIn("image_urls", body)
        mock_rollback.assert_called_once_with(
            photoshoot_id="ps-batch-endpoint",
            storage_paths=self._SUCCESS_RESULT.storage_paths,
            client_style_id="studio_portrait",
        )

    @patch("app.main.rollback_persisted_photoshoot")
    @patch("app.main.consume_photoshoot")
    @patch("app.main.photoshoot_service.generate_photoshoot")
    @patch("app.main.determine_photoshoot_payment")
    @patch("app.main.ensure_profile_exists")
    @patch("app.main._ensure_profile_for_user")
    @patch("app.main.settings")
    def test_endpoint_debit_runtime_error_returns_502_and_rolls_back(
        self,
        mock_settings: MagicMock,
        mock_ensure_profile_for_user: MagicMock,
        mock_ensure_profile_exists: MagicMock,
        mock_determine_payment: MagicMock,
        mock_generate: MagicMock,
        mock_consume: MagicMock,
        mock_rollback: MagicMock,
    ) -> None:
        mock_settings.enable_photoshoot_generation = True
        mock_settings.enable_credit_consumption = True
        mock_settings.free_generations_limit = 3
        mock_ensure_profile_exists.return_value = {"id": "endpoint-test-user"}
        mock_determine_payment.return_value = {"allowed": True}
        mock_generate.return_value = self._SUCCESS_RESULT
        mock_consume.side_effect = RuntimeError("Insufficient image credits")

        response = self._post_photoshoot_generate()

        self.assertEqual(response.status_code, 502)
        body = response.json()
        self.assertEqual(body, {"status": "error", "message": "Photoshoot generation failed"})
        mock_rollback.assert_called_once_with(
            photoshoot_id="ps-batch-endpoint",
            storage_paths=self._SUCCESS_RESULT.storage_paths,
            client_style_id="studio_portrait",
        )


if __name__ == "__main__":
    unittest.main()
