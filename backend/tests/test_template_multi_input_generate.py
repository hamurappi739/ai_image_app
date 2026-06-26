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
    validate_age_number,
    validate_cake_digit,
    validate_child_name,
)

_TEST_PHOTO_BYTES = b"fake-user-photo"
_TEST_PET_BYTES = b"fake-pet-photo"
_TEST_CHILD_BYTES = b"fake-child-photo"
_TEST_BABY_BYTES = b"fake-baby-photo"
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

    def test_validate_age_number_and_child_name(self) -> None:
        self.assertEqual(validate_age_number("7"), "7")
        self.assertEqual(validate_child_name("Маша"), "Маша")
        self.assertEqual(validate_child_name("Anna-Maria"), "Anna-Maria")

    def test_build_template_prompt_replaces_age_and_name(self) -> None:
        prompt = build_template_prompt(
            "Balloon {age_number} and name {child_name}.",
            age_number="5",
            child_name="Миша",
        )
        self.assertIn("Balloon 5 and name Миша.", prompt)


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

    @patch("app.main.photo_generation_service")
    def test_child_birthday_number_uses_child_photo_as_primary(
        self,
        mock_service: MagicMock,
    ) -> None:
        mock_service.generate.return_value = _MOCK_IMAGE_URL
        with patch.object(settings, "enable_credit_consumption", False):
            response = self.client.post(
                "/generate-with-photo",
                data={
                    "description": "ignored",
                    "template_id": "child_birthday_number",
                    "age_number": "4",
                },
                files={"child_photo": _photo_file("child.jpg", _TEST_CHILD_BYTES)},
            )
        self.assertEqual(response.status_code, 200)
        kwargs = mock_service.generate.call_args.kwargs
        self.assertEqual(kwargs["photo_bytes"], _TEST_CHILD_BYTES)
        self.assertIn("balloon number 4", kwargs["description"])
        self.assertEqual(kwargs["extra_photos"], [])

    @patch("app.main.photo_generation_service")
    def test_child_name_age_invalid_name_returns_400(
        self,
        mock_service: MagicMock,
    ) -> None:
        with patch.object(settings, "enable_credit_consumption", False):
            response = self.client.post(
                "/generate-with-photo",
                data={
                    "description": "ignored",
                    "template_id": "child_name_age",
                    "age_number": "3",
                    "child_name": "Masha123",
                },
                files={"child_photo": _photo_file("child.jpg", _TEST_CHILD_BYTES)},
            )
        self.assertEqual(response.status_code, 400)
        self.assertIn("Invalid child name value", response.json()["detail"])
        mock_service.generate.assert_not_called()

    @patch("app.main.photo_generation_service")
    def test_child_memory_birthday_requires_baby_photo(
        self,
        mock_service: MagicMock,
    ) -> None:
        with patch.object(settings, "enable_credit_consumption", False):
            response = self.client.post(
                "/generate-with-photo",
                data={
                    "description": "ignored",
                    "template_id": "child_memory_birthday",
                    "age_number": "2",
                },
                files={"child_photo": _photo_file("child.jpg", _TEST_CHILD_BYTES)},
            )
        self.assertEqual(response.status_code, 400)
        mock_service.generate.assert_not_called()

    @patch("app.main.photo_generation_service")
    def test_child_memory_birthday_with_two_photos(
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
                    "age_number": "2",
                },
                files=[
                    ("child_photo", _photo_file("child.jpg", _TEST_CHILD_BYTES)),
                    ("baby_photo", _photo_file("baby.jpg", _TEST_BABY_BYTES)),
                ],
            )
        self.assertEqual(response.status_code, 200)
        kwargs = mock_service.generate.call_args.kwargs
        self.assertEqual(kwargs["photo_bytes"], _TEST_CHILD_BYTES)
        self.assertEqual(len(kwargs["extra_photos"]), 1)
        self.assertEqual(kwargs["extra_photos"][0].photo_bytes, _TEST_BABY_BYTES)

    @patch("app.main.photo_generation_service")
    def test_birthday_balloons_uses_photo_as_primary_with_one_image(
        self,
        mock_service: MagicMock,
    ) -> None:
        mock_service.generate.return_value = _MOCK_IMAGE_URL
        with patch.object(settings, "enable_credit_consumption", False):
            response = self.client.post(
                "/generate-with-photo",
                data={
                    "description": "ignored",
                    "template_id": "birthday_balloons",
                    "age_number": "30",
                },
                files={"photo": _photo_file("user.jpg", _TEST_PHOTO_BYTES)},
            )
        self.assertEqual(response.status_code, 200)
        kwargs = mock_service.generate.call_args.kwargs
        self.assertEqual(kwargs["photo_bytes"], _TEST_PHOTO_BYTES)
        self.assertEqual(kwargs["extra_photos"], [])
        self.assertNotIn("{age_number}", kwargs["description"])
        self.assertIn("foil balloon numbers", kwargs["description"].lower())
        self.assertIn("30", kwargs["description"])

    @patch("app.main.photo_generation_service")
    def test_invalid_age_number_returns_400_before_provider(
        self,
        mock_service: MagicMock,
    ) -> None:
        with patch.object(settings, "enable_credit_consumption", False):
            response = self.client.post(
                "/generate-with-photo",
                data={
                    "description": "ignored",
                    "template_id": "birthday_balloons",
                    "age_number": "abc",
                },
                files={"photo": _photo_file("user.jpg")},
            )
        self.assertEqual(response.status_code, 400)
        self.assertIn("Invalid age number value", response.json()["detail"])
        mock_service.generate.assert_not_called()

    @patch("app.main.photo_generation_service")
    def test_provider_exception_returns_502_and_logs_safely(
        self,
        mock_service: MagicMock,
    ) -> None:
        from fastapi import HTTPException

        mock_service.generate.side_effect = HTTPException(
            status_code=502,
            detail="Gemini photo generation failed: status=503",
        )

        captured: list[logging.LogRecord] = []

        class _CollectHandler(logging.Handler):
            def emit(self, record: logging.LogRecord) -> None:
                captured.append(record)

        handler = _CollectHandler()
        pipeline_logger = logging.getLogger("uvicorn.error")
        pipeline_logger.addHandler(handler)
        self.addCleanup(pipeline_logger.removeHandler, handler)

        with patch.object(settings, "enable_credit_consumption", False):
            response = self.client.post(
                "/generate-with-photo",
                data={
                    "description": "ignored",
                    "template_id": "child_birthday_number",
                    "age_number": "4",
                },
                files={"child_photo": _photo_file("child.jpg", _TEST_CHILD_BYTES)},
            )

        self.assertEqual(response.status_code, 502)
        logged = "\n".join(record.getMessage() for record in captured)
        self.assertIn("stage=provider_generate", logged)
        self.assertIn("child_birthday_number", logged)
        self.assertIn("Gemini photo generation failed", logged)
        self.assertNotIn("fake-child-photo", logged)

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
            ("temp/reference.jpg", "https://signed.example.com/ref?token=secret-c"),
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
        self.assertNotIn("secret-c", logged)
        self.assertNotIn("super-secret-kie-key", logged)
        self.assertNotIn("test-user-id", logged)
        input_urls = mock_kie.generate_image_bytes.call_args.args[1]
        self.assertEqual(len(input_urls), 3)


class GeminiPhotoGenerationProviderTests(unittest.TestCase):
    @patch("app.services.photo_generation_service.settings")
    @patch("app.services.photo_generation_service.genai.Client")
    def test_gemini_no_image_response_logs_and_returns_502(
        self,
        mock_client_cls: MagicMock,
        mock_settings: MagicMock,
    ) -> None:
        from fastapi import HTTPException

        from app.services.photo_generation_service import GeminiPhotoGenerationProvider

        mock_settings.gemini_api_key = "test-key"
        mock_settings.gemini_model = "test-model"
        mock_response = MagicMock()
        mock_response.parts = []
        mock_response.candidates = []
        mock_client_cls.return_value.models.generate_content.return_value = mock_response

        captured: list[logging.LogRecord] = []

        class _CollectHandler(logging.Handler):
            def emit(self, record: logging.LogRecord) -> None:
                captured.append(record)

        handler = _CollectHandler()
        provider_logger = logging.getLogger("app.services.photo_generation_service")
        provider_logger.addHandler(handler)
        self.addCleanup(provider_logger.removeHandler, handler)

        provider = GeminiPhotoGenerationProvider()
        with self.assertRaises(HTTPException) as ctx:
            provider.generate(
                description="Test prompt without secrets",
                photo_bytes=_TEST_PHOTO_BYTES,
                photo_content_type=_TEST_PHOTO_TYPE,
                extra_photos=[],
            )

        self.assertEqual(ctx.exception.status_code, 502)
        logged = "\n".join(record.getMessage() for record in captured)
        self.assertIn("no_image_in_response", logged)
        self.assertNotIn("Test prompt without secrets", logged)


if __name__ == "__main__":
    unittest.main()
