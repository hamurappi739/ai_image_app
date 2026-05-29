"""Photoshoot style catalog for future img2img / style generation."""

from __future__ import annotations

from dataclasses import dataclass

from fastapi import HTTPException

PHOTOSHOOT_OUTPUT_COUNT = 3

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
        output_count=PHOTOSHOOT_OUTPUT_COUNT,
        instruction=(
            "Create 3 professional studio portrait photos based on the uploaded person. "
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
        output_count=PHOTOSHOOT_OUTPUT_COUNT,
        instruction=(
            "Create 3 business portrait photos based on the uploaded person. "
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
        output_count=PHOTOSHOOT_OUTPUT_COUNT,
        instruction=(
            "Create 3 warm home portrait photos based on the uploaded person. "
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
        output_count=PHOTOSHOOT_OUTPUT_COUNT,
        instruction=(
            "Create 3 premium cinematic portrait photos based on the uploaded person. "
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
        output_count=PHOTOSHOOT_OUTPUT_COUNT,
        instruction=(
            "Create 3 winter-themed portrait photos based on the uploaded person. "
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
        output_count=PHOTOSHOOT_OUTPUT_COUNT,
        instruction=(
            "Create 3 modern city portrait photos based on the uploaded person. "
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
        output_count=PHOTOSHOOT_OUTPUT_COUNT,
        instruction=(
            "Create 3 elegant evening portrait photos based on the uploaded person. "
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
        output_count=PHOTOSHOOT_OUTPUT_COUNT,
        instruction=(
            "Create 3 travel portrait photos based on the uploaded person. "
            "Preserve the person's face, identity, and key facial features. "
            "Use beautiful vacation locations, natural travel lighting, and scenic backgrounds. "
            "Improve atmosphere, color, background, and composition. "
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
