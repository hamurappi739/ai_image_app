"""Kie photoshoot duplicate detection and retry tests."""

from __future__ import annotations

import unittest
from unittest.mock import MagicMock, patch

from fastapi import HTTPException

from app.services.kie_photoshoot_provider import KiePhotoshootProvider
from app.services.photoshoot_similarity import (
    KIE_DUPLICATE_RETRY_PROMPT_SUFFIX,
    DuplicateFrameMatch,
)
from app.services.photoshoot_styles import get_photoshoot_style
from app.services.storage_service import storage_service

_SIGNED_URL = "https://supabase.example.com/signed/a"


class KiePhotoshootDuplicateGuardTests(unittest.TestCase):
    def test_duplicate_retry_uses_strengthened_prompt_suffix(self) -> None:
        provider = KiePhotoshootProvider(output_count=1)
        prompts: list[str] = []

        def capture_generate(*, prompt_suffix: str = "", **kwargs):
            prompts.append(prompt_suffix)
            return "data:image/png;base64,NEW"

        duplicate = DuplicateFrameMatch(
            kind="perceptual",
            duplicate_frame_index=0,
            perceptual_distance=1,
        )

        with patch.object(provider, "_generate_frame_data_url", side_effect=capture_generate):
            with patch(
                "app.services.kie_photoshoot_provider.find_generated_frame_duplicate",
                side_effect=[duplicate, None],
            ):
                result = provider._generate_unique_frame_data_url(
                    frame_index=1,
                    style=get_photoshoot_style("studio_portrait"),
                    client_style_id="studio_portrait",
                    photoshoot_id="ps-dup-retry",
                    user_description=None,
                    series_mode="identity_anchor",
                    identity_path="temp/a",
                    existing_data_urls=["data:image/png;base64,OLD"],
                    ttl_seconds=3600,
                    kie_client=MagicMock(),
                    task_cap=5,
                    on_frame_status=None,
                )

        self.assertEqual(result, "data:image/png;base64,NEW")
        self.assertEqual(len(prompts), 2)
        self.assertEqual(prompts[0], "")
        self.assertIn(KIE_DUPLICATE_RETRY_PROMPT_SUFFIX, prompts[1])

    def test_duplicate_persists_after_retry_returns_502(self) -> None:
        provider = KiePhotoshootProvider(output_count=1)
        duplicate = DuplicateFrameMatch(
            kind="perceptual",
            duplicate_frame_index=0,
            perceptual_distance=0,
        )

        with patch.object(
            provider,
            "_generate_frame_data_url",
            return_value="data:image/png;base64,DUP",
        ):
            with patch(
                "app.services.kie_photoshoot_provider.find_generated_frame_duplicate",
                return_value=duplicate,
            ):
                with self.assertRaises(HTTPException) as ctx:
                    provider._generate_unique_frame_data_url(
                        frame_index=2,
                        style=get_photoshoot_style("studio_portrait"),
                        client_style_id="studio_portrait",
                        photoshoot_id="ps-dup-fail",
                        user_description=None,
                        series_mode="identity_anchor",
                        identity_path="temp/a",
                        existing_data_urls=[
                            "data:image/png;base64,A",
                            "data:image/png;base64,B",
                        ],
                        ttl_seconds=3600,
                        kie_client=MagicMock(),
                        task_cap=5,
                        on_frame_status=None,
                    )

        self.assertEqual(ctx.exception.status_code, 502)

    def test_build_input_urls_returns_identity_and_preview_for_catalog(self) -> None:
        provider = KiePhotoshootProvider(output_count=3)
        preview_urls = [
            "https://cvzzceastvlbcxsckoqd.supabase.co/storage/v1/object/public/"
            "catalog-previews/photoshoots/studio_portrait_1_v2.jpg",
            "https://cvzzceastvlbcxsckoqd.supabase.co/storage/v1/object/public/"
            "catalog-previews/photoshoots/studio_portrait_2_v2.jpg",
            "https://cvzzceastvlbcxsckoqd.supabase.co/storage/v1/object/public/"
            "catalog-previews/photoshoots/studio_portrait_3_v2.jpg",
        ]
        provider._preview_input_urls = preview_urls
        with patch.object(
            storage_service,
            "create_signed_url",
            return_value="https://signed/identity",
        ):
            frame_zero_urls = provider._build_input_urls(
                identity_path="temp/a",
                frame_index=0,
                ttl_seconds=3600,
                client_style_id="studio_portrait",
                photoshoot_id="ps-urls",
            )
            frame_one_urls = provider._build_input_urls(
                identity_path="temp/a",
                frame_index=1,
                ttl_seconds=3600,
                client_style_id="studio_portrait",
                photoshoot_id="ps-urls",
            )

        self.assertEqual(
            frame_zero_urls,
            ["https://signed/identity", preview_urls[0]],
        )
        self.assertEqual(
            frame_one_urls,
            ["https://signed/identity", preview_urls[1]],
        )

    def test_build_input_urls_returns_identity_only_for_custom(self) -> None:
        provider = KiePhotoshootProvider(output_count=3)
        provider._preview_input_urls = [None, None, None]
        with patch.object(
            storage_service,
            "create_signed_url",
            return_value="https://signed/identity",
        ):
            urls = provider._build_input_urls(
                identity_path="temp/a",
                frame_index=0,
                ttl_seconds=3600,
                client_style_id="custom_photoshoot",
                photoshoot_id="ps-urls",
            )

        self.assertEqual(urls, ["https://signed/identity"])


if __name__ == "__main__":
    unittest.main()
