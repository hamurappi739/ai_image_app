"""Demo-mode checks: all active catalog photoshoots are free for MVP testing."""

from __future__ import annotations

import json
import unittest
from pathlib import Path

_BACKEND_ROOT = Path(__file__).resolve().parent.parent
_BACKEND_CATALOG = _BACKEND_ROOT / "app" / "catalog" / "photoshoots.json"
_FRONTEND_CATALOG = _BACKEND_ROOT.parent / "frontend" / "assets" / "catalog" / "photoshoots.json"
_EXPECTED_PHOTOSHOOT_COUNT = 15


def _load_catalog(path: Path) -> list[dict]:
    with path.open(encoding="utf-8") as handle:
        data = json.load(handle)
    if not isinstance(data, list):
        raise AssertionError(f"{path} must be a JSON array")
    return data


def _active_photoshoots(items: list[dict]) -> list[dict]:
    return [item for item in items if item.get("isActive", True)]


class PhotoshootCatalogDemoModeTests(unittest.TestCase):
    def test_backend_catalog_demo_mode(self) -> None:
        items = _load_catalog(_BACKEND_CATALOG)
        active = _active_photoshoots(items)
        self.assertEqual(len(active), _EXPECTED_PHOTOSHOOT_COUNT)
        for item in active:
            self.assertTrue(item.get("isFree"), f"{item['id']} must be isFree=true")
            self.assertEqual(item.get("priceImages"), 3, f"{item['id']} priceImages")
            preview_assets = item.get("previewAssets")
            self.assertIsInstance(preview_assets, list)
            self.assertEqual(len(preview_assets), 3, f"{item['id']} previewAssets count")

    def test_frontend_catalog_matches_backend_preview_assets(self) -> None:
        backend_items = {item["id"]: item for item in _load_catalog(_BACKEND_CATALOG)}
        frontend_items = {item["id"]: item for item in _load_catalog(_FRONTEND_CATALOG)}
        self.assertEqual(len(frontend_items), _EXPECTED_PHOTOSHOOT_COUNT)
        for style_id, backend_item in backend_items.items():
            frontend_item = frontend_items[style_id]
            self.assertEqual(
                frontend_item.get("previewAssets"),
                backend_item.get("previewAssets"),
                style_id,
            )
            self.assertTrue(frontend_item.get("isFree"), f"{style_id} frontend isFree")


if __name__ == "__main__":
    unittest.main()
