"""Backend style consistency locks for photoshoot generation prompts."""

from __future__ import annotations

from dataclasses import dataclass

from app.services.photoshoot_styles import _STYLE_ID_ALIASES

CUSTOM_PHOTOSHOOT_STYLE_ID = "custom_photoshoot"


@dataclass(frozen=True, slots=True)
class PhotoshootStyleLock:
    outfit_lock: str
    location_lock: str
    lighting_lock: str
    color_grading_lock: str
    forbidden_changes: str
    safe_batch_hard_rule: str | None = None


def resolve_style_lock_id(client_style_id: str) -> str:
    normalized = (client_style_id or "").strip()
    return _STYLE_ID_ALIASES.get(normalized, normalized)


def get_style_lock(client_style_id: str) -> PhotoshootStyleLock:
    lock_id = resolve_style_lock_id(client_style_id)
    return PHOTOSHOOT_STYLE_LOCKS.get(lock_id, _GENERIC_STYLE_LOCK)


def get_safe_batch_hard_rule(client_style_id: str) -> str | None:
    lock = get_style_lock(client_style_id)
    return lock.safe_batch_hard_rule


def build_style_lock_prompt_block(client_style_id: str) -> str:
    lock = get_style_lock(client_style_id)
    return (
        "Style consistency locks (critical):\n"
        f"- Outfit: {lock.outfit_lock}\n"
        f"- Location/background: {lock.location_lock}\n"
        f"- Lighting: {lock.lighting_lock}\n"
        f"- Color grading: {lock.color_grading_lock}\n"
        f"- Forbidden: {lock.forbidden_changes}"
    )


_GENERIC_STYLE_LOCK = PhotoshootStyleLock(
    outfit_lock="modest polished outfit with closed neckline, consistent across all frames",
    location_lock="one consistent neutral background matching the selected style text",
    lighting_lock="soft natural professional light, consistent across frames",
    color_grading_lock="natural realistic tones, consistent across frames",
    forbidden_changes=(
        "different outfit color, open neckline, off-shoulder top, different location, "
        "glamour, nightlife, collage"
    ),
)

PHOTOSHOOT_STYLE_LOCKS: dict[str, PhotoshootStyleLock] = {
    "studio_portrait": PhotoshootStyleLock(
        outfit_lock=(
            "beige, cream, or gray closed top or simple blazer, modest neckline, "
            "consistent studio portrait look"
        ),
        location_lock="warm gray or beige seamless studio background",
        lighting_lock="soft professional studio portrait light",
        color_grading_lock="neutral warm studio tones",
        forbidden_changes=(
            "office background, city street, park, off-shoulder top, black glamour, "
            "evening look, open neckline"
        ),
    ),
    "business_portrait": PhotoshootStyleLock(
        outfit_lock=(
            "navy, beige, or cream business blazer with closed light blouse, modest neckline"
        ),
        location_lock="neutral office or studio background",
        lighting_lock="soft professional business light",
        color_grading_lock="neutral business tones",
        forbidden_changes=(
            "casual black top, off-shoulder top, open neckline, floral wallpaper, park, "
            "evening look, glamour, nightlife"
        ),
    ),
    "city_portrait": PhotoshootStyleLock(
        outfit_lock=(
            "light top with beige cardigan, trench, or soft jacket, casual city style, "
            "modest neckline"
        ),
        location_lock="city street, building facade, or old town architecture, not a studio",
        lighting_lock="soft daylight",
        color_grading_lock="natural city tones",
        forbidden_changes=(
            "studio gray background, business blazer, winter snow, evening glamour, "
            "off-shoulder black top, open neckline"
        ),
    ),
    "evening_look": PhotoshootStyleLock(
        outfit_lock="closed elegant blouse or blazer, modest neckline",
        location_lock="warm neutral indoor background in soft blur",
        lighting_lock="soft warm indoor light",
        color_grading_lock="warm neutral elegant tones",
        forbidden_changes=(
            "black off-shoulder top, open neckline, floral wallpaper, nightlife, bar, "
            "hotel room, glamour, romantic mood, low-light club"
        ),
    ),
    "tender_photoshoot": PhotoshootStyleLock(
        outfit_lock=(
            "light beige or cream knit sweater with soft neutral pants, modest neckline"
        ),
        location_lock="soft beige interior with cream sofa, curtains, pampas or dried flowers",
        lighting_lock="soft diffused daylight",
        color_grading_lock="pastel warm gentle tones",
        forbidden_changes=(
            "business blazer, black clothing, dark dramatic background, street background, "
            "glamour, off-shoulder top, open neckline"
        ),
    ),
    "summer_photoshoot": PhotoshootStyleLock(
        outfit_lock=(
            "light cream, white, or pastel summer blouse or modest light summer dress, "
            "closed or modest neckline"
        ),
        location_lock="green summer garden or park with flowers and trees",
        lighting_lock="soft sunny daylight",
        color_grading_lock="warm fresh natural summer tones",
        forbidden_changes=(
            "black clothing, black top, off-shoulder top, open neckline, dark outfit, "
            "evening look, studio interior, winter clothing, business blazer"
        ),
        safe_batch_hard_rule=(
            "Never use black clothing or off-shoulder neckline for summer_photoshoot."
        ),
    ),
    "winter_photoshoot": PhotoshootStyleLock(
        outfit_lock=(
            "cream, white, or beige coat, sweater, or scarf, modest winter look"
        ),
        location_lock="snowy park or forest outdoor background",
        lighting_lock="soft winter daylight",
        color_grading_lock="light cold winter tones with warm natural skin",
        forbidden_changes=(
            "indoor background, studio interior, business blazer, summer dress, "
            "black off-shoulder top, open neckline, evening look, glamour"
        ),
    ),
    "home_portrait": PhotoshootStyleLock(
        outfit_lock="soft cardigan over white or cream top, modest home casual look",
        location_lock="bright living room, window area, or sofa in a tidy home interior",
        lighting_lock="natural window daylight",
        color_grading_lock="warm cozy home tones",
        forbidden_changes=(
            "studio gray background, business suit, street background, snow, glamour, "
            "black off-shoulder top, open neckline, nightlife"
        ),
    ),
    "expert_photoshoot": PhotoshootStyleLock(
        outfit_lock="navy or beige blazer with closed light blouse, modest neckline",
        location_lock="neutral office, studio, or expert professional background",
        lighting_lock="soft professional daylight",
        color_grading_lock="neutral expert and business tones",
        forbidden_changes=(
            "off-shoulder top, black casual top, open neckline, floral wallpaper, park, "
            "nightlife, glamour, evening look"
        ),
    ),
    "business_brand": PhotoshootStyleLock(
        outfit_lock=(
            "light beige, gray or cream textured blazer over white top, modest neckline"
        ),
        location_lock="warm neutral gray or beige studio background",
        lighting_lock="soft professional light",
        color_grading_lock="clean business brand tones",
        forbidden_changes=(
            "black off-shoulder top, open neckline, floral wallpaper, casual glamour, park, "
            "evening look, nightlife, black party top, dark suit"
        ),
        safe_batch_hard_rule=(
            "Never use black off-shoulder clothing for business_brand."
        ),
    ),
    "personal_brand": PhotoshootStyleLock(
        outfit_lock=(
            "casual-professional closed neckline outfit: light blouse, cardigan, or blazer "
            "in beige, cream, or navy"
        ),
        location_lock="pleasant neutral interior or soft office background",
        lighting_lock="natural soft daylight",
        color_grading_lock="friendly warm professional tones",
        forbidden_changes=(
            "evening glamour, off-shoulder top, open neckline, black party top, "
            "floral wallpaper, winter snow, nightlife, studio mismatch"
        ),
    ),
    "travel_portrait": PhotoshootStyleLock(
        outfit_lock=(
            "beige trench, cardigan, or light casual travel outfit, modest neckline"
        ),
        location_lock="old town street, travel viewpoint, or calm architectural background",
        lighting_lock="soft daylight",
        color_grading_lock="warm travel tones",
        forbidden_changes=(
            "studio background, business blazer, black off-shoulder top, open neckline, "
            "indoor office, winter snow, glamour, nightlife"
        ),
    ),
    "cafe_city": PhotoshootStyleLock(
        outfit_lock=(
            "olive or beige cardigan or jacket over white shirt or blouse, modest neckline"
        ),
        location_lock="cafe interior, cafe window, or cafe street facade",
        lighting_lock="soft cafe and window daylight",
        color_grading_lock="warm cafe city tones",
        forbidden_changes=(
            "studio gray background, business suit, snow, black off-shoulder top, "
            "open neckline, nightlife, bar glamour"
        ),
    ),
    "park_walk": PhotoshootStyleLock(
        outfit_lock=(
            "mint, pale green or light pastel cardigan over white top, modest neckline, "
            "calm park casual"
        ),
        location_lock="green park path with trees in soft blur",
        lighting_lock="soft daylight",
        color_grading_lock="fresh natural green tones",
        forbidden_changes=(
            "studio background, business blazer, evening look, black clothing, "
            "off-shoulder top, open neckline, city office, indoor floral wallpaper"
        ),
        safe_batch_hard_rule=(
            "Never use black clothing or off-shoulder neckline for park_walk."
        ),
    ),
    "premium_portrait": PhotoshootStyleLock(
        outfit_lock=(
            "graphite, navy, or beige elegant blazer with closed light blouse, modest neckline"
        ),
        location_lock="dark gray or refined neutral premium studio background",
        lighting_lock="premium soft portrait light",
        color_grading_lock="refined neutral premium tones",
        forbidden_changes=(
            "streetwear, open neckline, off-shoulder top, floral wallpaper, park, snow, "
            "nightlife glamour, casual black top"
        ),
    ),
    CUSTOM_PHOTOSHOOT_STYLE_ID: _GENERIC_STYLE_LOCK,
}
