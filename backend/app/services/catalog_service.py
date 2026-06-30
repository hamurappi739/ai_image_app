"""Load template and photoshoot catalogs from JSON files under ``app/catalog/``."""

from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from app.services.catalog_preview_urls import (
    enrich_photoshoot_catalog_item,
    enrich_template_catalog_item,
)

_CATALOG_DIR = Path(__file__).resolve().parent.parent / "catalog"
_CATALOG_META_PATH = _CATALOG_DIR / "catalog_meta.json"
_DEFAULT_CATALOG_VERSION = "1"


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


def _read_catalog_meta() -> dict[str, Any]:
    if not _CATALOG_META_PATH.is_file():
        return {
            "catalogVersion": _DEFAULT_CATALOG_VERSION,
            "updatedAt": datetime.now(timezone.utc).isoformat(),
        }

    try:
        raw = _CATALOG_META_PATH.read_text(encoding="utf-8")
        data = json.loads(raw)
    except (OSError, json.JSONDecodeError):
        return {
            "catalogVersion": _DEFAULT_CATALOG_VERSION,
            "updatedAt": datetime.now(timezone.utc).isoformat(),
        }

    if not isinstance(data, dict):
        return {
            "catalogVersion": _DEFAULT_CATALOG_VERSION,
            "updatedAt": datetime.now(timezone.utc).isoformat(),
        }

    catalog_version = data.get("catalogVersion")
    updated_at = data.get("updatedAt")
    return {
        "catalogVersion": (
            str(catalog_version).strip()
            if isinstance(catalog_version, str) and catalog_version.strip()
            else _DEFAULT_CATALOG_VERSION
        ),
        "updatedAt": (
            str(updated_at).strip()
            if isinstance(updated_at, str) and updated_at.strip()
            else datetime.now(timezone.utc).isoformat()
        ),
    }


def _catalog_response_meta() -> dict[str, str]:
    meta = _read_catalog_meta()
    return {
        "catalogVersion": meta["catalogVersion"],
        "updatedAt": meta["updatedAt"],
    }


def load_templates_catalog() -> dict[str, Any]:
    items = [
        enrich_template_catalog_item(item)
        for item in _active_sorted(_read_catalog_array("templates.json"))
    ]
    return {
        "items": items,
        "source": "backend",
        "version": _DEFAULT_CATALOG_VERSION,
        **_catalog_response_meta(),
    }


def load_photoshoots_catalog() -> dict[str, Any]:
    items = [
        enrich_photoshoot_catalog_item(item)
        for item in _active_sorted(_read_catalog_array("photoshoots.json"))
    ]
    return {
        "items": items,
        "source": "backend",
        "version": _DEFAULT_CATALOG_VERSION,
        **_catalog_response_meta(),
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


_template_catalog_by_id: dict[str, dict[str, Any]] | None = None


def _template_catalog_map() -> dict[str, dict[str, Any]]:
    global _template_catalog_by_id
    if _template_catalog_by_id is None:
        items = _read_catalog_array("templates.json")
        _template_catalog_by_id = {
            str(item["id"]): item
            for item in items
            if isinstance(item, dict) and item.get("id")
        }
    return _template_catalog_by_id


def get_template_catalog_item(template_id: str) -> dict[str, Any] | None:
    normalized = (template_id or "").strip()
    if not normalized:
        return None
    return _template_catalog_map().get(normalized)


def invalidate_template_catalog_cache() -> None:
    """Clear in-memory template catalog map (tests / hot reload)."""
    global _template_catalog_by_id
    _template_catalog_by_id = None
