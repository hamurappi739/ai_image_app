"""Photoshoot prompt assembly: base style + identity lock + per-frame prompts."""

from __future__ import annotations

from app.services.catalog_service import get_photoshoot_catalog_item
from app.services.gemini_quality_instructions import STANDALONE_SINGLE_IMAGE_RULES
from app.services.photoshoot_style_locks import (
    CUSTOM_PHOTOSHOOT_STYLE_ID,
    build_style_lock_prompt_block,
    get_safe_batch_hard_rule,
)
from app.services.photoshoot_styles import PhotoshootStyle

IDENTITY_LOCK_PROMPT = (
    "Это одна цельная фотосессия из 3 кадров. Все 3 кадра должны выглядеть как снимки, "
    "сделанные в одной съёмке. Сохрани одного и того же человека с исходного фото: "
    "то же лицо, возраст, форма лица, глаза, нос, губы, волосы, кожа и узнаваемость. "
    "Не меняй человека и не омолаживай. Сохрани один и тот же комплект одежды во всех 3 кадрах. "
    "Сохрани одну и ту же локацию, один фон, один свет и единую реалистичную обработку. "
    "Меняй только ракурс, позу, кадрирование и направление взгляда. "
    "Не меняй стиль между кадрами."
)

NEGATIVE_QUALITY_PROMPT = (
    "Без текста, логотипов, водяных знаков, UI-иконок, коллажа, рамок, галочек, "
    "крестиков, искажённых лиц, лишних пальцев, кривых рук, пластиковой кожи, "
    "сильного фильтра, случайных посторонних людей на переднем плане, разных локаций, "
    "разной одежды, разного возраста, другого человека."
)

GENERIC_FRAME_PROMPTS: tuple[str, ...] = (
    "Кадр 1 из 3: основной портрет, прямой взгляд.",
    "Кадр 2 из 3: лёгкий поворот, другой ракурс.",
    "Кадр 3 из 3: чуть шире, естественная поза.",
)

# Reference-role blocks for photoshoot pack v1 (docs/cursor_preview_assets_handoff.md).
PHOTOSHOOT_FRAME0_IDENTITY_REFERENCE_PREFIX = (
    "You are given one uploaded user photo. Use it only as the identity reference. "
    "Keep the same face, age, facial proportions, skin tone, hairstyle direction and natural expression."
)

PHOTOSHOOT_CONTINUATION_REFERENCE_PREFIX = (
    "You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. "
    "Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, "
    "color grading and overall look."
)

# Reserved for future single-template photo prompts (not wired yet).
SINGLE_TEMPLATE_IDENTITY_REFERENCE_INTRO = (
    "You are given one uploaded user photo. Use it as the identity reference. "
    "Keep the same person and transform only the clothes, background, pose, lighting and style described below."
)

# User-approved photoshoot prompt pack v1 (preview screenshot targets).
PHOTOSHOOT_PROMPT_PACK_V1: dict[str, tuple[str, str, str]] = {
    "urban_portrait": (
        "Frame 1 of the selected urban portrait session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: city background, crop, camera distance, body position, gaze direction, hand visibility, daylight, color palette, casual wardrobe style and overall street composition. Replace only the person in Image 2 with the uploaded person from Image 1, preserving the uploaded person's identity, age, face, skin tone, hairstyle and recognizable features. Do not copy the preview subject's face or identity. Keep the result natural, polished and photorealistic, connected to the same urban photoshoot. No extra people, no text, no logos, no watermark, no distorted face or hands.",
        "Frame 2 of the selected urban portrait session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: second city angle, medium crop, body turn, hand placement, gaze, architecture, background depth, natural daylight, muted urban palette and wardrobe style. Replace only the preview subject with the uploaded person from Image 1 while keeping the uploaded person's real identity, age, facial features, skin tone and hairstyle. Do not copy identity from the preview. Keep the outfit style stable if the previews show the same look, and do not move the scene to a studio or office. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted face or hands.",
        "Frame 3 of the selected urban portrait session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: wider city composition, sidewalk or street depth, pose, walking or standing direction if shown, arm position, gaze, background structure, light and color palette. Replace only the person in Image 2 with the uploaded person from Image 1, preserving identity, age, face shape, skin tone, hairstyle and recognizable features. Do not copy the preview person's identity. Keep this frame part of the same urban set and follow the third preview rather than inventing a different location. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted face or hands.",
    ),
    "tender_photoshoot": (
        "Frame 1 of the selected tender photoshoot. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: soft crop, seated or relaxed posture if shown, gaze direction, hand visibility, cozy background, gentle daylight, muted palette, wardrobe style and delicate composition. Replace only the preview subject with the uploaded person from Image 1, preserving the uploaded person's identity, age, face, skin tone, hairstyle and recognizable features. Do not copy the preview subject's face or identity. Keep the outfit tasteful, safe and soft, with modest, opaque, tasteful and appropriate wardrobe styling. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted face or hands.",
        'Frame 2 of the selected tender photoshoot. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: second pose, medium crop, body angle, hand placement near face, sofa or interior structure if present, soft light, warm beige palette, wardrobe style and calm mood. Replace only the person in Image 2 with the uploaded person from Image 1 while preserving identity, age, facial features, skin tone and hairstyle. Do not copy identity from Image 2. Keep the frame connected to the same tender session and follow the preview rather than inventing a new room or pose. Photorealistic, natural, high quality. No extra people, no text, no watermark, modest styling, no distorted hands or face.',
        "Frame 3 of the selected tender photoshoot. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: wider or more intimate crop as shown, pose, head direction, arm position, background decor, soft daylight, cozy palette, wardrobe style and overall composition. Replace only the preview subject with the uploaded person from Image 1, preserving identity, age, face shape, skin tone, hairstyle and recognizable features. Do not copy the preview subject's identity. Keep the outfit safe, consistent and tasteful; modest, opaque, tasteful and appropriate wardrobe styling. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted face or hands.",
    ),
    "home_portrait": (
        "Frame 1 of the selected home portrait session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: home interior, sofa or room layout, close crop, posture, gaze direction, natural window light, casual wardrobe style, warm palette and relaxed composition. Replace only the preview subject with the uploaded person from Image 1, preserving the uploaded person's identity, age, face, skin tone, hairstyle and recognizable features. Do not copy the preview subject's face or identity. Keep the image authentic, cozy, photorealistic and part of the same home session, not a studio or hotel scene. No extra people, no text, no watermark, no distorted hands or face.",
        'Frame 2 of the selected home portrait session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: second home pose, medium crop, body angle, hand placement, sofa or room details, soft window light, wardrobe style and cozy color palette. Replace only the person in Image 2 with the uploaded person from Image 1, preserving identity, age, facial structure, skin tone, hairstyle, recognizability and natural facial features. Adapt expression, gaze and head angle to the selected preview frame. Do not copy identity from Image 2. Keep the outfit style stable if the previews show one look, and do not move the scene to studio, office, cafe or luxury hotel unless shown. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted face or hands.',
        "Frame 3 of the selected home portrait session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: wider home composition, seated or relaxed pose, arm position, gaze, sofa, living room background, daylight, wardrobe style and warm domestic mood. Replace only the preview subject with the uploaded person from Image 1 while preserving identity, age, face, skin tone, hairstyle and recognizable features. Do not copy the preview subject's identity. Keep this frame consistent with the same home photoshoot and follow the third preview's framing. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted hands or face.",
    ),
    "cafe_city": (
        "Frame 1 of the selected cafe-city session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: cafe table or window setting, close crop, seated or leaning posture, hand position, gaze, coffee or decor if present, warm light, city background, wardrobe style and composition. Replace only the preview subject with the uploaded person from Image 1, preserving identity, age, face, skin tone, hairstyle and recognizable features. Do not copy the preview subject's identity. Keep the result natural, stylish, photorealistic and connected to the same cafe-city outing. No extra people, no text, no logos, no watermark, no distorted face or hands.",
        'Frame 2 of the selected cafe-city session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: second cafe angle, medium crop, body turn, gaze, hand placement, table or window details, warm cafe light, city-through-window background, wardrobe style and muted palette. Replace only the person in Image 2 with the uploaded person from Image 1 while preserving identity, age, facial features, skin tone, hairstyle and expression. Do not copy identity from Image 2. Keep the outfit style stable and do not shift to an office, studio, club or crowded restaurant unless the preview shows it. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted face or hands.',
        "Frame 3 of the selected cafe-city session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: wider cafe or street composition, standing or outdoor pose if shown, body angle, arm position, cafe facade or city background, light, wardrobe style and overall layout. Replace only the preview subject with the uploaded person from Image 1, preserving identity, age, face shape, skin tone, hairstyle and recognizable features. Do not copy the preview subject's identity. Keep the frame part of the same cafe-city photoshoot and follow the third preview's location. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted hands or face.",
    ),
    "business_brand": (
        "Frame 1 of the selected business brand session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: business-brand crop, camera distance, posture, gaze, clean background, lighting mood, wardrobe style, palette and polished composition. Replace only the preview subject with the uploaded person from Image 1, preserving the uploaded person's identity, age, face, skin tone, hairstyle and recognizable features. Do not copy the preview subject's identity or age. Keep the look professional, modern, credible and photorealistic, suitable for website or profile use. No extra people, no text, no logos, no watermark, no distorted face or hands.",
        'Frame 2 of the selected business brand session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: medium crop, body orientation, hand position, professional outfit style, studio or clean background, soft light, neutral palette and overall composition. Replace only the person in Image 2 with the uploaded person from Image 1 while preserving identity, age, facial features, skin tone, hairstyle, recognizability and natural facial features. Adapt expression, gaze and head angle to the selected preview frame. Do not copy identity from Image 2. Keep the outfit style stable with the preview set and avoid glamour, random casual locations or unrelated backgrounds. Photorealistic, natural, high quality. No text, no watermark, no extra people, no distorted face or hands.',
        "Frame 3 of the selected business brand session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: wider brand portrait framing, three-quarter angle, arm or hand placement, gaze, background, lighting, professional wardrobe style and negative space. Replace only the preview subject with the uploaded person from Image 1, preserving identity, age, face shape, skin tone, hairstyle and recognizable features. Do not copy the preview subject's face or identity. Keep the frame consistent with the same business brand series and follow the third preview's composition. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted hands or face.",
    ),
    "travel_portrait": (
        "Frame 1 of the selected travel portrait session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: travel background, close crop, camera distance, pose, body direction, gaze, daylight, wardrobe style, color palette and atmospheric composition. Replace only the preview subject with the uploaded person from Image 1, preserving the uploaded person's identity, age, face, skin tone, hairstyle and recognizable features. Do not copy the preview subject's face or identity. Keep the result natural, relaxed, photorealistic and tied to the same travel location shown in the preview. No extra people, no text, no logos, no watermark, no distorted face or hands.",
        'Frame 2 of the selected travel portrait session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: second travel angle, medium crop, hand position, body turn, street or scenic structure, daylight, wardrobe style, palette and relaxed expression. Replace only the person in Image 2 with the uploaded person from Image 1 while preserving identity, age, facial features, skin tone, hairstyle, recognizability and natural facial features. Adapt expression, gaze and head angle to the selected preview frame. Do not copy identity from Image 2. Keep the outfit and location family consistent with the travel preview set; do not move to studio, office, beach or winter unless preview shows it. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted face or hands.',
        "Frame 3 of the selected travel portrait session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: wider travel composition, walking or turning pose if shown, arm placement, environmental depth, background architecture or landscape, light, wardrobe style and overall frame layout. Replace only the preview subject with the uploaded person from Image 1, preserving identity, age, face, skin tone, hairstyle and recognizable features. Do not copy the preview subject's identity. Keep it as the same travel photoshoot and follow the third preview's scene and camera distance. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted face or hands.",
    ),
    "park_walk": (
        "Frame 1 of the selected park walk session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: green park background, close crop, camera distance, relaxed posture, gaze direction, soft daylight, casual wardrobe style, fresh palette and natural outdoor composition. Replace only the preview subject with the uploaded person from Image 1, preserving identity, age, facial structure, skin tone, hairstyle and recognizable features. Do not copy the preview subject's identity or age. Keep the result calm, natural, photorealistic and tied to the same park setting. No extra people, no text, no logos, no watermark, no distorted face or hands.",
        'Frame 2 of the selected park walk session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: second park angle, medium crop, body turn, hand position, bench or path details if present, trees, soft daylight, casual outfit style and relaxed mood. Replace only the person in Image 2 with the uploaded person from Image 1 while preserving identity, age, face, skin tone, hairstyle, recognizability and natural facial features. Adapt expression, gaze and head angle to the selected preview frame. Do not copy identity from Image 2. Keep the outfit style stable and do not change the setting to city street, studio, business interior or winter unless the preview shows it. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted face or hands.',
        "Frame 3 of the selected park walk session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: wider park crop, walking or standing pose if shown, body direction, arm placement, path depth, trees, daylight, wardrobe style and overall composition. Replace only the preview subject with the uploaded person from Image 1, preserving the uploaded person's identity, age, face, skin tone, hairstyle and recognizable features. Do not copy the preview subject's identity. Keep this as one continuous park walk photoshoot and follow the third preview frame closely. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted face or hands.",
    ),
}

PHOTOSHOOT_PROMPT_PACK_V1_STYLE_IDS: frozenset[str] = frozenset(PHOTOSHOOT_PROMPT_PACK_V1.keys())

# Authoring source for catalog JSON; also used when framePrompts missing in catalog.
FRAME_PROMPTS_BY_STYLE_ID: dict[str, list[str]] = {
    "studio_portrait": [
        "Frame 1 of the selected studio portrait session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: close crop, camera height, head position, shoulder angle, gaze direction, soft studio lighting, warm gray-beige backdrop, neutral wardrobe style and clean centered composition. Replace only the person in Image 2 with the uploaded person from Image 1 while preserving the uploaded person's identity, age, face, skin tone, hairstyle and recognizable features. Do not copy the preview subject's identity or age. Keep the result photorealistic, natural and premium. No extra people, no text, no watermark, no distorted face, no broken hands.",
        "Frame 2 of the selected studio portrait session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: medium portrait distance, torso crop, body turn, head tilt, hand placement, facial mood, studio background structure, lighting direction, color palette and wardrobe style. Replace only the preview subject with the uploaded person from Image 1; keep the uploaded person's identity, age, facial features, skin tone and hairstyle. Do not copy the preview person's face or identity. Keep this frame consistent with the same studio session and outfit style, but follow the second preview's pose and composition. Photorealistic, natural, high quality. No text, no watermark, no extra people, no distorted face or hands.",
        "Frame 3 of the selected studio portrait session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: wider studio crop, seated or standing posture if shown, body angle, arm position, gaze direction, negative space, backdrop, soft light and refined neutral styling. Replace only the person in the preview with the uploaded person from Image 1, preserving the uploaded person's identity, age, face, skin tone, hairstyle and recognizable features. Do not copy the preview subject's identity. Keep the wardrobe aligned with the same studio outfit family and make the frame feel connected to the full set. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted face or hands.",
    ],
    "business_portrait": [
        "Frame 1 of the selected business portrait session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: professional close crop, camera distance, frontal or near-frontal posture, gaze direction, shoulder line, background, soft business lighting, wardrobe style and clean composition. Replace only the person in Image 2 with the uploaded person from Image 1, preserving the uploaded person's identity, age, facial features, skin tone, hairstyle, recognizability and natural facial features. Adapt expression, gaze and head angle to the selected preview frame. Do not copy the preview subject's face, identity or age. Keep the result professional, trustworthy, photorealistic and suitable for a work profile. No extra people, no text, no logos, no watermark, no distorted face or hands.",
        "Frame 2 of the selected business portrait session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: medium crop, body angle, head turn, gaze direction, shoulders, background structure, light quality, business wardrobe style and neutral palette. Replace only the preview subject with the uploaded person from Image 1, keeping the uploaded person's real identity, age, face shape, skin tone, hairstyle and recognizable features. Do not copy identity from Image 2. Maintain a clean professional portrait mood, not glamour and not casual lifestyle unless the preview shows it. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted hands or face.",
        "Frame 3 of the selected business portrait session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: wider professional crop, body posture, visible hand position if present, camera distance, gaze, clean backdrop, lighting mood, business outfit style and overall composition. Replace only the preview subject with the uploaded person from Image 1 while preserving the uploaded person's identity, age, facial structure, skin tone, hairstyle, recognizability and natural facial features. Adapt expression, gaze and head angle to the selected preview frame. Do not copy the preview person's identity. Keep the outfit style consistent with the business set and keep the mood credible, calm and professional. Photorealistic, natural, high quality. No text, no watermark, no extra people, no distorted face or hands.",
    ],
    "urban_portrait": [
        "Frame 1 of the selected urban portrait session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: city background, crop, camera distance, body position, gaze direction, hand visibility, daylight, color palette, casual wardrobe style and overall street composition. Replace only the person in Image 2 with the uploaded person from Image 1, preserving the uploaded person's identity, age, face, skin tone, hairstyle and recognizable features. Do not copy the preview subject's face or identity. Keep the result natural, polished and photorealistic, connected to the same urban photoshoot. No extra people, no text, no logos, no watermark, no distorted face or hands.",
        "Frame 2 of the selected urban portrait session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: second city angle, medium crop, body turn, hand placement, gaze, architecture, background depth, natural daylight, muted urban palette and wardrobe style. Replace only the preview subject with the uploaded person from Image 1 while keeping the uploaded person's real identity, age, facial features, skin tone and hairstyle. Do not copy identity from the preview. Keep the outfit style stable if the previews show the same look, and do not move the scene to a studio or office. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted face or hands.",
        "Frame 3 of the selected urban portrait session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: wider city composition, sidewalk or street depth, pose, walking or standing direction if shown, arm position, gaze, background structure, light and color palette. Replace only the person in Image 2 with the uploaded person from Image 1, preserving identity, age, face shape, skin tone, hairstyle and recognizable features. Do not copy the preview person's identity. Keep this frame part of the same urban set and follow the third preview rather than inventing a different location. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted face or hands.",
    ],
    "evening_look": [
        "Frame 1 of the selected evening portrait session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: close crop, interior background, warm light, body posture, gaze, elegant wardrobe style, palette and refined composition. Replace only the person in Image 2 with the uploaded person from Image 1 while preserving the uploaded person's identity, age, face, skin tone, hairstyle and recognizable features. Do not copy the preview subject's identity or age. Keep the outfit tasteful and safe, with modest, opaque, tasteful and appropriate wardrobe styling. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted face or hands.",
        'Frame 2 of the selected evening portrait session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: medium framing, body angle, hand or arm position, gaze direction, warm interior lighting, background blur, wardrobe style and elegant mood. Replace only the preview subject with the uploaded person from Image 1, preserving identity, age, facial structure, skin tone, hairstyle, recognizability and natural facial features. Adapt expression, gaze and head angle to the selected preview frame. Do not copy identity from Image 2. Keep the styling refined and appropriate, modest, tasteful and appropriate for a public portrait. Keep it consistent with the same evening photoshoot, not a random glamour scene. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted face or hands.',
        "Frame 3 of the selected evening portrait session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: wider indoor crop, posture, gaze, arm placement, room details, warm refined lighting, palette, wardrobe style and overall composition. Replace only the person in Image 2 with the uploaded person from Image 1 while preserving the uploaded person's identity, age, face, skin tone and hairstyle. Do not copy the preview subject's identity. Keep the outfit safe, tasteful and consistent with the preview set, with modest, opaque, tasteful and appropriate wardrobe styling. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted face or hands.",
    ],
    "tender_photoshoot": [
        "Frame 1 of the selected tender photoshoot. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: soft crop, seated or relaxed posture if shown, gaze direction, hand visibility, cozy background, gentle daylight, muted palette, wardrobe style and delicate composition. Replace only the preview subject with the uploaded person from Image 1, preserving the uploaded person's identity, age, face, skin tone, hairstyle and recognizable features. Do not copy the preview subject's face or identity. Keep the outfit tasteful, safe and soft, with modest, opaque, tasteful and appropriate wardrobe styling. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted face or hands.",
        'Frame 2 of the selected tender photoshoot. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: second pose, medium crop, body angle, hand placement near face, sofa or interior structure if present, soft light, warm beige palette, wardrobe style and calm mood. Replace only the person in Image 2 with the uploaded person from Image 1 while preserving identity, age, facial features, skin tone and hairstyle. Do not copy identity from Image 2. Keep the frame connected to the same tender session and follow the preview rather than inventing a new room or pose. Photorealistic, natural, high quality. No extra people, no text, no watermark, modest styling, no distorted hands or face.',
        "Frame 3 of the selected tender photoshoot. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: wider or more intimate crop as shown, pose, head direction, arm position, background decor, soft daylight, cozy palette, wardrobe style and overall composition. Replace only the preview subject with the uploaded person from Image 1, preserving identity, age, face shape, skin tone, hairstyle and recognizable features. Do not copy the preview subject's identity. Keep the outfit safe, consistent and tasteful; modest, opaque, tasteful and appropriate wardrobe styling. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted face or hands.",
    ],
    "summer_photoshoot": [
        "Frame 1 of the selected summer photoshoot. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: summer location, close crop, camera distance, pose, gaze direction, background blur, sunlight, warm color palette, outfit style and relaxed composition. Replace only the person in Image 2 with the uploaded person from Image 1, preserving the uploaded person's identity, age, facial features, skin tone, hairstyle and recognizable features. Do not copy the preview subject's identity. Keep the result fresh, natural, photorealistic and connected to the same summer set. No extra people, no text, no logos, no watermark, no distorted face or hands.",
        'Frame 2 of the selected summer photoshoot. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: medium crop, body turn, hand position, gaze, summer wardrobe style, greenery or terrace background, warm daylight and overall composition. Replace only the preview subject with the uploaded person from Image 1 while preserving identity, age, face shape, skin tone, hairstyle, recognizability and natural facial features. Adapt expression, gaze and head angle to the selected preview frame. Do not copy identity from Image 2. Keep the outfit style stable if the previews show one consistent look, and do not shift the scene into studio, office, winter or evening glamour. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted face or hands.',
        "Frame 3 of the selected summer photoshoot. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: wider lifestyle crop, walking or standing pose if shown, body direction, arm placement, environment depth, sunlight, palette, wardrobe style and relaxed summer mood. Replace only the preview subject with the uploaded person from Image 1, preserving identity, age, face, skin tone, hairstyle and recognizable features. Do not copy the preview subject's identity. Keep the frame part of the same summer session and follow the third preview's location and composition. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted face or hands.",
    ],
    "winter_photoshoot": [
        "Frame 1 of the selected winter photoshoot. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: snowy background, close crop, camera distance, winter outfit style, pose, gaze direction, daylight mood, muted palette and cozy composition. Replace only the preview subject with the uploaded person from Image 1, preserving the uploaded person's identity, age, facial structure, skin tone, hairstyle and recognizable features. Do not copy the preview subject's face, identity or age. Keep the image warm, natural and photorealistic, not harsh or theatrical. No extra people, no text, no logos, no watermark, no distorted face or hands.",
        'Frame 2 of the selected winter photoshoot. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: medium crop, body angle, hand position on coat or scarf if shown, snowy path or trees, winter clothing style, soft daylight and calm seasonal palette. Replace only the person in Image 2 with the uploaded person from Image 1 while preserving identity, age, face, skin tone, hairstyle, recognizability and natural facial features. Adapt expression, gaze and head angle to the selected preview frame. Do not copy identity from Image 2. Keep the outfit style consistent with the winter previews and do not change the scene into studio, autumn, city cafe or summer. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted face or hands.',
        "Frame 3 of the selected winter photoshoot. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: wider crop, walking or side pose if shown, arm placement, snowy environment depth, trees or path structure, daylight, winter wardrobe style and overall composition. Replace only the preview subject with the uploaded person from Image 1, preserving identity, age, facial features, skin tone and hairstyle. Do not copy the preview subject's identity. Keep the frame connected to the same winter walk and follow the third preview rather than inventing a new location. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted face or hands.",
    ],
    "home_portrait": [
        "Frame 1 of the selected home portrait session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: home interior, sofa or room layout, close crop, posture, gaze direction, natural window light, casual wardrobe style, warm palette and relaxed composition. Replace only the preview subject with the uploaded person from Image 1, preserving the uploaded person's identity, age, face, skin tone, hairstyle and recognizable features. Do not copy the preview subject's face or identity. Keep the image authentic, cozy, photorealistic and part of the same home session, not a studio or hotel scene. No extra people, no text, no watermark, no distorted hands or face.",
        'Frame 2 of the selected home portrait session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: second home pose, medium crop, body angle, hand placement, sofa or room details, soft window light, wardrobe style and cozy color palette. Replace only the person in Image 2 with the uploaded person from Image 1, preserving identity, age, facial structure, skin tone, hairstyle, recognizability and natural facial features. Adapt expression, gaze and head angle to the selected preview frame. Do not copy identity from Image 2. Keep the outfit style stable if the previews show one look, and do not move the scene to studio, office, cafe or luxury hotel unless shown. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted face or hands.',
        "Frame 3 of the selected home portrait session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: wider home composition, seated or relaxed pose, arm position, gaze, sofa, living room background, daylight, wardrobe style and warm domestic mood. Replace only the preview subject with the uploaded person from Image 1 while preserving identity, age, face, skin tone, hairstyle and recognizable features. Do not copy the preview subject's identity. Keep this frame consistent with the same home photoshoot and follow the third preview's framing. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted hands or face.",
    ],
    "expert_photoshoot": [
        "Frame 1 of the selected expert photoshoot. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: professional crop, camera distance, posture, gaze direction, background, lighting, smart wardrobe style, palette and trustworthy composition. Replace only the preview subject with the uploaded person from Image 1, preserving the uploaded person's identity, age, facial structure, skin tone, hairstyle and recognizable features. Do not copy the preview subject's face, identity or age. Keep the result professional, calm, competent and photorealistic, suitable for an expert profile. No extra people, no text, no logos, no watermark, no distorted face or hands.",
        'Frame 2 of the selected expert photoshoot. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: medium professional crop, body angle, head turn, hand visibility if present, background structure, soft light, business-casual wardrobe style and composed expert mood. Replace only the preview subject with the uploaded person from Image 1 while preserving identity, age, facial features, skin tone, hairstyle and expression. Do not copy identity from Image 2. Keep it clean, trustworthy and not too glamour, not cafe or home unless the preview shows that. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted hands or face.',
        "Frame 3 of the selected expert photoshoot. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: wider professional composition, posture, visible hands if shown, body angle, gaze, background, lighting mood, wardrobe style and presentation-ready framing. Replace only the person in Image 2 with the uploaded person from Image 1, preserving identity, age, face, skin tone, hairstyle and recognizable features. Do not copy the preview subject's identity. Keep the outfit style stable across the expert set and keep the result polished, credible and photorealistic. No extra people, no text, no logos, no watermark, no distorted face or hands.",
    ],
    "business_brand": [
        "Frame 1 of the selected business brand session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: business-brand crop, camera distance, posture, gaze, clean background, lighting mood, wardrobe style, palette and polished composition. Replace only the preview subject with the uploaded person from Image 1, preserving the uploaded person's identity, age, face, skin tone, hairstyle and recognizable features. Do not copy the preview subject's identity or age. Keep the look professional, modern, credible and photorealistic, suitable for website or profile use. No extra people, no text, no logos, no watermark, no distorted face or hands.",
        'Frame 2 of the selected business brand session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: medium crop, body orientation, hand position, professional outfit style, studio or clean background, soft light, neutral palette and overall composition. Replace only the person in Image 2 with the uploaded person from Image 1 while preserving identity, age, facial features, skin tone, hairstyle, recognizability and natural facial features. Adapt expression, gaze and head angle to the selected preview frame. Do not copy identity from Image 2. Keep the outfit style stable with the preview set and avoid glamour, random casual locations or unrelated backgrounds. Photorealistic, natural, high quality. No text, no watermark, no extra people, no distorted face or hands.',
        "Frame 3 of the selected business brand session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: wider brand portrait framing, three-quarter angle, arm or hand placement, gaze, background, lighting, professional wardrobe style and negative space. Replace only the preview subject with the uploaded person from Image 1, preserving identity, age, face shape, skin tone, hairstyle and recognizable features. Do not copy the preview subject's face or identity. Keep the frame consistent with the same business brand series and follow the third preview's composition. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted hands or face.",
    ],
    "personal_brand": [
        "Frame 1 of the selected personal brand session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: close crop, camera distance, posture, gaze direction, background, light quality, wardrobe style, palette and open brand-focused composition. Replace only the preview subject with the uploaded person from Image 1, preserving identity, age, face, skin tone, hairstyle and recognizable features. Do not copy the preview subject's identity or age. Keep the image modern, natural, approachable, photorealistic and suitable for social media or profile use. No extra people, no text, no logos, no watermark, no distorted face or hands.",
        'Frame 2 of the selected personal brand session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: medium crop, body turn, hand or arm position, gaze, setting, soft light, wardrobe style and lifestyle-professional mood. Replace only the person in Image 2 with the uploaded person from Image 1, preserving identity, age, facial structure, skin tone, hairstyle, recognizability and natural facial features. Adapt expression, gaze and head angle to the selected preview frame. Do not copy identity from Image 2. Keep the outfit style stable if the previews show one look, and do not shift into a random corporate, home, cafe or glamour scene unless the preview shows it. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted face or hands.',
        "Frame 3 of the selected personal brand session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: wider lifestyle-brand crop, environment visibility, body orientation, arm position, gaze, background structure, light, wardrobe style and overall composition. Replace only the preview subject with the uploaded person from Image 1 while preserving identity, age, face, skin tone, hairstyle and recognizable features. Do not copy the preview subject's identity. Keep it connected to the same brand session and follow the third preview rather than inventing a new setting. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted face or hands.",
    ],
    "travel_portrait": [
        "Frame 1 of the selected travel portrait session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: travel background, close crop, camera distance, pose, body direction, gaze, daylight, wardrobe style, color palette and atmospheric composition. Replace only the preview subject with the uploaded person from Image 1, preserving the uploaded person's identity, age, face, skin tone, hairstyle and recognizable features. Do not copy the preview subject's face or identity. Keep the result natural, relaxed, photorealistic and tied to the same travel location shown in the preview. No extra people, no text, no logos, no watermark, no distorted face or hands.",
        'Frame 2 of the selected travel portrait session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: second travel angle, medium crop, hand position, body turn, street or scenic structure, daylight, wardrobe style, palette and relaxed expression. Replace only the person in Image 2 with the uploaded person from Image 1 while preserving identity, age, facial features, skin tone, hairstyle, recognizability and natural facial features. Adapt expression, gaze and head angle to the selected preview frame. Do not copy identity from Image 2. Keep the outfit and location family consistent with the travel preview set; do not move to studio, office, beach or winter unless preview shows it. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted face or hands.',
        "Frame 3 of the selected travel portrait session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: wider travel composition, walking or turning pose if shown, arm placement, environmental depth, background architecture or landscape, light, wardrobe style and overall frame layout. Replace only the preview subject with the uploaded person from Image 1, preserving identity, age, face, skin tone, hairstyle and recognizable features. Do not copy the preview subject's identity. Keep it as the same travel photoshoot and follow the third preview's scene and camera distance. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted face or hands.",
    ],
    "cafe_city": [
        "Frame 1 of the selected cafe-city session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: cafe table or window setting, close crop, seated or leaning posture, hand position, gaze, coffee or decor if present, warm light, city background, wardrobe style and composition. Replace only the preview subject with the uploaded person from Image 1, preserving identity, age, face, skin tone, hairstyle and recognizable features. Do not copy the preview subject's identity. Keep the result natural, stylish, photorealistic and connected to the same cafe-city outing. No extra people, no text, no logos, no watermark, no distorted face or hands.",
        'Frame 2 of the selected cafe-city session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: second cafe angle, medium crop, body turn, gaze, hand placement, table or window details, warm cafe light, city-through-window background, wardrobe style and muted palette. Replace only the person in Image 2 with the uploaded person from Image 1 while preserving identity, age, facial features, skin tone, hairstyle and expression. Do not copy identity from Image 2. Keep the outfit style stable and do not shift to an office, studio, club or crowded restaurant unless the preview shows it. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted face or hands.',
        "Frame 3 of the selected cafe-city session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: wider cafe or street composition, standing or outdoor pose if shown, body angle, arm position, cafe facade or city background, light, wardrobe style and overall layout. Replace only the preview subject with the uploaded person from Image 1, preserving identity, age, face shape, skin tone, hairstyle and recognizable features. Do not copy the preview subject's identity. Keep the frame part of the same cafe-city photoshoot and follow the third preview's location. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted hands or face.",
    ],
    "park_walk": [
        "Frame 1 of the selected park walk session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: green park background, close crop, camera distance, relaxed posture, gaze direction, soft daylight, casual wardrobe style, fresh palette and natural outdoor composition. Replace only the preview subject with the uploaded person from Image 1, preserving identity, age, facial structure, skin tone, hairstyle and recognizable features. Do not copy the preview subject's identity or age. Keep the result calm, natural, photorealistic and tied to the same park setting. No extra people, no text, no logos, no watermark, no distorted face or hands.",
        'Frame 2 of the selected park walk session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: second park angle, medium crop, body turn, hand position, bench or path details if present, trees, soft daylight, casual outfit style and relaxed mood. Replace only the person in Image 2 with the uploaded person from Image 1 while preserving identity, age, face, skin tone, hairstyle, recognizability and natural facial features. Adapt expression, gaze and head angle to the selected preview frame. Do not copy identity from Image 2. Keep the outfit style stable and do not change the setting to city street, studio, business interior or winter unless the preview shows it. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted face or hands.',
        "Frame 3 of the selected park walk session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: wider park crop, walking or standing pose if shown, body direction, arm placement, path depth, trees, daylight, wardrobe style and overall composition. Replace only the preview subject with the uploaded person from Image 1, preserving the uploaded person's identity, age, face, skin tone, hairstyle and recognizable features. Do not copy the preview subject's identity. Keep this as one continuous park walk photoshoot and follow the third preview frame closely. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted face or hands.",
    ],
    "premium_portrait": [
        "Frame 1 of the selected premium portrait session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: premium studio crop, camera distance, posture, gaze, dark or refined backdrop, soft sculpting light, wardrobe style, palette and editorial composition. Replace only the preview subject with the uploaded person from Image 1, preserving identity, age, face, skin tone, hairstyle and recognizable features. Do not copy the preview subject's identity or age. Keep the styling tasteful, polished, photorealistic and modest, tasteful and appropriate for a public portrait. No extra people, no text, no logos, no watermark, no distorted face or hands.",
        'Frame 2 of the selected premium portrait session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: medium premium crop, body turn, head angle, hand or arm position if visible, dark studio background, lighting direction, wardrobe style and luxury mood. Replace only the person in Image 2 with the uploaded person from Image 1 while preserving identity, age, facial features, skin tone, hairstyle and expression. Do not copy identity from Image 2. Keep the outfit style stable and tasteful, with modest, opaque, tasteful and appropriate wardrobe styling. Photorealistic, natural, high quality. No text, no watermark, no extra people, no distorted face or hands.',
        "Frame 3 of the selected premium portrait session. Use Image 1 as the identity reference and Image 2 as the exact visual blueprint for this frame. Match the preview closely: wider editorial crop, negative space, body angle, gaze direction, arm placement, backdrop, soft dramatic light, premium wardrobe style and overall layout. Replace only the preview subject with the uploaded person from Image 1, preserving identity, age, face, skin tone, hairstyle and recognizable features. Do not copy the preview subject's identity. Keep the frame connected to the same premium studio set and do not invent a lifestyle or office scene. Photorealistic, natural, high quality. No extra people, no text, no watermark, no distorted face or hands.",
    ],
}


def build_photoshoot_prompt(base_prompt: str, frame_prompt: str) -> str:
    """Assemble final per-frame instruction for Gemini photoshoot generation."""
    return (
        f"{base_prompt.strip()}\n\n"
        f"{IDENTITY_LOCK_PROMPT}\n\n"
        f"{frame_prompt.strip()}\n\n"
        f"{NEGATIVE_QUALITY_PROMPT}\n\n"
        f"{STANDALONE_SINGLE_IMAGE_RULES}\n"
        "Верни ровно одно готовое изображение. Без NSFW."
    )


def _catalog_lookup_ids(client_style_id: str, style: PhotoshootStyle) -> list[str]:
    normalized = (client_style_id or "").strip()
    candidates: list[str] = []
    if normalized:
        candidates.append(normalized)
    if style.id not in candidates:
        candidates.append(style.id)
    return candidates


def _frame_prompts_from_catalog_item(
    item: dict,
    output_count: int,
) -> list[str] | None:
    raw = item.get("framePrompts")
    if not isinstance(raw, list):
        return None
    prompts = [str(value).strip() for value in raw if str(value).strip()]
    if len(prompts) < output_count:
        return None
    return prompts[:output_count]


def resolve_frame_prompts(
    client_style_id: str,
    style: PhotoshootStyle,
    *,
    output_count: int,
) -> list[str]:
    for lookup_id in _catalog_lookup_ids(client_style_id, style):
        item = get_photoshoot_catalog_item(lookup_id)
        if item is None:
            continue
        from_catalog = _frame_prompts_from_catalog_item(item, output_count)
        if from_catalog is not None:
            return from_catalog
        authored = FRAME_PROMPTS_BY_STYLE_ID.get(lookup_id)
        if authored is not None and len(authored) >= output_count:
            return authored[:output_count]

    for lookup_id in _catalog_lookup_ids(client_style_id, style):
        authored = FRAME_PROMPTS_BY_STYLE_ID.get(lookup_id)
        if authored is not None and len(authored) >= output_count:
            return authored[:output_count]

    return list(GENERIC_FRAME_PROMPTS[:output_count])


def _append_style_locks(prompt: str, client_style_id: str) -> str:
    return f"{prompt.strip()}\n\n{build_style_lock_prompt_block(client_style_id)}"


def resolve_prompt_source(
    client_style_id: str,
    style: PhotoshootStyle,
    *,
    user_description: str | None,
) -> str:
    normalized_id = (client_style_id or "").strip()
    is_custom = (
        normalized_id == CUSTOM_PHOTOSHOOT_STYLE_ID
        or style.id == CUSTOM_PHOTOSHOOT_STYLE_ID
    )
    if is_custom:
        if user_description and user_description.strip():
            return "custom_user_description"
        return "fallback_style_instruction"

    for lookup_id in _catalog_lookup_ids(client_style_id, style):
        item = get_photoshoot_catalog_item(lookup_id)
        if item is not None:
            prompt = item.get("prompt")
            if isinstance(prompt, str) and prompt.strip():
                return "backend_catalog"

    if style.instruction.strip():
        return "fallback_style_instruction"
    return "fallback_style_instruction"


def resolve_base_prompt(
    client_style_id: str,
    style: PhotoshootStyle,
    *,
    user_description: str | None,
) -> str:
    prompt_source = resolve_prompt_source(
        client_style_id,
        style,
        user_description=user_description,
    )
    if prompt_source == "custom_user_description":
        return user_description.strip()  # type: ignore[union-attr]

    for lookup_id in _catalog_lookup_ids(client_style_id, style):
        item = get_photoshoot_catalog_item(lookup_id)
        if item is not None:
            prompt = item.get("prompt")
            if isinstance(prompt, str) and prompt.strip():
                return prompt.strip()

    return style.instruction.strip()


def build_photoshoot_frame_prompt(
    client_style_id: str,
    style: PhotoshootStyle,
    *,
    frame_index: int,
    output_count: int,
    user_description: str | None = None,
    series_reference_mode: str = "legacy",
) -> str:
    """Build Gemini instruction for one photoshoot frame (0-based index)."""
    base_prompt = resolve_base_prompt(
        client_style_id,
        style,
        user_description=user_description,
    )
    frame_prompts = resolve_frame_prompts(
        client_style_id,
        style,
        output_count=output_count,
    )
    safe_index = min(max(frame_index, 0), len(frame_prompts) - 1)
    prompt = build_photoshoot_prompt(base_prompt, frame_prompts[safe_index])
    if output_count > 1:
        prompt = (
            f"{prompt}\n\n"
            f"{build_universal_photoshoot_diversity_rules(frame_index, output_count)}"
        )
    if frame_index == 0 and series_reference_mode in {"identity_anchor", "anchor_only"}:
        prompt = f"{prompt}\n\n{build_series_anchor_frame_prompt()}"
    if frame_index > 0 and series_reference_mode in {"identity_anchor", "anchor_only"}:
        prompt = (
            f"{prompt}\n\n"
            f"{build_series_continuation_reference_prompt(series_reference_mode, frame_index, client_style_id)}"
        )
    return _append_style_locks(prompt, client_style_id)


KIE_VERTICAL_PORTRAIT_FORMAT_INSTRUCTION = (
    "Generate a vertical portrait photo in 3:4 aspect ratio.\n"
    "Do not create a horizontal/wide image.\n"
    "Keep the person fully framed for the requested crop."
)

KIE_IDENTITY_ONLY_REFERENCE_INSTRUCTION = (
    "Use Image 1 only as the identity reference. Do not copy the source photo pose, "
    "crop, background, clothes, or lighting. Create a new photo in the selected style."
)

KIE_PHOTOSHOOT_PREVIEW_REFERENCE_INSTRUCTION = (
    "Image roles:\n"
    "- Image 1 is the uploaded user photo. Use it only as the identity reference: face, "
    "age, facial proportions, skin tone, natural facial features and recognizability.\n"
    "- Image 1 must NOT be used as pose, crop, head angle, gaze, expression, hair silhouette, "
    "background, wardrobe or lighting reference.\n"
    "- Do not paste, clone, or transplant the face or head from Image 1.\n"
    "- Image 2 is the selected photoshoot preview reference for this exact frame. Use it as "
    "the main visual blueprint: pose, crop, camera distance, body angle, hand position, head angle, "
    "gaze direction, facial orientation, expression mood, background, lighting mood, color palette, "
    "wardrobe style and overall composition.\n"
    "- Reconstruct the uploaded person's identity naturally inside the pose and camera angle of Image 2.\n"
    "- Match Image 2 head angle, gaze direction, facial orientation, expression mood, camera "
    "distance and crop.\n"
    "- Replace only the person from Image 2 with the uploaded person from Image 1.\n"
    "- Do not copy the face, identity, age or personal features from Image 2.\n"
    "- Preserve recognizability from Image 1, but adapt the face to Image 2's pose and perspective.\n"
    "- Hair may follow the uploaded person's recognizable color, texture and length, but its placement "
    "and silhouette should adapt to the preview pose and scene."
)


def append_kie_vertical_portrait_instruction(prompt: str) -> str:
    """Kie image-to-image format guard (vertical 3:4 portrait)."""
    return f"{prompt}\n\n{KIE_VERTICAL_PORTRAIT_FORMAT_INSTRUCTION}"


def build_kie_independent_frame_composition(frame_index: int) -> str:
    """Frame-specific shot targets when Kie uses identity-only references."""
    if frame_index <= 0:
        return (
            "Independent frame shot (frame 1 of 3):\n"
            "Close-up or chest-up opening portrait. Calm or direct gaze. Establish outfit, "
            "location, lighting, and color grading for the series through prompt and style only."
        )
    if frame_index == 1:
        return (
            "Independent frame shot (frame 2 of 3):\n"
            "Medium portrait with a clear three-quarter body turn. Different head angle, "
            "hand and arm position, gaze, crop, and camera distance from frame 1."
        )
    return (
        "Independent frame shot (frame 3 of 3):\n"
        "Wider waist-up or lifestyle portrait with more environment visible. Different body "
        "orientation, gaze, and hand/arm position from frames 1 and 2."
    )


KIE_RESCUE_NEGATIVE_RULES = (
    "No text, logos, watermarks, distorted faces, extra fingers, plastic skin, "
    "or duplicate people."
)


def build_kie_rescue_frame_prompt(
    style: PhotoshootStyle,
    *,
    frame_index: int,
    use_preview_reference: bool = False,
) -> str:
    """Short rescue prompt after Kie task failure (identity + style + frame shot)."""
    title = (style.title or "Photoshoot").strip()
    if use_preview_reference:
        return (
            f"Rescue regeneration for photoshoot style: {title}.\n"
            f"{KIE_PHOTOSHOOT_PREVIEW_REFERENCE_INSTRUCTION}\n"
            "Do not copy the uploaded photo pose or face angle. Recreate the same identity "
            "in the preview pose.\n"
            "Match the preview composition while keeping the result safe, modest, and "
            "photorealistic. Preserve identity from Image 1.\n"
            "No NSFW content, no revealing clothing, no policy-sensitive content, "
            "no text or logos.\n"
            f"{KIE_RESCUE_NEGATIVE_RULES}\n"
            f"{KIE_VERTICAL_PORTRAIT_FORMAT_INSTRUCTION}"
        )
    return (
        f"Rescue regeneration for photoshoot style: {title}.\n"
        f"{KIE_IDENTITY_ONLY_REFERENCE_INSTRUCTION}\n"
        f"{build_kie_independent_frame_composition(frame_index)}\n"
        f"{KIE_RESCUE_NEGATIVE_RULES}\n"
        f"{KIE_VERTICAL_PORTRAIT_FORMAT_INSTRUCTION}"
    )


def build_kie_photoshoot_frame_prompt(
    client_style_id: str,
    style: PhotoshootStyle,
    *,
    frame_index: int,
    output_count: int,
    user_description: str | None = None,
    series_reference_mode: str = "legacy",
    use_preview_reference: bool = False,
) -> str:
    """Build Kie photoshoot instruction for one frame."""
    base_prompt = resolve_base_prompt(
        client_style_id,
        style,
        user_description=user_description,
    )
    frame_prompts = resolve_frame_prompts(
        client_style_id,
        style,
        output_count=output_count,
    )
    safe_index = min(max(frame_index, 0), len(frame_prompts) - 1)
    prompt = build_photoshoot_prompt(base_prompt, frame_prompts[safe_index])
    if output_count > 1 and not use_preview_reference:
        prompt = (
            f"{prompt}\n\n"
            f"{build_universal_photoshoot_diversity_rules(frame_index, output_count)}"
        )
    mode = series_reference_mode.strip().lower()
    if mode in {"identity_anchor", "anchor_only", "legacy"}:
        if use_preview_reference:
            prompt = f"{prompt}\n\n{KIE_PHOTOSHOOT_PREVIEW_REFERENCE_INSTRUCTION}"
        else:
            prompt = f"{prompt}\n\n{KIE_IDENTITY_ONLY_REFERENCE_INSTRUCTION}"
            if output_count > 1:
                prompt = f"{prompt}\n\n{build_kie_independent_frame_composition(frame_index)}"
    return append_kie_vertical_portrait_instruction(_append_style_locks(prompt, client_style_id))


def build_series_anchor_frame_prompt() -> str:
    """Instructions for frame 0 when it becomes the series style anchor."""
    return (
        "Series anchor frame (frame 1 of 3):\n"
        "Create the main portrait for this photoshoot — calm, direct shot, close-up or chest-up. "
        "Establish a clear wardrobe, background, location, lighting, and color grading that "
        "later frames will match. This frame sets the style anchor for the series."
    )


def build_universal_photoshoot_diversity_rules(
    frame_index: int,
    output_count: int,
) -> str:
    """Shared composition diversity rules applied to every photoshoot style."""
    _ = output_count
    if frame_index <= 0:
        return (
            "Universal photoshoot diversity rules (frame 1 of 3):\n"
            "Close or chest-up identity anchor. Calm or direct gaze. Establish outfit, location, "
            "lighting, and color grading for the series. This frame is the style anchor."
        )
    if frame_index == 1:
        return (
            "Universal photoshoot diversity rules (frame 2 of 3):\n"
            "Medium portrait with a clear three-quarter body turn. Different head angle from "
            "frame 1. Different hand and arm position. Slightly different crop and camera distance. "
            "Must not mirror frame 1 pose, gaze, or composition."
        )
    return (
        "Universal photoshoot diversity rules (frame 3 of 3):\n"
        "Wider waist-up or lifestyle portrait with more environment visible. Different body "
        "orientation from frames 1 and 2. Different gaze and clearly different hand/arm position. "
        "Critical: frame 3 must differ from both frame 1 and frame 2. Do not reuse the pose, "
        "crop, body angle, hands, gaze, or background framing from frame 2."
    )


def build_series_anti_duplicate_rules(
    *,
    style_image_label: str,
    previous_image_label: str | None = None,
) -> str:
    """Rules to prevent copying pose/composition from reference frames."""
    previous_block = ""
    if previous_image_label:
        previous_block = (
            f"8. {previous_image_label} is an avoid-copy reference only — do not repeat its pose, "
            "crop, body angle, hands, gaze, or background framing.\n"
        )
    return (
        "Anti-duplicate rules (critical):\n"
        f"1. {style_image_label} is a style reference only, not a pose/composition reference.\n"
        f"2. Do not recreate {style_image_label}.\n"
        "3. Do not copy the same pose, same crop, same camera angle, same facial expression.\n"
        "4. Generate a clearly different photo from the same photoshoot.\n"
        "5. Keep the same person, same outfit, same location, same lighting, same color grading.\n"
        f"6. Change at least 3 visual elements compared to {style_image_label}:\n"
        "   - camera distance / crop\n"
        "   - body angle\n"
        "   - head direction / gaze\n"
        "   - hand position / arms position\n"
        "   - seated vs standing pose\n"
        "   - background framing\n"
        "7. The result must look like another shot from the same professional photoshoot, "
        "not a duplicate.\n"
        f"{previous_block}"
        "One photoshoot, three different shots — not three different looks or outfits."
    )


def build_series_continuation_frame_composition(frame_index: int) -> str:
    """Frame-specific pose and composition targets for continuation frames."""
    if frame_index == 1:
        return (
            "This shot (frame 2 of 3) — noticeably different from the anchor frame:\n"
            "Medium shot with a clear three-quarter body turn. Camera at a different distance "
            "than the anchor. Gaze slightly off-camera or to the side. Different hand and arm "
            "position. Must not mirror the anchor pose, crop, or expression."
        )
    if frame_index >= 2:
        return (
            "This shot (frame 3 of 3) — clearly different from frames 1 and 2:\n"
            "Wider portrait or waist-up framing with a different camera distance. Distinct body "
            "pose — for example hands folded, resting on a table/chair/wall, or a relaxed standing "
            "pose. Different head angle and gaze. Same outfit and location, but not the same "
            "composition as the anchor frame or frame 2."
        )
    return ""


def build_series_continuation_reference_prompt(
    series_reference_mode: str,
    frame_index: int,
    client_style_id: str,
) -> str:
    """Explain reference image roles and anti-duplicate rules for continuation frames."""
    composition = build_series_continuation_frame_composition(frame_index)
    composition_block = f"\n\n{composition}" if composition else ""

    if series_reference_mode == "anchor_only":
        if frame_index >= 2:
            anti_duplicate = build_series_anti_duplicate_rules(
                style_image_label="Image 1",
                previous_image_label="Image 2",
            )
            return (
                "Reference image roles for this request:\n"
                "Image 1: The first generated frame of this photoshoot series. Use it only as a "
                "style anchor — preserve wardrobe, background, location, lighting, color grading, "
                "and processing. Do NOT copy its pose, crop, camera angle, or facial expression.\n"
                "Image 2: The immediately previous generated frame (frame 2). Avoid-copy reference "
                "only — do NOT copy its pose, crop, body angle, hands, gaze, or background framing.\n"
                "Generate exactly ONE new frame of the same photoshoot.\n\n"
                f"{anti_duplicate}"
                f"{composition_block}\n\n"
                f"{build_style_lock_prompt_block(client_style_id)}"
            )
        anti_duplicate = build_series_anti_duplicate_rules(style_image_label="Image 1")
        return (
            "Reference image roles for this request:\n"
            "Image 1: The first generated frame of this photoshoot series. Use it only as a "
            "style anchor — preserve wardrobe, background, location, lighting, color grading, "
            "and processing. Do NOT copy its pose, crop, camera angle, or facial expression.\n"
            "Generate exactly ONE new frame of the same photoshoot.\n\n"
            f"{anti_duplicate}"
            f"{composition_block}\n\n"
            f"{build_style_lock_prompt_block(client_style_id)}"
        )

    if frame_index >= 2:
        anti_duplicate = build_series_anti_duplicate_rules(
            style_image_label="Image 2",
            previous_image_label="Image 3",
        )
        return (
            "Reference image roles for this request:\n"
            "Image 1: The original user photo. Identity reference only — preserve face, age, facial "
            "features, skin tone, hair, and recognizability. Do not copy pose or composition from "
            "Image 1 unless needed for identity.\n"
            "Image 2: The first generated frame of this photoshoot series. Style anchor only — "
            "preserve wardrobe, background, location, lighting, color grading, and processing. "
            "Do NOT copy pose, crop, camera angle, or facial expression from Image 2.\n"
            "Image 3: The immediately previous generated frame (frame 2). Avoid-copy reference only — "
            "do NOT copy its pose, crop, body angle, hands, gaze, or background framing.\n"
            "Generate exactly ONE new frame of the same photoshoot.\n\n"
            f"{anti_duplicate}"
            f"{composition_block}\n\n"
            f"{build_style_lock_prompt_block(client_style_id)}"
        )

    anti_duplicate = build_series_anti_duplicate_rules(style_image_label="Image 2")
    return (
        "Reference image roles for this request:\n"
        "Image 1: The original user photo. Identity reference only — preserve face, age, facial "
        "features, skin tone, hair, and recognizability. Do not copy pose or composition from "
        "Image 1 unless needed for identity.\n"
        "Image 2: The first generated frame of this photoshoot series. Style anchor only — "
        "preserve wardrobe, background, location, lighting, color grading, and processing. "
        "Do NOT copy pose, crop, camera angle, or facial expression from Image 2.\n"
        "Generate exactly ONE new frame of the same photoshoot.\n\n"
        f"{anti_duplicate}"
        f"{composition_block}\n\n"
        f"{build_style_lock_prompt_block(client_style_id)}"
    )


def build_identity_only_fallback_prompt_suffix(
    *,
    frame_index: int,
    output_count: int,
    client_style_id: str | None = None,
) -> str:
    """Extra instructions when continuation frame falls back to original photo only."""
    frame_number = min(max(frame_index, 0), output_count - 1) + 1
    lines = [
        f"\n\nFallback generation mode (frame {frame_number} of {output_count}):",
        f"Generate this as frame {frame_number} of {output_count} of the same photoshoot.",
        "The style anchor image is not attached because the previous attempt copied it or failed.",
        "Use the original photo only for identity.",
        "Follow the chosen style from the text instructions exactly.",
        "Keep the same outfit described in the selected style.",
        "Keep the same background/location described in the selected style.",
        "Keep the same lighting and color grading described in the selected style.",
        "Do not switch to a different outfit color or neckline.",
        "Do not switch to a different location or background.",
        "This is not a new look; it is another frame from the same photoshoot.",
        "Create a different frame from all previous generated frames.",
        "Do not repeat the same pose, crop, face angle, gaze, expression, or camera distance.",
    ]
    if client_style_id:
        lines.append(build_style_lock_prompt_block(client_style_id))
    lines.append("Return exactly one image.")
    return "\n".join(lines)


def build_safe_frame0_fallback_prompt(client_style_id: str) -> str:
    """Neutral English fallback prompt for frame 0 after empty Gemini image response."""
    prompt = (
        "Create one realistic professional portrait photo of the person in the attached image.\n"
        "Preserve the same identity, face, age, facial features, hair, and natural expression.\n"
        "Use a modest polished outfit, soft natural light, and a background matching the selected style.\n"
        "Make it look like the first photo from a calm professional photoshoot.\n"
        "Do not create a collage, text, logo, watermark, multiple people, or multiple panels.\n"
        "Return exactly one image."
    )
    return _append_style_locks(prompt, client_style_id)


def build_safe_continuation_fallback_prompt_suffix(
    *,
    frame_index: int,
    output_count: int,
    client_style_id: str | None = None,
) -> str:
    """Ultra-safe suffix when identity-only continuation fallback returns empty image."""
    frame_number = min(max(frame_index, 0), output_count - 1) + 1
    lines = [
        f"\n\nSafe continuation fallback (frame {frame_number} of {output_count}):",
        "Keep only the same person from the attached original photo.",
        "Follow the selected style text instructions for outfit, background, location, and lighting.",
        "Keep the outfit modest and consistent with the selected style instructions.",
        "Keep the same location/background type as previous frames according to the style text.",
        "Change only pose, crop, gaze, and camera distance.",
        "Do not change clothing color dramatically.",
        "Do not switch to a different outfit color, neckline, or location.",
        "Do not introduce black off-shoulder or open neckline if the style asks for a modest polished outfit.",
        "Make it clearly different from previous generated frames in pose and framing only.",
        "Avoid complex scene, dramatic lighting, glamour, nightlife, low-light, luxury, "
        "cinematic, fashion editorial.",
    ]
    if client_style_id:
        lines.append(build_style_lock_prompt_block(client_style_id))
    lines.append("Return exactly one image.")
    return "\n".join(lines)


_SAFE_A_ONLY_BATCH_FRAME_COMPOSITIONS: tuple[str, ...] = (
    "Frame 1 of 3: Close chest-up direct portrait, straight gaze, calm expression.",
    "Frame 2 of 3: Medium portrait with three-quarter body turn, different camera distance and gaze.",
    "Frame 3 of 3: Wider waist-up portrait, different body angle and off-camera gaze.",
)


def build_safe_a_only_batch_frame_prompt(
    client_style_id: str,
    *,
    frame_index: int,
    output_count: int,
) -> str:
    """Short safe English prompt for full A-only batch fallback after primary pipeline failure."""
    safe_index = min(max(frame_index, 0), len(_SAFE_A_ONLY_BATCH_FRAME_COMPOSITIONS) - 1)
    composition = _SAFE_A_ONLY_BATCH_FRAME_COMPOSITIONS[safe_index]
    frame_number = safe_index + 1
    prompt = (
        f"Safe batch fallback — {composition}\n"
        f"Generate frame {frame_number} of {output_count} for one cohesive photoshoot series.\n"
        "Use the attached original photo for identity only.\n"
        "Create one realistic professional portrait.\n"
        "Keep outfit, location, lighting, and color grading consistent across all frames.\n"
        "Change only pose, crop, gaze, and camera distance between frames.\n"
        "No anchor image is attached. Follow the selected style locks exactly.\n"
        "Return exactly one image."
    )
    hard_rule = get_safe_batch_hard_rule(client_style_id)
    if hard_rule:
        prompt = f"{prompt}\n{hard_rule}"
    return _append_style_locks(prompt, client_style_id)
