"""Stage 3 template catalog: child birthday and balloon templates."""

from __future__ import annotations

import json
import unittest
from pathlib import Path

_BACKEND_ROOT = Path(__file__).resolve().parent.parent
_BACKEND_CATALOG = _BACKEND_ROOT / "app" / "catalog" / "templates.json"
_FRONTEND_CATALOG = _BACKEND_ROOT.parent / "frontend" / "assets" / "catalog" / "templates.json"

_STAGE3_TEMPLATE_IDS = (
    "child_birthday_number",
    "child_name_age",
    "child_memory_birthday",
    "birthday_balloons",
)

_CHILD_INTRO = (
    "You are given one uploaded image. Image 1 is the child photo and must be used "
    "as the identity reference for the child."
)

_MEMORY_INTRO = (
    "You are given two uploaded images. Image 1 is the current child photo"
)


def _load_catalog(path: Path) -> list[dict]:
    with path.open(encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, list):
        raise AssertionError(f"{path} must be a JSON array")
    return data


class TemplatesCatalogStage3Tests(unittest.TestCase):
    def setUp(self) -> None:
        self.backend_by_id = {
            item["id"]: item for item in _load_catalog(_BACKEND_CATALOG)
        }
        self.frontend_by_id = {
            item["id"]: item for item in _load_catalog(_FRONTEND_CATALOG)
        }

    def test_stage3_template_ids_exist_in_both_catalogs(self) -> None:
        for template_id in _STAGE3_TEMPLATE_IDS:
            self.assertIn(template_id, self.backend_by_id, template_id)
            self.assertIn(template_id, self.frontend_by_id, template_id)

    def test_child_birthday_number_requirements(self) -> None:
        item = self.backend_by_id["child_birthday_number"]
        requirements = item["inputRequirements"]
        self.assertEqual(len(requirements["photos"]), 1)
        self.assertEqual(requirements["photos"][0]["field"], "child_photo")
        field_types = [field["type"] for field in requirements["fields"]]
        self.assertEqual(field_types, ["age_number"])
        self.assertIn(_CHILD_INTRO, item["prompt"])
        self.assertIn("{age_number}", item["prompt"])

    def test_child_name_age_requirements(self) -> None:
        item = self.backend_by_id["child_name_age"]
        field_types = [field["type"] for field in item["inputRequirements"]["fields"]]
        self.assertEqual(field_types, ["child_name", "age_number"])
        self.assertIn("{child_name}", item["prompt"])

    def test_child_memory_birthday_requirements(self) -> None:
        item = self.backend_by_id["child_memory_birthday"]
        photo_fields = [photo["field"] for photo in item["inputRequirements"]["photos"]]
        self.assertEqual(photo_fields, ["child_photo", "baby_photo"])
        self.assertIn(_MEMORY_INTRO, item["prompt"])

    def test_birthday_balloons_requirements(self) -> None:
        item = self.backend_by_id["birthday_balloons"]
        prompt = item["prompt"]
        self.assertEqual(item["category"], "Для себя")
        photo_fields = [photo["field"] for photo in item["inputRequirements"]["photos"]]
        self.assertEqual(photo_fields, ["photo"])
        field_types = [field["type"] for field in item["inputRequirements"]["fields"]]
        self.assertEqual(field_types, ["age_number"])
        self.assertTrue(
            prompt.startswith(
                "Use the uploaded photo as the identity reference for the person."
            )
        )
        self.assertIn("foil balloon numbers", prompt)
        self.assertIn("{age_number}", prompt)
        self.assertIn("no cake topper number", prompt.lower())
        self.assertIn("no printed number on the cake", prompt.lower())
        self.assertNotIn("cake topper number {age_number}", prompt.lower())

    def test_frontend_catalog_matches_backend_stage3(self) -> None:
        keys = (
            "id",
            "title",
            "category",
            "shortDescription",
            "prompt",
            "previewAsset",
            "inputRequirements",
        )
        for template_id in _STAGE3_TEMPLATE_IDS:
            backend_item = self.backend_by_id[template_id]
            frontend_item = self.frontend_by_id[template_id]
            for key in keys:
                self.assertEqual(
                    frontend_item.get(key),
                    backend_item.get(key),
                    f"{template_id}.{key}",
                )


if __name__ == "__main__":
    unittest.main()
