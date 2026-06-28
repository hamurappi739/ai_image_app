"""Tests for generation image URL validation and gallery persistence guards."""

from __future__ import annotations

import io
import unittest
from unittest.mock import MagicMock, patch

from fastapi.testclient import TestClient

from app.auth import CurrentUser, get_current_user
from app.config import settings
from app.main import app
from app.services.generation_image_url import (
    filter_persistable_generation_rows,
    is_blocked_generation_placeholder_url,
    should_persist_generation_image_url,
)

_ALLOWED_HOST = "cvzzceastvlbcxsckoqd.supabase.co"
_SUPABASE_IMAGE_URL = (
    f"https://{_ALLOWED_HOST}/storage/v1/object/public/"
    "generated-images/generations/user-1/photo.jpg"
)
_MOCK_CDN_URL = "https://cdn.example.com/generated.png"
_DATA_URL = "data:image/png;base64,iVBORw0KGgo="
_TEST_USER = CurrentUser(id="user-demo-1", email="demo@example.com")
_TEST_PHOTO_BYTES = b"fake-user-photo"
_TEST_PHOTO_TYPE = "image/jpeg"
_MOCK_PROMPT = "Custom portrait prompt"
_GENERATION_ROW = {
    "id": "gen-demo-1",
    "user_id": _TEST_USER.id,
    "prompt": _MOCK_PROMPT,
    "image_url": _SUPABASE_IMAGE_URL,
    "payment_type": "free",
    "photoshoot_id": None,
    "created_at": "2026-05-29T12:00:00+00:00",
}
_LEGACY_MOCK_ROW = {
    **_GENERATION_ROW,
    "id": "gen-legacy-mock",
    "image_url": _MOCK_CDN_URL,
}


def _photo_file() -> tuple[str, io.BytesIO, str]:
    return ("user.jpg", io.BytesIO(_TEST_PHOTO_BYTES), _TEST_PHOTO_TYPE)


class GenerationImageUrlValidationTests(unittest.TestCase):
    @patch.object(settings, "supabase_url", f"https://{_ALLOWED_HOST}")
    def test_should_persist_accepts_supabase_generated_images_url(self) -> None:
        self.assertTrue(should_persist_generation_image_url(_SUPABASE_IMAGE_URL))

    @patch.object(settings, "supabase_url", f"https://{_ALLOWED_HOST}")
    def test_should_persist_rejects_cdn_example(self) -> None:
        self.assertFalse(should_persist_generation_image_url(_MOCK_CDN_URL))

    def test_should_persist_rejects_data_url(self) -> None:
        self.assertTrue(is_blocked_generation_placeholder_url(_DATA_URL))
        self.assertFalse(should_persist_generation_image_url(_DATA_URL))

    def test_should_persist_rejects_placehold_co(self) -> None:
        url = "https://placehold.co/400x600/png?text=Demo"
        self.assertTrue(is_blocked_generation_placeholder_url(url))
        self.assertFalse(should_persist_generation_image_url(url))

    def test_filter_persistable_generation_rows_drops_legacy_mock(self) -> None:
        rows = filter_persistable_generation_rows(
            [_GENERATION_ROW, _LEGACY_MOCK_ROW],
        )
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]["id"], "gen-demo-1")


class DemoGenerationPersistTests(unittest.TestCase):
    def setUp(self) -> None:
        self.client = TestClient(app)
        app.dependency_overrides[get_current_user] = lambda: _TEST_USER

    def tearDown(self) -> None:
        app.dependency_overrides.clear()

    @patch.object(settings, "supabase_url", f"https://{_ALLOWED_HOST}")
    @patch("app.main._optional_user_for_generation", return_value=_TEST_USER)
    @patch("app.main.ensure_profile_exists", return_value={"id": _TEST_USER.id})
    @patch("app.main.consume_generation")
    @patch("app.main.create_generation_record")
    @patch("app.main.photo_generation_service")
    def test_demo_mode_mock_cdn_url_skips_create_generation_record(
        self,
        mock_service: MagicMock,
        mock_create_record: MagicMock,
        mock_consume: MagicMock,
        _mock_ensure_profile: MagicMock,
        _mock_optional_user: MagicMock,
    ) -> None:
        mock_service.generate.return_value = _MOCK_CDN_URL

        with patch.object(settings, "enable_credit_consumption", False):
            response = self.client.post(
                "/generate-with-photo",
                data={"description": _MOCK_PROMPT},
                files={"photo": _photo_file()},
            )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["image_url"], _MOCK_CDN_URL)
        mock_create_record.assert_not_called()
        mock_consume.assert_not_called()

    @patch.object(settings, "supabase_url", f"https://{_ALLOWED_HOST}")
    @patch("app.main._optional_user_for_generation", return_value=_TEST_USER)
    @patch("app.main.ensure_profile_exists", return_value={"id": _TEST_USER.id})
    @patch("app.main.consume_generation")
    @patch("app.main.create_generation_record")
    @patch("app.main.photo_generation_service")
    def test_demo_mode_supabase_url_persists_generation(
        self,
        mock_service: MagicMock,
        mock_create_record: MagicMock,
        mock_consume: MagicMock,
        _mock_ensure_profile: MagicMock,
        _mock_optional_user: MagicMock,
    ) -> None:
        mock_service.generate.return_value = _SUPABASE_IMAGE_URL
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
            prompt="Своя идея",
            image_url=_SUPABASE_IMAGE_URL,
            payment_type="free",
        )
        mock_consume.assert_not_called()

    @patch.object(settings, "supabase_url", f"https://{_ALLOWED_HOST}")
    @patch("app.main._optional_user_for_generation", return_value=_TEST_USER)
    @patch("app.main.ensure_profile_exists", return_value={"id": _TEST_USER.id})
    @patch("app.main._store_generated_image_if_needed", return_value=_SUPABASE_IMAGE_URL)
    @patch("app.main.consume_generation")
    @patch("app.main.create_generation_record")
    @patch("app.main.photo_generation_service")
    def test_demo_mode_data_url_uploaded_before_db_insert(
        self,
        mock_service: MagicMock,
        mock_create_record: MagicMock,
        mock_consume: MagicMock,
        mock_store: MagicMock,
        _mock_ensure_profile: MagicMock,
        _mock_optional_user: MagicMock,
    ) -> None:
        mock_service.generate.return_value = _DATA_URL
        mock_create_record.return_value = _GENERATION_ROW

        with patch.object(settings, "enable_credit_consumption", False):
            response = self.client.post(
                "/generate-with-photo",
                data={"description": _MOCK_PROMPT},
                files={"photo": _photo_file()},
            )

        self.assertEqual(response.status_code, 200)
        mock_store.assert_called_once()
        mock_create_record.assert_called_once_with(
            user_id=_TEST_USER.id,
            prompt="Своя идея",
            image_url=_SUPABASE_IMAGE_URL,
            payment_type="free",
        )

    @patch.object(settings, "supabase_url", f"https://{_ALLOWED_HOST}")
    @patch("app.main._ensure_profile_for_user")
    @patch("app.main.get_generations_by_user_id")
    def test_get_generations_filters_legacy_mock_urls(
        self,
        mock_get_generations: MagicMock,
        _mock_ensure_profile: MagicMock,
    ) -> None:
        mock_get_generations.return_value = [_GENERATION_ROW, _LEGACY_MOCK_ROW]

        response = self.client.get("/generations")

        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertEqual(len(body["generations"]), 1)
        self.assertEqual(body["generations"][0]["image_url"], _SUPABASE_IMAGE_URL)

    @patch.object(settings, "supabase_url", f"https://{_ALLOWED_HOST}")
    @patch("app.main.consume_generation")
    @patch("app.main.create_generation_record")
    @patch("app.main.ensure_profile_exists")
    @patch("app.main.photo_generation_service")
    def test_credit_mode_mock_cdn_url_rejects_consume(
        self,
        mock_service: MagicMock,
        mock_ensure_profile: MagicMock,
        mock_create_record: MagicMock,
        mock_consume: MagicMock,
    ) -> None:
        mock_service.generate.return_value = _MOCK_CDN_URL
        mock_ensure_profile.return_value = {
            "id": _TEST_USER.id,
            "free_generations_used": 0,
        }

        with patch.object(settings, "enable_credit_consumption", True):
            response = self.client.post(
                "/generate-with-photo",
                data={"description": _MOCK_PROMPT},
                files={"photo": _photo_file()},
            )

        self.assertEqual(response.status_code, 500)
        mock_consume.assert_not_called()
        mock_create_record.assert_not_called()

    @patch.object(settings, "supabase_url", f"https://{_ALLOWED_HOST}")
    @patch("app.main.consume_generation")
    @patch("app.main.create_generation_record")
    @patch("app.main.ensure_profile_exists")
    @patch("app.main.photo_generation_service")
    def test_credit_mode_supabase_url_uses_consume(
        self,
        mock_service: MagicMock,
        mock_ensure_profile: MagicMock,
        mock_create_record: MagicMock,
        mock_consume: MagicMock,
    ) -> None:
        mock_service.generate.return_value = _SUPABASE_IMAGE_URL
        mock_ensure_profile.return_value = {
            "id": _TEST_USER.id,
            "free_generations_used": 0,
        }
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
