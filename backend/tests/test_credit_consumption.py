"""Credit consumption rules and pre-generation balance guards."""

from __future__ import annotations

import io
import unittest
from unittest.mock import MagicMock, patch

from fastapi import HTTPException
from fastapi.testclient import TestClient

from app.auth import CurrentUser, get_current_user
from app.config import settings
from app.main import app
from app.services.balance_service import (
    PHOTOSHOOT_IMAGE_COST,
    build_balance_response,
    consume_image_credits,
    consume_photoshoot,
    determine_image_payment,
    determine_photoshoot_payment,
    paid_image_balance,
    total_available_images,
)
from app.services.photoshoot_service import PhotoshootGenerateResult

_ALLOWED_HOST = "cvzzceastvlbcxsckoqd.supabase.co"
_SUPABASE_IMAGE_URL = (
    f"https://{_ALLOWED_HOST}/storage/v1/object/public/"
    "generated-images/generations/user-1/photo.jpg"
)
_TEST_USER = CurrentUser(id="credit-test-user", email="credit@example.com")
_TEST_PHOTO_BYTES = b"fake-user-photo"
_TEST_JPEG_BYTES = b"\xff\xd8\xff\xe0" + b"\x00" * 16
_FREE_LIMIT = 3


def _photo_file() -> tuple[str, io.BytesIO, str]:
    return ("user.jpg", io.BytesIO(_TEST_PHOTO_BYTES), "image/jpeg")


def _profile(
    *,
    free_used: int = 0,
    paid_images: int = 0,
) -> dict:
    return {
        "id": _TEST_USER.id,
        "free_generations_used": free_used,
        "paid_image_generations": paid_images,
        "paid_photoshoots": 0,
    }


class BalanceServiceRulesTests(unittest.TestCase):
    def test_free_generations_apply_to_single_image_only(self) -> None:
        profile = _profile(free_used=0, paid_images=0)
        self.assertTrue(determine_image_payment(profile, _FREE_LIMIT, 1)["allowed"])
        self.assertFalse(
            determine_photoshoot_payment(profile, _FREE_LIMIT)["allowed"]
        )

    @patch("app.services.supabase_service.update_profile")
    def test_photoshoot_requires_paid_images_not_free_quota(
        self,
        mock_update: MagicMock,
    ) -> None:
        profile = _profile(free_used=0, paid_images=PHOTOSHOOT_IMAGE_COST)
        self.assertTrue(
            determine_photoshoot_payment(profile, _FREE_LIMIT)["allowed"]
        )
        mock_update.return_value = _profile(free_used=0, paid_images=0)
        updated = consume_photoshoot(profile, _FREE_LIMIT)
        self.assertEqual(paid_image_balance(updated), 0)
        self.assertEqual(int(updated["free_generations_used"]), 0)

    @patch("app.services.supabase_service.update_profile")
    def test_single_generation_uses_free_before_paid(
        self,
        mock_update: MagicMock,
    ) -> None:
        profile = _profile(free_used=2, paid_images=5)
        mock_update.return_value = _profile(free_used=3, paid_images=5)
        updated = consume_image_credits(profile, _FREE_LIMIT, 1)
        self.assertEqual(int(updated["free_generations_used"]), 3)
        self.assertEqual(paid_image_balance(updated), 5)

    def test_available_photoshoots_uses_paid_balance_only(self) -> None:
        profile = _profile(free_used=0, paid_images=7)
        payload = build_balance_response(profile, _FREE_LIMIT, consumption_enabled=True)
        self.assertEqual(payload["available_photoshoots_by_images"], 2)
        self.assertEqual(payload["paid_image_generations"], 7)
        self.assertEqual(payload["available_photos"], 10)
        self.assertEqual(payload["total_available_images"], 10)

    def test_available_photos_includes_free_and_paid_for_singles(self) -> None:
        profile = _profile(free_used=1, paid_images=2)
        payload = build_balance_response(profile, _FREE_LIMIT, consumption_enabled=True)
        self.assertEqual(payload["free_generations_remaining"], 2)
        self.assertEqual(payload["available_photos"], 4)
        self.assertEqual(total_available_images(profile, _FREE_LIMIT), 4)

    def test_paid_photoshoots_field_is_not_used_for_debit(self) -> None:
        profile = _profile(free_used=0, paid_images=0)
        profile["paid_photoshoots"] = 5
        self.assertFalse(
            determine_photoshoot_payment(profile, _FREE_LIMIT)["allowed"]
        )


class GenerateWithPhotoCreditTests(unittest.TestCase):
    def setUp(self) -> None:
        app.dependency_overrides[get_current_user] = lambda: _TEST_USER
        self.client = TestClient(app)

    def tearDown(self) -> None:
        app.dependency_overrides.clear()

    @patch.object(settings, "supabase_url", f"https://{_ALLOWED_HOST}")
    @patch("app.main.photo_generation_service")
    @patch("app.main.ensure_profile_exists")
    def test_zero_balance_returns_402_without_calling_provider(
        self,
        mock_ensure_profile: MagicMock,
        mock_service: MagicMock,
    ) -> None:
        mock_ensure_profile.return_value = _profile(free_used=3, paid_images=0)

        with patch.object(settings, "enable_credit_consumption", True):
            response = self.client.post(
                "/generate-with-photo",
                data={"description": "Portrait"},
                files={"photo": _photo_file()},
            )

        self.assertEqual(response.status_code, 402)
        self.assertEqual(response.json()["detail"], "insufficient_images")
        mock_service.generate.assert_not_called()

    @patch.object(settings, "supabase_url", f"https://{_ALLOWED_HOST}")
    @patch("app.services.credits_service.insert_credit_transaction", return_value={"id": "tx-1"})
    @patch(
        "app.services.credits_service.create_generation_record",
        return_value={"id": "gen-1"},
    )
    @patch("app.services.supabase_service.update_profile")
    @patch("app.main._optional_user_for_generation", return_value=_TEST_USER)
    @patch("app.main.photo_generation_service")
    @patch("app.main.ensure_profile_exists")
    def test_balance_one_debits_paid_image_after_success(
        self,
        mock_ensure_profile: MagicMock,
        mock_service: MagicMock,
        _mock_optional_user: MagicMock,
        mock_update: MagicMock,
        _mock_create: MagicMock,
        _mock_tx: MagicMock,
    ) -> None:
        profile = _profile(free_used=3, paid_images=1)

        def _apply_update(_user_id: str, updates: dict) -> dict:
            updated = dict(profile)
            updated.update(updates)
            return updated

        mock_ensure_profile.return_value = profile
        mock_update.side_effect = _apply_update
        mock_service.generate.return_value = _SUPABASE_IMAGE_URL

        with patch.object(settings, "enable_credit_consumption", True):
            response = self.client.post(
                "/generate-with-photo",
                data={"description": "Portrait"},
                files={"photo": _photo_file()},
            )

        self.assertEqual(response.status_code, 200)
        mock_service.generate.assert_called_once()
        mock_update.assert_called_once()
        self.assertEqual(
            mock_update.call_args[0][1]["paid_image_generations"],
            0,
        )
        balance = response.json()["balance"]
        self.assertEqual(balance["paid_image_generations"], 0)
        self.assertEqual(balance["available_photos"], 0)

    @patch("app.main.ensure_profile_exists", return_value={"id": _TEST_USER.id})
    @patch("app.main.create_generation_record", return_value={"id": "gen-demo"})
    @patch("app.services.supabase_service.update_profile")
    @patch("app.main._optional_user_for_generation", return_value=_TEST_USER)
    @patch("app.main.photo_generation_service")
    def test_demo_mode_skips_debit_for_single_generation(
        self,
        mock_service: MagicMock,
        _mock_optional_user: MagicMock,
        mock_update: MagicMock,
        _mock_create: MagicMock,
        _mock_ensure: MagicMock,
    ) -> None:
        mock_service.generate.return_value = _SUPABASE_IMAGE_URL

        with patch.object(settings, "enable_credit_consumption", False):
            response = self.client.post(
                "/generate-with-photo",
                data={"description": "Portrait"},
                files={"photo": _photo_file()},
            )

        self.assertEqual(response.status_code, 200)
        mock_update.assert_not_called()

    @patch.object(settings, "supabase_url", f"https://{_ALLOWED_HOST}")
    @patch("app.main.consume_generation")
    @patch("app.main.photo_generation_service")
    @patch("app.main.ensure_profile_exists")
    def test_provider_error_does_not_consume(
        self,
        mock_ensure_profile: MagicMock,
        mock_service: MagicMock,
        mock_consume: MagicMock,
    ) -> None:
        mock_ensure_profile.return_value = _profile(free_used=0, paid_images=1)
        mock_service.generate.side_effect = HTTPException(status_code=503, detail="down")

        with patch.object(settings, "enable_credit_consumption", True):
            response = self.client.post(
                "/generate-with-photo",
                data={"description": "Portrait"},
                files={"photo": _photo_file()},
            )

        self.assertEqual(response.status_code, 503)
        mock_consume.assert_not_called()


class PhotoshootCreditTests(unittest.TestCase):
    _SUCCESS_RESULT = PhotoshootGenerateResult(
        image_urls=[
            "https://cdn.example/0.png",
            "https://cdn.example/1.png",
            "https://cdn.example/2.png",
        ],
        photoshoot_id="ps-credit",
        storage_paths=["a", "b", "c"],
    )

    def setUp(self) -> None:
        app.dependency_overrides[get_current_user] = lambda: _TEST_USER
        self.client = TestClient(app)

    def tearDown(self) -> None:
        app.dependency_overrides.clear()

    @patch("app.main.photoshoot_service.generate_photoshoot")
    @patch("app.main.ensure_profile_exists")
    @patch("app.main.settings")
    def test_balance_two_returns_402_without_generation(
        self,
        mock_settings: MagicMock,
        mock_ensure_profile: MagicMock,
        mock_generate: MagicMock,
    ) -> None:
        mock_settings.enable_photoshoot_generation = True
        mock_settings.enable_credit_consumption = True
        mock_settings.free_generations_limit = _FREE_LIMIT
        mock_ensure_profile.return_value = _profile(
            free_used=0,
            paid_images=PHOTOSHOOT_IMAGE_COST - 1,
        )

        response = self.client.post(
            "/photoshoots/generate",
            data={"style_id": "studio_portrait"},
            files={"photo": ("photo.jpg", io.BytesIO(_TEST_JPEG_BYTES), "image/jpeg")},
        )

        self.assertEqual(response.status_code, 402)
        self.assertEqual(response.json()["detail"], "insufficient_images")
        mock_generate.assert_not_called()

    @patch("app.services.supabase_service.update_profile")
    @patch("app.main.photoshoot_service.generate_photoshoot")
    @patch("app.main.ensure_profile_exists")
    @patch("app.main.settings")
    def test_balance_three_debits_paid_images_after_success(
        self,
        mock_settings: MagicMock,
        mock_ensure_profile: MagicMock,
        mock_generate: MagicMock,
        mock_update: MagicMock,
    ) -> None:
        mock_settings.enable_photoshoot_generation = True
        mock_settings.enable_credit_consumption = True
        mock_settings.free_generations_limit = _FREE_LIMIT
        profile = _profile(free_used=3, paid_images=PHOTOSHOOT_IMAGE_COST)

        def _apply_update(_user_id: str, updates: dict) -> dict:
            updated = dict(profile)
            updated.update(updates)
            return updated

        mock_ensure_profile.return_value = profile
        mock_update.side_effect = _apply_update
        mock_generate.return_value = self._SUCCESS_RESULT

        response = self.client.post(
            "/photoshoots/generate",
            data={"style_id": "studio_portrait"},
            files={"photo": ("photo.jpg", io.BytesIO(_TEST_JPEG_BYTES), "image/jpeg")},
        )

        self.assertEqual(response.status_code, 200)
        mock_generate.assert_called_once()
        mock_update.assert_called_once_with(
            _TEST_USER.id,
            {"paid_image_generations": 0},
        )
        balance = response.json()["balance"]
        self.assertEqual(balance["paid_image_generations"], 0)
        self.assertEqual(balance["available_photos"], 0)
        self.assertEqual(balance["free_generations_remaining"], 0)

    @patch("app.main.consume_photoshoot")
    @patch("app.main.photoshoot_service.generate_photoshoot")
    @patch("app.main.ensure_profile_exists")
    @patch("app.main.settings")
    def test_photoshoot_partial_fail_no_debit(
        self,
        mock_settings: MagicMock,
        mock_ensure_profile: MagicMock,
        mock_generate: MagicMock,
        mock_consume: MagicMock,
    ) -> None:
        mock_settings.enable_photoshoot_generation = True
        mock_settings.enable_credit_consumption = True
        mock_settings.free_generations_limit = _FREE_LIMIT
        mock_ensure_profile.return_value = _profile(
            paid_images=PHOTOSHOOT_IMAGE_COST,
        )
        mock_generate.side_effect = HTTPException(
            status_code=502,
            detail="partial_upload:2/3",
        )

        response = self.client.post(
            "/photoshoots/generate",
            data={"style_id": "studio_portrait"},
            files={"photo": ("photo.jpg", io.BytesIO(_TEST_JPEG_BYTES), "image/jpeg")},
        )

        self.assertEqual(response.status_code, 502)
        mock_consume.assert_not_called()

    @patch("app.main.consume_photoshoot")
    @patch("app.main.photoshoot_service.generate_photoshoot")
    @patch("app.main.ensure_profile_exists")
    @patch("app.main.settings")
    def test_generation_failure_does_not_debit(
        self,
        mock_settings: MagicMock,
        mock_ensure_profile: MagicMock,
        mock_generate: MagicMock,
        mock_consume: MagicMock,
    ) -> None:
        mock_settings.enable_photoshoot_generation = True
        mock_settings.enable_credit_consumption = True
        mock_settings.free_generations_limit = _FREE_LIMIT
        mock_ensure_profile.return_value = _profile(
            paid_images=PHOTOSHOOT_IMAGE_COST,
        )
        mock_generate.side_effect = HTTPException(status_code=502, detail="fail")

        response = self.client.post(
            "/photoshoots/generate",
            data={"style_id": "studio_portrait"},
            files={"photo": ("photo.jpg", io.BytesIO(_TEST_JPEG_BYTES), "image/jpeg")},
        )

        self.assertEqual(response.status_code, 502)
        mock_consume.assert_not_called()

    @patch("app.main.consume_photoshoot")
    @patch("app.main.photoshoot_service.generate_photoshoot")
    @patch("app.main.ensure_profile_exists")
    @patch("app.main.settings")
    def test_demo_mode_skips_debit(
        self,
        mock_settings: MagicMock,
        mock_ensure_profile: MagicMock,
        mock_generate: MagicMock,
        mock_consume: MagicMock,
    ) -> None:
        mock_settings.enable_photoshoot_generation = True
        mock_settings.enable_credit_consumption = False
        mock_settings.free_generations_limit = _FREE_LIMIT
        mock_generate.return_value = self._SUCCESS_RESULT

        response = self.client.post(
            "/photoshoots/generate",
            data={"style_id": "studio_portrait"},
            files={"photo": ("photo.jpg", io.BytesIO(_TEST_JPEG_BYTES), "image/jpeg")},
        )

        self.assertEqual(response.status_code, 200)
        mock_consume.assert_not_called()
        mock_ensure_profile.assert_not_called()


class GenerateEndpointCreditTests(unittest.TestCase):
    def setUp(self) -> None:
        app.dependency_overrides[get_current_user] = lambda: _TEST_USER
        self.client = TestClient(app)

    def tearDown(self) -> None:
        app.dependency_overrides.clear()

    @patch("app.main.generate_image")
    @patch("app.main.ensure_profile_exists")
    def test_generate_zero_balance_402_before_provider(
        self,
        mock_ensure_profile: MagicMock,
        mock_generate_image: MagicMock,
    ) -> None:
        mock_ensure_profile.return_value = _profile(free_used=3, paid_images=0)

        with patch.object(settings, "enable_credit_consumption", True):
            response = self.client.post(
                "/generate",
                json={"prompt": "A portrait"},
            )

        self.assertEqual(response.status_code, 402)
        mock_generate_image.assert_not_called()

    @patch.object(settings, "supabase_url", f"https://{_ALLOWED_HOST}")
    @patch("app.services.credits_service.insert_credit_transaction", return_value={"id": "tx-1"})
    @patch(
        "app.services.credits_service.create_generation_record",
        return_value={"id": "gen-1"},
    )
    @patch("app.services.supabase_service.update_profile")
    @patch("app.main.generate_image")
    @patch("app.main.ensure_profile_exists")
    @patch("app.main._optional_user_for_generation", return_value=_TEST_USER)
    def test_generate_balance_one_debits_after_success(
        self,
        _mock_optional_user: MagicMock,
        mock_ensure_profile: MagicMock,
        mock_generate_image: MagicMock,
        mock_update: MagicMock,
        _mock_create: MagicMock,
        _mock_tx: MagicMock,
    ) -> None:
        profile = _profile(free_used=3, paid_images=1)

        def _apply_update(_user_id: str, updates: dict) -> dict:
            updated = dict(profile)
            updated.update(updates)
            return updated

        mock_ensure_profile.return_value = profile
        mock_update.side_effect = _apply_update
        mock_generate_image.return_value = _SUPABASE_IMAGE_URL

        with patch.object(settings, "enable_credit_consumption", True):
            response = self.client.post(
                "/generate",
                json={"prompt": "A portrait"},
            )

        self.assertEqual(response.status_code, 200)
        mock_generate_image.assert_called_once()
        mock_update.assert_called_once()
        self.assertEqual(
            mock_update.call_args[0][1]["paid_image_generations"],
            0,
        )
        balance = response.json()["balance"]
        self.assertEqual(balance["paid_image_generations"], 0)
        self.assertEqual(balance["available_photos"], 0)

    @patch("app.services.supabase_service.update_profile")
    @patch("app.main.generate_image")
    @patch("app.main.ensure_profile_exists")
    @patch("app.main._optional_user_for_generation", return_value=_TEST_USER)
    def test_generate_provider_error_does_not_debit(
        self,
        _mock_optional_user: MagicMock,
        mock_ensure_profile: MagicMock,
        mock_generate_image: MagicMock,
        mock_update: MagicMock,
    ) -> None:
        mock_ensure_profile.return_value = _profile(free_used=0, paid_images=1)
        mock_generate_image.side_effect = HTTPException(status_code=503, detail="down")

        with patch.object(settings, "enable_credit_consumption", True):
            response = self.client.post(
                "/generate",
                json={"prompt": "A portrait"},
            )

        self.assertEqual(response.status_code, 503)
        mock_update.assert_not_called()

    @patch("app.main.ensure_profile_exists", return_value={"id": _TEST_USER.id})
    @patch("app.main.create_generation_record", return_value={"id": "gen-demo"})
    @patch("app.services.supabase_service.update_profile")
    @patch("app.main.generate_image", return_value=_SUPABASE_IMAGE_URL)
    @patch("app.main._optional_user_for_generation", return_value=_TEST_USER)
    def test_generate_demo_mode_skips_debit(
        self,
        _mock_optional_user: MagicMock,
        _mock_generate_image: MagicMock,
        mock_update: MagicMock,
        _mock_create: MagicMock,
        _mock_ensure: MagicMock,
    ) -> None:
        with patch.object(settings, "enable_credit_consumption", False):
            response = self.client.post(
                "/generate",
                json={"prompt": "A portrait"},
            )

        self.assertEqual(response.status_code, 200)
        mock_update.assert_not_called()


class BalanceEndpointTests(unittest.TestCase):
    def setUp(self) -> None:
        app.dependency_overrides[get_current_user] = lambda: _TEST_USER
        self.client = TestClient(app)

    def tearDown(self) -> None:
        app.dependency_overrides.clear()

    @patch("app.main.ensure_profile_exists")
    def test_get_balance_exposes_available_photos_for_ui(
        self,
        mock_ensure_profile: MagicMock,
    ) -> None:
        mock_ensure_profile.return_value = _profile(free_used=1, paid_images=4)

        with patch.object(settings, "enable_credit_consumption", True):
            response = self.client.get("/balance")

        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertEqual(payload["available_photos"], 6)
        self.assertEqual(payload["total_available_images"], 6)
        self.assertEqual(payload["paid_image_generations"], 4)
        self.assertTrue(payload["consumption_enabled"])


if __name__ == "__main__":
    unittest.main()
