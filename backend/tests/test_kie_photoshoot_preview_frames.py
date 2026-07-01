"""Integration tests for Kie catalog photoshoot preview frame references."""

from __future__ import annotations

import unittest
from unittest.mock import MagicMock, patch

from app.config import settings
from app.services.kie_image_service import KieImageGenerationError
from app.services.kie_photoshoot_provider import KiePhotoshootProvider
from app.services.photoshoot_reference_service import PhotoshootFramePreviewReference
from app.services.photoshoot_styles import get_photoshoot_style
from app.services.storage_service import storage_service

_TEST_PHOTO_BYTES = b"fake-photo"
_TEST_PHOTO_TYPE = "image/jpeg"
_SIGNED_IDENTITY = "https://supabase.example.com/signed/identity"
_PREVIEW_URLS = [
    "https://cvzzceastvlbcxsckoqd.supabase.co/storage/v1/object/public/"
    "catalog-previews/photoshoots/studio_portrait_1_v2.jpg",
    "https://cvzzceastvlbcxsckoqd.supabase.co/storage/v1/object/public/"
    "catalog-previews/photoshoots/studio_portrait_2_v2.jpg",
    "https://cvzzceastvlbcxsckoqd.supabase.co/storage/v1/object/public/"
    "catalog-previews/photoshoots/studio_portrait_3_v2.jpg",
]
_RESULT_IMAGE_BYTES = b"\x89PNG\r\n\x1a\n" + b"\x00" * 32


def _distinct_result_bytes(call_index: int) -> bytes:
    return _RESULT_IMAGE_BYTES + bytes([call_index % 256])


def _preview_refs_from_urls(urls: list[str | None]) -> list[PhotoshootFramePreviewReference]:
    refs: list[PhotoshootFramePreviewReference] = []
    for url in urls:
        if url is None:
            refs.append(PhotoshootFramePreviewReference(None, "missing", None))
        else:
            refs.append(PhotoshootFramePreviewReference(url, "preview_url", None))
    return refs


class KiePhotoshootPreviewFramesTests(unittest.TestCase):
    def setUp(self) -> None:
        self._saved_settings = {
            "photoshoot_series_reference_mode": settings.photoshoot_series_reference_mode,
            "kie_temp_signed_url_ttl_seconds": settings.kie_temp_signed_url_ttl_seconds,
            "supabase_temp_storage_bucket": settings.supabase_temp_storage_bucket,
            "kie_image_model": settings.kie_image_model,
            "kie_max_photoshoot_tasks": settings.kie_max_photoshoot_tasks,
            "supabase_url": settings.supabase_url,
            "supabase_catalog_previews_bucket": settings.supabase_catalog_previews_bucket,
        }
        settings.photoshoot_series_reference_mode = "identity_anchor"
        settings.kie_temp_signed_url_ttl_seconds = 3600
        settings.supabase_temp_storage_bucket = "temp-bucket"
        settings.kie_image_model = "test-model"
        settings.kie_max_photoshoot_tasks = 5
        settings.supabase_url = "https://cvzzceastvlbcxsckoqd.supabase.co"
        settings.supabase_catalog_previews_bucket = "catalog-previews"

    def tearDown(self) -> None:
        for key, value in self._saved_settings.items():
            setattr(settings, key, value)

    def _run_provider_with_kie_client(self, *, client_style_id: str, preview_urls):
        provider = KiePhotoshootProvider(output_count=3)
        captured_calls: list[tuple[int, list[str], str]] = []
        kie_client = MagicMock()

        def capture_generate(instruction, input_urls, **kwargs):
            captured_calls.append(
                (kwargs.get("frame_index"), list(input_urls), instruction)
            )
            return (_distinct_result_bytes(len(captured_calls)), "image/png")

        kie_client.generate_image_bytes.side_effect = capture_generate

        with patch(
            "app.services.kie_photoshoot_provider.resolve_photoshoot_preview_references_for_session",
            return_value=_preview_refs_from_urls(preview_urls),
        ):
            with patch.object(
                storage_service,
                "upload_temp_input_bytes",
                return_value=("temp/identity", _SIGNED_IDENTITY),
            ):
                with patch.object(
                    storage_service,
                    "create_signed_url",
                    return_value=_SIGNED_IDENTITY,
                ):
                    with patch.object(storage_service, "delete_temp_objects_best_effort") as mock_cleanup:
                        with patch(
                            "app.services.kie_photoshoot_provider.KieImageTaskClient",
                            return_value=kie_client,
                        ):
                            result = provider.generate(
                                get_photoshoot_style(client_style_id),
                                _TEST_PHOTO_BYTES,
                                _TEST_PHOTO_TYPE,
                                client_style_id=client_style_id,
                                photoshoot_id="ps-preview-frames",
                                user_id="user-1",
                            )

        return result, captured_calls, mock_cleanup

    def test_catalog_frames_use_identity_and_matching_preview_urls(self) -> None:
        result, captured_calls, _mock_cleanup = self._run_provider_with_kie_client(
            client_style_id="studio_portrait",
            preview_urls=_PREVIEW_URLS,
        )

        self.assertEqual(len(result), 3)
        self.assertEqual(len(captured_calls), 3)
        for frame_index, input_urls, instruction in captured_calls:
            self.assertEqual(len(input_urls), 2)
            self.assertEqual(input_urls[0], _SIGNED_IDENTITY)
            self.assertEqual(input_urls[1], _PREVIEW_URLS[frame_index])
            self.assertIn("Image 2 is the selected photoshoot preview reference", instruction)

    def test_custom_photoshoot_uses_identity_only(self) -> None:
        result, captured_calls, _mock_cleanup = self._run_provider_with_kie_client(
            client_style_id="custom_photoshoot",
            preview_urls=[None, None, None],
        )

        self.assertEqual(len(result), 3)
        for _frame_index, input_urls, instruction in captured_calls:
            self.assertEqual(len(input_urls), 1)
            self.assertEqual(input_urls[0], _SIGNED_IDENTITY)
            self.assertNotIn("Image 2 is the selected photoshoot preview reference", instruction)

    def test_missing_preview_reference_falls_back_to_identity_only(self) -> None:
        preview_urls = [_PREVIEW_URLS[0], None, _PREVIEW_URLS[2]]
        _result, captured_calls, _mock_cleanup = self._run_provider_with_kie_client(
            client_style_id="studio_portrait",
            preview_urls=preview_urls,
        )

        self.assertEqual(len(captured_calls[0][1]), 2)
        self.assertEqual(len(captured_calls[1][1]), 1)
        self.assertEqual(len(captured_calls[2][1]), 2)

    def test_temp_cleanup_includes_uploaded_preview_asset_paths(self) -> None:
        provider = KiePhotoshootProvider(output_count=1)
        preview_refs = [
            PhotoshootFramePreviewReference(
                "https://signed/preview-asset",
                "preview_asset",
                "temp/preview-asset",
            )
        ]
        kie_client = MagicMock()
        kie_client.generate_image_bytes.return_value = (_RESULT_IMAGE_BYTES, "image/png")

        with patch(
            "app.services.kie_photoshoot_provider.resolve_photoshoot_preview_references_for_session",
            return_value=preview_refs,
        ):
            with patch.object(
                storage_service,
                "upload_temp_input_bytes",
                return_value=("temp/identity", _SIGNED_IDENTITY),
            ):
                with patch.object(
                    storage_service,
                    "create_signed_url",
                    return_value=_SIGNED_IDENTITY,
                ):
                    with patch.object(storage_service, "delete_temp_objects_best_effort") as mock_cleanup:
                        with patch(
                            "app.services.kie_photoshoot_provider.KieImageTaskClient",
                            return_value=kie_client,
                        ):
                            provider.generate(
                                get_photoshoot_style("studio_portrait"),
                                _TEST_PHOTO_BYTES,
                                _TEST_PHOTO_TYPE,
                                client_style_id="studio_portrait",
                                photoshoot_id="ps-preview-cleanup",
                                user_id="user-1",
                            )

        mock_cleanup.assert_called_once()
        deleted_paths = mock_cleanup.call_args.args[0]
        self.assertIn("temp/identity", deleted_paths)
        self.assertIn("temp/preview-asset", deleted_paths)

    def test_rescue_retry_uses_preview_aware_prompt_for_catalog(self) -> None:
        provider = KiePhotoshootProvider(output_count=1)
        provider._preview_input_urls = [_PREVIEW_URLS[0]]
        prompts: list[str] = []
        kie_client = MagicMock()

        def capture_generate(instruction, _input_urls, **_kwargs):
            prompts.append(instruction)
            if len(prompts) == 1:
                raise KieImageGenerationError("kie_task_failed")
            return (_RESULT_IMAGE_BYTES, "image/png")

        kie_client.generate_image_bytes.side_effect = capture_generate

        with patch.object(storage_service, "create_signed_url", return_value=_SIGNED_IDENTITY):
            provider._generate_frame_with_fail_retry(
                frame_index=0,
                style=get_photoshoot_style("studio_portrait"),
                client_style_id="studio_portrait",
                photoshoot_id="ps-rescue-preview",
                user_description=None,
                series_mode="identity_anchor",
                identity_path="temp/identity",
                existing_data_urls=[],
                ttl_seconds=3600,
                kie_client=kie_client,
                task_cap=5,
                on_frame_status=None,
            )

        self.assertEqual(len(prompts), 2)
        self.assertNotIn("Rescue regeneration", prompts[0])
        self.assertIn("Rescue regeneration", prompts[1])
        self.assertIn("Image 2 is the selected photoshoot preview reference", prompts[1])

    def test_generated_frames_are_not_uploaded_as_references(self) -> None:
        provider = KiePhotoshootProvider(output_count=3)
        call_count = 0

        def distinct_generate(_instruction, _input_urls, **_kwargs):
            nonlocal call_count
            call_count += 1
            return (_distinct_result_bytes(call_count), "image/png")

        with patch(
            "app.services.kie_photoshoot_provider.resolve_photoshoot_preview_references_for_session",
            return_value=_preview_refs_from_urls(_PREVIEW_URLS),
        ):
            with patch.object(
                storage_service,
                "upload_temp_input_bytes",
                return_value=("temp/identity", _SIGNED_IDENTITY),
            ) as mock_upload_bytes:
                with patch.object(storage_service, "upload_temp_input_data_url") as mock_upload_data_url:
                    with patch.object(
                        storage_service,
                        "create_signed_url",
                        return_value=_SIGNED_IDENTITY,
                    ):
                        with patch.object(storage_service, "delete_temp_objects_best_effort"):
                            with patch(
                                "app.services.kie_photoshoot_provider.KieImageTaskClient",
                            ) as mock_client_cls:
                                kie_client = MagicMock()
                                kie_client.generate_image_bytes.side_effect = distinct_generate
                                mock_client_cls.return_value = kie_client
                                provider.generate(
                                    get_photoshoot_style("studio_portrait"),
                                    _TEST_PHOTO_BYTES,
                                    _TEST_PHOTO_TYPE,
                                    client_style_id="studio_portrait",
                                    photoshoot_id="ps-no-generated-refs",
                                    user_id="user-1",
                                )

        mock_upload_bytes.assert_called_once()
        mock_upload_data_url.assert_not_called()


if __name__ == "__main__":
    unittest.main()
