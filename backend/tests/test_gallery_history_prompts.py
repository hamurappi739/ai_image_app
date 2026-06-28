"""Gallery/history prompt labels for photoshoots and templates."""

from __future__ import annotations

import io
import unittest
from unittest.mock import MagicMock, patch

from fastapi.testclient import TestClient

from app.config import settings
from app.main import app
from app.services.catalog_service import invalidate_template_catalog_cache
from app.services.photoshoot_service import (
    _photoshoot_history_prompt,
    resolve_photoshoot_user_description,
)
from app.services.photoshoot_style_locks import CUSTOM_PHOTOSHOOT_STYLE_ID
from app.services.photoshoot_styles import PHOTOSHOOT_STYLES
from app.services.template_generation_service import resolve_template_history_prompt

_TEST_PHOTO_BYTES = b"fake-user-photo"
_TEST_PHOTO_TYPE = "image/jpeg"
_SUPABASE_IMAGE_URL = (
    "https://cvzzceastvlbcxsckoqd.supabase.co/storage/v1/object/public/"
    "generated-images/generations/user-1/photo.jpg"
)


def _photo_file() -> tuple[str, io.BytesIO, str]:
    return ("user.jpg", io.BytesIO(_TEST_PHOTO_BYTES), _TEST_PHOTO_TYPE)


class PhotoshootHistoryPromptTests(unittest.TestCase):
    summer_style = PHOTOSHOOT_STYLES["summer_photoshoot"]
    custom_style = PHOTOSHOOT_STYLES[CUSTOM_PHOTOSHOOT_STYLE_ID]

    def test_resolve_photoshoot_user_description_ignores_catalog_style(self) -> None:
        catalog_text = "Создай серию из 3 летних реалистичных фото"
        self.assertIsNone(
            resolve_photoshoot_user_description("summer_photoshoot", catalog_text),
        )

    def test_resolve_photoshoot_user_description_keeps_custom_text(self) -> None:
        user_text = "Soft pastel portrait in a light studio."
        self.assertEqual(
            resolve_photoshoot_user_description(CUSTOM_PHOTOSHOOT_STYLE_ID, user_text),
            user_text,
        )

    def test_catalog_history_prompt_uses_style_title(self) -> None:
        prompt = _photoshoot_history_prompt(
            self.summer_style,
            "ignored catalog prompt text",
            client_style_id="summer_photoshoot",
        )
        self.assertEqual(prompt, "Фотосессия: Летняя фотосессия")

    def test_custom_history_prompt_uses_user_description(self) -> None:
        user_text = "Деловой образ в светлой студии"
        prompt = _photoshoot_history_prompt(
            self.custom_style,
            user_text,
            client_style_id=CUSTOM_PHOTOSHOOT_STYLE_ID,
        )
        self.assertEqual(prompt, f"Своя фотосессия: {user_text}")

    def test_custom_history_prompt_without_description(self) -> None:
        prompt = _photoshoot_history_prompt(
            self.custom_style,
            None,
            client_style_id=CUSTOM_PHOTOSHOOT_STYLE_ID,
        )
        self.assertEqual(prompt, "Своя фотосессия")


class TemplateHistoryPromptTests(unittest.TestCase):
    def setUp(self) -> None:
        invalidate_template_catalog_cache()

    def test_vibrant_look_history_prompt(self) -> None:
        self.assertEqual(
            resolve_template_history_prompt("vibrant_look"),
            "Шаблон: Яркий образ",
        )

    def test_multi_input_templates_use_catalog_title(self) -> None:
        self.assertEqual(
            resolve_template_history_prompt("woman_with_cat"),
            "Шаблон: Фото с кошкой",
        )
        self.assertEqual(
            resolve_template_history_prompt("child_birthday_number"),
            "Шаблон: Ребёнок с цифрой",
        )

    def test_missing_template_id_is_custom_idea(self) -> None:
        self.assertEqual(resolve_template_history_prompt(None), "Своя идея")
        self.assertEqual(resolve_template_history_prompt(""), "Своя идея")
        self.assertEqual(resolve_template_history_prompt("   "), "Своя идея")


class GenerateWithPhotoHistoryPersistTests(unittest.TestCase):
    def setUp(self) -> None:
        invalidate_template_catalog_cache()
        self.client = TestClient(app)

    @patch.object(settings, "supabase_url", "https://cvzzceastvlbcxsckoqd.supabase.co")
    @patch("app.main._optional_user_for_generation")
    @patch("app.main.ensure_profile_exists", return_value={"id": "user-demo-1"})
    @patch("app.main.create_generation_record")
    @patch("app.main.photo_generation_service")
    def test_demo_mode_vibrant_look_saves_template_gallery_label(
        self,
        mock_service: MagicMock,
        mock_create_record: MagicMock,
        _mock_ensure_profile: MagicMock,
        mock_optional_user: MagicMock,
    ) -> None:
        from app.auth import CurrentUser

        mock_optional_user.return_value = CurrentUser(
            id="user-demo-1",
            email="demo@example.com",
        )
        mock_service.generate.return_value = _SUPABASE_IMAGE_URL
        mock_create_record.return_value = {"id": "gen-1"}

        with patch.object(settings, "enable_credit_consumption", False):
            response = self.client.post(
                "/generate-with-photo",
                data={
                    "description": "Full provider prompt with reference block",
                    "template_id": "vibrant_look",
                },
                files={"photo": _photo_file()},
            )

        self.assertEqual(response.status_code, 200)
        mock_create_record.assert_called_once()
        self.assertEqual(
            mock_create_record.call_args.kwargs["prompt"],
            "Шаблон: Яркий образ",
        )

    @patch.object(settings, "supabase_url", "https://cvzzceastvlbcxsckoqd.supabase.co")
    @patch("app.main._optional_user_for_generation")
    @patch("app.main.ensure_profile_exists", return_value={"id": "user-demo-1"})
    @patch("app.main.create_generation_record")
    @patch("app.main.photo_generation_service")
    def test_demo_mode_custom_idea_saves_gallery_label(
        self,
        mock_service: MagicMock,
        mock_create_record: MagicMock,
        _mock_ensure_profile: MagicMock,
        mock_optional_user: MagicMock,
    ) -> None:
        from app.auth import CurrentUser

        mock_optional_user.return_value = CurrentUser(
            id="user-demo-1",
            email="demo@example.com",
        )
        mock_service.generate.return_value = _SUPABASE_IMAGE_URL
        mock_create_record.return_value = {"id": "gen-2"}

        with patch.object(settings, "enable_credit_consumption", False):
            response = self.client.post(
                "/generate-with-photo",
                data={"description": "User custom portrait prompt"},
                files={"photo": _photo_file()},
            )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            mock_create_record.call_args.kwargs["prompt"],
            "Своя идея",
        )

    @patch.object(settings, "supabase_url", "https://cvzzceastvlbcxsckoqd.supabase.co")
    @patch("app.main.consume_generation")
    @patch("app.main.ensure_profile_exists")
    @patch("app.main.photo_generation_service")
    def test_credit_mode_vibrant_look_passes_history_label_to_consume(
        self,
        mock_service: MagicMock,
        mock_ensure_profile: MagicMock,
        mock_consume: MagicMock,
    ) -> None:
        mock_service.generate.return_value = _SUPABASE_IMAGE_URL
        mock_ensure_profile.return_value = {
            "id": "user-demo-1",
            "free_generations_used": 0,
        }
        mock_consume.return_value = {
            "profile": {"id": "user-demo-1", "free_generations_used": 1},
            "payment_type": "free",
        }

        with patch.object(settings, "enable_credit_consumption", True):
            response = self.client.post(
                "/generate-with-photo",
                data={
                    "description": "Provider prompt",
                    "template_id": "vibrant_look",
                },
                files={"photo": _photo_file()},
            )

        self.assertEqual(response.status_code, 200)
        mock_consume.assert_called_once()
        self.assertEqual(mock_consume.call_args.args[2], "Шаблон: Яркий образ")


class PhotoshootGenerateHistoryPersistTests(unittest.TestCase):
    def setUp(self) -> None:
        from app.auth import CurrentUser, get_current_user

        def _override_user() -> CurrentUser:
            return CurrentUser(id="endpoint-test-user", email="u@example.com")

        app.dependency_overrides[get_current_user] = _override_user
        self.client = TestClient(app)

    def tearDown(self) -> None:
        app.dependency_overrides.clear()

    @patch("app.services.photoshoot_service.create_generation_record")
    @patch("app.main.photoshoot_service.generate_photoshoot")
    def test_catalog_photoshoot_ignores_incoming_description_for_history(
        self,
        mock_generate: MagicMock,
        mock_create_record: MagicMock,
    ) -> None:
        from app.services.photoshoot_service import (
            PhotoshootGenerateResult,
            _save_photoshoot_results_to_history,
        )

        def _fake_generate(**kwargs) -> PhotoshootGenerateResult:
            _save_photoshoot_results_to_history(
                user_id=kwargs["user_id"],
                style=kwargs["style"],
                image_urls=[_SUPABASE_IMAGE_URL],
                client_style_id=kwargs["client_style_id"],
                user_description=kwargs.get("user_description"),
                photoshoot_id="ps-summer",
            )
            return PhotoshootGenerateResult(
                image_urls=[_SUPABASE_IMAGE_URL],
                photoshoot_id="ps-summer",
                storage_paths=["path/1.jpg"],
            )

        mock_generate.side_effect = _fake_generate
        mock_create_record.return_value = {"id": "gen-ps-1"}

        with patch.object(settings, "enable_credit_consumption", False), patch.object(
            settings, "enable_photoshoot_generation", True
        ):
            response = self.client.post(
                "/photoshoots/generate",
                data={
                    "style_id": "summer_photoshoot",
                    "style_title": "Летняя фотосессия",
                    "description": "Создай серию из 3 летних реалистичных фото",
                },
                files={"photo": _photo_file()},
            )

        self.assertEqual(response.status_code, 200)
        self.assertIsNone(mock_generate.call_args.kwargs["user_description"])
        mock_create_record.assert_called()
        self.assertEqual(
            mock_create_record.call_args.kwargs["prompt"],
            "Фотосессия: Летняя фотосессия",
        )


if __name__ == "__main__":
    unittest.main()
