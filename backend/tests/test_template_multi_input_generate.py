"""Stage 2: multi-input template generation for /generate-with-photo."""

from __future__ import annotations

import io
import logging
import unittest
from unittest.mock import MagicMock, patch

from fastapi.testclient import TestClient

from app.config import settings
from app.main import app
from app.services.image_provider_resolver import KIE_IMAGE_PROVIDER
from app.services.catalog_service import invalidate_template_catalog_cache
from app.services.template_generation_service import (
    build_template_prompt,
    validate_cake_digit,
)

_TEST_PHOTO_BYTES = b"fake-user-photo"
_TEST_PET_BYTES = b"fake-pet-photo"
_TEST_CHILD_BYTES = b"fake-child-photo"
_TEST_PHOTO_TYPE = "image/jpeg"
_MOCK_IMAGE_URL = "https://cdn.example.com/generated.png"


def _photo_file(name: str, content: bytes = _TEST_PHOTO_BYTES) -> tuple[str, io.BytesIO, str]:
    return (name, io.BytesIO(content), _TEST_PHOTO_TYPE)


class TemplateGenerationServiceTests(unittest.TestCase):
    def test_validate_cake_digit_accepts_one_and_two_digits(self) -> None:
        self.assertEqual(validate_cake_digit("3"), "3")
        self.assertEqual(validate_cake_digit("99"), "99")

    def test_build_template_prompt_replaces_digit(self) -> None:
        prompt = build_template_prompt(
            "The birthday cake must have the number {digit} clearly visible as a candle or cake topper.",
            cake_digit="3",
        )
        self.assertIn(
            "The birthday cake must have the number 3 clearly visible",
            prompt,
        )


class GenerateWithPhotoMultiInputEndpointTests(unittest.TestCase):
    def setUp(self) -> None:
        invalidate_template_catalog_cache()
        self.client = TestClient(app)

    @patch("app.main.photo_generation_service")
    def test_single_photo_still_works(self, mock_service: MagicMock) -> None:
        mock_service.generate.return_value = _MOCK_IMAGE_URL
        with patch.object(settings, "enable_credit_consumption", False):
            response = self.client.post(
                "/generate-with-photo",
                data={"description": "Single photo prompt"},
                files={"photo": _photo_file("user.jpg")},
            )
        self.assertEqual(response.status_code, 200)
        mock_service.generate.assert_called_once()
        kwargs = mock_service.generate.call_args.kwargs
        self.assertEqual(kwargs["description"], "Single photo prompt")
        self.assertEqual(kwargs["extra_photos"], [])

    @patch("app.main.photo_generation_service")
    def test_woman_with_cat_without_pet_photo_returns_400(self, mock_service: MagicMock) -> None:
        with patch.object(settings, "enable_credit_consumption", False):
            response = self.client.post(
                "/generate-with-photo",
                data={
                    "description": "ignored",
                    "template_id": "woman_with_cat",
                },
                files={"photo": _photo_file("user.jpg")},
            )
        self.assertEqual(response.status_code, 400)
        self.assertIn("Required template inputs are missing", response.json()["detail"])
        mock_service.generate.assert_not_called()

    @patch("app.main.photo_generation_service")
    def test_woman_with_cat_with_both_photos_calls_provider_with_extra(
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
                files=[
                    ("photo", _photo_file("user.jpg", _TEST_PHOTO_BYTES)),
                    ("pet_photo", _photo_file("pet.jpg", _TEST_PET_BYTES)),
                ],
            )
        self.assertEqual(response.status_code, 200)
        mock_service.generate.assert_called_once()
        kwargs = mock_service.generate.call_args.kwargs
        self.assertEqual(len(kwargs["extra_photos"]), 1)
        self.assertEqual(kwargs["extra_photos"][0].photo_bytes, _TEST_PET_BYTES)
        self.assertIn("Image 2 is the pet photo", kwargs["description"])

    @patch("app.main.photo_generation_service")
    def test_photo_with_child_without_child_photo_returns_400(
        self,
        mock_service: MagicMock,
    ) -> None:
        with patch.object(settings, "enable_credit_consumption", False):
            response = self.client.post(
                "/generate-with-photo",
                data={
                    "description": "ignored",
                    "template_id": "photo_with_child",
                    "cake_digit": "3",
                },
                files={"photo": _photo_file("user.jpg")},
            )
        self.assertEqual(response.status_code, 400)
        mock_service.generate.assert_not_called()

    @patch("app.main.photo_generation_service")
    def test_photo_with_child_without_cake_digit_returns_400(
        self,
        mock_service: MagicMock,
    ) -> None:
        with patch.object(settings, "enable_credit_consumption", False):
            response = self.client.post(
                "/generate-with-photo",
                data={
                    "description": "ignored",
                    "template_id": "photo_with_child",
                },
                files=[
                    ("photo", _photo_file("user.jpg")),
                    ("child_photo", _photo_file("child.jpg", _TEST_CHILD_BYTES)),
                ],
            )
        self.assertEqual(response.status_code, 400)
        mock_service.generate.assert_not_called()

    @patch("app.main.photo_generation_service")
    def test_photo_with_child_invalid_cake_digit_returns_400(
        self,
        mock_service: MagicMock,
    ) -> None:
        with patch.object(settings, "enable_credit_consumption", False):
            response = self.client.post(
                "/generate-with-photo",
                data={
                    "description": "ignored",
                    "template_id": "photo_with_child",
                    "cake_digit": "abc",
                },
                files=[
                    ("photo", _photo_file("user.jpg")),
                    ("child_photo", _photo_file("child.jpg", _TEST_CHILD_BYTES)),
                ],
            )
        self.assertEqual(response.status_code, 400)
        self.assertIn("Invalid cake digit value", response.json()["detail"])
        mock_service.generate.assert_not_called()

    @patch("app.main.photo_generation_service")
    def test_photo_with_child_valid_digit_builds_prompt(
        self,
        mock_service: MagicMock,
    ) -> None:
        mock_service.generate.return_value = _MOCK_IMAGE_URL
        with patch.object(settings, "enable_credit_consumption", False):
            response = self.client.post(
                "/generate-with-photo",
                data={
                    "description": "ignored",
                    "template_id": "photo_with_child",
                    "cake_digit": "3",
                },
                files=[
                    ("photo", _photo_file("user.jpg", _TEST_PHOTO_BYTES)),
                    ("child_photo", _photo_file("child.jpg", _TEST_CHILD_BYTES)),
                ],
            )
        self.assertEqual(response.status_code, 200)
        prompt = mock_service.generate.call_args.kwargs["description"]
        self.assertIn(
            "The birthday cake must have the number 3 clearly visible",
            prompt,
        )
        extras = mock_service.generate.call_args.kwargs["extra_photos"]
        self.assertEqual(len(extras), 1)
        self.assertEqual(extras[0].photo_bytes, _TEST_CHILD_BYTES)

    @patch("app.main.get_current_user")
    @patch("app.services.photo_generation_service.storage_service")
    @patch("app.services.photo_generation_service.resolve_template_image_provider")
    @patch("app.services.photo_generation_service.KieImageTaskClient")
    def test_multi_photo_kie_logs_do_not_leak_secrets(
        self,
        mock_kie_client_cls: MagicMock,
        mock_resolve_provider: MagicMock,
        mock_storage: MagicMock,
        mock_get_current_user: MagicMock,
    ) -> None:
        from app.auth import CurrentUser

        test_user = CurrentUser(id="test-user-id", email="test@example.com")
        mock_get_current_user.return_value = test_user
        mock_storage.upload_temp_input_bytes.side_effect = [
            ("temp/user.jpg", "https://signed.example.com/user?token=secret-a"),
            ("temp/pet.jpg", "https://signed.example.com/pet?token=secret-b"),
        ]
        mock_kie = MagicMock()
        mock_kie.generate_image_bytes.return_value = (b"\x89PNG\r\n", "image/png")
        mock_kie.created_tasks_count = 1
        mock_kie_client_cls.return_value = mock_kie

        mock_resolve_provider.return_value = KIE_IMAGE_PROVIDER

        captured: list[logging.LogRecord] = []

        class _CollectHandler(logging.Handler):
            def emit(self, record: logging.LogRecord) -> None:
                captured.append(record)

        handler = _CollectHandler()
        root = logging.getLogger()
        root.addHandler(handler)
        self.addCleanup(root.removeHandler, handler)

        with patch.object(settings, "enable_credit_consumption", False), patch.object(
            settings, "kie_api_key", "super-secret-kie-key"
        ):
            response = self.client.post(
                "/generate-with-photo",
                data={
                    "description": "ignored",
                    "template_id": "woman_with_cat",
                },
                files=[
                    ("photo", _photo_file("user.jpg")),
                    ("pet_photo", _photo_file("pet.jpg", _TEST_PET_BYTES)),
                ],
                headers={"Authorization": "Bearer test-token"},
            )

        self.assertEqual(response.status_code, 200)
        logged = "\n".join(record.getMessage() for record in captured)
        self.assertNotIn("secret-a", logged)
        self.assertNotIn("secret-b", logged)
        self.assertNotIn("super-secret-kie-key", logged)
        self.assertNotIn("test-user-id", logged)
        input_urls = mock_kie.generate_image_bytes.call_args.args[1]
        self.assertEqual(len(input_urls), 2)


if __name__ == "__main__":
    unittest.main()
