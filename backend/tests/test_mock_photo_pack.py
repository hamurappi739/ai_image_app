"""Tests for POST /payments/mock/photo-pack."""

from __future__ import annotations

import unittest
from unittest.mock import MagicMock, patch

from fastapi.testclient import TestClient

from app.auth import CurrentUser, get_current_user
from app.config import settings
from app.main import app

_TEST_USER = CurrentUser(id="mock-pack-user", email="mock@example.com")


def _profile(*, paid_images: int = 0, free_used: int = 0) -> dict:
    return {
        "id": _TEST_USER.id,
        "free_generations_used": free_used,
        "paid_image_generations": paid_images,
        "paid_photoshoots": 0,
    }


class MockPhotoPackEndpointTests(unittest.TestCase):
    def setUp(self) -> None:
        app.dependency_overrides[get_current_user] = lambda: _TEST_USER
        self.client = TestClient(app)

    def tearDown(self) -> None:
        app.dependency_overrides.clear()

    def test_no_auth_returns_401(self) -> None:
        app.dependency_overrides.clear()
        with patch.object(settings, "environment", "production"), patch.object(
            settings, "test_user_id", None
        ), patch.object(settings, "enable_mock_payments", True):
            response = self.client.post(
                "/payments/mock/photo-pack",
                json={"package_id": "photos_20"},
            )
        self.assertEqual(response.status_code, 401)

    def test_disabled_in_production_without_flag_returns_404(self) -> None:
        with patch.object(settings, "environment", "production"), patch.object(
            settings, "enable_mock_payments", False
        ):
            response = self.client.post(
                "/payments/mock/photo-pack",
                json={"package_id": "photos_20"},
            )
        self.assertEqual(response.status_code, 404)

    def test_enabled_in_production_with_flag(self) -> None:
        with patch.object(settings, "environment", "production"), patch.object(
            settings, "enable_mock_payments", True
        ), patch(
            "app.routes.payments.mock_credit_photo_pack",
        ) as mock_credit:
            mock_credit.return_value = MagicMock(
                package_id="package_499_20_images",
                photos_added=20,
                balance={
                    "free_generations_limit": 3,
                    "free_generations_used": 0,
                    "free_generations_remaining": 3,
                    "paid_image_generations": 20,
                    "paid_photoshoots": 0,
                    "total_available_images": 23,
                    "available_photos": 23,
                    "photoshoot_image_cost": 3,
                    "available_photoshoots_by_images": 6,
                    "consumption_enabled": False,
                },
            )
            response = self.client.post(
                "/payments/mock/photo-pack",
                json={"package_id": "photos_20"},
            )
        self.assertEqual(response.status_code, 200)
        mock_credit.assert_called_once()

    def test_unknown_package_returns_400(self) -> None:
        with patch.object(settings, "environment", "development"):
            response = self.client.post(
                "/payments/mock/photo-pack",
                json={"package_id": "photos_999"},
            )
        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.json()["detail"], "Unknown package_id")

    @patch("app.services.supabase_service.update_profile")
    @patch("app.services.payment_verification.ensure_profile_exists")
    def test_photos_20_adds_twenty_paid_images(
        self,
        mock_ensure: MagicMock,
        mock_update: MagicMock,
    ) -> None:
        profile = _profile(paid_images=5, free_used=1)

        def _apply_update(_user_id: str, updates: dict) -> dict:
            updated = dict(profile)
            updated.update(updates)
            return updated

        mock_ensure.return_value = profile
        mock_update.side_effect = _apply_update

        with patch.object(settings, "environment", "development"), patch.object(
            settings, "enable_credit_consumption", True
        ):
            response = self.client.post(
                "/payments/mock/photo-pack",
                json={"package_id": "photos_20"},
            )

        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertEqual(payload["status"], "credited")
        self.assertEqual(payload["package_id"], "package_499_20_images")
        self.assertEqual(payload["photos_added"], 20)
        self.assertEqual(payload["balance"]["paid_image_generations"], 25)
        self.assertEqual(payload["balance"]["available_photos"], 27)
        self.assertEqual(int(mock_update.call_args[0][1]["paid_image_generations"]), 25)
        self.assertNotIn("free_generations_used", mock_update.call_args[0][1])


if __name__ == "__main__":
    unittest.main()
