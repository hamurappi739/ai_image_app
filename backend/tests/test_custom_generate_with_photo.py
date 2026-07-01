"""Custom «Своя идея» generation with optional extra photos."""

from __future__ import annotations

import io
import unittest
from unittest.mock import MagicMock, patch

from fastapi.testclient import TestClient

from app.config import settings
from app.main import app
from app.services.catalog_service import invalidate_template_catalog_cache
from app.services.gemini_quality_instructions import build_photo_edit_instruction
from app.services.template_generation_service import resolve_template_generation_inputs
from tests.valid_upload_test_bytes import VALID_TEST_JPEG_BYTES

_TEST_PHOTO_BYTES = VALID_TEST_JPEG_BYTES
_TEST_EXTRA_1_BYTES = VALID_TEST_JPEG_BYTES
_TEST_EXTRA_2_BYTES = VALID_TEST_JPEG_BYTES
_TEST_PET_BYTES = VALID_TEST_JPEG_BYTES
_TEST_PHOTO_TYPE = "image/jpeg"
_MOCK_IMAGE_URL = "https://cdn.example.com/generated.png"


def _photo_file(
    name: str,
    content: bytes = _TEST_PHOTO_BYTES,
) -> tuple[str, io.BytesIO, str]:
    return (name, io.BytesIO(content), _TEST_PHOTO_TYPE)


class CustomGenerateWithPhotoTests(unittest.TestCase):
    def setUp(self) -> None:
        invalidate_template_catalog_cache()
        self.client = TestClient(app)

    @patch("app.main.photo_generation_service")
    def test_custom_generate_with_one_photo_works_as_before(
        self,
        mock_service: MagicMock,
    ) -> None:
        mock_service.generate.return_value = _MOCK_IMAGE_URL
        with patch.object(settings, "enable_credit_consumption", False):
            response = self.client.post(
                "/generate-with-photo",
                data={"description": "Custom portrait prompt"},
                files={"photo": _photo_file("user.jpg")},
            )
        self.assertEqual(response.status_code, 200)
        kwargs = mock_service.generate.call_args.kwargs
        self.assertEqual(kwargs["photo_bytes"], _TEST_PHOTO_BYTES)
        self.assertEqual(kwargs["extra_photos"], [])
        self.assertIsNone(kwargs["template_id"])

    @patch("app.main.photo_generation_service")
    def test_custom_generate_with_two_photos_sends_one_extra(
        self,
        mock_service: MagicMock,
    ) -> None:
        mock_service.generate.return_value = _MOCK_IMAGE_URL
        with patch.object(settings, "enable_credit_consumption", False):
            response = self.client.post(
                "/generate-with-photo",
                data={"description": "Group portrait prompt"},
                files={
                    "photo": _photo_file("user.jpg"),
                    "extra_photo_1": _photo_file("friend.jpg", _TEST_EXTRA_1_BYTES),
                },
            )
        self.assertEqual(response.status_code, 200)
        kwargs = mock_service.generate.call_args.kwargs
        self.assertEqual(len(kwargs["extra_photos"]), 1)
        self.assertEqual(kwargs["extra_photos"][0].photo_bytes, _TEST_EXTRA_1_BYTES)

    @patch("app.main.photo_generation_service")
    def test_custom_generate_with_three_photos_sends_two_extras(
        self,
        mock_service: MagicMock,
    ) -> None:
        mock_service.generate.return_value = _MOCK_IMAGE_URL
        with patch.object(settings, "enable_credit_consumption", False):
            response = self.client.post(
                "/generate-with-photo",
                data={"description": "Three people prompt"},
                files={
                    "photo": _photo_file("user.jpg"),
                    "extra_photo_1": _photo_file("friend.jpg", _TEST_EXTRA_1_BYTES),
                    "extra_photo_2": _photo_file("friend2.jpg", _TEST_EXTRA_2_BYTES),
                },
            )
        self.assertEqual(response.status_code, 200)
        kwargs = mock_service.generate.call_args.kwargs
        self.assertEqual(len(kwargs["extra_photos"]), 2)
        self.assertEqual(kwargs["extra_photos"][0].photo_bytes, _TEST_EXTRA_1_BYTES)
        self.assertEqual(kwargs["extra_photos"][1].photo_bytes, _TEST_EXTRA_2_BYTES)

    def test_custom_generate_without_primary_photo_returns_400(self) -> None:
        response = self.client.post(
            "/generate-with-photo",
            data={"description": "Missing photo"},
        )
        self.assertEqual(response.status_code, 400)

    @patch("app.main.photo_generation_service")
    def test_custom_optional_photos_are_not_required(
        self,
        mock_service: MagicMock,
    ) -> None:
        mock_service.generate.return_value = _MOCK_IMAGE_URL
        with patch.object(settings, "enable_credit_consumption", False):
            response = self.client.post(
                "/generate-with-photo",
                data={"description": "Only primary photo"},
                files={"photo": _photo_file("user.jpg")},
            )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(mock_service.generate.call_args.kwargs["extra_photos"], [])

    @patch("app.main.photo_generation_service")
    def test_template_with_input_requirements_ignores_extra_photo_fields(
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
                    "extra_photo_1": _photo_file("extra.jpg", _TEST_EXTRA_1_BYTES),
                },
            )
        self.assertEqual(response.status_code, 200)
        kwargs = mock_service.generate.call_args.kwargs
        self.assertEqual(len(kwargs["extra_photos"]), 1)
        self.assertEqual(kwargs["extra_photos"][0].photo_bytes, _TEST_PET_BYTES)


class CustomPromptInstructionTests(unittest.TestCase):
    def test_extra_photo_rules_added_when_extras_present(self) -> None:
        instruction = build_photo_edit_instruction(
            "Family portrait together",
            extra_photos_count=2,
        )
        self.assertIn(
            "Use the first uploaded photo as the main identity/reference image.",
            instruction,
        )
        self.assertIn("optional references for extra people", instruction)
        self.assertIn("Do not add people from optional photos unless", instruction)

    def test_extra_photo_rules_omitted_for_single_photo(self) -> None:
        instruction = build_photo_edit_instruction(
            "Solo portrait",
            extra_photos_count=0,
        )
        self.assertNotIn("optional references for extra people", instruction)


class ResolveCustomGenerationTests(unittest.TestCase):
    def test_resolve_custom_with_optional_extras(self) -> None:
        class _Upload:
            content_type = _TEST_PHOTO_TYPE

            def __init__(self, data: bytes) -> None:
                self._data = data

            @property
            def file(self) -> io.BytesIO:
                return io.BytesIO(self._data)

        result = resolve_template_generation_inputs(
            template_id=None,
            description="Group photo",
            photo=_Upload(_TEST_PHOTO_BYTES),
            extra_photo_1=_Upload(_TEST_EXTRA_1_BYTES),
        )
        self.assertEqual(result.photo_bytes, _TEST_PHOTO_BYTES)
        self.assertEqual(len(result.extra_photos), 1)
        self.assertEqual(result.extra_photos[0].photo_bytes, _TEST_EXTRA_1_BYTES)


if __name__ == "__main__":
    unittest.main()
