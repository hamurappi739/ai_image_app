"""Production auth guards and development TEST_USER_ID fallback."""

from __future__ import annotations

import io
import unittest
from unittest.mock import patch

from fastapi.testclient import TestClient

from app.config import settings
from app.main import app
from tests.valid_upload_test_bytes import VALID_TEST_JPEG_BYTES

_TEST_PHOTO_BYTES = VALID_TEST_JPEG_BYTES
_TEST_PHOTO_TYPE = "image/jpeg"


def _photo_file() -> tuple[str, io.BytesIO, str]:
    return ("user.jpg", io.BytesIO(_TEST_PHOTO_BYTES), _TEST_PHOTO_TYPE)


class ProductionAuthTests(unittest.TestCase):
    def setUp(self) -> None:
        self.client = TestClient(app)

    @patch.object(settings, "environment", "production")
    def test_production_balance_without_authorization_returns_401(self) -> None:
        response = self.client.get("/balance")
        self.assertEqual(response.status_code, 401)
        self.assertEqual(response.json()["detail"], "Authorization required")

    @patch.object(settings, "environment", "production")
    def test_production_generations_without_authorization_returns_401(self) -> None:
        response = self.client.get("/generations")
        self.assertEqual(response.status_code, 401)

    @patch.object(settings, "environment", "production")
    @patch("app.main.photo_generation_service")
    def test_production_generate_with_photo_without_authorization_returns_401(
        self,
        mock_service: unittest.mock.MagicMock,
    ) -> None:
        mock_service.generate.return_value = (
            "https://cvzzceastvlbcxsckoqd.supabase.co/storage/v1/object/public/"
            "generated-images/generations/user/test.jpg"
        )
        response = self.client.post(
            "/generate-with-photo",
            data={"description": "Portrait prompt"},
            files={"photo": _photo_file()},
        )
        self.assertEqual(response.status_code, 401)
        mock_service.generate.assert_not_called()

    @patch.object(settings, "environment", "production")
    @patch.object(settings, "test_user_id", "legacy-test-user-id")
    def test_production_with_test_user_id_is_not_ready(self) -> None:
        response = self.client.get("/ready")
        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertEqual(body["status"], "not_ready")
        self.assertFalse(body["checks"]["production_safe"])

    @patch.object(settings, "environment", "production")
    @patch.object(settings, "test_user_id", "legacy-test-user-id")
    def test_production_never_uses_test_user_id_fallback(self) -> None:
        response = self.client.get("/balance")
        self.assertEqual(response.status_code, 401)

    @patch.object(settings, "environment", "development")
    @patch.object(settings, "test_user_id", "dev-test-user-id")
    @patch("app.main.get_generations_by_user_id", return_value=[])
    @patch("app.main._ensure_profile_for_user")
    def test_development_test_user_fallback_allows_generations_list(
        self,
        _mock_ensure_profile: unittest.mock.MagicMock,
        _mock_get_generations: unittest.mock.MagicMock,
    ) -> None:
        response = self.client.get("/generations")
        self.assertEqual(response.status_code, 200)
        _mock_get_generations.assert_called_once_with("dev-test-user-id", limit=20)


if __name__ == "__main__":
    unittest.main()
