"""Sync FRAME_PROMPTS_BY_STYLE_ID in photoshoot_prompts.py from catalog JSON."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
CATALOG = ROOT / "backend" / "app" / "catalog" / "photoshoots.json"
PROMPTS = ROOT / "backend" / "app" / "services" / "photoshoot_prompts.py"

INLINE_STYLE_IDS = [
    "business_portrait",
    "studio_portrait",
    "evening_look",
    "premium_portrait",
    "summer_photoshoot",
    "winter_photoshoot",
    "expert_photoshoot",
    "personal_brand",
]


def _block(style_id: str, prompts: list[str]) -> str:
    lines = [f'    "{style_id}": [']
    for prompt in prompts:
        lines.append(f"        {prompt!r},")
    lines.append("    ],")
    return "\n".join(lines)


def main() -> None:
    by_id = {
        item["id"]: item["framePrompts"]
        for item in json.loads(CATALOG.read_text(encoding="utf-8"))
    }
    text = PROMPTS.read_text(encoding="utf-8")
    for style_id in INLINE_STYLE_IDS:
        pattern = rf'    "{style_id}": \[\n(?:        .+\n)+?    \],'
        block = _block(style_id, by_id[style_id])
        text, count = re.subn(pattern, lambda _m, b=block: b, text, count=1)
        if count != 1:
            raise SystemExit(f"Failed to replace {style_id}")
        print(f"synced {style_id}")
    PROMPTS.write_text(text, encoding="utf-8")


if __name__ == "__main__":
    main()
