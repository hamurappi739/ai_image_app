"""Stage 1 template catalog: five new portrait cards and woman_with_cat block."""

from __future__ import annotations

import json
import unittest
from pathlib import Path

_BACKEND_ROOT = Path(__file__).resolve().parent.parent
_BACKEND_CATALOG = _BACKEND_ROOT / "app" / "catalog" / "templates.json"
_FRONTEND_CATALOG = _BACKEND_ROOT.parent / "frontend" / "assets" / "catalog" / "templates.json"

_STAGE1_TEMPLATE_IDS = (
    "volcanic_gray_rock",
    "ocean_portrait",
    "beach_sand_portrait",
    "white_dress_yellow_meadow",
    "woman_with_cat",
)

_SINGLE_PHOTO_TEMPLATE_IDS = _STAGE1_TEMPLATE_IDS[:-1]

_IDENTITY_INTRO = (
    "You are given one uploaded user photo. Use it as the identity reference. "
    "Keep the same person: face, age, facial proportions, skin tone, hairstyle "
    "direction and natural expression. Transform only the clothes, background, "
    "pose, lighting and style described below."
)


def _load_catalog(path: Path) -> list[dict]:
    with path.open(encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, list):
        raise AssertionError(f"{path} must be a JSON array")
    return data


class TemplatesCatalogStage1Tests(unittest.TestCase):
    def setUp(self) -> None:
        self.backend_by_id = {
            item["id"]: item for item in _load_catalog(_BACKEND_CATALOG)
        }
        self.frontend_by_id = {
            item["id"]: item for item in _load_catalog(_FRONTEND_CATALOG)
        }

    def test_stage1_template_ids_exist_in_both_catalogs(self) -> None:
        for template_id in _STAGE1_TEMPLATE_IDS:
            self.assertIn(template_id, self.backend_by_id, template_id)
            self.assertIn(template_id, self.frontend_by_id, template_id)

    def test_single_photo_templates_have_identity_intro_and_preview(self) -> None:
        for template_id in _SINGLE_PHOTO_TEMPLATE_IDS:
            for catalog in (self.backend_by_id, self.frontend_by_id):
                item = catalog[template_id]
                prompt = item.get("prompt", "")
                self.assertTrue(
                    prompt.startswith(_IDENTITY_INTRO),
                    f"{template_id} prompt must start with identity intro",
                )
                self.assertEqual(
                    item.get("previewAsset"),
                    f"assets/previews/templates/{template_id}.jpg",
                    template_id,
                )
                self.assertNotEqual(prompt.strip(), "", template_id)

    def test_woman_with_cat_is_unblocked_with_two_image_prompt(self) -> None:
        for catalog in (self.backend_by_id, self.frontend_by_id):
            item = catalog["woman_with_cat"]
            self.assertFalse(item.get("generationBlocked"), "woman_with_cat unblocked")
            prompt = item.get("prompt", "")
            self.assertIn("Image 2 is the pet photo", prompt)
            requirements = item.get("inputRequirements")
            self.assertIsInstance(requirements, dict)
            photos = requirements.get("photos")
            self.assertEqual(len(photos), 2)
            fields = {photo["field"] for photo in photos}
            self.assertEqual(fields, {"photo", "pet_photo"})

    def test_frontend_catalog_matches_backend_stage1_fields(self) -> None:
        keys = (
            "id",
            "title",
            "category",
            "shortDescription",
            "prompt",
            "previewAsset",
            "referenceAsset",
            "priceImages",
            "isActive",
            "sortOrder",
            "generationBlocked",
            "generationBlockedMessage",
        )
        for template_id in _STAGE1_TEMPLATE_IDS:
            backend_item = self.backend_by_id[template_id]
            frontend_item = self.frontend_by_id[template_id]
            for key in keys:
                if key in backend_item or key in frontend_item:
                    self.assertEqual(
                        frontend_item.get(key),
                        backend_item.get(key),
                        f"{template_id}.{key}",
                    )


if __name__ == "__main__":
    unittest.main()
