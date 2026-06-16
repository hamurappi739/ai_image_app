#!/usr/bin/env python3
"""One-off generator for assets/catalog/*.json from app_prompts.dart structure."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROMPTS = (ROOT / "lib/data/app_prompts.dart").read_text(encoding="utf-8")


def extract_map(name: str) -> dict[str, str]:
    pattern = rf"{name} = <String, String>\{{(.*?)\}};"
    block = re.search(pattern, PROMPTS, re.S).group(1)
    result: dict[str, str] = {}
    for key, value in re.findall(r"'([^']+)':\s*\n?\s*'((?:\\'|[^'])*)'", block):
        result[key] = value.replace("\\'", "'")
    return result


template_short = extract_map("templateShortDescriptions")
template_full = extract_map("templateFullPrompts")
photoshoot_short = extract_map("photoshootShortDescriptions")
photoshoot_full = extract_map("photoshootStylePrompts")

preview_file = {
    "tender_portrait": "gentle_portrait.jpg",
    "vibrant_look": "bright_look.jpg",
    "photo_with_child": "child_photo.jpg",
    "festive_look": "holiday_look.jpg",
    "clothing_photo": "clothes_photo.jpg",
}

templates_meta = [
    ("beautiful_portrait", "Красивый портрет", "Для себя", 10),
    ("social_photo", "Фото для соцсетей", "Для себя", 20),
    ("winter_portrait", "Зимний портрет", "Для себя", 30),
    ("summer_portrait", "Летний портрет", "Для себя", 40),
    ("tender_portrait", "Нежный портрет", "Для себя", 50),
    ("vibrant_look", "Яркий образ", "Для себя", 60),
    ("business_portrait", "Деловой портрет", "Для работы", 10),
    ("resume_photo", "Фото для резюме", "Для работы", 20),
    ("profile_photo", "Фото для профиля", "Для работы", 30),
    ("expert_look", "Экспертный образ", "Для работы", 40),
    ("family_photo", "Семейное фото", "Для семьи", 10),
    ("photo_with_child", "Фото с ребёнком", "Для семьи", 20),
    ("festive_look", "Праздничный образ", "Для семьи", 30),
    ("product_photo", "Фото товара", "Для продажи", 10),
    ("clothing_photo", "Фото одежды", "Для продажи", 20),
    ("jewelry_photo", "Фото украшений", "Для продажи", 30),
    ("interior_photo", "Фото интерьера", "Для продажи", 40),
]

photoshoots_meta = [
    ("studio_portrait", "Студийный портрет", "Популярное сейчас", 20, "Популярно", True),
    ("business_portrait", "Деловой портрет", "Популярное сейчас", 10, "Для работы", True),
    ("urban_portrait", "Городской портрет", "Популярное сейчас", 30, "Для соцсетей", False),
    ("evening_look", "Вечерний образ", "Популярное сейчас", 40, "Для себя", False),
    ("tender_photoshoot", "Нежная фотосессия", "Для себя", 10, "Для себя", False),
    ("summer_photoshoot", "Летняя фотосессия", "Для себя", 20, "Для себя", False),
    ("winter_photoshoot", "Зимняя фотосессия", "Для себя", 30, "Для себя", False),
    ("home_portrait", "Домашний портрет", "Для себя", 40, "Для себя", True),
    ("expert_photoshoot", "Экспертная фотосессия", "Для работы", 10, "Для работы", False),
    ("business_brand", "Бизнес-портрет", "Для работы", 20, "Для работы", False),
    ("personal_brand", "Фото для личного бренда", "Для работы", 30, "Для работы", False),
    ("travel_portrait", "Портрет в путешествии", "Атмосферные", 10, "Атмосфера", False),
    ("cafe_city", "Кафе и город", "Атмосферные", 20, "Атмосфера", False),
    ("park_walk", "Прогулка в парке", "Атмосферные", 30, "Атмосфера", False),
    ("premium_portrait", "Премиум-портрет", "Атмосферные", 40, "Для себя", False),
]

catalog_dir = ROOT / "assets/catalog"
catalog_dir.mkdir(parents=True, exist_ok=True)

templates_out = []
for tid, title, category, sort_order in templates_meta:
    fname = preview_file.get(tid, f"{tid}.jpg")
    templates_out.append(
        {
            "id": tid,
            "title": title,
            "category": category,
            "shortDescription": template_short[tid],
            "prompt": template_full[tid],
            "previewAsset": f"assets/previews/templates/{fname}",
            "priceImages": 1,
            "isActive": True,
            "sortOrder": sort_order,
        }
    )

photoshoots_out = []
for pid, title, category, sort_order, badge, is_free in photoshoots_meta:
    photoshoots_out.append(
        {
            "id": pid,
            "title": title,
            "category": category,
            "shortDescription": photoshoot_short[pid],
            "prompt": photoshoot_full[pid],
            "previewAssets": [
                f"assets/previews/photoshoots/{pid}_1.jpg",
                f"assets/previews/photoshoots/{pid}_2.jpg",
                f"assets/previews/photoshoots/{pid}_3.jpg",
            ],
            "priceImages": 3,
            "isActive": True,
            "sortOrder": sort_order,
            "badge": badge,
            "isFree": is_free,
        }
    )

(catalog_dir / "templates.json").write_text(
    json.dumps(templates_out, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)
(catalog_dir / "photoshoots.json").write_text(
    json.dumps(photoshoots_out, ensure_ascii=False, indent=2) + "\n",
    encoding="utf-8",
)

print(f"Wrote {len(templates_out)} templates, {len(photoshoots_out)} photoshoots")
