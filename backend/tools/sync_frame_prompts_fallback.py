"""Sync photoshoot fallback frame prompts from catalog JSON into photoshoot_prompts.py."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
CATALOG = ROOT / "backend" / "app" / "catalog" / "photoshoots.json"
PROMPTS = ROOT / "backend" / "app" / "services" / "photoshoot_prompts.py"

PHOTOSHOOT_PROMPT_PACK_V1_STYLE_IDS = [
    "urban_portrait",
    "tender_photoshoot",
    "home_portrait",
    "cafe_city",
    "business_brand",
    "travel_portrait",
    "park_walk",
]


def _list_block(style_id: str, prompts: list[str]) -> str:
    lines = [f'    "{style_id}": [']
    for prompt in prompts:
        lines.append(f"        {prompt!r},")
    lines.append("    ],")
    return "\n".join(lines)


def _tuple_block(style_id: str, prompts: list[str]) -> str:
    lines = [f'    "{style_id}": (']
    for prompt in prompts:
        lines.append(f"        {prompt!r},")
    lines.append("    ),")
    return "\n".join(lines)


def _frame_prompts_dict_block(by_id: dict[str, list[str]]) -> str:
    lines = ["FRAME_PROMPTS_BY_STYLE_ID: dict[str, list[str]] = {"]
    for style_id in by_id:
        lines.append(_list_block(style_id, by_id[style_id]))
    lines.append("}")
    return "\n".join(lines)


def _prompt_pack_v1_block(by_id: dict[str, list[str]]) -> str:
    lines = ["PHOTOSHOOT_PROMPT_PACK_V1: dict[str, tuple[str, str, str]] = {"]
    for style_id in PHOTOSHOOT_PROMPT_PACK_V1_STYLE_IDS:
        lines.append(_tuple_block(style_id, by_id[style_id]))
    lines.append("}")
    return "\n".join(lines)


def main() -> None:
    catalog_items = json.loads(CATALOG.read_text(encoding="utf-8"))
    by_id = {item["id"]: item["framePrompts"] for item in catalog_items}

    for style_id, prompts in by_id.items():
        if len(prompts) != 3:
            raise SystemExit(f"{style_id}: expected 3 framePrompts, got {len(prompts)}")

    text = PROMPTS.read_text(encoding="utf-8")

    pack_pattern = (
        r"PHOTOSHOOT_PROMPT_PACK_V1: dict\[str, tuple\[str, str, str\]\] = \{"
        r".*?\n\}"
    )
    text, pack_count = re.subn(
        pack_pattern,
        _prompt_pack_v1_block(by_id),
        text,
        count=1,
        flags=re.DOTALL,
    )
    if pack_count != 1:
        raise SystemExit("Failed to replace PHOTOSHOOT_PROMPT_PACK_V1")

    frame_pattern = r"FRAME_PROMPTS_BY_STYLE_ID: dict\[str, list\[str\]\] = \{.*?\n\}"
    text, frame_count = re.subn(
        frame_pattern,
        _frame_prompts_dict_block(by_id),
        text,
        count=1,
        flags=re.DOTALL,
    )
    if frame_count != 1:
        raise SystemExit("Failed to replace FRAME_PROMPTS_BY_STYLE_ID")

    PROMPTS.write_text(text, encoding="utf-8")
    print(f"synced PHOTOSHOOT_PROMPT_PACK_V1: {len(PHOTOSHOOT_PROMPT_PACK_V1_STYLE_IDS)} styles")
    print(f"synced FRAME_PROMPTS_BY_STYLE_ID: {len(by_id)} styles")


if __name__ == "__main__":
    main()
