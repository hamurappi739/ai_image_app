"""Demo/staging mode: persist generations when credit consumption is disabled."""

from __future__ import annotations

import io
import unittest
from unittest.mock import MagicMock, patch

from fastapi.testclient import TestClient

from app.auth import CurrentUser, get_current_user
from app.config import settings
from app.main import app

_TEST_USER = CurrentUser(id="user-demo-1", email="demo@example.com")
_TEST_PHOTO_BYTES = b"fake-user-photo"
_TEST_PHOTO_TYPE = "image/jpeg"
_MOCK_IMAGE_URL = "https://cdn.example.com/generated.jpg"
_MOCK_PROMPT = "Custom portrait prompt"
_GENERATION_ROW = {
    "id": "gen-demo-1",
    "user_id": _TEST_USER.id,
    "prompt": _MOCK_PROMPT,
    "image_url": _MOCK_IMAGE_URL,
    "payment_type": "free",
    "photoshoot_id": None,
    "created_at": "2026-05-29T12:00:00+00:00",
}


def _photo_file() -> tuple[str, io.BytesIO, str]:
    return ("user.jpg", io.BytesIO(_TEST_PHOTO_BYTES), _TEST_PHOTO_TYPE)


class DemoGenerationPersistTests(unittest.TestCase):
    def setUp(self) -> None:
        self.client = TestClient(app)
        app.dependency_overrides[get_current_user] = lambda: _TEST_USER

    def tearDown(self) -> None:
        app.dependency_overrides.clear()

    @patch("app.main._optional_user_for_generation", return_value=_TEST_USER)
    @patch("app.main.ensure_profile_exists", return_value={"id": _TEST_USER.id})
    @patch("app.main.consume_generation")
    @patch("app.main.create_generation_record")
    @patch("app.main.photo_generation_service")
    def test_generate_with_photo_demo_mode_persists_without_consume(
        self,
        mock_service: MagicMock,
        mock_create_record: MagicMock,
        mock_consume: MagicMock,
        _mock_ensure_profile: MagicMock,
        _mock_optional_user: MagicMock,
    ) -> None:
        mock_service.generate.return_value = _MOCK_IMAGE_URL
        mock_create_record.return_value = _GENERATION_ROW

        with patch.object(settings, "enable_credit_consumption", False):
            response = self.client.post(
                "/generate-with-photo",
                data={"description": _MOCK_PROMPT},
                files={"photo": _photo_file()},
            )

        self.assertEqual(response.status_code, 200)
        mock_create_record.assert_called_once_with(
            user_id=_TEST_USER.id,
            prompt=_MOCK_PROMPT,
            image_url=_MOCK_IMAGE_URL,
            payment_type="free",
        )
        mock_consume.assert_not_called()

    @patch("app.main._optional_user_for_generation", return_value=_TEST_USER)
    @patch("app.main.ensure_profile_exists", return_value={"id": _TEST_USER.id})
    @patch("app.main.consume_generation")
    @patch("app.main.create_generation_record")
    @patch("app.main.get_generations_by_user_id")
    @patch("app.main.photo_generation_service")
    def test_get_generations_returns_demo_mode_record(
        self,
        mock_service: MagicMock,
        mock_get_generations: MagicMock,
        mock_create_record: MagicMock,
        mock_consume: MagicMock,
        _mock_ensure_profile: MagicMock,
        _mock_optional_user: MagicMock,
    ) -> None:
        mock_service.generate.return_value = _MOCK_IMAGE_URL
        mock_create_record.return_value = _GENERATION_ROW
        mock_get_generations.return_value = [_GENERATION_ROW]

        with patch.object(settings, "enable_credit_consumption", False):
            post_response = self.client.post(
                "/generate-with-photo",
                data={"description": _MOCK_PROMPT},
                files={"photo": _photo_file()},
            )
            self.assertEqual(post_response.status_code, 200)

            list_response = self.client.get("/generations")

        self.assertEqual(list_response.status_code, 200)
        body = list_response.json()
        self.assertEqual(len(body["generations"]), 1)
        self.assertEqual(body["generations"][0]["id"], "gen-demo-1")
        self.assertEqual(body["generations"][0]["image_url"], _MOCK_IMAGE_URL)
        mock_consume.assert_not_called()
        mock_get_generations.assert_called_once()
        self.assertEqual(mock_get_generations.call_args.args[0], _TEST_USER.id)

    @patch("app.main._optional_user_for_generation", return_value=_TEST_USER)
    @patch("app.main.ensure_profile_exists", return_value={"id": _TEST_USER.id})
    @patch("app.main.consume_generation")
    @patch("app.main.create_generation_record")
    @patch("app.main.generate_image", return_value=_MOCK_IMAGE_URL)
    def test_generate_text_only_demo_mode_persists_without_consume(
        self,
        _mock_generate_image: MagicMock,
        mock_create_record: MagicMock,
        mock_consume: MagicMock,
        _mock_ensure_profile: MagicMock,
        _mock_optional_user: MagicMock,
    ) -> None:
        mock_create_record.return_value = {
            **_GENERATION_ROW,
            "prompt": "Text-only prompt",
        }

        with patch.object(settings, "enable_credit_consumption", False):
            response = self.client.post(
                "/generate",
                json={"prompt": "Text-only prompt"},
            )

        self.assertEqual(response.status_code, 200)
        mock_create_record.assert_called_once_with(
            user_id=_TEST_USER.id,
            prompt="Text-only prompt",
            image_url=_MOCK_IMAGE_URL,
            payment_type="free",
        )
        mock_consume.assert_not_called()

    @patch("app.main.consume_generation")
    @patch("app.main.create_generation_record")
    @patch("app.main.ensure_profile_exists")
    @patch("app.main.photo_generation_service")
    def test_generate_with_photo_credit_mode_uses_consume(
        self,
        mock_service: MagicMock,
        mock_ensure_profile: MagicMock,
        mock_create_record: MagicMock,
        mock_consume: MagicMock,
    ) -> None:
        mock_service.generate.return_value = _MOCK_IMAGE_URL
        mock_ensure_profile.return_value = {"id": _TEST_USER.id, "free_generations_used": 0}
        mock_consume.return_value = {
            "profile": {"id": _TEST_USER.id, "free_generations_used": 1},
            "payment_type": "free",
        }

        with patch.object(settings, "enable_credit_consumption", True):
            response = self.client.post(
                "/generate-with-photo",
                data={"description": _MOCK_PROMPT},
                files={"photo": _photo_file()},
            )

        self.assertEqual(response.status_code, 200)
        mock_consume.assert_called_once()
        mock_create_record.assert_not_called()


if __name__ == "__main__":
    unittest.main()
