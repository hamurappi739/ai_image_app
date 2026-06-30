"""Kie photoshoot independent frames and fail-retry tests."""

from __future__ import annotations

import io
import unittest
from unittest.mock import MagicMock, patch

from fastapi import HTTPException
from fastapi.testclient import TestClient

from app.config import settings
from app.main import app
from app.services.kie_image_service import KieImageGenerationError
from app.services.kie_photoshoot_provider import KiePhotoshootProvider
from app.services.photoshoot_similarity import (
    KIE_FRAME_FAIL_RETRY_PROMPT_SUFFIX,
    KIE_FRAME_FAIL_RETRY_PROMPT_SUFFIX_FRAME0,
    kie_frame_fail_retry_prompt_suffix,
)
from app.services.photoshoot_service import PhotoshootGenerateResult, PhotoshootService
from app.services.photoshoot_styles import get_photoshoot_style
from app.services.storage_service import storage_service

_TEST_PHOTO_BYTES = b"fake-photo"
_TEST_PHOTO_TYPE = "image/jpeg"
_TEST_JPEG_BYTES = b"\xff\xd8\xff\xe0" + b"\x00" * 16
_SIGNED_URL_A = "https://supabase.example.com/signed/a"
_RESULT_IMAGE_BYTES = b"\x89PNG\r\n\x1a\n" + b"\x00" * 32
KIE_IMAGE_PROVIDER = "kie_gpt_image_2"
_PHOTOSHOOT_FAILURE_MESSAGE = "Photoshoot generation failed, please retry"
_SUCCESS_RESULT = PhotoshootGenerateResult(
    image_urls=["https://cdn/1.png", "https://cdn/2.png", "https://cdn/3.png"],
    photoshoot_id="ps-success",
    storage_paths=["p1", "p2", "p3"],
)
_TEST_USER_ID = "ce38d11c-2319-4eac-adfe-46ac6d176e47"


def _distinct_result_bytes(call_index: int) -> bytes:
    return _RESULT_IMAGE_BYTES + bytes([call_index % 256])


def _kie_pipeline_patches(testcase: unittest.TestCase):
    return (
        patch("app.services.photoshoot_service.resolve_photoshoot_image_provider"),
        patch("app.services.kie_photoshoot_provider.KieImageTaskClient"),
        patch.object(storage_service, "upload_temp_input_bytes"),
        patch.object(storage_service, "upload_temp_input_data_url"),
        patch.object(storage_service, "create_signed_url"),
        patch.object(storage_service, "delete_temp_objects_best_effort"),
        patch("app.services.photoshoot_service._upload_photoshoot_frames_to_storage"),
        patch("app.services.photoshoot_service._save_photoshoot_results_to_history"),
    )


def _apply_kie_pipeline_settings() -> dict[str, object]:
    saved = {
        "photoshoot_series_reference_mode": settings.photoshoot_series_reference_mode,
        "kie_temp_signed_url_ttl_seconds": settings.kie_temp_signed_url_ttl_seconds,
        "supabase_temp_storage_bucket": settings.supabase_temp_storage_bucket,
        "kie_image_model": settings.kie_image_model,
        "kie_max_photoshoot_tasks": settings.kie_max_photoshoot_tasks,
    }
    settings.photoshoot_series_reference_mode = "identity_anchor"
    settings.kie_temp_signed_url_ttl_seconds = 3600
    settings.supabase_temp_storage_bucket = "temp-bucket"
    settings.kie_image_model = "test-model"
    settings.kie_max_photoshoot_tasks = 5
    return saved


def _restore_kie_pipeline_settings(saved: dict[str, object]) -> None:
    for key, value in saved.items():
        setattr(settings, key, value)


def _configure_kie_pipeline_mocks(
    mock_resolve_provider: MagicMock,
    mock_upload_bytes: MagicMock,
    mock_signed_url: MagicMock,
    mock_upload_frames: MagicMock,
    mock_save_history: MagicMock,
) -> None:
    mock_resolve_provider.return_value = KIE_IMAGE_PROVIDER
    mock_upload_bytes.return_value = ("temp/a", _SIGNED_URL_A)
    mock_signed_url.return_value = _SIGNED_URL_A
    mock_upload_frames.return_value = (
        ["https://public/1", "https://public/2", "https://public/3"],
        ["p1", "p2", "p3"],
    )
    mock_save_history.return_value = "ps-done"


def _run_three_frame_photoshoot(
    generate_side_effect,
) -> tuple[
    int,
    list[int],
    PhotoshootGenerateResult | None,
    HTTPException | None,
    MagicMock,
    MagicMock,
]:
    reference_counts: list[int] = []
    saved_settings = _apply_kie_pipeline_settings()
    patchers = _kie_pipeline_patches(unittest.TestCase())
    mocks = [patcher.start() for patcher in patchers]
    try:
        (
            mock_resolve_provider,
            mock_kie_client_cls,
            mock_upload_bytes,
            mock_upload_data_url,
            mock_signed_url,
            mock_delete_temp,
            mock_upload_frames,
            mock_save_history,
        ) = mocks

        _configure_kie_pipeline_mocks(
            mock_resolve_provider,
            mock_upload_bytes,
            mock_signed_url,
            mock_upload_frames,
            mock_save_history,
        )

        kie_client = MagicMock()
        kie_client.http_calls_count = 0
        kie_client.created_tasks_count = 0

        def _track_refs(instruction, input_urls, **kwargs):
            reference_counts.append(len(input_urls))
            return generate_side_effect(instruction, input_urls, **kwargs)

        kie_client.generate_image_bytes.side_effect = _track_refs
        mock_kie_client_cls.return_value = kie_client

        service = PhotoshootService()
        try:
            result = service.generate_photoshoot(
                user_id="user-1",
                style=get_photoshoot_style("studio_portrait"),
                photo_bytes=_TEST_PHOTO_BYTES,
                photo_content_type=_TEST_PHOTO_TYPE,
                client_style_id="studio_portrait",
            )
            return (
                kie_client.generate_image_bytes.call_count,
                reference_counts,
                result,
                None,
                mock_upload_data_url,
                mock_upload_bytes,
            )
        except HTTPException as exc:
            return (
                kie_client.generate_image_bytes.call_count,
                reference_counts,
                None,
                exc,
                mock_upload_data_url,
                mock_upload_bytes,
            )
    finally:
        for patcher in reversed(patchers):
            patcher.stop()
        _restore_kie_pipeline_settings(saved_settings)


class KieIndependentFramesUnitTests(unittest.TestCase):
    def test_frame_zero_retry_suffix_is_opening_photo_prompt(self) -> None:
        self.assertEqual(
            kie_frame_fail_retry_prompt_suffix(0),
            KIE_FRAME_FAIL_RETRY_PROMPT_SUFFIX_FRAME0,
        )
        self.assertEqual(
            kie_frame_fail_retry_prompt_suffix(1),
            KIE_FRAME_FAIL_RETRY_PROMPT_SUFFIX,
        )

    def test_fail_retry_logs_and_uses_frame_zero_suffix(self) -> None:
        provider = KiePhotoshootProvider(output_count=1)
        prompts: list[str] = []

        def capture_generate(*, extra_prompt_suffix: str = "", **kwargs):
            prompts.append(extra_prompt_suffix)
            if len(prompts) == 1:
                raise KieImageGenerationError("kie_task_failed")
            return "data:image/png;base64,NEW"

        with patch.object(provider, "_generate_unique_frame_data_url", side_effect=capture_generate):
            with self.assertLogs("uvicorn.error", level="WARNING") as logs:
                result = provider._generate_frame_with_fail_retry(
                    frame_index=0,
                    style=get_photoshoot_style("studio_portrait"),
                    client_style_id="personal_brand",
                    photoshoot_id="ps-frame0-retry",
                    user_description=None,
                    series_mode="identity_anchor",
                    identity_path="temp/a",
                    existing_data_urls=[],
                    ttl_seconds=3600,
                    kie_client=MagicMock(),
                    task_cap=5,
                    on_frame_status=None,
                )

        self.assertEqual(result, "data:image/png;base64,NEW")
        self.assertIn(KIE_FRAME_FAIL_RETRY_PROMPT_SUFFIX_FRAME0, prompts[1])
        self.assertTrue(
            any("Kie frame failed, retrying" in message for message in logs.output),
            logs.output,
        )

    def test_fail_twice_aborts_with_502(self) -> None:
        provider = KiePhotoshootProvider(output_count=1)

        with patch.object(
            provider,
            "_generate_unique_frame_data_url",
            side_effect=KieImageGenerationError("kie_task_failed"),
        ):
            with self.assertRaises(HTTPException) as ctx:
                provider._generate_frame_with_fail_retry(
                    frame_index=0,
                    style=get_photoshoot_style("studio_portrait"),
                    client_style_id="personal_brand",
                    photoshoot_id="ps-fail-twice",
                    user_description=None,
                    series_mode="identity_anchor",
                    identity_path="temp/a",
                    existing_data_urls=[],
                    ttl_seconds=3600,
                    kie_client=MagicMock(),
                    task_cap=5,
                    on_frame_status=None,
                )

        self.assertEqual(ctx.exception.status_code, 502)
        self.assertEqual(ctx.exception.detail, _PHOTOSHOOT_FAILURE_MESSAGE)


class KieIndependentFramesPipelineTests(unittest.TestCase):
    def test_all_frames_use_identity_reference_only(self) -> None:
        call_count = 0

        def generate_side_effect(_instruction, input_urls, **_kwargs):
            nonlocal call_count
            call_count += 1
            self.assertEqual(len(input_urls), 1)
            return (_distinct_result_bytes(call_count), "image/png")

        count, refs, result, exc, mock_upload_data_url, mock_upload_bytes = (
            _run_three_frame_photoshoot(generate_side_effect)
        )
        self.assertIsNone(exc)
        assert result is not None
        self.assertEqual(len(result.image_urls), 3)
        self.assertEqual(count, 3)
        self.assertEqual(refs, [1, 1, 1])
        mock_upload_bytes.assert_called_once()
        mock_upload_data_url.assert_not_called()

    def test_frame_zero_fail_once_then_success_completes_photoshoot(self) -> None:
        call_count = 0

        def generate_side_effect(*args, **kwargs):
            nonlocal call_count
            call_count += 1
            if call_count == 1:
                raise KieImageGenerationError("kie_task_failed")
            return (_distinct_result_bytes(call_count), "image/png")

        count, refs, result, exc, *_rest = _run_three_frame_photoshoot(generate_side_effect)
        self.assertIsNone(exc)
        assert result is not None
        self.assertEqual(len(result.image_urls), 3)
        self.assertEqual(count, 4)
        self.assertTrue(all(ref == 1 for ref in refs))

    def test_frame_one_fail_once_then_success(self) -> None:
        call_count = 0

        def generate_side_effect(*args, **kwargs):
            nonlocal call_count
            call_count += 1
            if call_count == 2:
                raise KieImageGenerationError("kie_task_failed")
            return (_distinct_result_bytes(call_count), "image/png")

        count, refs, result, exc, *_rest = _run_three_frame_photoshoot(generate_side_effect)
        self.assertIsNone(exc)
        assert result is not None
        self.assertEqual(len(result.image_urls), 3)
        self.assertEqual(count, 4)
        self.assertEqual(refs, [1, 1, 1, 1])

    def test_frame_two_fail_twice_aborts_without_persist(self) -> None:
        call_count = 0

        def generate_side_effect(*args, **kwargs):
            nonlocal call_count
            call_count += 1
            if call_count in {3, 4}:
                raise KieImageGenerationError("kie_task_failed")
            return (_distinct_result_bytes(call_count), "image/png")

        count, refs, result, exc, *_rest = _run_three_frame_photoshoot(generate_side_effect)
        self.assertIsNone(result)
        assert exc is not None
        self.assertEqual(exc.status_code, 502)
        self.assertEqual(count, 4)
        self.assertEqual(refs, [1, 1, 1, 1])


class KieIndependentFramesDebitTests(unittest.TestCase):
    def setUp(self) -> None:
        self.client = TestClient(app)

    @patch("app.services.supabase_service.update_profile")
    @patch("app.main.photoshoot_service.generate_photoshoot")
    @patch("app.main.ensure_profile_exists")
    @patch("app.main.settings")
    def test_frame_zero_fail_retry_success_debits_once(
        self,
        mock_settings: MagicMock,
        mock_ensure_profile: MagicMock,
        mock_generate: MagicMock,
        mock_update: MagicMock,
    ) -> None:
        from app.services.balance_service import PHOTOSHOOT_IMAGE_COST

        mock_settings.enable_photoshoot_generation = True
        mock_settings.enable_credit_consumption = True
        mock_settings.free_generations_limit = 3
        profile = {
            "id": _TEST_USER_ID,
            "free_generations_used": 3,
            "paid_image_generations": PHOTOSHOOT_IMAGE_COST,
        }

        def _apply_update(_user_id: str, updates: dict) -> dict:
            updated = dict(profile)
            updated.update(updates)
            return updated

        mock_ensure_profile.return_value = profile
        mock_update.side_effect = _apply_update
        mock_generate.return_value = _SUCCESS_RESULT

        with patch.object(settings, "enable_credit_consumption", True):
            with patch.object(settings, "test_user_id", _TEST_USER_ID):
                response = self.client.post(
                    "/photoshoots/generate",
                    data={"style_id": "studio_portrait"},
                    files={
                        "photo": (
                            "photo.jpg",
                            io.BytesIO(_TEST_JPEG_BYTES),
                            "image/jpeg",
                        ),
                    },
                )

        self.assertEqual(response.status_code, 200)
        mock_generate.assert_called_once()
        mock_update.assert_called_once_with(
            _TEST_USER_ID,
            {"paid_image_generations": 0},
        )

    @patch("app.main.consume_photoshoot")
    @patch("app.main.photoshoot_service.generate_photoshoot")
    @patch("app.main.ensure_profile_exists")
    @patch("app.main.settings")
    def test_final_fail_no_debit(
        self,
        mock_settings: MagicMock,
        mock_ensure_profile: MagicMock,
        mock_generate: MagicMock,
        mock_consume: MagicMock,
    ) -> None:
        mock_settings.enable_photoshoot_generation = True
        mock_settings.enable_credit_consumption = True
        mock_settings.free_generations_limit = 3
        mock_ensure_profile.return_value = {
            "paid_image_generations": 3,
            "free_generations_used": 3,
        }
        mock_generate.side_effect = HTTPException(
            status_code=502,
            detail=_PHOTOSHOOT_FAILURE_MESSAGE,
        )

        with patch.object(settings, "enable_credit_consumption", True):
            with patch.object(settings, "test_user_id", _TEST_USER_ID):
                response = self.client.post(
                    "/photoshoots/generate",
                    data={"style_id": "studio_portrait"},
                    files={
                        "photo": (
                            "photo.jpg",
                            io.BytesIO(_TEST_JPEG_BYTES),
                            "image/jpeg",
                        ),
                    },
                )

        self.assertEqual(response.status_code, 502)
        mock_consume.assert_not_called()


if __name__ == "__main__":
    unittest.main()
