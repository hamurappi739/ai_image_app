"""Photoshoot style catalog for future img2img / style generation."""

from __future__ import annotations

from dataclasses import dataclass

from fastapi import HTTPException

PHOTOSHOOT_PRODUCT_OUTPUT_COUNT = 3

# Flutter currently sends ``urban_portrait`` for the city portrait style.
_STYLE_ID_ALIASES: dict[str, str] = {
    "urban_portrait": "city_portrait",
}


@dataclass(frozen=True, slots=True)
class PhotoshootStyle:
    id: str
    title: str
    price_rub: int
    is_free: bool
    output_count: int
    instruction: str


PHOTOSHOOT_STYLES: dict[str, PhotoshootStyle] = {
    "studio_portrait": PhotoshootStyle(
        id="studio_portrait",
        title="Студийный портрет",
        price_rub=0,
        is_free=True,
        output_count=PHOTOSHOOT_PRODUCT_OUTPUT_COUNT,
        instruction=(
            "Create one standalone professional studio portrait photo based on the uploaded person. "
            "Preserve the person's face, identity, and key facial features. "
            "Use clean studio lighting, a soft neutral background, and balanced composition. "
            "Improve light, color, and overall polish while keeping the person recognizable. "
            "Do not change the person's identity. No NSFW content."
        ),
    ),
    "business_portrait": PhotoshootStyle(
        id="business_portrait",
        title="Деловой портрет",
        price_rub=0,
        is_free=True,
        output_count=PHOTOSHOOT_PRODUCT_OUTPUT_COUNT,
        instruction=(
            "Create one standalone business portrait photo based on the uploaded person. "
            "Preserve the person's face, identity, and key facial features. "
            "Use a professional office or neutral business background, confident posture, "
            "and polished corporate lighting. Improve clarity, color, and composition. "
            "Do not change the person's identity. No NSFW content."
        ),
    ),
    "home_portrait": PhotoshootStyle(
        id="home_portrait",
        title="Домашний портрет",
        price_rub=0,
        is_free=True,
        output_count=PHOTOSHOOT_PRODUCT_OUTPUT_COUNT,
        instruction=(
            "Create one standalone warm home portrait photo based on the uploaded person. "
            "Preserve the person's face, identity, and key facial features. "
            "Use cozy indoor atmosphere, natural window light, and a relaxed home setting. "
            "Improve warmth, soft lighting, background, and composition. "
            "Do not change the person's identity. No NSFW content."
        ),
    ),
    "premium_portrait": PhotoshootStyle(
        id="premium_portrait",
        title="Премиум-портрет",
        price_rub=100,
        is_free=False,
        output_count=PHOTOSHOOT_PRODUCT_OUTPUT_COUNT,
        instruction=(
            "Create one standalone premium cinematic portrait photo based on the uploaded person. "
            "Preserve the person's face, identity, and key facial features. "
            "Use elegant cinematic lighting, rich tones, and a refined premium background. "
            "Improve depth, color grading, and composition while keeping the person recognizable. "
            "Do not change the person's identity. No NSFW content."
        ),
    ),
    "winter_photoshoot": PhotoshootStyle(
        id="winter_photoshoot",
        title="Зимняя фотосессия",
        price_rub=100,
        is_free=False,
        output_count=PHOTOSHOOT_PRODUCT_OUTPUT_COUNT,
        instruction=(
            "Create one standalone winter-themed portrait photo based on the uploaded person. "
            "Preserve the person's face, identity, and key facial features. "
            "Use snowy or winter atmosphere, soft cold light, and seasonal winter styling. "
            "Improve atmosphere, background, color, and composition. "
            "Do not change the person's identity. No NSFW content."
        ),
    ),
    "city_portrait": PhotoshootStyle(
        id="city_portrait",
        title="Городской портрет",
        price_rub=100,
        is_free=False,
        output_count=PHOTOSHOOT_PRODUCT_OUTPUT_COUNT,
        instruction=(
            "Create one standalone modern city portrait photo based on the uploaded person. "
            "Preserve the person's face, identity, and key facial features. "
            "Use an urban city background, stylish street lighting, and contemporary composition. "
            "Improve light, background depth, color, and overall polish. "
            "Do not change the person's identity. No NSFW content."
        ),
    ),
    "evening_look": PhotoshootStyle(
        id="evening_look",
        title="Вечерний образ",
        price_rub=100,
        is_free=False,
        output_count=PHOTOSHOOT_PRODUCT_OUTPUT_COUNT,
        instruction=(
            "Create one standalone elegant evening portrait photo based on the uploaded person. "
            "Preserve the person's face, identity, and key facial features. "
            "Use evening styling, premium low-light ambiance, and a sophisticated background. "
            "Improve mood lighting, color, and composition. "
            "Do not change the person's identity. No NSFW content."
        ),
    ),
    "travel_portrait": PhotoshootStyle(
        id="travel_portrait",
        title="Портрет в путешествии",
        price_rub=100,
        is_free=False,
        output_count=PHOTOSHOOT_PRODUCT_OUTPUT_COUNT,
        instruction=(
            "Создай реалистичный портрет в путешествии по исходному фото. "
            "Сохрани лицо, возраст, черты, цвет глаз и узнаваемость человека. "
            "Красивый атмосферный фон, мягкий естественный свет, лёгкий стильный образ. "
            "Без искажений лица, рук, пальцев и фона."
        ),
    ),
    "tender_photoshoot": PhotoshootStyle(
        id="tender_photoshoot",
        title="Нежная фотосессия",
        price_rub=100,
        is_free=False,
        output_count=PHOTOSHOOT_PRODUCT_OUTPUT_COUNT,
        instruction=(
            "Создай нежный реалистичный портрет по загруженному фото. "
            "Сохрани лицо, возраст, черты, цвет глаз и естественную мимику человека. "
            "Мягкий рассеянный свет, спокойный светлый фон, тёплая атмосфера. "
            "Без искажений лица, рук, пальцев и пропорций."
        ),
    ),
    "summer_photoshoot": PhotoshootStyle(
        id="summer_photoshoot",
        title="Летняя фотосессия",
        price_rub=100,
        is_free=False,
        output_count=PHOTOSHOOT_PRODUCT_OUTPUT_COUNT,
        instruction=(
            "Создай летнее реалистичное фото по исходному снимку. "
            "Сохрани лицо, возраст, основные черты, цвет глаз и узнаваемость человека. "
            "Мягкий солнечный свет, лёгкий образ, приятный природный или городской фон. "
            "Без искажений лица, рук, пальцев и тела."
        ),
    ),
    "expert_photoshoot": PhotoshootStyle(
        id="expert_photoshoot",
        title="Экспертная фотосессия",
        price_rub=100,
        is_free=False,
        output_count=PHOTOSHOOT_PRODUCT_OUTPUT_COUNT,
        instruction=(
            "Создай экспертное фото по загруженному снимку. "
            "Сохрани лицо, возраст, черты, цвет глаз и узнаваемость человека. "
            "Образ специалиста: спокойный фон, мягкий деловой свет, уверенный взгляд. "
            "Без искажений лица, рук, пальцев и пропорций."
        ),
    ),
    "business_brand": PhotoshootStyle(
        id="business_brand",
        title="Бизнес-портрет",
        price_rub=100,
        is_free=False,
        output_count=PHOTOSHOOT_PRODUCT_OUTPUT_COUNT,
        instruction=(
            "Создай бизнес-портрет по исходному фото. "
            "Сохрани лицо, возраст, форму лица, цвет глаз и узнаваемость человека. "
            "Современный деловой стиль, нейтральный фон, мягкий профессиональный свет. "
            "Без искажений лица, рук, пальцев и тела."
        ),
    ),
    "personal_brand": PhotoshootStyle(
        id="personal_brand",
        title="Фото для личного бренда",
        price_rub=100,
        is_free=False,
        output_count=PHOTOSHOOT_PRODUCT_OUTPUT_COUNT,
        instruction=(
            "Создай фото для личного бренда по загруженному изображению. "
            "Сохрани лицо, возраст, черты, цвет глаз и узнаваемость человека. "
            "Современный уверенный образ, приятный фон, мягкий свет, естественные позы. "
            "Без искажений лица, рук и пальцев."
        ),
    ),
    "cafe_city": PhotoshootStyle(
        id="cafe_city",
        title="Кафе и город",
        price_rub=100,
        is_free=False,
        output_count=PHOTOSHOOT_PRODUCT_OUTPUT_COUNT,
        instruction=(
            "Создай фото в стиле кафе и города по загруженному снимку. "
            "Сохрани лицо, возраст, черты, цвет глаз и узнаваемость человека. "
            "Уютное кафе или городская улица, мягкий свет, стильный повседневный образ. "
            "Без искажений лица, рук, пальцев и перспективы."
        ),
    ),
    "park_walk": PhotoshootStyle(
        id="park_walk",
        title="Прогулка в парке",
        price_rub=100,
        is_free=False,
        output_count=PHOTOSHOOT_PRODUCT_OUTPUT_COUNT,
        instruction=(
            "Создай реалистичное фото на прогулке в парке по исходному фото. "
            "Сохрани лицо, возраст, форму лица, цвет глаз и узнаваемость человека. "
            "Природный фон, мягкий дневной свет, спокойный образ, естественные позы. "
            "Без искажений лица, рук, пальцев и тела."
        ),
    ),
    "custom_photoshoot": PhotoshootStyle(
        id="custom_photoshoot",
        title="Своя фотосессия",
        price_rub=0,
        is_free=True,
        output_count=PHOTOSHOOT_PRODUCT_OUTPUT_COUNT,
        instruction=(
            "Create one standalone portrait photo based on the uploaded person. "
            "Preserve the person's face, identity, and key facial features. "
            "Use a cohesive polished photoshoot look with natural lighting and clean composition. "
            "Do not change the person's identity. No NSFW content."
        ),
    ),
}


def get_photoshoot_style(style_id: str) -> PhotoshootStyle:
    """Return catalog style by id; raise 400 for unknown ids."""
    normalized_id = (style_id or "").strip()
    if not normalized_id:
        raise HTTPException(status_code=400, detail="Unknown photoshoot style")

    canonical_id = _STYLE_ID_ALIASES.get(normalized_id, normalized_id)
    style = PHOTOSHOOT_STYLES.get(canonical_id)
    if style is None:
        raise HTTPException(status_code=400, detail="Unknown photoshoot style")

    return style
