"""Hidden template reference image for catalog template generation."""

from __future__ import annotations

import io
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch

from fastapi.testclient import TestClient

from app.config import settings
from app.main import app
from app.services.catalog_service import invalidate_template_catalog_cache
from app.services.gemini_quality_instructions import append_template_reference_prompt_block
from app.services.template_reference_service import (
    load_template_reference_image,
    normalize_reference_asset_path,
)
from tests.valid_upload_test_bytes import VALID_TEST_JPEG_BYTES

_TEST_PHOTO_BYTES = VALID_TEST_JPEG_BYTES
_TEST_PET_BYTES = VALID_TEST_JPEG_BYTES
_TEST_CHILD_BYTES = VALID_TEST_JPEG_BYTES
_TEST_BABY_BYTES = VALID_TEST_JPEG_BYTES
_TEST_PHOTO_TYPE = "image/jpeg"
_MOCK_IMAGE_URL = "https://cdn.example.com/generated.png"
_BACKEND_ROOT = Path(__file__).resolve().parent.parent
_REFERENCE_BLOCK = "Reference image roles:"


def _photo_file(
    name: str,
    content: bytes = _TEST_PHOTO_BYTES,
) -> tuple[str, io.BytesIO, str]:
    return (name, io.BytesIO(content), _TEST_PHOTO_TYPE)


def _input_image_count(kwargs: dict) -> int:
    count = 1
    count += len(kwargs.get("extra_photos") or [])
    if kwargs.get("reference_photo") is not None:
        count += 1
    return count


class TemplateReferenceImageEndpointTests(unittest.TestCase):
    def setUp(self) -> None:
        invalidate_template_catalog_cache()
        self.client = TestClient(app)

    @patch("app.main.photo_generation_service")
    def test_single_photo_template_sends_user_and_reference_images(
        self,
        mock_service: MagicMock,
    ) -> None:
        mock_service.generate.return_value = _MOCK_IMAGE_URL
        with patch.object(settings, "enable_credit_consumption", False):
            response = self.client.post(
                "/generate-with-photo",
                data={
                    "description": "ignored",
                    "template_id": "business_portrait",
                },
                files={"photo": _photo_file("user.jpg")},
            )
        self.assertEqual(response.status_code, 200)
        kwargs = mock_service.generate.call_args.kwargs
        self.assertEqual(_input_image_count(kwargs), 2)
        self.assertIsNotNone(kwargs["reference_photo"])
        self.assertIn(_REFERENCE_BLOCK, kwargs["description"])
        self.assertIn("main visual blueprint", kwargs["description"])
        self.assertIn(
            "Do not ignore the template preview reference",
            kwargs["description"],
        )

    @patch("app.main.photo_generation_service")
    def test_single_photo_template_prompt_includes_reference_block(
        self,
        mock_service: MagicMock,
    ) -> None:
        mock_service.generate.return_value = _MOCK_IMAGE_URL
        with patch.object(settings, "enable_credit_consumption", False):
            response = self.client.post(
                "/generate-with-photo",
                data={
                    "description": "ignored",
                    "template_id": "ocean_portrait",
                },
                files={"photo": _photo_file("user.jpg")},
            )
        self.assertEqual(response.status_code, 200)
        description = mock_service.generate.call_args.kwargs["description"]
        self.assertIn("Match the template preview reference closely", description)
        self.assertIn("Do not ignore the template preview reference", description)

    @patch("app.main.photo_generation_service")
    def test_woman_with_cat_sends_three_images(
        self,
        mock_service: MagicMock,
    ) -> None:
        mock_service.generate.return_value = _MOCK_IMAGE_URL
        with patch.object(settings, "enable_credit_consumption", False):
            response = self.client.post(
                "/generate-with-photo",
                data={
                    "description": "ignored",
                    "template_id": "woman_with_cat",
                },
                files={
                    "photo": _photo_file("user.jpg"),
                    "pet_photo": _photo_file("cat.jpg", _TEST_PET_BYTES),
                },
            )
        self.assertEqual(response.status_code, 200)
        kwargs = mock_service.generate.call_args.kwargs
        self.assertEqual(_input_image_count(kwargs), 3)
        self.assertEqual(len(kwargs["extra_photos"]), 1)
        self.assertIsNotNone(kwargs["reference_photo"])
        self.assertIn(
            "The last image is not an identity image",
            kwargs["description"],
        )
        self.assertIn("template layout/style blueprint", kwargs["description"])

    @patch("app.main.photo_generation_service")
    def test_child_memory_birthday_sends_three_images(
        self,
        mock_service: MagicMock,
    ) -> None:
        mock_service.generate.return_value = _MOCK_IMAGE_URL
        with patch.object(settings, "enable_credit_consumption", False):
            response = self.client.post(
                "/generate-with-photo",
                data={
                    "description": "ignored",
                    "template_id": "child_memory_birthday",
                    "age_number": "5",
                },
                files={
                    "child_photo": _photo_file("child.jpg", _TEST_CHILD_BYTES),
                    "baby_photo": _photo_file("baby.jpg", _TEST_BABY_BYTES),
                },
            )
        self.assertEqual(response.status_code, 200)
        kwargs = mock_service.generate.call_args.kwargs
        self.assertEqual(_input_image_count(kwargs), 3)
        self.assertEqual(len(kwargs["extra_photos"]), 1)
        self.assertIsNotNone(kwargs["reference_photo"])
        self.assertIn(
            "The last image is not an identity image",
            kwargs["description"],
        )

    @patch("app.main.photo_generation_service")
    @patch(
        "app.services.template_generation_service.load_template_reference_for_catalog_item",
        return_value=None,
    )
    def test_missing_reference_file_continues_with_user_images_only(
        self,
        _mock_load: MagicMock,
        mock_service: MagicMock,
    ) -> None:
        mock_service.generate.return_value = _MOCK_IMAGE_URL
        with patch.object(settings, "enable_credit_consumption", False):
            response = self.client.post(
                "/generate-with-photo",
                data={
                    "description": "ignored",
                    "template_id": "business_portrait",
                },
                files={"photo": _photo_file("user.jpg")},
            )
        self.assertEqual(response.status_code, 200)
        kwargs = mock_service.generate.call_args.kwargs
        self.assertEqual(_input_image_count(kwargs), 1)
        self.assertIsNone(kwargs["reference_photo"])
        self.assertNotIn(_REFERENCE_BLOCK, kwargs["description"])

    @patch("app.main.photo_generation_service")
    def test_custom_flow_does_not_send_reference_image(
        self,
        mock_service: MagicMock,
    ) -> None:
        mock_service.generate.return_value = _MOCK_IMAGE_URL
        with patch.object(settings, "enable_credit_consumption", False):
            response = self.client.post(
                "/generate-with-photo",
                data={"description": "Custom portrait"},
                files={"photo": _photo_file("user.jpg")},
            )
        self.assertEqual(response.status_code, 200)
        kwargs = mock_service.generate.call_args.kwargs
        self.assertIsNone(kwargs["reference_photo"])
        self.assertNotIn(_REFERENCE_BLOCK, kwargs["description"])


class TemplateReferencePathTests(unittest.TestCase):
    def test_path_traversal_is_rejected(self) -> None:
        self.assertIsNone(
            normalize_reference_asset_path(
                "assets/previews/templates/../../secret.jpg"
            )
        )
        self.assertIsNone(
            normalize_reference_asset_path("/etc/passwd")
        )

    def test_allowed_path_is_accepted(self) -> None:
        self.assertEqual(
            normalize_reference_asset_path(
                "assets/previews/templates/birthday_balloons.jpg"
            ),
            "assets/previews/templates/birthday_balloons.jpg",
        )

    def test_missing_reference_file_returns_none(self) -> None:
        self.assertIsNone(
            load_template_reference_image(
                "assets/previews/templates/does_not_exist.jpg"
            )
        )


class TemplateReferencePromptTests(unittest.TestCase):
    _REQUIRED_PHRASES = (
        "main visual blueprint",
        "Match the template preview reference closely",
        "Do not ignore the template preview reference",
    )

    def test_general_reference_prompt_block_contains_required_phrases(self) -> None:
        prompt = append_template_reference_prompt_block(
            "Template prompt body",
            template_id="volcanic_gray_rock",
            has_reference=True,
        )
        self.assertIn(_REFERENCE_BLOCK, prompt)
        for phrase in self._REQUIRED_PHRASES:
            self.assertIn(phrase, prompt, phrase)

    def test_single_photo_template_includes_reference_block(self) -> None:
        prompt = append_template_reference_prompt_block(
            "Business portrait prompt",
            template_id="business_portrait",
            has_reference=True,
            user_image_count=1,
        )
        self.assertIn("main visual blueprint", prompt)
        self.assertNotIn(
            "The last image is not an identity image",
            prompt,
        )

    def test_multi_input_template_includes_identity_blueprint_line(self) -> None:
        prompt = append_template_reference_prompt_block(
            "Woman with cat prompt",
            template_id="woman_with_cat",
            has_reference=True,
            user_image_count=2,
        )
        self.assertIn("main visual blueprint", prompt)
        self.assertIn(
            "The last image is not an identity image",
            prompt,
        )
        self.assertIn("template layout/style blueprint", prompt)

    def test_has_reference_false_returns_prompt_unchanged(self) -> None:
        prompt = append_template_reference_prompt_block(
            "Plain prompt",
            template_id="business_portrait",
            has_reference=False,
        )
        self.assertEqual(prompt, "Plain prompt")
        self.assertNotIn(_REFERENCE_BLOCK, prompt)

    def test_birthday_balloons_adds_balloon_reference_extra(self) -> None:
        prompt = append_template_reference_prompt_block(
            "Birthday prompt",
            template_id="birthday_balloons",
            has_reference=True,
        )
        self.assertIn("metallic foil balloon numbers", prompt)
        self.assertIn("cake topper", prompt)
        self.assertIn("printed number on the cake", prompt)


class TemplateReferenceCatalogSyncTests(unittest.TestCase):
    def setUp(self) -> None:
        backend_path = _BACKEND_ROOT / "app" / "catalog" / "templates.json"
        frontend_path = (
            _BACKEND_ROOT.parent / "frontend" / "assets" / "catalog" / "templates.json"
        )
        import json

        self.backend_by_id = {
            item["id"]: item
            for item in json.loads(backend_path.read_text(encoding="utf-8"))
        }
        self.frontend_by_id = {
            item["id"]: item
            for item in json.loads(frontend_path.read_text(encoding="utf-8"))
        }

    def test_frontend_backend_reference_asset_in_sync(self) -> None:
        for template_id, backend_item in self.backend_by_id.items():
            frontend_item = self.frontend_by_id[template_id]
            self.assertEqual(
                frontend_item.get("referenceAsset"),
                backend_item.get("referenceAsset"),
                template_id,
            )
            self.assertTrue(backend_item.get("referenceAsset"))


if __name__ == "__main__":
    unittest.main()
