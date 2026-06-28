"""One-off patch: strengthen photoshoot framePrompts for parallel frame diversity."""

from __future__ import annotations

import json
from pathlib import Path

NEG = (
    " Do not repeat the same pose, crop, camera distance, arm position, gaze direction, "
    "background framing, or composition from the other frames."
)

ROOT = Path(__file__).resolve().parent.parent.parent
PATHS = [
    ROOT / "backend" / "app" / "catalog" / "photoshoots.json",
    ROOT / "frontend" / "assets" / "catalog" / "photoshoots.json",
]

REWRITES: dict[str, list[str]] = {
    "summer_photoshoot": [
        (
            "You are given one uploaded user photo. Use it only as the identity reference. "
            "Keep the same face, age, facial proportions, skin tone, hairstyle direction and natural expression. "
            "Transform this person into a bright summer portrait.\n\n"
            "Generate a photorealistic close head-and-shoulders summer portrait in soft golden-hour sunlight. "
            "Light summer dress or airy white/cream blouse, park greenery or sunny terrace softly blurred behind. "
            "Direct gentle gaze into camera, relaxed smile, warm vibrant natural colors, fresh vacation mood.\n\n"
            "Frame 0 is the identity and style anchor: closest crop, frontal chest-up, main summer look."
        ),
        (
            "You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. "
            "Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, "
            "color grading and overall look. Generate frame 2 of this summer photoshoot.\n\n"
            "Create a medium chest-up portrait, body turned three-quarters to the camera, one hand visible resting "
            "naturally or touching hair/sunhat strap. Gaze slightly off-camera or over the shoulder. Same summer outfit, "
            "same park/terrace location, same warm sunlight and color palette.\n\n"
            "Must differ from frame 0: medium camera distance, three-quarter body angle, visible hand pose, "
            "off-center gaze."
            + NEG
        ),
        (
            "You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. "
            "Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, "
            "color grading and overall look. Generate frame 3 of this summer photoshoot.\n\n"
            "Create a wider waist-up or full-body lifestyle summer portrait on a sunny path or terrace, person walking "
            "slowly or standing with relaxed arms, camera slightly lower showing more sky and environment. Same light "
            "summer outfit, same golden-hour light, joyful vacation atmosphere.\n\n"
            "Must differ from frames 0 and 1: widest crop, walking or side-standing pose, more environment, "
            "different camera height."
            + NEG
        ),
    ],
    "studio_portrait": [
        (
            "You are given one uploaded user photo. Use it only as the identity reference. "
            "Keep the same face, age, facial proportions, skin tone, hairstyle direction and natural expression.\n\n"
            "Generate a photorealistic premium studio portrait: warm gray-beige backdrop, soft volumetric light, "
            "neutral elegant outfit. Close chest-up framing, direct gaze, calm light smile. Clean high-end studio mood."
        ),
        (
            "You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. "
            "Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, "
            "color grading and overall look. Generate frame 2 of this studio portrait session.\n\n"
            "Medium chest-up portrait, head tilted slightly, shoulders angled three-quarters, soft smile, one hand "
            "resting near collar or lapels. Same gray-beige studio, same outfit and soft light.\n\n"
            "Must differ from frame 0: medium distance, three-quarter shoulders, head tilt, hand visible."
            + NEG
        ),
        (
            "You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. "
            "Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, "
            "color grading and overall look. Generate frame 3 of this studio portrait session.\n\n"
            "Wider waist-up studio portrait, person seated or standing with relaxed arms, gaze gently away from camera, "
            "more negative space around subject. Same backdrop, outfit and premium soft light.\n\n"
            "Must differ from frames 0 and 1: wider crop, seated/standing full torso, averted gaze, more space."
            + NEG
        ),
    ],
    "business_portrait": [
        (
            "You are given one uploaded user photo. Use it only as the identity reference. "
            "Keep the same face, age, facial proportions, skin tone, hairstyle direction and natural expression.\n\n"
            "Generate a photorealistic business portrait: shoulders-up, direct confident gaze, light neutral background, "
            "soft professional studio light, light blouse or restrained blazer. Resume/profile quality."
        ),
        (
            "You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. "
            "Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, "
            "color grading and overall look. Generate frame 2 of this business portrait session.\n\n"
            "Medium chest-up portrait, three-quarter head turn, calm professional expression, hands not visible. "
            "Same outfit, background and soft business light.\n\n"
            "Must differ from frame 0: medium crop, three-quarter angle, no direct frontal gaze."
            + NEG
        ),
        (
            "You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. "
            "Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, "
            "color grading and overall look. Generate frame 3 of this business portrait session.\n\n"
            "Wider chest-up or waist-up business portrait, hands folded calmly at waist level, body slightly angled, "
            "confident approachable expression. Same professional outfit and neutral backdrop.\n\n"
            "Must differ from frames 0 and 1: wider framing, visible hands, waist-level composition."
            + NEG
        ),
    ],
    "evening_look": [
        (
            "You are given one uploaded user photo. Use it only as the identity reference. "
            "Keep the same face, age, facial proportions, skin tone, hairstyle direction and natural expression.\n\n"
            "Generate an elegant evening-style portrait: shoulders or chest-up, warm soft interior light, closed elegant "
            "blouse or jacket, blurred neutral background, minimal jewelry, natural skin."
        ),
        (
            "You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. "
            "Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, "
            "color grading and overall look. Generate frame 2 of this evening portrait session.\n\n"
            "Medium portrait, body turned three-quarters, confident calm pose, gaze slightly off-camera. Same elegant "
            "outfit, warm interior light and soft background.\n\n"
            "Must differ from frame 0: medium distance, three-quarter body, off-camera gaze."
            + NEG
        ),
        (
            "You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. "
            "Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, "
            "color grading and overall look. Generate frame 3 of this evening portrait session.\n\n"
            "Wider waist-up portrait, relaxed arm position, gentle side glance, more room visible in soft interior blur. "
            "Same outfit, palette and warm light.\n\n"
            "Must differ from frames 0 and 1: widest crop, waist-up, side glance, more background visible."
            + NEG
        ),
    ],
    "winter_photoshoot": [
        (
            "You are given one uploaded user photo. Use it only as the identity reference. "
            "Keep the same face, age, facial proportions, skin tone, hairstyle direction and natural expression.\n\n"
            "Generate a cozy winter close portrait: warm coat or wool jacket, soft snow blurred behind, calm daylight, "
            "natural skin, closest head-and-shoulders crop, gentle smile."
        ),
        (
            "You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. "
            "Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, "
            "color grading and overall look. Generate frame 2 of this winter photoshoot.\n\n"
            "Medium portrait on a winter park path, body turned three-quarters, hands in pockets or holding coat collar, "
            "cozy atmosphere, same winter outfit and soft snow light.\n\n"
            "Must differ from frame 0: medium distance, outdoor path context, three-quarter turn, hand pose."
            + NEG
        ),
        (
            "You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. "
            "Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, "
            "color grading and overall look. Generate frame 3 of this winter photoshoot.\n\n"
            "Wider waist-up winter lifestyle portrait, person walking slowly in snow or standing sideways, more trees and "
            "path visible, rosy natural cheeks. Same coat and winter palette.\n\n"
            "Must differ from frames 0 and 1: widest crop, walking/side pose, more environment."
            + NEG
        ),
    ],
    "expert_photoshoot": [
        (
            "You are given one uploaded user photo. Use it only as the identity reference. "
            "Keep the same face, age, facial proportions, skin tone, hairstyle direction and natural expression.\n\n"
            "Generate a trustworthy expert portrait: shoulders-up, smart casual or business-casual, neutral background, "
            "soft professional light, calm confident direct gaze."
        ),
        (
            "You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. "
            "Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, "
            "color grading and overall look. Generate frame 2 of this expert photoshoot.\n\n"
            "Medium chest-up portrait, slight head turn, approachable specialist expression, same outfit and backdrop.\n\n"
            "Must differ from frame 0: medium crop, three-quarter angle, softer expression."
            + NEG
        ),
        (
            "You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. "
            "Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, "
            "color grading and overall look. Generate frame 3 of this expert photoshoot.\n\n"
            "Wider waist-up portrait, relaxed confident posture, hands visible resting naturally, suitable for website hero. "
            "Same expert styling and light.\n\n"
            "Must differ from frames 0 and 1: wider framing, visible hands, presentation-ready composition."
            + NEG
        ),
    ],
    "personal_brand": [
        (
            "You are given one uploaded user photo. Use it only as the identity reference. "
            "Keep the same face, age, facial proportions, skin tone, hairstyle direction and natural expression.\n\n"
            "Generate a personal-brand portrait: close crop, modern confident look, pleasant background, soft light, "
            "open natural expression, social-media ready."
        ),
        (
            "You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. "
            "Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, "
            "color grading and overall look. Generate frame 2 of this personal-brand session.\n\n"
            "Medium chest-up portrait, three-quarter angle, confident pose, engaging eye contact or slight off-camera look. "
            "Same outfit, location and warm grading.\n\n"
            "Must differ from frame 0: medium distance, angled body, different gaze."
            + NEG
        ),
        (
            "You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. "
            "Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, "
            "color grading and overall look. Generate frame 3 of this personal-brand session.\n\n"
            "Wider lifestyle portrait with light smile, relaxed arms, more environment visible, trustworthy professional mood. "
            "Same brand styling throughout.\n\n"
            "Must differ from frames 0 and 1: widest crop, lifestyle context, relaxed arms."
            + NEG
        ),
    ],
    "premium_portrait": [
        (
            "You are given one uploaded user photo. Use it only as the identity reference. "
            "Keep the same face, age, facial proportions, skin tone, hairstyle direction and natural expression.\n\n"
            "Generate a premium studio portrait: dark gray/graphite backdrop, soft volumetric light, graphite jacket over "
            "light closed blouse, closest chest-up crop, elegant restrained high-end mood."
        ),
        (
            "You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. "
            "Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, "
            "color grading and overall look. Generate frame 2 of this premium portrait session.\n\n"
            "Medium chest-up portrait, subtle body turn, calm confident gaze, minimalist magazine quality. Same graphite "
            "outfit and studio light.\n\n"
            "Must differ from frame 0: medium distance, body turn, different head angle."
            + NEG
        ),
        (
            "You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. "
            "Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, "
            "color grading and overall look. Generate frame 3 of this premium portrait session.\n\n"
            "Wider waist-up premium portrait, gaze slightly away, editorial negative space, realistic skin, same graphite "
            "styling and soft volumetric light.\n\n"
            "Must differ from frames 0 and 1: widest crop, averted gaze, editorial spacing."
            + NEG
        ),
    ],
}


def append_neg_if_missing(prompt: str) -> str:
    if NEG.strip() in prompt:
        return prompt
    return prompt.rstrip() + NEG


def patch_catalog(path: Path) -> None:
    data = json.loads(path.read_text(encoding="utf-8"))
    for item in data:
        style_id = item["id"]
        if style_id in REWRITES:
            item["framePrompts"] = REWRITES[style_id]
            continue
        prompts = item.get("framePrompts")
        if not isinstance(prompts, list) or len(prompts) < 3:
            continue
        item["framePrompts"] = [
            prompts[0],
            append_neg_if_missing(prompts[1]),
            append_neg_if_missing(prompts[2]),
        ]
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    for path in PATHS:
        patch_catalog(path)
        print(f"patched {path}")


if __name__ == "__main__":
    main()
