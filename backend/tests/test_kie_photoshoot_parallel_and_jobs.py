"""Tests for parallel Kie photoshoot, job progress, and createTask rate limiting."""

from __future__ import annotations

import io
import threading
import time
import unittest
from unittest.mock import MagicMock, patch

from fastapi import HTTPException
from fastapi.testclient import TestClient

from app.auth import CurrentUser, get_current_user
from app.main import app
from app.services.image_provider_resolver import KIE_IMAGE_PROVIDER
from app.services.kie_photoshoot_provider import KiePhotoshootProvider
from app.services.kie_rate_limiter import (
    acquire_kie_create_task_slot,
    reset_kie_create_task_rate_limiter_for_tests,
)
from app.services.photoshoot_job_service import (
    _run_photoshoot_job,
    get_photoshoot_job_status,
)
from app.services.photoshoot_job_store import (
    InMemoryPhotoshootJobStore,
    PhotoshootJobStartPayload,
    photoshoot_job_store,
)
from app.services.photoshoot_service import (
    PhotoshootGenerateResult,
    PhotoshootService,
    _PHOTOSHOOT_FAILURE_MESSAGE,
)
from app.services.photoshoot_styles import get_photoshoot_style
from app.services.storage_service import storage_service

_TEST_PHOTO_BYTES = b"fake-photo"
_TEST_PHOTO_TYPE = "image/jpeg"
_RESULT_IMAGE_BYTES = b"\x89PNG\r\n\x1a\n" + b"\x00" * 32
_SIGNED_URL_A = "https://supabase.example.com/signed/a"
_SIGNED_URL_B = "https://supabase.example.com/signed/b"


class KieParallelPipelineTests(unittest.TestCase):
    def test_frame_zero_runs_before_parallel_batch(self) -> None:
        provider = KiePhotoshootProvider(output_count=3)
        call_log: list[int] = []
        lock = threading.Lock()

        original = provider._generate_frame_data_url

        def tracking_generate(*, frame_index: int, **kwargs):
            with lock:
                call_log.append(frame_index)
            time.sleep(0.05 if frame_index > 0 else 0.0)
            return f"data:image/png;base64,FRAME{frame_index}"

        with patch.object(provider, "_generate_frame_data_url", side_effect=tracking_generate):
            with patch.object(storage_service, "upload_temp_input_bytes", return_value=("temp/a", _SIGNED_URL_A)):
                with patch.object(storage_service, "upload_temp_input_data_url", return_value=("temp/b", _SIGNED_URL_B)):
                    with patch.object(storage_service, "create_signed_url", return_value=_SIGNED_URL_A):
                        with patch.object(storage_service, "delete_temp_objects_best_effort"):
                            with patch("app.services.kie_photoshoot_provider.settings") as mock_settings:
                                mock_settings.photoshoot_series_reference_mode = "identity_anchor"
                                mock_settings.kie_max_photoshoot_tasks = 5
                                mock_settings.kie_temp_signed_url_ttl_seconds = 3600
                                mock_settings.supabase_temp_storage_bucket = "ai-temp-inputs"
                                mock_settings.kie_image_model = "gpt-image-2-image-to-image"
                                result = provider.generate(
                                    get_photoshoot_style("studio_portrait"),
                                    _TEST_PHOTO_BYTES,
                                    _TEST_PHOTO_TYPE,
                                    client_style_id="studio_portrait",
                                    photoshoot_id="ps-parallel",
                                    user_id="user-1",
                                )

        self.assertEqual(len(result), 3)
        self.assertEqual(call_log[0], 0)
        self.assertEqual(set(call_log[1:]), {1, 2})

    @patch("app.services.kie_photoshoot_provider.as_completed")
    @patch("app.services.kie_photoshoot_provider.ThreadPoolExecutor")
    def test_frames_one_and_two_use_thread_pool(
        self,
        mock_executor_cls: MagicMock,
        mock_as_completed: MagicMock,
    ) -> None:
        provider = KiePhotoshootProvider(output_count=3)
        mock_executor = MagicMock()
        mock_executor_cls.return_value.__enter__.return_value = mock_executor

        submitted_indices: list[int] = []

        def submit_stub(fn, **kwargs):
            future = MagicMock()
            future.result.return_value = f"data:image/png;base64,FRAME{kwargs['frame_index']}"
            submitted_indices.append(kwargs["frame_index"])
            return future

        mock_executor.submit.side_effect = submit_stub
        mock_as_completed.side_effect = lambda futures: list(futures.keys())

        with patch.object(
            provider,
            "_generate_frame_data_url",
            return_value="data:image/png;base64,FRAME0",
        ) as mock_generate:
            with patch.object(storage_service, "upload_temp_input_bytes", return_value=("temp/a", _SIGNED_URL_A)):
                with patch.object(storage_service, "upload_temp_input_data_url", return_value=("temp/b", _SIGNED_URL_B)):
                    with patch.object(storage_service, "create_signed_url", return_value=_SIGNED_URL_A):
                        with patch.object(storage_service, "delete_temp_objects_best_effort"):
                            with patch("app.services.kie_photoshoot_provider.settings") as mock_settings:
                                mock_settings.photoshoot_series_reference_mode = "identity_anchor"
                                mock_settings.kie_max_photoshoot_tasks = 5
                                mock_settings.kie_temp_signed_url_ttl_seconds = 3600
                                mock_settings.supabase_temp_storage_bucket = "ai-temp-inputs"
                                mock_settings.kie_image_model = "gpt-image-2-image-to-image"
                                provider.generate(
                                    get_photoshoot_style("studio_portrait"),
                                    _TEST_PHOTO_BYTES,
                                    _TEST_PHOTO_TYPE,
                                    client_style_id="studio_portrait",
                                    photoshoot_id="ps-threadpool",
                                    user_id="user-1",
                                )

        mock_executor_cls.assert_called_once_with(max_workers=2)
        self.assertEqual(mock_executor.submit.call_count, 2)
        self.assertEqual(set(submitted_indices), {1, 2})
        self.assertEqual(mock_generate.call_count, 1)
        self.assertEqual(mock_generate.call_args.kwargs["frame_index"], 0)


class KieRateLimiterTests(unittest.TestCase):
    def tearDown(self) -> None:
        reset_kie_create_task_rate_limiter_for_tests()

    @patch("app.services.kie_rate_limiter.settings")
    def test_rate_limiter_waits_instead_of_exceeding_limit(
        self,
        mock_settings: MagicMock,
    ) -> None:
        mock_settings.kie_create_task_rate_limit = 2
        mock_settings.kie_create_task_rate_window_seconds = 10.0
        reset_kie_create_task_rate_limiter_for_tests()

        clock = [0.0]

        def fake_monotonic() -> float:
            return clock[0]

        def fake_sleep(seconds: float) -> None:
            clock[0] += seconds

        with patch("app.services.kie_rate_limiter.time.monotonic", side_effect=fake_monotonic):
            with patch("app.services.kie_rate_limiter.time.sleep", side_effect=fake_sleep) as mock_sleep:
                acquire_kie_create_task_slot()
                acquire_kie_create_task_slot()
                acquire_kie_create_task_slot()

        mock_sleep.assert_called()
        self.assertGreaterEqual(mock_sleep.call_count, 1)


class PhotoshootJobProgressTests(unittest.TestCase):
    def test_job_store_updates_frame_statuses(self) -> None:
        store = InMemoryPhotoshootJobStore()
        job = store.create_job(
            user_id="user-1",
            style_id="studio_portrait",
            style_title="Studio",
            output_count=3,
        )

        job.status = "running"
        job.frames[0].status = "generating"
        store.save_job(job)

        saved = store.get_job(job.job_id)
        assert saved is not None
        self.assertEqual(saved.frames[0].status, "generating")
        self.assertEqual(saved.frames[1].status, "queued")

        saved.frames[0].status = "done"
        saved.frames[1].status = "generating"
        saved.frames[2].status = "generating"
        store.save_job(saved)

        updated = store.get_job(job.job_id)
        assert updated is not None
        self.assertEqual(updated.frames[0].status, "done")
        self.assertEqual(updated.frames[1].status, "generating")
        self.assertEqual(updated.frames[2].status, "generating")

    @patch("app.services.photoshoot_job_service._photoshoot_service")
    @patch("app.services.photoshoot_job_service.settings")
    def test_job_runner_updates_frame_statuses_from_callback(
        self,
        mock_settings: MagicMock,
        mock_service: MagicMock,
    ) -> None:
        mock_settings.enable_photoshoot_generation = True
        mock_settings.enable_credit_consumption = False

        job = photoshoot_job_store.create_job(
            user_id="user-job",
            style_id="studio_portrait",
            style_title="Studio",
            output_count=3,
        )
        photoshoot_job_store.put_start_payload(
            job.job_id,
            PhotoshootJobStartPayload(
                user_id="user-job",
                user_email="user@example.com",
                style_id="studio_portrait",
                style_title="Studio",
                photo_bytes=_TEST_PHOTO_BYTES,
                photo_content_type=_TEST_PHOTO_TYPE,
                user_description=None,
                output_count=3,
            ),
        )

        def fake_generate(**kwargs):
            on_frame_status = kwargs["on_frame_status"]
            on_frame_status(0, "generating")
            on_frame_status(0, "done")
            on_frame_status(1, "generating")
            on_frame_status(2, "generating")
            return PhotoshootGenerateResult(
                image_urls=["https://cdn/1.png", "https://cdn/2.png", "https://cdn/3.png"],
                photoshoot_id="ps-job",
                storage_paths=["p1", "p2", "p3"],
            )

        mock_service.generate_photoshoot.side_effect = fake_generate

        _run_photoshoot_job(job.job_id)

        payload = get_photoshoot_job_status(job.job_id, user_id="user-job")
        self.assertEqual(payload["status"], "success")
        self.assertEqual(payload["frames"][0]["status"], "done")
        self.assertEqual(payload["frames"][1]["status"], "generating")
        self.assertEqual(payload["frames"][2]["status"], "generating")


class PhotoshootJobEndpointTests(unittest.TestCase):
    def setUp(self) -> None:
        def _override_user() -> CurrentUser:
            return CurrentUser(id="endpoint-test-user", email="u@example.com")

        app.dependency_overrides[get_current_user] = _override_user
        self.client = TestClient(app)

    def tearDown(self) -> None:
        app.dependency_overrides.clear()

    @patch("app.main.start_photoshoot_job", return_value="job-123")
    @patch("app.main.settings")
    def test_start_endpoint_returns_job_id(
        self,
        mock_settings: MagicMock,
        mock_start: MagicMock,
    ) -> None:
        mock_settings.enable_photoshoot_generation = True
        mock_settings.enable_credit_consumption = False
        mock_settings.photoshoot_output_count = 3

        response = self.client.post(
            "/photoshoots/generate/start",
            data={"style_id": "studio_portrait"},
            files={
                "photo": ("photo.jpg", io.BytesIO(b"\xff\xd8\xff\xe0" + b"\x00" * 16), "image/jpeg"),
            },
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["job_id"], "job-123")
        mock_start.assert_called_once()

    @patch("app.main.get_photoshoot_job_status")
    def test_status_endpoint_returns_frame_progress(
        self,
        mock_status: MagicMock,
    ) -> None:
        mock_status.return_value = {
            "status": "running",
            "message": "Photoshoot generation in progress",
            "frames": [
                {"index": 0, "status": "done"},
                {"index": 1, "status": "generating"},
                {"index": 2, "status": "queued"},
            ],
            "images": [],
        }

        response = self.client.get("/photoshoots/generate/status/job-123")

        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertEqual(body["status"], "running")
        self.assertEqual(len(body["frames"]), 3)
        self.assertEqual(body["frames"][1]["status"], "generating")


class LegacyPhotoshootEndpointTests(unittest.TestCase):
    def setUp(self) -> None:
        def _override_user() -> CurrentUser:
            return CurrentUser(id="endpoint-test-user", email="u@example.com")

        app.dependency_overrides[get_current_user] = _override_user
        self.client = TestClient(app)

    def tearDown(self) -> None:
        app.dependency_overrides.clear()

    @patch("app.main.photoshoot_service.generate_photoshoot")
    @patch("app.main.settings")
    def test_legacy_generate_endpoint_still_works(
        self,
        mock_settings: MagicMock,
        mock_generate: MagicMock,
    ) -> None:
        mock_settings.enable_photoshoot_generation = True
        mock_settings.enable_credit_consumption = False
        mock_generate.return_value = PhotoshootGenerateResult(
            image_urls=["https://cdn/1.png", "https://cdn/2.png", "https://cdn/3.png"],
            photoshoot_id="ps-legacy",
            storage_paths=["p1", "p2", "p3"],
        )

        response = self.client.post(
            "/photoshoots/generate",
            data={"style_id": "studio_portrait"},
            files={
                "photo": ("photo.jpg", io.BytesIO(b"\xff\xd8\xff\xe0" + b"\x00" * 16), "image/jpeg"),
            },
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["status"], "success")
        self.assertEqual(len(response.json()["images"]), 3)
        mock_generate.assert_called_once()


class KieParallelFailureAtomicityTests(unittest.TestCase):
    @patch("app.services.photoshoot_service.resolve_photoshoot_image_provider")
    @patch("app.services.kie_photoshoot_provider.KieImageTaskClient")
    @patch.object(storage_service, "upload_temp_input_bytes")
    @patch.object(storage_service, "upload_temp_input_data_url")
    @patch.object(storage_service, "create_signed_url")
    @patch.object(storage_service, "delete_temp_objects_best_effort")
    @patch("app.services.photoshoot_service._upload_photoshoot_frames_to_storage")
    @patch("app.services.photoshoot_service._save_photoshoot_results_to_history")
    def test_parallel_frame_two_failure_skips_persist(
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
        from app.services.kie_image_service import KieImageGenerationError

        mock_resolve_provider.return_value = KIE_IMAGE_PROVIDER
        mock_upload_bytes.return_value = ("temp/a", _SIGNED_URL_A)
        mock_upload_data_url.return_value = ("temp/b", _SIGNED_URL_B)
        mock_signed_url.side_effect = (
            lambda *args, **kwargs: _SIGNED_URL_B
            if args and args[0] == "temp/b"
            else _SIGNED_URL_A
        )

        call_count = 0

        def generate_side_effect(*args, **kwargs):
            nonlocal call_count
            call_count += 1
            if call_count >= 3:
                raise KieImageGenerationError("kie_task_failed")
            return (_RESULT_IMAGE_BYTES, "image/png")

        kie_client = MagicMock()
        kie_client.http_calls_count = 0
        kie_client.created_tasks_count = 0
        kie_client.generate_image_bytes.side_effect = generate_side_effect
        mock_kie_client_cls.return_value = kie_client

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
        self.assertEqual(ctx.exception.detail, _PHOTOSHOOT_FAILURE_MESSAGE)
        mock_upload_frames.assert_not_called()
        mock_save_history.assert_not_called()


if __name__ == "__main__":
    unittest.main()
