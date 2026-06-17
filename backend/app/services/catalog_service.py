"""Load template and photoshoot catalogs from JSON files under ``app/catalog/``."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

_CATALOG_DIR = Path(__file__).resolve().parent.parent / "catalog"
_CATALOG_VERSION = "1"


def _catalog_path(filename: str) -> Path:
    return _CATALOG_DIR / filename


def _read_catalog_array(filename: str) -> list[dict[str, Any]]:
    path = _catalog_path(filename)
    if not path.is_file():
        raise FileNotFoundError(f"Catalog file not found: {path}")

    try:
        raw = path.read_text(encoding="utf-8")
    except OSError as exc:
        raise RuntimeError(f"Failed to read catalog file: {path}") from exc

    try:
        data = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise ValueError(f"Invalid JSON in catalog file: {path}") from exc

    if not isinstance(data, list):
        raise ValueError(f"Catalog file must contain a JSON array: {path}")

    return data


def _active_sorted(items: list[dict[str, Any]]) -> list[dict[str, Any]]:
    active = [item for item in items if item.get("isActive", True) is True]
    active.sort(key=lambda item: item.get("sortOrder", 0))
    return active


def load_templates_catalog() -> dict[str, Any]:
    items = _active_sorted(_read_catalog_array("templates.json"))
    return {
        "items": items,
        "source": "backend",
        "version": _CATALOG_VERSION,
    }


def load_photoshoots_catalog() -> dict[str, Any]:
    items = _active_sorted(_read_catalog_array("photoshoots.json"))
    return {
        "items": items,
        "source": "backend",
        "version": _CATALOG_VERSION,
    }


_photoshoot_catalog_by_id: dict[str, dict[str, Any]] | None = None


def _photoshoot_catalog_map() -> dict[str, dict[str, Any]]:
    global _photoshoot_catalog_by_id
    if _photoshoot_catalog_by_id is None:
        items = _read_catalog_array("photoshoots.json")
        _photoshoot_catalog_by_id = {
            str(item["id"]): item
            for item in items
            if isinstance(item, dict) and item.get("id")
        }
    return _photoshoot_catalog_by_id


def get_photoshoot_catalog_item(style_id: str) -> dict[str, Any] | None:
    """Return raw catalog entry for photoshoot generation (prompt / framePrompts)."""
    normalized = (style_id or "").strip()
    if not normalized:
        return None
    catalog = _photoshoot_catalog_map()
    if normalized in catalog:
        return catalog[normalized]
    return None


def invalidate_photoshoot_catalog_cache() -> None:
    """Clear in-memory catalog map (tests / hot reload)."""
    global _photoshoot_catalog_by_id
    _photoshoot_catalog_by_id = None
