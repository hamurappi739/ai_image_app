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
        'Opening frame of the urban session. Create a close portrait with a chest-up to half-body crop on a quiet city sidewalk near a light stone facade. The subject should face the camera in a relaxed posture with a gentle direct gaze and understated expression. Keep the same light neutral city outfit, the same daylight quality and the same elegant urban background. Make the face clearly readable while still preserving a sense of location. The composition should feel clean, stylish and social-media ready. Keep the same identity and the same wardrobe. Photorealistic. Do not duplicate the pose, crop or framing used in the other frames.',
        'Second frame of the same urban session. Create a medium portrait near the same building facade, doorway or column, with the body turned three-quarters and one hand resting naturally near a pocket, lapel or cardigan edge. The gaze can be into camera or slightly off-camera. Use the same outfit, the same soft daylight and the same beige-toned city palette. This frame should clearly differ from the opening image through body angle, hand placement, camera distance and background framing while still feeling part of the same photoshoot. Keep the same identity and the same wardrobe. Photorealistic. No duplicate pose.',
        'Third frame of the same urban session. Create the widest shot of the set, with a waist-up to almost full-body crop on the sidewalk and more of the street depth visible behind the subject. Show a relaxed standing or slow walking pose, with the body slightly turned and the arms in a different natural position from the earlier frames. Maintain the same light neutral outfit, the same architectural street setting and the same daylight mood. Keep the same identity and the same wardrobe. Photorealistic. Do not repeat the pose, crop, gaze direction or composition from the other frames. Preserve the same location, lighting and session mood.',
    ),
    "tender_photoshoot": (
        'Opening frame of the tender session. Create a close portrait with a half-body crop, the subject seated on a cream sofa in soft daylight, shoulders relaxed and a gentle natural smile. The face should be clearly visible and softly lit, with a calm direct gaze and a quiet intimate mood. Keep the same beige-toned interior, the same cream knit outfit and a subtle hint of sofa or soft decor in the background. The composition should feel warm, delicate and inviting. Keep the same identity and the same wardrobe. Photorealistic. Do not duplicate the pose, crop or gaze used in the other frames. Preserve the same location, lighting and session mood.',
        'Second frame of the same tender session. Create a medium seated portrait on the same sofa, with the body turned slightly, the head gently tilted and one hand resting near the chin, cheek, knee or sofa arm. The expression should remain soft and calm. Use the same cream knit outfit, the same daylight from the window and the same beige interior styling. This frame should clearly differ from the opening portrait through hand placement, body angle, crop and composition while staying within the same cozy atmosphere. Keep the same identity and the same wardrobe. Photorealistic. No duplicate pose. Preserve the same location, lighting and session mood.',
        'Third frame of the same tender session. Create a wider but still intimate portrait, showing more of the sofa and soft room elements while keeping the subject comfortably seated. Turn the face slightly toward the light and use a gentle smile or quiet thoughtful expression. The pose should be different from the earlier frames, with a new arm position and more negative space around the subject. Keep the same outfit, the same beige interior and the same warm daylight mood. Keep the same identity and the same wardrobe. Photorealistic. Do not repeat the pose, crop or composition from the other frames.',
    ),
    "home_portrait": (
        'Opening frame of the home session. Create a close portrait with a half-body crop, the subject seated on a sofa near a window, relaxed and approachable. Use a calm direct gaze and a soft natural expression. Keep the face clearly visible, with gentle daylight and a softly blurred background hinting at home decor such as a blanket, vase or plant. Use the same soft casual outfit that will remain unchanged across the series. The image should feel warm and real. Keep the same identity and the same wardrobe. Photorealistic. Do not duplicate the pose, crop or gaze used in the other frames. Preserve the same location, lighting and session mood.',
        'Second frame of the same home session. Create a medium seated portrait, more centered on the sofa, with the body slightly turned and the hands resting naturally on the knees, lap or sofa. The expression should stay soft and friendly. Use the same cozy living room, the same daylight and the same home outfit. This frame should clearly differ from the opening portrait through crop, posture, hand placement and composition while staying within the same room and atmosphere. Keep the same identity and the same wardrobe. Photorealistic. No duplicate pose. Preserve the same location, lighting and session mood.',
        'Third frame of the same home session. Create a wider portrait that shows more of the sofa and living room surroundings while keeping the subject as the focus. The posture should be relaxed and slightly angled, with a new arm position and either a direct soft gaze or a gentle smile. Maintain the same casual outfit, the same window light and the same warm neutral home palette. This should be the most environmental frame of the series. Keep the same identity and the same wardrobe. Photorealistic. Do not repeat the pose, crop or composition from the other frames. Preserve the same location, lighting and session mood.',
    ),
    "cafe_city": (
        'Opening frame of the cafe-city session. Create a close portrait at a small cafe table or beside a large cafe window, with a coffee cup subtly present and a calm confident expression. Use a chest-up crop, direct or near-direct gaze and a relaxed seated posture. Keep the same smart casual outfit, the same warm cafe-window setting and the same city atmosphere visible in the background. The composition should feel cozy, stylish and natural. Keep the same identity and the same wardrobe. Photorealistic. Do not duplicate the pose, crop or gaze used in the other frames. Preserve the same location, lighting and session mood.',
        'Second frame of the same cafe-city session. Create a medium portrait near the same window or table, with the body turned three-quarters and the subject sitting or leaning naturally. A coffee cup or tabletop element may remain lightly visible. Use the same outfit, the same warm cafe light and the same city-through-window context. This frame should clearly differ from the opening image through crop, body angle, hand position and gaze direction while still looking like part of the same outing. Keep the same identity and the same wardrobe. Photorealistic. No duplicate pose. Preserve the same location, lighting and session mood.',
        'Third frame of the same cafe-city session. Create a wider portrait just outside the cafe or near its entrance, showing more of the city street and cafe facade behind the subject. Use a standing pose with relaxed arms and a different orientation from the first two frames. Keep the same smart casual outfit and the same blend of urban and cafe atmosphere. This should be the most environmental frame in the set while still feeling connected to the same place. Keep the same identity and the same wardrobe. Photorealistic. Do not repeat the pose, crop or composition from the other frames. Preserve the same location, lighting and session mood.',
    ),
    "business_brand": (
        'Opening frame of the business brand session. Create a close portrait with a chest-up crop, mostly frontal posture and a calm confident gaze. The expression should feel polished, open and suitable for personal branding. Use the same light professional outfit, the same warm neutral studio background and the same soft business light that will remain consistent across the set. Keep the composition clean and focused on the face and upper wardrobe. Keep the same identity and the same wardrobe. Photorealistic. Do not duplicate the pose, crop or gaze direction used in the other frames. Preserve the same location, lighting and session mood.',
        'Second frame of the same business brand session. Create a medium portrait with a chest-up to mid-torso crop, body more directly oriented or slightly angled, and hands lightly joined at waist level or resting naturally. The gaze can stay into camera or shift subtly for variety. Use the same blazer-and-top outfit, the same neutral studio background and the same soft professional light. This frame should clearly differ from the opening portrait through crop, hand placement and body angle. Keep the same identity and the same wardrobe. Photorealistic. No duplicate pose or framing. Preserve the same location, lighting and session mood.',
        'Third frame of the same business brand session. Create a wider portrait with a three-quarter angle, showing more of the torso and more negative space around the subject. Keep the posture poised and the expression engaged, with a different arm position from the earlier frames. Maintain the same light blazer, the same neutral background and the same polished studio mood. This should feel like the broadest, most brand-oriented image in the series. Keep the same identity and the same wardrobe. Photorealistic. Do not repeat the pose, crop or composition from the other frames. Preserve the same location, lighting and session mood.',
    ),
    "travel_portrait": (
        'Opening frame of the travel session. Create a close portrait with a chest-up crop on a charming old-town street, using a relaxed posture and a soft direct gaze. Keep the face clearly visible while still showing enough of the warm stone surroundings to establish the travel setting. Use the same neutral travel outfit that stays constant throughout the series and keep the daylight soft and flattering. The image should feel elegant, relaxed and place-specific. Keep the same identity and the same wardrobe. Photorealistic. Do not duplicate the pose, crop or gaze used in the other frames. Preserve the same location, lighting and session mood.',
        'Second frame of the same travel session. Create a medium portrait with the body turned three-quarters in the same narrow street, one hand naturally touching the jacket, cardigan edge or a light strap. The gaze can be into camera or slightly away for variety. Maintain the same travel outfit, the same cobblestone or stone-wall setting and the same warm daylight palette. This frame should clearly differ from the opening image through body angle, hand placement, crop and composition. Keep the same identity and the same wardrobe. Photorealistic. No duplicate pose. Preserve the same location, lighting and session mood.',
        'Third frame of the same travel session. Create a wider portrait that shows more of the alley or street, with the subject standing, turning back slightly or walking slowly through the location. Use a different arm position and more environmental context than in the earlier frames. Keep the same neutral travel outfit, the same warm old-town atmosphere and the same soft daylight. This should feel like the most environmental image of the series. Keep the same identity and the same wardrobe. Photorealistic. Do not repeat the pose, crop or composition from the other frames. Preserve the same location, lighting and session mood.',
    ),
    "park_walk": (
        'Opening frame of the park walk session. Create a close portrait with a chest-up crop, relaxed posture and a soft natural smile, set against a green park background with gently blurred trees or a path. Keep the face clearly visible and use soft daylight that feels fresh and flattering. Use the same casual park outfit that will remain unchanged across the series. The image should feel calm, airy and natural. Keep the same identity and the same wardrobe. Photorealistic. Do not duplicate the pose, crop or gaze direction used in the other frames. Preserve the same location, lighting and session mood.',
        'Second frame of the same park walk session. Create a medium portrait near a bench, railing or pathway edge, with the body turned slightly and the hands resting naturally, holding a tote strap or touching part of the outfit. The expression should stay relaxed and open. Use the same green park setting, the same soft daylight and the same casual outfit. This frame should clearly differ from the opening portrait through crop, body angle, hand placement and composition while keeping the same park mood. Keep the same identity and the same wardrobe. Photorealistic. No duplicate pose. Preserve the same location, lighting and session mood.',
        'Third frame of the same park walk session. Create a wider walking or standing portrait on the park path with more trees and space visible around the subject. The body should be slightly turned and the arms positioned differently from the earlier frames for a more lifestyle-oriented feel. Maintain the same outfit, the same daylight and the same fresh green palette. This should be the most environmental frame of the set. Keep the same identity and the same wardrobe. Photorealistic. Do not repeat the pose, crop or composition from the other frames. Preserve the same location, lighting and session mood.',
    ),
}

PHOTOSHOOT_PROMPT_PACK_V1_STYLE_IDS: frozenset[str] = frozenset(PHOTOSHOOT_PROMPT_PACK_V1.keys())

# Authoring source for catalog JSON; also used when framePrompts missing in catalog.
FRAME_PROMPTS_BY_STYLE_ID: dict[str, list[str]] = {
    "studio_portrait": [
        'Opening portrait of the studio session. Create a close portrait with a head-and-shoulders to upper-chest crop, camera at eye level, subject facing mostly forward, calm direct gaze and a subtle natural smile. Keep the posture relaxed, shoulders clean, and the face clearly visible. Use the same warm gray-beige studio backdrop, the same soft volumetric light and the same neutral outfit established for the session. Composition should feel simple, premium and centered on the face. Keep the same identity and the same wardrobe. Photorealistic. Do not duplicate the pose, crop, gaze direction or framing used in the other frames.',
        'Second frame of the same studio session. Create a medium portrait with a chest-up to mid-torso crop, body turned three-quarters, head slightly tilted, and one hand lightly touching the collar, lapel or upper torso. The expression should stay calm and polished, with the gaze either softly into camera or slightly off-camera. Use the same warm gray-beige background, the same neutral outfit, and the same light quality and palette. This frame must clearly differ from the opening portrait through camera distance, body angle, hand placement and composition. Keep the same identity and the same wardrobe. Photorealistic. No duplicate pose.',
        'Third frame of the same studio session. Create a wider portrait with a waist-up crop, more breathing room around the subject, and a relaxed seated or standing posture. Turn the body slightly to the side, keep the arms relaxed, and use a gentle off-camera gaze for a more editorial finish. Show a bit more of the studio space while keeping the same warm gray-beige backdrop, neutral outfit and soft refined lighting. This frame should feel like the widest and most spacious image in the set. Keep the same identity and the same wardrobe. Photorealistic. Do not repeat the pose, crop, hand position or gaze from the other frames.',
    ],
    "business_portrait": [
        'Opening frame of the business session. Create a close professional portrait with a shoulders-up to upper-chest crop, mostly frontal angle, direct confident gaze and composed posture. The expression should feel calm, trustworthy and suitable for a business profile. Keep the background clean and light neutral, the lighting soft and professional, and the wardrobe exactly the same as the rest of the session. Emphasize a crisp, polished headshot feel with the face clearly visible and well lit. Keep the same identity and the same wardrobe. Photorealistic. Do not duplicate the pose, crop or gaze used in the other frames.',
        'Second frame of the same business session. Create a medium portrait with a chest-up crop, body angled three-quarters and the head turned slightly back toward the camera. Keep the expression professional and approachable. Hands should stay out of frame, with the composition focused on the torso line, shoulders and posture. Use the same neutral background, the same lighting setup and the same business outfit. This frame must clearly differ from the opening frame through camera distance, body angle and gaze direction. Keep the same identity and the same wardrobe. Photorealistic. No duplicate pose or framing.',
        'Third frame of the same business session. Create a wider portrait with a chest-up to waist-up crop, the body slightly angled and both hands visible, folded or resting calmly around waist level. The expression should remain confident and approachable, suitable for a website or professional presentation. Use the same background, same light quality and the same business clothing as in the previous frames. Show more of the posture and outfit while keeping the scene clean and minimal. Keep the same identity and the same wardrobe. Photorealistic. Do not repeat the crop, arm position or composition from the other frames.',
    ],
    "urban_portrait": [
        'Opening frame of the urban session. Create a close portrait with a chest-up to half-body crop on a quiet city sidewalk near a light stone facade. The subject should face the camera in a relaxed posture with a gentle direct gaze and understated expression. Keep the same light neutral city outfit, the same daylight quality and the same elegant urban background. Make the face clearly readable while still preserving a sense of location. The composition should feel clean, stylish and social-media ready. Keep the same identity and the same wardrobe. Photorealistic. Do not duplicate the pose, crop or framing used in the other frames.',
        'Second frame of the same urban session. Create a medium portrait near the same building facade, doorway or column, with the body turned three-quarters and one hand resting naturally near a pocket, lapel or cardigan edge. The gaze can be into camera or slightly off-camera. Use the same outfit, the same soft daylight and the same beige-toned city palette. This frame should clearly differ from the opening image through body angle, hand placement, camera distance and background framing while still feeling part of the same photoshoot. Keep the same identity and the same wardrobe. Photorealistic. No duplicate pose.',
        'Third frame of the same urban session. Create the widest shot of the set, with a waist-up to almost full-body crop on the sidewalk and more of the street depth visible behind the subject. Show a relaxed standing or slow walking pose, with the body slightly turned and the arms in a different natural position from the earlier frames. Maintain the same light neutral outfit, the same architectural street setting and the same daylight mood. Keep the same identity and the same wardrobe. Photorealistic. Do not repeat the pose, crop, gaze direction or composition from the other frames. Preserve the same location, lighting and session mood.',
    ],
    "evening_look": [
        'Opening frame of the evening session. Create a close portrait with a shoulders-up to upper-chest crop, camera near eye level, a composed posture and a calm direct gaze. Keep the face clearly lit by warm soft interior light and use a softly blurred elegant background. The expression should feel confident, relaxed and understated. Use the same refined evening outfit and the same warm neutral palette that will remain constant through the set. Keep the same identity and the same wardrobe. Photorealistic. Do not duplicate the pose, crop or gaze direction used in the other frames. Preserve the same location, lighting and session mood.',
        'Second frame of the same evening session. Create a medium portrait with a chest-up to mid-torso crop, the body turned three-quarters and the head slightly angled, with a composed off-camera or near-camera gaze. Keep the subject poised and elegant, with the arms or upper torso positioned differently from the first frame. Use the same interior setting, same warm soft light and the same evening outfit. This image should clearly differ from frame 0 through distance, body angle and expression while preserving the same atmosphere. Keep the same identity and the same wardrobe. Photorealistic. No duplicate pose.',
        'Third frame of the same evening session. Create a wider portrait with a waist-up crop, more visible interior space and a relaxed elegant posture. The subject may sit or stand with arms resting naturally, using a gentle side glance or softly averted gaze for variety. Maintain the same wardrobe, warm lighting and refined indoor background so the image remains part of the same set. This should be the widest and most atmospheric frame in the series. Keep the same identity and the same wardrobe. Photorealistic. Do not repeat the pose, crop, arm position or composition from the other frames. Preserve the same location, lighting and session mood.',
    ],
    "tender_photoshoot": [
        'Opening frame of the tender session. Create a close portrait with a half-body crop, the subject seated on a cream sofa in soft daylight, shoulders relaxed and a gentle natural smile. The face should be clearly visible and softly lit, with a calm direct gaze and a quiet intimate mood. Keep the same beige-toned interior, the same cream knit outfit and a subtle hint of sofa or soft decor in the background. The composition should feel warm, delicate and inviting. Keep the same identity and the same wardrobe. Photorealistic. Do not duplicate the pose, crop or gaze used in the other frames. Preserve the same location, lighting and session mood.',
        'Second frame of the same tender session. Create a medium seated portrait on the same sofa, with the body turned slightly, the head gently tilted and one hand resting near the chin, cheek, knee or sofa arm. The expression should remain soft and calm. Use the same cream knit outfit, the same daylight from the window and the same beige interior styling. This frame should clearly differ from the opening portrait through hand placement, body angle, crop and composition while staying within the same cozy atmosphere. Keep the same identity and the same wardrobe. Photorealistic. No duplicate pose. Preserve the same location, lighting and session mood.',
        'Third frame of the same tender session. Create a wider but still intimate portrait, showing more of the sofa and soft room elements while keeping the subject comfortably seated. Turn the face slightly toward the light and use a gentle smile or quiet thoughtful expression. The pose should be different from the earlier frames, with a new arm position and more negative space around the subject. Keep the same outfit, the same beige interior and the same warm daylight mood. Keep the same identity and the same wardrobe. Photorealistic. Do not repeat the pose, crop or composition from the other frames.',
    ],
    "summer_photoshoot": [
        'Opening frame of the summer session. Create a close portrait with a head-and-shoulders to upper-chest crop, soft golden daylight, a gentle direct gaze and a relaxed natural smile. Keep the face clearly visible and flattering, with softly blurred greenery or a terrace background that suggests summer without overpowering the subject. Use the same light seasonal outfit that will stay constant through the series. The image should feel fresh, warm and inviting. Keep the same identity and the same wardrobe. Photorealistic. Do not duplicate the pose, crop or gaze direction used in the other frames. Preserve the same location, lighting and session mood.',
        'Second frame of the same summer session. Create a medium portrait with a chest-up to mid-torso crop, the body turned three-quarters and one hand visible, resting naturally, touching the hair or adjusting part of the outfit. The gaze should shift slightly off-camera or over the shoulder for variety. Keep the same summer outfit, the same warm daylight and the same park or terrace setting. This frame should clearly differ from frame 0 through hand placement, body angle, camera distance and gaze direction while remaining part of the same set. Keep the same identity and the same wardrobe. Photorealistic. No duplicate pose.',
        'Third frame of the same summer session. Create the widest shot of the series, with a waist-up to full-body lifestyle crop on a sunny path or terrace. Show the subject standing or walking slowly with relaxed arms and more surrounding environment visible, including a sense of open summer space. Maintain the same outfit, the same warm sunlight and the same vacation-like mood. This frame should feel more dynamic and environmental than the first two. Keep the same identity and the same wardrobe. Photorealistic. Do not repeat the pose, crop, arm position or composition from the other frames. Preserve the same location, lighting and session mood.',
    ],
    "winter_photoshoot": [
        'Opening frame of the winter session. Create a close winter portrait with a head-and-shoulders to upper-chest crop, soft snow blurred in the background and a calm direct gaze. The subject should look warmly dressed and comfortable, with the face clearly visible and softly lit by natural daylight. Use the same winter coat or outerwear that will remain unchanged throughout the series. The mood should feel cozy, calm and seasonal. Keep the same identity and the same wardrobe. Photorealistic. Do not duplicate the pose, crop or gaze direction used in the other frames. Preserve the same location, lighting and session mood.',
        'Second frame of the same winter session. Create a medium portrait on the same winter path, with the body turned three-quarters and the hands interacting naturally with the outfit, such as holding the coat collar, resting in pockets or adjusting a scarf. Keep the expression relaxed and composed. Use the same snowy park environment, the same winter clothing and the same soft daylight. This frame should clearly differ from the opening portrait through camera distance, hand placement, body angle and composition. Keep the same identity and the same wardrobe. Photorealistic. No duplicate pose. Preserve the same location, lighting and session mood.',
        'Third frame of the same winter session. Create a wider lifestyle portrait with a waist-up to fuller crop, showing more of the snowy path and nearby trees. The subject may stand in side orientation or walk slowly, with arms in a different natural position from the previous frames. Keep the same coat and winter styling, the same peaceful snow-covered environment and the same gentle daylight. This should be the most environmental image in the set. Keep the same identity and the same wardrobe. Photorealistic. Do not repeat the pose, crop or composition from the other frames. Preserve the same location, lighting and session mood.',
    ],
    "home_portrait": [
        'Opening frame of the home session. Create a close portrait with a half-body crop, the subject seated on a sofa near a window, relaxed and approachable. Use a calm direct gaze and a soft natural expression. Keep the face clearly visible, with gentle daylight and a softly blurred background hinting at home decor such as a blanket, vase or plant. Use the same soft casual outfit that will remain unchanged across the series. The image should feel warm and real. Keep the same identity and the same wardrobe. Photorealistic. Do not duplicate the pose, crop or gaze used in the other frames. Preserve the same location, lighting and session mood.',
        'Second frame of the same home session. Create a medium seated portrait, more centered on the sofa, with the body slightly turned and the hands resting naturally on the knees, lap or sofa. The expression should stay soft and friendly. Use the same cozy living room, the same daylight and the same home outfit. This frame should clearly differ from the opening portrait through crop, posture, hand placement and composition while staying within the same room and atmosphere. Keep the same identity and the same wardrobe. Photorealistic. No duplicate pose. Preserve the same location, lighting and session mood.',
        'Third frame of the same home session. Create a wider portrait that shows more of the sofa and living room surroundings while keeping the subject as the focus. The posture should be relaxed and slightly angled, with a new arm position and either a direct soft gaze or a gentle smile. Maintain the same casual outfit, the same window light and the same warm neutral home palette. This should be the most environmental frame of the series. Keep the same identity and the same wardrobe. Photorealistic. Do not repeat the pose, crop or composition from the other frames. Preserve the same location, lighting and session mood.',
    ],
    "expert_photoshoot": [
        'Opening frame of the expert session. Create a close professional portrait with a shoulders-up to upper-chest crop, direct confident gaze and composed posture. The expression should feel trustworthy and calm, appropriate for an expert profile. Use a clean neutral background, soft professional light and the same smart-casual outfit that remains constant through the set. Keep the face clearly visible and well defined. Keep the same identity and the same wardrobe. Photorealistic. Do not duplicate the pose, crop or gaze used in the other frames. Preserve the same location, lighting and session mood.',
        'Second frame of the same expert session. Create a medium portrait with a chest-up crop, slight body turn and a gentle head angle. The expression should remain approachable and assured, with the gaze either into camera or slightly off-camera. Use the same background, the same soft professional light and the same outfit. This frame should clearly differ from the opening image through camera distance, body angle and facial direction while keeping the same expert tone. Keep the same identity and the same wardrobe. Photorealistic. No duplicate pose. Preserve the same location, lighting and session mood.',
        'Third frame of the same expert session. Create a wider portrait with a waist-up crop and hands visible, resting naturally or lightly joined, suitable for a website hero or presentation profile. The body should be slightly angled, with open posture and calm confident presence. Maintain the same background, same light quality and same expert wardrobe. This frame should show more of the outfit and posture than the first two. Keep the same identity and the same wardrobe. Photorealistic. Do not repeat the pose, arm position or framing from the other frames. Preserve the same location, lighting and session mood.',
    ],
    "business_brand": [
        'Opening frame of the business brand session. Create a close portrait with a chest-up crop, mostly frontal posture and a calm confident gaze. The expression should feel polished, open and suitable for personal branding. Use the same light professional outfit, the same warm neutral studio background and the same soft business light that will remain consistent across the set. Keep the composition clean and focused on the face and upper wardrobe. Keep the same identity and the same wardrobe. Photorealistic. Do not duplicate the pose, crop or gaze direction used in the other frames. Preserve the same location, lighting and session mood.',
        'Second frame of the same business brand session. Create a medium portrait with a chest-up to mid-torso crop, body more directly oriented or slightly angled, and hands lightly joined at waist level or resting naturally. The gaze can stay into camera or shift subtly for variety. Use the same blazer-and-top outfit, the same neutral studio background and the same soft professional light. This frame should clearly differ from the opening portrait through crop, hand placement and body angle. Keep the same identity and the same wardrobe. Photorealistic. No duplicate pose or framing. Preserve the same location, lighting and session mood.',
        'Third frame of the same business brand session. Create a wider portrait with a three-quarter angle, showing more of the torso and more negative space around the subject. Keep the posture poised and the expression engaged, with a different arm position from the earlier frames. Maintain the same light blazer, the same neutral background and the same polished studio mood. This should feel like the broadest, most brand-oriented image in the series. Keep the same identity and the same wardrobe. Photorealistic. Do not repeat the pose, crop or composition from the other frames. Preserve the same location, lighting and session mood.',
    ],
    "personal_brand": [
        'Opening frame of the personal brand session. Create a close portrait with a head-and-shoulders to upper-chest crop, direct engaging gaze and a confident natural expression. Keep the face clear and inviting, with a clean pleasant background and soft flattering light. Use the same outfit that will remain unchanged through the series, styled for a modern personal-brand look. The image should feel suitable for profile or social media use. Keep the same identity and the same wardrobe. Photorealistic. Do not duplicate the pose, crop or gaze direction used in the other frames. Preserve the same location, lighting and session mood.',
        'Second frame of the same personal brand session. Create a medium portrait with a chest-up crop, body turned three-quarters and a more expressive pose than frame 0. The gaze may stay into camera or move slightly off-camera, but the mood should remain confident and approachable. Use the same outfit, the same soft lighting and the same pleasant brand-friendly setting. This frame should clearly differ from the opening portrait through crop, body angle and composition while still feeling part of the same set. Keep the same identity and the same wardrobe. Photorealistic. No duplicate pose. Preserve the same location, lighting and session mood.',
        'Third frame of the same personal brand session. Create a wider lifestyle portrait with more environment visible and a relaxed arm position, suitable for website banners or promotional use. The pose should feel open and natural, with a slightly different angle and more spatial context than the first two frames. Maintain the same outfit, same palette and same soft light so the image stays within the same personal-brand session. Keep the same identity and the same wardrobe. Photorealistic. Do not repeat the pose, crop or composition from the other frames. Preserve the same location, lighting and session mood.',
    ],
    "travel_portrait": [
        'Opening frame of the travel session. Create a close portrait with a chest-up crop on a charming old-town street, using a relaxed posture and a soft direct gaze. Keep the face clearly visible while still showing enough of the warm stone surroundings to establish the travel setting. Use the same neutral travel outfit that stays constant throughout the series and keep the daylight soft and flattering. The image should feel elegant, relaxed and place-specific. Keep the same identity and the same wardrobe. Photorealistic. Do not duplicate the pose, crop or gaze used in the other frames. Preserve the same location, lighting and session mood.',
        'Second frame of the same travel session. Create a medium portrait with the body turned three-quarters in the same narrow street, one hand naturally touching the jacket, cardigan edge or a light strap. The gaze can be into camera or slightly away for variety. Maintain the same travel outfit, the same cobblestone or stone-wall setting and the same warm daylight palette. This frame should clearly differ from the opening image through body angle, hand placement, crop and composition. Keep the same identity and the same wardrobe. Photorealistic. No duplicate pose. Preserve the same location, lighting and session mood.',
        'Third frame of the same travel session. Create a wider portrait that shows more of the alley or street, with the subject standing, turning back slightly or walking slowly through the location. Use a different arm position and more environmental context than in the earlier frames. Keep the same neutral travel outfit, the same warm old-town atmosphere and the same soft daylight. This should feel like the most environmental image of the series. Keep the same identity and the same wardrobe. Photorealistic. Do not repeat the pose, crop or composition from the other frames. Preserve the same location, lighting and session mood.',
    ],
    "cafe_city": [
        'Opening frame of the cafe-city session. Create a close portrait at a small cafe table or beside a large cafe window, with a coffee cup subtly present and a calm confident expression. Use a chest-up crop, direct or near-direct gaze and a relaxed seated posture. Keep the same smart casual outfit, the same warm cafe-window setting and the same city atmosphere visible in the background. The composition should feel cozy, stylish and natural. Keep the same identity and the same wardrobe. Photorealistic. Do not duplicate the pose, crop or gaze used in the other frames. Preserve the same location, lighting and session mood.',
        'Second frame of the same cafe-city session. Create a medium portrait near the same window or table, with the body turned three-quarters and the subject sitting or leaning naturally. A coffee cup or tabletop element may remain lightly visible. Use the same outfit, the same warm cafe light and the same city-through-window context. This frame should clearly differ from the opening image through crop, body angle, hand position and gaze direction while still looking like part of the same outing. Keep the same identity and the same wardrobe. Photorealistic. No duplicate pose. Preserve the same location, lighting and session mood.',
        'Third frame of the same cafe-city session. Create a wider portrait just outside the cafe or near its entrance, showing more of the city street and cafe facade behind the subject. Use a standing pose with relaxed arms and a different orientation from the first two frames. Keep the same smart casual outfit and the same blend of urban and cafe atmosphere. This should be the most environmental frame in the set while still feeling connected to the same place. Keep the same identity and the same wardrobe. Photorealistic. Do not repeat the pose, crop or composition from the other frames. Preserve the same location, lighting and session mood.',
    ],
    "park_walk": [
        'Opening frame of the park walk session. Create a close portrait with a chest-up crop, relaxed posture and a soft natural smile, set against a green park background with gently blurred trees or a path. Keep the face clearly visible and use soft daylight that feels fresh and flattering. Use the same casual park outfit that will remain unchanged across the series. The image should feel calm, airy and natural. Keep the same identity and the same wardrobe. Photorealistic. Do not duplicate the pose, crop or gaze direction used in the other frames. Preserve the same location, lighting and session mood.',
        'Second frame of the same park walk session. Create a medium portrait near a bench, railing or pathway edge, with the body turned slightly and the hands resting naturally, holding a tote strap or touching part of the outfit. The expression should stay relaxed and open. Use the same green park setting, the same soft daylight and the same casual outfit. This frame should clearly differ from the opening portrait through crop, body angle, hand placement and composition while keeping the same park mood. Keep the same identity and the same wardrobe. Photorealistic. No duplicate pose. Preserve the same location, lighting and session mood.',
        'Third frame of the same park walk session. Create a wider walking or standing portrait on the park path with more trees and space visible around the subject. The body should be slightly turned and the arms positioned differently from the earlier frames for a more lifestyle-oriented feel. Maintain the same outfit, the same daylight and the same fresh green palette. This should be the most environmental frame of the set. Keep the same identity and the same wardrobe. Photorealistic. Do not repeat the pose, crop or composition from the other frames. Preserve the same location, lighting and session mood.',
    ],
    "premium_portrait": [
        'Opening frame of the premium session. Create a close portrait with a chest-up crop, calm direct gaze and poised posture against the dark graphite studio background. Use soft volumetric light to shape the face while keeping the expression elegant and restrained. The same refined premium outfit should be clearly visible and remain unchanged through the set. The composition should feel intimate, luxurious and editorial. Keep the same identity and the same wardrobe. Photorealistic. Do not duplicate the pose, crop or gaze direction used in the other frames. Preserve the same location, lighting and session mood.',
        'Second frame of the same premium session. Create a medium portrait with a chest-up to mid-torso crop, subtle body turn and a slightly different head angle from the first frame. Keep the expression composed and confident. Use the same graphite-toned studio background, the same soft directional light and the same premium outfit. This image should clearly differ from the opening portrait through camera distance, body angle and composition while preserving the same high-end atmosphere. Keep the same identity and the same wardrobe. Photorealistic. No duplicate pose. Preserve the same location, lighting and session mood.',
        'Third frame of the same premium session. Create a wider portrait with a waist-up crop, more negative space and a gently averted or side-directed gaze for an editorial finish. The body may be seated or standing, but the arm position should differ from the earlier frames. Maintain the same wardrobe, the same dark premium studio environment and the same soft sculpting light. This should be the most spacious and magazine-like frame in the set. Keep the same identity and the same wardrobe. Photorealistic. Do not repeat the pose, crop or composition from the other frames. Preserve the same location, lighting and session mood.',
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


def build_kie_photoshoot_frame_prompt(
    client_style_id: str,
    style: PhotoshootStyle,
    *,
    frame_index: int,
    output_count: int,
    user_description: str | None = None,
    series_reference_mode: str = "legacy",
) -> str:
    """Build Kie photoshoot instruction for one frame (identity-only references)."""
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
    mode = series_reference_mode.strip().lower()
    if mode in {"identity_anchor", "anchor_only", "legacy"}:
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
