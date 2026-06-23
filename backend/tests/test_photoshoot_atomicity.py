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
    DuplicateFrameMatch,
    GeminiPhotoshootProvider,
    PhotoshootGenerateResult,
    PhotoshootService,
    _MAX_GEMINI_FRAME_ATTEMPTS,
    _PHOTOSHOOT_FAILURE_MESSAGE,
    _find_generated_frame_duplicate,
    _is_anchor_only_fallback_eligible,
    _is_empty_image_response_error,
    _is_identity_fallback_eligible,
    _is_multi_image_fallback_eligible,
    _is_retryable_gemini_photoshoot_error,
    _upload_photoshoot_frames_to_storage,
    rollback_persisted_photoshoot,
)
from app.services.photoshoot_styles import PHOTOSHOOT_STYLES
from app.services.storage_service import storage_service

_TEST_DATA_URL = "data:image/png;base64,iVBORw0KGgo="
_TEST_DATA_URL_2 = "data:image/png;base64,QUJDRA=="
_TEST_DATA_URL_3 = "data:image/png;base64,QUJDREVG"
_TEST_DATA_URL_4 = "data:image/png;base64,QUJDRUZX"
_TEST_PHOTO_BYTES = b"fake-photo"
_TEST_PHOTO_TYPE = "image/jpeg"
_TEST_JPEG_BYTES = b"\xff\xd8\xff\xe0" + b"\x00" * 16


def _empty_image_http_exception() -> HTTPException:
    return HTTPException(
        status_code=502,
        detail=(
            "Gemini did not return a photoshoot image: "
            "candidates=1; parts=0; part_types=none"
        ),
    )


def _identity_reference() -> tuple[bytes, str]:
    return _TEST_PHOTO_BYTES, _TEST_PHOTO_TYPE


def _anchor_reference_from_data_url(data_url: str) -> tuple[bytes, str]:
    content_type, content = storage_service._parse_generated_image_data_url(data_url)
    return content, content_type


def _reference_counts(mock_call_frame: MagicMock) -> list[int]:
    return [
        len(call.kwargs["reference_images"])
        for call in mock_call_frame.call_args_list
    ]


def _configure_gemini_settings(mock_settings: MagicMock, *, mode: str = "legacy") -> None:
    mock_settings.image_provider = "gemini"
    mock_settings.gemini_api_key = "test-key"
    mock_settings.gemini_model = "gemini-2.5-flash-image"
    mock_settings.photoshoot_output_count = 3
    mock_settings.photoshoot_series_reference_mode = mode


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
        mock_settings.photoshoot_series_reference_mode = "legacy"
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
        mock_settings.photoshoot_series_reference_mode = "legacy"
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
        mock_service_settings.photoshoot_series_reference_mode = "legacy"
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


class PhotoshootEndpointCreditConsumptionTests(unittest.TestCase):
    _SUCCESS_RESULT = PhotoshootGenerateResult(
        image_urls=[
            "https://cdn.example/0.png",
            "https://cdn.example/1.png",
            "https://cdn.example/2.png",
        ],
        photoshoot_id="ps-demo-safe",
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

    @patch("app.main.photoshoot_service.generate_photoshoot")
    @patch("app.main.ensure_profile_exists")
    @patch("app.main.settings")
    def test_consumption_disabled_skips_profile_precheck_and_starts_generation(
        self,
        mock_settings: MagicMock,
        mock_ensure_profile_exists: MagicMock,
        mock_generate: MagicMock,
    ) -> None:
        mock_settings.enable_photoshoot_generation = True
        mock_settings.enable_credit_consumption = False
        mock_ensure_profile_exists.side_effect = HTTPException(
            status_code=503,
            detail="Supabase is temporarily unavailable",
        )
        mock_generate.return_value = self._SUCCESS_RESULT

        response = self._post_photoshoot_generate()

        self.assertEqual(response.status_code, 200)
        mock_ensure_profile_exists.assert_not_called()
        mock_generate.assert_called_once()

    @patch("app.main.photoshoot_service.generate_photoshoot")
    @patch("app.main.ensure_profile_exists")
    @patch("app.main.settings")
    def test_consumption_disabled_calls_generate_even_if_profile_would_fail(
        self,
        mock_settings: MagicMock,
        mock_ensure_profile_exists: MagicMock,
        mock_generate: MagicMock,
    ) -> None:
        mock_settings.enable_photoshoot_generation = True
        mock_settings.enable_credit_consumption = False
        mock_ensure_profile_exists.side_effect = RuntimeError("Supabase down")
        mock_generate.return_value = self._SUCCESS_RESULT

        response = self._post_photoshoot_generate()

        self.assertEqual(response.status_code, 200)
        mock_ensure_profile_exists.assert_not_called()
        mock_generate.assert_called_once()

    @patch("app.main.photoshoot_service.generate_photoshoot")
    @patch("app.main.ensure_profile_exists")
    @patch("app.main.settings")
    def test_consumption_enabled_profile_precheck_timeout_skips_generation(
        self,
        mock_settings: MagicMock,
        mock_ensure_profile_exists: MagicMock,
        mock_generate: MagicMock,
    ) -> None:
        mock_settings.enable_photoshoot_generation = True
        mock_settings.enable_credit_consumption = True
        mock_settings.free_generations_limit = 3
        mock_ensure_profile_exists.side_effect = HTTPException(
            status_code=503,
            detail="Supabase is temporarily unavailable",
        )

        response = self._post_photoshoot_generate()

        self.assertEqual(response.status_code, 502)
        self.assertEqual(
            response.json(),
            {"status": "error", "message": "Photoshoot generation failed"},
        )
        mock_ensure_profile_exists.assert_called_once()
        mock_generate.assert_not_called()


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


class PhotoshootSeriesReferenceModeTests(unittest.TestCase):
    style = PHOTOSHOOT_STYLES["studio_portrait"]

    @patch("app.services.photoshoot_service.genai.Client")
    @patch.object(GeminiPhotoshootProvider, "_call_gemini_frame")
    @patch("app.services.photoshoot_service.settings")
    def test_legacy_mode_uses_one_reference_per_frame(
        self,
        mock_settings: MagicMock,
        mock_call_frame: MagicMock,
        mock_client_cls: MagicMock,
    ) -> None:
        _configure_gemini_settings(mock_settings, mode="legacy")
        mock_call_frame.side_effect = [
            _TEST_DATA_URL,
            _TEST_DATA_URL_2,
            _TEST_DATA_URL_3,
        ]

        provider = GeminiPhotoshootProvider(output_count=3)
        provider.generate(
            self.style,
            _TEST_PHOTO_BYTES,
            _TEST_PHOTO_TYPE,
            client_style_id="studio_portrait",
            photoshoot_id="ps-legacy",
        )

        self.assertEqual(mock_call_frame.call_count, 3)
        self.assertEqual(_reference_counts(mock_call_frame), [1, 1, 1])

    @patch("app.services.photoshoot_service.genai.Client")
    @patch.object(GeminiPhotoshootProvider, "_call_gemini_frame")
    @patch("app.services.photoshoot_service.settings")
    def test_identity_anchor_mode_uses_two_references_for_frames_one_and_two(
        self,
        mock_settings: MagicMock,
        mock_call_frame: MagicMock,
        mock_client_cls: MagicMock,
    ) -> None:
        _configure_gemini_settings(mock_settings, mode="identity_anchor")
        mock_call_frame.side_effect = [
            _TEST_DATA_URL,
            _TEST_DATA_URL_2,
            _TEST_DATA_URL_3,
        ]

        provider = GeminiPhotoshootProvider(output_count=3)
        provider.generate(
            self.style,
            _TEST_PHOTO_BYTES,
            _TEST_PHOTO_TYPE,
            client_style_id="studio_portrait",
            photoshoot_id="ps-identity-anchor",
        )

        self.assertEqual(mock_call_frame.call_count, 3)
        self.assertEqual(_reference_counts(mock_call_frame), [1, 2, 2])

    @patch("app.services.photoshoot_service.genai.Client")
    @patch.object(GeminiPhotoshootProvider, "_call_gemini_frame")
    @patch("app.services.photoshoot_service.settings")
    def test_anchor_only_mode_uses_anchor_reference_for_frames_one_and_two(
        self,
        mock_settings: MagicMock,
        mock_call_frame: MagicMock,
        mock_client_cls: MagicMock,
    ) -> None:
        _configure_gemini_settings(mock_settings, mode="anchor_only")
        mock_call_frame.side_effect = [
            _TEST_DATA_URL,
            _TEST_DATA_URL_2,
            _TEST_DATA_URL_3,
        ]
        expected_anchor = _anchor_reference_from_data_url(_TEST_DATA_URL)

        provider = GeminiPhotoshootProvider(output_count=3)
        provider.generate(
            self.style,
            _TEST_PHOTO_BYTES,
            _TEST_PHOTO_TYPE,
            client_style_id="studio_portrait",
            photoshoot_id="ps-anchor-only",
        )

        self.assertEqual(mock_call_frame.call_count, 3)
        self.assertEqual(_reference_counts(mock_call_frame), [1, 1, 1])
        frame_one_refs = mock_call_frame.call_args_list[1].kwargs["reference_images"]
        frame_two_refs = mock_call_frame.call_args_list[2].kwargs["reference_images"]
        self.assertEqual(frame_one_refs, [expected_anchor])
        self.assertEqual(frame_two_refs, [expected_anchor])
        self.assertNotEqual(frame_one_refs[0][0], _TEST_PHOTO_BYTES)

    @patch("app.services.photoshoot_service.create_generation_record")
    @patch("app.services.photoshoot_service.storage_service")
    @patch("app.services.photoshoot_service.genai.Client")
    @patch.object(GeminiPhotoshootProvider, "_call_gemini_frame")
    @patch("app.services.photoshoot_service.settings")
    def test_frame_zero_failure_skips_later_frames_and_persist(
        self,
        mock_settings: MagicMock,
        mock_call_frame: MagicMock,
        mock_client_cls: MagicMock,
        mock_storage: MagicMock,
        mock_create_record: MagicMock,
    ) -> None:
        _configure_gemini_settings(mock_settings, mode="identity_anchor")
        mock_call_frame.side_effect = _FakeGeminiClientError(
            400,
            "User location is not supported for the API use.",
        )

        service = PhotoshootService()
        with self.assertRaises(HTTPException):
            service.generate_photoshoot(
                user_id="user-1",
                style=self.style,
                photo_bytes=_TEST_PHOTO_BYTES,
                photo_content_type=_TEST_PHOTO_TYPE,
                client_style_id="studio_portrait",
            )

        mock_call_frame.assert_called_once()
        mock_create_record.assert_not_called()
        mock_storage.upload_generated_image_data_url_with_path.assert_not_called()

    @patch("app.services.photoshoot_service.create_generation_record")
    @patch("app.services.photoshoot_service.storage_service")
    @patch("app.services.photoshoot_service.genai.Client")
    @patch.object(GeminiPhotoshootProvider, "_call_gemini_frame")
    @patch("app.services.photoshoot_service.settings")
    def test_frame_two_failure_after_success_aborts_without_persist(
        self,
        mock_settings: MagicMock,
        mock_call_frame: MagicMock,
        mock_client_cls: MagicMock,
        mock_storage: MagicMock,
        mock_create_record: MagicMock,
    ) -> None:
        _configure_gemini_settings(mock_settings, mode="identity_anchor")

        def _parse_data_url(data_url: str) -> tuple[str, bytes]:
            content, content_type = _anchor_reference_from_data_url(data_url)
            return content_type, content

        mock_storage._parse_generated_image_data_url.side_effect = _parse_data_url
        mock_call_frame.side_effect = [
            _TEST_DATA_URL,
            _TEST_DATA_URL,
            _FakeGeminiClientError(
                400,
                "User location is not supported for the API use.",
            ),
        ]

        service = PhotoshootService()
        with self.assertRaises(HTTPException):
            service.generate_photoshoot(
                user_id="user-1",
                style=self.style,
                photo_bytes=_TEST_PHOTO_BYTES,
                photo_content_type=_TEST_PHOTO_TYPE,
                client_style_id="studio_portrait",
            )

        self.assertEqual(mock_call_frame.call_count, 3)
        mock_create_record.assert_not_called()
        mock_storage.upload_generated_image_data_url_with_path.assert_not_called()

    @patch("app.services.photoshoot_service.genai.Client")
    @patch.object(GeminiPhotoshootProvider, "_call_gemini_frame")
    @patch("app.services.photoshoot_service.settings")
    def test_location_400_does_not_fallback_to_identity_only(
        self,
        mock_settings: MagicMock,
        mock_call_frame: MagicMock,
        mock_client_cls: MagicMock,
    ) -> None:
        _configure_gemini_settings(mock_settings, mode="identity_anchor")
        mock_call_frame.side_effect = [
            _TEST_DATA_URL,
            _FakeGeminiClientError(
                400,
                "User location is not supported for the API use.",
            ),
        ]

        provider = GeminiPhotoshootProvider(output_count=3)
        with self.assertRaises(HTTPException):
            provider.generate(
                self.style,
                _TEST_PHOTO_BYTES,
                _TEST_PHOTO_TYPE,
                client_style_id="studio_portrait",
                photoshoot_id="ps-no-fallback",
            )

        self.assertEqual(mock_call_frame.call_count, 2)

    @patch("app.services.photoshoot_service.genai.Client")
    @patch.object(GeminiPhotoshootProvider, "_call_gemini_frame")
    @patch("app.services.photoshoot_service.settings")
    def test_multi_image_400_falls_back_to_identity_only_for_frame_one(
        self,
        mock_settings: MagicMock,
        mock_call_frame: MagicMock,
        mock_client_cls: MagicMock,
    ) -> None:
        _configure_gemini_settings(mock_settings, mode="identity_anchor")
        mock_call_frame.side_effect = [
            _TEST_DATA_URL,
            _FakeGeminiClientError(400, "too many image parts in request"),
            _TEST_DATA_URL_2,
            _TEST_DATA_URL_3,
        ]

        provider = GeminiPhotoshootProvider(output_count=3)
        result = provider.generate(
            self.style,
            _TEST_PHOTO_BYTES,
            _TEST_PHOTO_TYPE,
            client_style_id="studio_portrait",
            photoshoot_id="ps-fallback",
        )

        self.assertEqual(len(result), 3)
        self.assertEqual(mock_call_frame.call_count, 4)
        fallback_refs = mock_call_frame.call_args_list[2].kwargs["reference_images"]
        self.assertEqual(fallback_refs, [_identity_reference()])
        fallback_instruction = mock_call_frame.call_args_list[2].kwargs["instruction"]
        self.assertIn("Fallback generation mode", fallback_instruction)

    @patch("app.services.photoshoot_service.genai.Client")
    @patch.object(GeminiPhotoshootProvider, "_call_gemini_frame")
    @patch("app.services.photoshoot_service.settings")
    def test_empty_image_response_falls_back_to_identity_only_without_retrying_primary(
        self,
        mock_settings: MagicMock,
        mock_call_frame: MagicMock,
        mock_client_cls: MagicMock,
    ) -> None:
        _configure_gemini_settings(mock_settings, mode="identity_anchor")
        mock_call_frame.side_effect = [
            _TEST_DATA_URL,
            _empty_image_http_exception(),
            _TEST_DATA_URL_2,
            _TEST_DATA_URL_3,
        ]

        provider = GeminiPhotoshootProvider(output_count=3)
        result = provider.generate(
            self.style,
            _TEST_PHOTO_BYTES,
            _TEST_PHOTO_TYPE,
            client_style_id="studio_portrait",
            photoshoot_id="ps-empty-fallback",
        )

        self.assertEqual(len(result), 3)
        self.assertEqual(mock_call_frame.call_count, 4)
        self.assertEqual(
            mock_call_frame.call_args_list[1].kwargs["reference_images"],
            [_identity_reference(), _anchor_reference_from_data_url(_TEST_DATA_URL)],
        )
        self.assertEqual(
            mock_call_frame.call_args_list[2].kwargs["reference_images"],
            [_identity_reference()],
        )
        self.assertLess(mock_call_frame.call_count, 1 + _MAX_GEMINI_FRAME_ATTEMPTS + 1)
        self.assertEqual(
            mock_call_frame.call_args_list[2].kwargs["reference_images"],
            [_identity_reference()],
        )

    @patch("app.services.photoshoot_service.genai.Client")
    @patch.object(GeminiPhotoshootProvider, "_call_gemini_frame")
    @patch("app.services.photoshoot_service.settings")
    def test_frame_zero_empty_image_uses_safe_prompt_on_attempt_two(
        self,
        mock_settings: MagicMock,
        mock_call_frame: MagicMock,
        mock_client_cls: MagicMock,
    ) -> None:
        _configure_gemini_settings(mock_settings, mode="identity_anchor")
        mock_call_frame.side_effect = [
            _empty_image_http_exception(),
            _TEST_DATA_URL,
            _TEST_DATA_URL_2,
            _TEST_DATA_URL_3,
        ]

        provider = GeminiPhotoshootProvider(output_count=3)
        result = provider.generate(
            self.style,
            _TEST_PHOTO_BYTES,
            _TEST_PHOTO_TYPE,
            client_style_id="evening_look",
            photoshoot_id="ps-frame-zero-safe-fallback",
        )

        self.assertEqual(len(result), 3)
        self.assertEqual(mock_call_frame.call_count, 4)
        self.assertIn(
            "Create one realistic professional portrait photo",
            mock_call_frame.call_args_list[1].kwargs["instruction"],
        )
        self.assertIn(
            "closed elegant blouse or blazer",
            mock_call_frame.call_args_list[1].kwargs["instruction"],
        )
        self.assertNotEqual(
            mock_call_frame.call_args_list[0].kwargs["instruction"],
            mock_call_frame.call_args_list[1].kwargs["instruction"],
        )
        self.assertEqual(
            mock_call_frame.call_args_list[0].kwargs["reference_images"],
            [_identity_reference()],
        )
        self.assertEqual(
            mock_call_frame.call_args_list[1].kwargs["reference_images"],
            [_identity_reference()],
        )

    @patch("app.services.photoshoot_service.create_generation_record")
    @patch("app.services.photoshoot_service.storage_service")
    @patch("app.services.photoshoot_service.genai.Client")
    @patch.object(GeminiPhotoshootProvider, "_call_gemini_frame")
    @patch("app.services.photoshoot_service.settings")
    def test_frame_zero_empty_image_on_all_attempts_aborts_without_persist(
        self,
        mock_settings: MagicMock,
        mock_call_frame: MagicMock,
        mock_client_cls: MagicMock,
        mock_storage: MagicMock,
        mock_create_record: MagicMock,
    ) -> None:
        _configure_gemini_settings(mock_settings, mode="identity_anchor")
        mock_call_frame.side_effect = _empty_image_http_exception()

        service = PhotoshootService()
        with self.assertRaises(HTTPException):
            service.generate_photoshoot(
                user_id="user-1",
                style=PHOTOSHOOT_STYLES["evening_look"],
                photo_bytes=_TEST_PHOTO_BYTES,
                photo_content_type=_TEST_PHOTO_TYPE,
                client_style_id="evening_look",
            )

        self.assertEqual(mock_call_frame.call_count, _MAX_GEMINI_FRAME_ATTEMPTS)
        self.assertIn(
            "Create one realistic professional portrait photo",
            mock_call_frame.call_args_list[1].kwargs["instruction"],
        )
        mock_create_record.assert_not_called()
        mock_storage.upload_generated_image_data_url_with_path.assert_not_called()

    @patch("app.services.photoshoot_service.genai.Client")
    @patch.object(GeminiPhotoshootProvider, "_call_gemini_frame")
    @patch("app.services.photoshoot_service.settings")
    def test_frame_zero_location_400_does_not_use_safe_fallback(
        self,
        mock_settings: MagicMock,
        mock_call_frame: MagicMock,
        mock_client_cls: MagicMock,
    ) -> None:
        _configure_gemini_settings(mock_settings, mode="identity_anchor")
        mock_call_frame.side_effect = _FakeGeminiClientError(
            400,
            "User location is not supported for the API use.",
        )

        provider = GeminiPhotoshootProvider(output_count=3)
        with self.assertRaises(HTTPException):
            provider.generate(
                PHOTOSHOOT_STYLES["evening_look"],
                _TEST_PHOTO_BYTES,
                _TEST_PHOTO_TYPE,
                client_style_id="evening_look",
                photoshoot_id="ps-frame-zero-location",
            )

        self.assertEqual(mock_call_frame.call_count, 1)

    @patch("app.services.photoshoot_service.genai.Client")
    @patch.object(GeminiPhotoshootProvider, "_call_gemini_frame")
    @patch("app.services.photoshoot_service.settings")
    def test_perceptual_near_duplicate_triggers_identity_only_fallback(
        self,
        mock_settings: MagicMock,
        mock_call_frame: MagicMock,
        mock_client_cls: MagicMock,
    ) -> None:
        _configure_gemini_settings(mock_settings, mode="identity_anchor")
        mock_call_frame.side_effect = [
            _TEST_DATA_URL,
            _TEST_DATA_URL_2,
            _TEST_DATA_URL_3,
            _TEST_DATA_URL_4,
        ]
        near_duplicate = DuplicateFrameMatch(
            kind="perceptual",
            duplicate_frame_index=0,
            perceptual_distance=2,
        )

        with patch(
            "app.services.photoshoot_service._find_generated_frame_duplicate",
            side_effect=[near_duplicate, None, None],
        ):
            provider = GeminiPhotoshootProvider(output_count=3)
            result = provider.generate(
                self.style,
                _TEST_PHOTO_BYTES,
                _TEST_PHOTO_TYPE,
                client_style_id="studio_portrait",
                photoshoot_id="ps-near-dup",
            )

        self.assertEqual(len(result), 3)
        self.assertEqual(result[1], _TEST_DATA_URL_3)
        self.assertEqual(
            mock_call_frame.call_args_list[2].kwargs["reference_images"],
            [_identity_reference()],
        )

    @patch("app.services.photoshoot_service.create_generation_record")
    @patch("app.services.photoshoot_service.storage_service")
    @patch("app.services.photoshoot_service.genai.Client")
    @patch.object(GeminiPhotoshootProvider, "_call_gemini_frame")
    @patch("app.services.photoshoot_service.settings")
    def test_near_duplicate_persists_after_fallback_aborts_without_persist(
        self,
        mock_settings: MagicMock,
        mock_call_frame: MagicMock,
        mock_client_cls: MagicMock,
        mock_storage: MagicMock,
        mock_create_record: MagicMock,
    ) -> None:
        _configure_gemini_settings(mock_settings, mode="identity_anchor")

        def _parse_data_url(data_url: str) -> tuple[str, bytes]:
            content, content_type = _anchor_reference_from_data_url(data_url)
            return content_type, content

        mock_storage._parse_generated_image_data_url.side_effect = _parse_data_url
        mock_call_frame.side_effect = [
            _TEST_DATA_URL,
            _TEST_DATA_URL_2,
            _TEST_DATA_URL_2,
        ] + [_empty_image_http_exception()] * (3 * _MAX_GEMINI_FRAME_ATTEMPTS)
        near_duplicate = DuplicateFrameMatch(
            kind="perceptual",
            duplicate_frame_index=0,
            perceptual_distance=1,
        )

        with patch(
            "app.services.photoshoot_service._find_generated_frame_duplicate",
            side_effect=[near_duplicate, near_duplicate],
        ):
            service = PhotoshootService()
            with self.assertRaises(HTTPException):
                service.generate_photoshoot(
                    user_id="user-1",
                    style=self.style,
                    photo_bytes=_TEST_PHOTO_BYTES,
                    photo_content_type=_TEST_PHOTO_TYPE,
                    client_style_id="studio_portrait",
                )

        self.assertGreater(mock_call_frame.call_count, 3)
        batch_calls = [
            call
            for call in mock_call_frame.call_args_list
            if "Safe batch fallback" in call.kwargs.get("instruction", "")
        ]
        self.assertTrue(batch_calls)
        mock_create_record.assert_not_called()
        mock_storage.upload_generated_image_data_url_with_path.assert_not_called()

    @patch("app.services.photoshoot_service.genai.Client")
    @patch.object(GeminiPhotoshootProvider, "_call_gemini_frame")
    @patch("app.services.photoshoot_service.settings")
    def test_duplicate_frame_one_triggers_identity_only_fallback(
        self,
        mock_settings: MagicMock,
        mock_call_frame: MagicMock,
        mock_client_cls: MagicMock,
    ) -> None:
        _configure_gemini_settings(mock_settings, mode="identity_anchor")
        mock_call_frame.side_effect = [
            _TEST_DATA_URL,
            _TEST_DATA_URL,
            _TEST_DATA_URL_2,
            _TEST_DATA_URL_3,
        ]

        provider = GeminiPhotoshootProvider(output_count=3)
        result = provider.generate(
            self.style,
            _TEST_PHOTO_BYTES,
            _TEST_PHOTO_TYPE,
            client_style_id="studio_portrait",
            photoshoot_id="ps-duplicate-fallback",
        )

        self.assertEqual(result[0], _TEST_DATA_URL)
        self.assertEqual(result[1], _TEST_DATA_URL_2)
        self.assertEqual(mock_call_frame.call_count, 4)
        self.assertEqual(
            mock_call_frame.call_args_list[2].kwargs["reference_images"],
            [_identity_reference()],
        )

    @patch("app.services.photoshoot_service.create_generation_record")
    @patch("app.services.photoshoot_service.storage_service")
    @patch("app.services.photoshoot_service.genai.Client")
    @patch.object(GeminiPhotoshootProvider, "_call_gemini_frame")
    @patch("app.services.photoshoot_service.settings")
    def test_duplicate_persists_after_fallback_aborts_without_persist(
        self,
        mock_settings: MagicMock,
        mock_call_frame: MagicMock,
        mock_client_cls: MagicMock,
        mock_storage: MagicMock,
        mock_create_record: MagicMock,
    ) -> None:
        _configure_gemini_settings(mock_settings, mode="identity_anchor")

        def _parse_data_url(data_url: str) -> tuple[str, bytes]:
            content, content_type = _anchor_reference_from_data_url(data_url)
            return content_type, content

        mock_storage._parse_generated_image_data_url.side_effect = _parse_data_url
        mock_call_frame.side_effect = [
            _TEST_DATA_URL,
            _TEST_DATA_URL,
            _TEST_DATA_URL,
        ] + [_empty_image_http_exception()] * (3 * _MAX_GEMINI_FRAME_ATTEMPTS)

        service = PhotoshootService()
        with self.assertRaises(HTTPException) as ctx:
            service.generate_photoshoot(
                user_id="user-1",
                style=self.style,
                photo_bytes=_TEST_PHOTO_BYTES,
                photo_content_type=_TEST_PHOTO_TYPE,
                client_style_id="studio_portrait",
            )

        self.assertEqual(ctx.exception.status_code, 502)
        self.assertGreater(mock_call_frame.call_count, 3)
        mock_create_record.assert_not_called()
        mock_storage.upload_generated_image_data_url_with_path.assert_not_called()

    def test_identity_fallback_eligibility_classification(self) -> None:
        location_exc = _FakeGeminiClientError(
            400,
            "User location is not supported for the API use.",
        )
        multi_image_exc = _FakeGeminiClientError(
            400,
            "too many image parts in request",
        )
        empty_image_exc = _empty_image_http_exception()
        self.assertFalse(_is_multi_image_fallback_eligible(location_exc))
        self.assertTrue(_is_multi_image_fallback_eligible(multi_image_exc))
        self.assertTrue(_is_empty_image_response_error(empty_image_exc))
        self.assertTrue(_is_identity_fallback_eligible(empty_image_exc))
        self.assertFalse(_is_anchor_only_fallback_eligible(location_exc))
        self.assertTrue(_is_anchor_only_fallback_eligible(multi_image_exc))

    @patch("app.services.photoshoot_service.genai.Client")
    @patch.object(GeminiPhotoshootProvider, "_call_gemini_frame")
    @patch("app.services.photoshoot_service.settings")
    def test_duplicate_fallback_empty_switches_to_safe_continuation_and_succeeds(
        self,
        mock_settings: MagicMock,
        mock_call_frame: MagicMock,
        mock_client_cls: MagicMock,
    ) -> None:
        _configure_gemini_settings(mock_settings, mode="identity_anchor")
        mock_call_frame.side_effect = [
            _TEST_DATA_URL,
            _TEST_DATA_URL_2,
            _empty_image_http_exception(),
            _TEST_DATA_URL_3,
            _TEST_DATA_URL_4,
        ]
        near_duplicate = DuplicateFrameMatch(
            kind="perceptual",
            duplicate_frame_index=0,
            perceptual_distance=2,
        )

        with patch(
            "app.services.photoshoot_service._find_generated_frame_duplicate",
            side_effect=[near_duplicate, None, None, None],
        ):
            provider = GeminiPhotoshootProvider(output_count=3)
            result = provider.generate(
                self.style,
                _TEST_PHOTO_BYTES,
                _TEST_PHOTO_TYPE,
                client_style_id="evening_look",
                photoshoot_id="ps-safe-continuation",
            )

        self.assertEqual(len(result), 3)
        self.assertEqual(result[1], _TEST_DATA_URL_3)
        self.assertEqual(mock_call_frame.call_count, 5)
        safe_call = mock_call_frame.call_args_list[3]
        self.assertEqual(safe_call.kwargs["reference_images"], [_identity_reference()])
        self.assertIn("Safe continuation fallback", safe_call.kwargs["instruction"])
        self.assertIn("Avoid complex scene", safe_call.kwargs["instruction"])
        self.assertNotIn(
            "Fallback generation mode",
            safe_call.kwargs["instruction"],
        )

    @patch("app.services.photoshoot_service.create_generation_record")
    @patch("app.services.photoshoot_service.storage_service")
    @patch("app.services.photoshoot_service.genai.Client")
    @patch.object(GeminiPhotoshootProvider, "_call_gemini_frame")
    @patch("app.services.photoshoot_service.settings")
    def test_fallback_empty_all_attempts_after_safe_continuation_aborts_without_persist(
        self,
        mock_settings: MagicMock,
        mock_call_frame: MagicMock,
        mock_client_cls: MagicMock,
        mock_storage: MagicMock,
        mock_create_record: MagicMock,
    ) -> None:
        _configure_gemini_settings(mock_settings, mode="identity_anchor")

        def _parse_data_url(data_url: str) -> tuple[str, bytes]:
            content, content_type = _anchor_reference_from_data_url(data_url)
            return content_type, content

        mock_storage._parse_generated_image_data_url.side_effect = _parse_data_url
        mock_call_frame.side_effect = [
            _TEST_DATA_URL,
            _TEST_DATA_URL_2,
            _empty_image_http_exception(),
            _empty_image_http_exception(),
        ] + [_empty_image_http_exception()] * (3 * _MAX_GEMINI_FRAME_ATTEMPTS)
        near_duplicate = DuplicateFrameMatch(
            kind="perceptual",
            duplicate_frame_index=0,
            perceptual_distance=2,
        )

        with patch(
            "app.services.photoshoot_service._find_generated_frame_duplicate",
            side_effect=[near_duplicate, None],
        ):
            service = PhotoshootService()
            with self.assertRaises(HTTPException) as ctx:
                service.generate_photoshoot(
                    user_id="user-1",
                    style=PHOTOSHOOT_STYLES["evening_look"],
                    photo_bytes=_TEST_PHOTO_BYTES,
                    photo_content_type=_TEST_PHOTO_TYPE,
                    client_style_id="evening_look",
                )

        self.assertEqual(ctx.exception.status_code, 502)
        self.assertGreater(mock_call_frame.call_count, 4)
        self.assertIn(
            "Safe continuation fallback",
            mock_call_frame.call_args_list[3].kwargs["instruction"],
        )
        batch_calls = [
            call
            for call in mock_call_frame.call_args_list
            if "Safe batch fallback" in call.kwargs.get("instruction", "")
        ]
        self.assertTrue(batch_calls)
        mock_create_record.assert_not_called()
        mock_storage.upload_generated_image_data_url_with_path.assert_not_called()

    @patch("app.services.photoshoot_service.genai.Client")
    @patch.object(GeminiPhotoshootProvider, "_call_gemini_frame")
    @patch("app.services.photoshoot_service.settings")
    def test_location_400_in_identity_only_fallback_does_not_use_safe_continuation(
        self,
        mock_settings: MagicMock,
        mock_call_frame: MagicMock,
        mock_client_cls: MagicMock,
    ) -> None:
        _configure_gemini_settings(mock_settings, mode="identity_anchor")
        mock_call_frame.side_effect = [
            _TEST_DATA_URL,
            _TEST_DATA_URL_2,
            _FakeGeminiClientError(
                400,
                "User location is not supported for the API use.",
            ),
        ]
        near_duplicate = DuplicateFrameMatch(
            kind="perceptual",
            duplicate_frame_index=0,
            perceptual_distance=2,
        )

        with patch(
            "app.services.photoshoot_service._find_generated_frame_duplicate",
            side_effect=[near_duplicate],
        ):
            provider = GeminiPhotoshootProvider(output_count=3)
            with self.assertRaises(HTTPException):
                provider.generate(
                    self.style,
                    _TEST_PHOTO_BYTES,
                    _TEST_PHOTO_TYPE,
                    client_style_id="evening_look",
                    photoshoot_id="ps-fallback-location",
                )

        self.assertEqual(mock_call_frame.call_count, 3)
        self.assertNotIn(
            "Safe continuation fallback",
            mock_call_frame.call_args_list[-1].kwargs["instruction"],
        )

    @patch("app.services.photoshoot_service.genai.Client")
    @patch.object(GeminiPhotoshootProvider, "_call_gemini_frame")
    @patch("app.services.photoshoot_service.settings")
    def test_frame_two_empty_triggers_safe_a_only_batch_fallback_and_succeeds(
        self,
        mock_settings: MagicMock,
        mock_call_frame: MagicMock,
        mock_client_cls: MagicMock,
    ) -> None:
        _configure_gemini_settings(mock_settings, mode="identity_anchor")
        mock_call_frame.side_effect = [
            _TEST_DATA_URL,
            _TEST_DATA_URL_2,
            _empty_image_http_exception(),
            _empty_image_http_exception(),
            _empty_image_http_exception(),
            _TEST_DATA_URL_3,
            _TEST_DATA_URL_4,
            _TEST_DATA_URL_4,
        ]

        provider = GeminiPhotoshootProvider(output_count=3)
        result = provider.generate(
            self.style,
            _TEST_PHOTO_BYTES,
            _TEST_PHOTO_TYPE,
            client_style_id="business_brand",
            photoshoot_id="ps-safe-batch-success",
        )

        self.assertEqual(len(result), 3)
        self.assertEqual(result[0], _TEST_DATA_URL_3)
        batch_calls = [
            call
            for call in mock_call_frame.call_args_list
            if "Safe batch fallback" in call.kwargs.get("instruction", "")
        ]
        self.assertEqual(len(batch_calls), 3)
        for call in batch_calls:
            self.assertEqual(call.kwargs["reference_images"], [_identity_reference()])

    @patch("app.services.photoshoot_service.create_generation_record")
    @patch("app.services.photoshoot_service.storage_service")
    @patch("app.services.photoshoot_service.genai.Client")
    @patch.object(GeminiPhotoshootProvider, "_call_gemini_frame")
    @patch("app.services.photoshoot_service.settings")
    def test_safe_batch_success_persists_after_primary_failure(
        self,
        mock_settings: MagicMock,
        mock_call_frame: MagicMock,
        mock_client_cls: MagicMock,
        mock_storage: MagicMock,
        mock_create_record: MagicMock,
    ) -> None:
        _configure_gemini_settings(mock_settings, mode="identity_anchor")

        def _parse_data_url(data_url: str) -> tuple[str, bytes]:
            content, content_type = _anchor_reference_from_data_url(data_url)
            return content_type, content

        mock_storage._parse_generated_image_data_url.side_effect = _parse_data_url
        mock_storage.upload_generated_image_data_url_with_path.side_effect = [
            ("photoshoots/user-1/frame-0.png", "https://cdn.example/0.png"),
            ("photoshoots/user-1/frame-1.png", "https://cdn.example/1.png"),
            ("photoshoots/user-1/frame-2.png", "https://cdn.example/2.png"),
        ]
        mock_call_frame.side_effect = [
            _TEST_DATA_URL,
            _TEST_DATA_URL_2,
            _empty_image_http_exception(),
            _empty_image_http_exception(),
            _empty_image_http_exception(),
            _TEST_DATA_URL_3,
            _TEST_DATA_URL_4,
            _TEST_DATA_URL_4,
        ]

        service = PhotoshootService()
        with patch.object(
            PhotoshootService,
            "_get_provider",
            return_value=GeminiPhotoshootProvider(output_count=3),
        ):
            result = service.generate_photoshoot(
                user_id="user-1",
                style=self.style,
                photo_bytes=_TEST_PHOTO_BYTES,
                photo_content_type=_TEST_PHOTO_TYPE,
                client_style_id="business_brand",
            )

        self.assertEqual(len(result.image_urls), 3)
        mock_create_record.assert_called()
        self.assertEqual(mock_storage.upload_generated_image_data_url_with_path.call_count, 3)


if __name__ == "__main__":
    unittest.main()
