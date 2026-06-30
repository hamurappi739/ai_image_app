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
        (
            "You are given one uploaded user photo. Use it only as the identity reference. "
            "Keep the same face, age, facial proportions, skin tone, hairstyle direction and natural expression. "
            "Transform this person into an elegant city portrait in a soft beige urban look.\n\n"
            "Generate a photorealistic portrait on a quiet city sidewalk near a light stone building facade "
            "with columns and large windows. The person wears a light cream blouse or knit top, beige cardigan "
            "or light trench-style layer, and beige trousers. Chest-up to half-body framing, relaxed posture, "
            "looking gently into the camera, soft natural daylight, premium clean city atmosphere.\n\n"
            "Keep the outfit light beige/cream, keep the background as an elegant city street facade, "
            "no studio background, no office blazer, no evening look, no black clothing, no crowd, "
            "no cars dominating the frame."
        ),
        (
            "You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. "
            "Image 2 is the first generated photo and must be used as the style anchor for outfit, location, "
            "lighting, color grading and overall look. Generate a new photo of the same person in the same city "
            "photoshoot, not a copy of Image 2.\n\n"
            "Create a medium portrait near the same stone city facade, with the body turned slightly three-quarters "
            "to the camera. The person stands closer to a doorway or column, one hand relaxed near the cardigan or "
            "pocket, gaze softly into camera or slightly off-camera. Same beige outfit, same soft daylight, "
            "same elegant urban palette.\n\n"
            "Change the crop and pose from the first frame: different body angle, different hand position, "
            "slightly different background framing. Do not change the outfit color or location."
        ),
        (
            "You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. "
            "Image 2 is the first generated photo and must be used as the style anchor for outfit, location, "
            "lighting, color grading and overall look. Generate the third distinct photo of the same city photoshoot.\n\n"
            "Create a wider waist-up or almost full-body city portrait on the sidewalk, the person walking slowly "
            "or standing with one hand in a pocket, building facade receding into the background. Same light "
            "cream/beige outfit, same soft neutral daylight, polished city lifestyle mood.\n\n"
            "The third frame must be clearly different from frames 0 and 1: wider camera distance, more visible "
            "street depth, different arm position and gaze. Do not create a studio portrait or business suit look."
        ),
    ),
    "tender_photoshoot": (
        (
            "You are given one uploaded user photo. Use it only as the identity reference. "
            "Keep the same face, age, facial proportions, skin tone, hairstyle direction and natural expression. "
            "Transform this person into a gentle cozy indoor portrait.\n\n"
            "Generate a photorealistic soft beige interior photoshoot: the person sits on a cream sofa, wearing a "
            "light beige or cream knit sweater and soft neutral pants. Warm daylight through sheer curtains, pampas "
            "grass or soft dried flowers in the background, calm gentle smile, close half-body framing.\n\n"
            "Keep the palette cream, beige and warm white. No dark dramatic lighting, no business jacket, "
            "no outdoor park, no black clothes, no glamour evening mood."
        ),
        (
            "You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. "
            "Image 2 is the first generated photo and must be used as the style anchor for outfit, location, "
            "lighting, color grading and overall look. Generate a new photo from the same tender indoor photoshoot.\n\n"
            "Create a medium seated portrait on the same cream sofa. The person leans slightly forward, one elbow "
            "resting on the knee or sofa arm, one hand gently near the chin or cheek. Same cream knit sweater, "
            "same soft beige interior, same window daylight and calm warm color grading.\n\n"
            "Make it a different composition from the first frame: different hand placement, different head tilt, "
            "slightly closer or more centered crop. Do not change the room, outfit or light."
        ),
        (
            "You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. "
            "Image 2 is the first generated photo and must be used as the style anchor for outfit, location, "
            "lighting, color grading and overall look. Generate the third distinct photo from this same tender photoshoot.\n\n"
            "Create a soft close portrait with the person seated comfortably, shoulders relaxed, gentle smile, "
            "face slightly turned toward the light. Cream sofa and pampas/dried flowers remain softly visible in the "
            "background, same beige knit outfit and soft daylight.\n\n"
            "The third photo should feel closer and more intimate than the first two, with a different crop and gaze. "
            "Keep one consistent outfit and location."
        ),
    ),
    "home_portrait": (
        (
            "You are given one uploaded user photo. Use it only as the identity reference. "
            "Keep the same face, age, facial proportions, skin tone, hairstyle direction and natural expression. "
            "Transform this person into a warm home portrait.\n\n"
            "Generate a photorealistic portrait in a bright cozy living room. The person sits on a sofa near a window, "
            "wearing a soft cream cardigan over a white top, relaxed and approachable. Background includes warm neutral "
            "home decor, a blanket, vase or plants, soft daylight, clean natural color palette.\n\n"
            "Keep it realistic and simple: no studio backdrop, no formal suit, no dark evening light, "
            "no cluttered room, no luxury hotel look."
        ),
        (
            "You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. "
            "Image 2 is the first generated photo and must be used as the style anchor for outfit, location, "
            "lighting, color grading and overall look. Generate a second home portrait in the same living room.\n\n"
            "Create a medium seated portrait with the person sitting more centered on the sofa, hands relaxed on knees "
            "or folded naturally, looking into the camera with a soft friendly expression. Same cream cardigan, white "
            "top, warm window daylight, neutral home decor.\n\n"
            "Change the pose and crop from the first frame. Keep the same room, outfit and cozy natural mood."
        ),
        (
            "You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. "
            "Image 2 is the first generated photo and must be used as the style anchor for outfit, location, "
            "lighting, color grading and overall look. Generate the third distinct photo from the same home portrait session.\n\n"
            "Create a wider relaxed portrait on the sofa with more of the blanket and living room visible. The person "
            "sits comfortably, slightly angled, hands resting naturally, soft direct gaze or gentle smile. Same cream "
            "cardigan, white top, warm neutral interior and daylight.\n\n"
            "Make the third frame wider and calmer than the first two. Do not change the outfit, background style or lighting."
        ),
    ),
    "cafe_city": (
        (
            "You are given one uploaded user photo. Use it only as the identity reference. "
            "Keep the same face, age, facial proportions, skin tone, hairstyle direction and natural expression. "
            "Transform this person into a cafe and city portrait.\n\n"
            "Generate a photorealistic portrait at a small cafe table near a large window. The person wears an olive, "
            "sage or beige jacket over a crisp white blouse or shirt. A coffee cup is on the table, warm cafe lamps and "
            "city street visible through the window, calm confident expression, elegant lifestyle mood.\n\n"
            "Keep the outfit olive/beige plus white shirt. Keep cafe-window-city atmosphere. No studio gray background, "
            "no black evening dress, no office desk, no crowded restaurant."
        ),
        (
            "You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. "
            "Image 2 is the first generated photo and must be used as the style anchor for outfit, location, "
            "lighting, color grading and overall look. Generate a second photo in the same cafe and city photoshoot.\n\n"
            "Create a closer portrait by the cafe window with the coffee cup slightly visible in the foreground. "
            "The person sits or leans naturally, body turned three-quarters, gaze into camera or softly toward the window. "
            "Same olive/beige jacket, white shirt, warm cafe light and street-through-window background.\n\n"
            "Change the pose, crop and gaze from the first frame. Do not change the outfit, cafe location or warm color grading."
        ),
        (
            "You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. "
            "Image 2 is the first generated photo and must be used as the style anchor for outfit, location, "
            "lighting, color grading and overall look. Generate the third distinct photo from this cafe-city session.\n\n"
            "Create a portrait just outside or near the cafe entrance, the city street and cafe windows visible behind "
            "the person. The person stands in the same olive/beige jacket and white shirt, relaxed confident posture, "
            "soft daylight mixed with warm cafe light.\n\n"
            "The third frame should show more city context and a standing pose. Keep it part of the same session, "
            "not a different outfit or different place."
        ),
    ),
    "business_brand": (
        (
            "You are given one uploaded user photo. Use it only as the identity reference. "
            "Keep the same face, age, facial proportions, skin tone, hairstyle direction and natural expression. "
            "Transform this person into a clean business brand portrait.\n\n"
            "Generate a photorealistic professional portrait on a warm neutral gray or beige studio background. "
            "The person wears a light beige, gray or cream textured blazer over a white top. Chest-up framing, calm "
            "confident expression, soft professional daylight, clean personal-brand style.\n\n"
            "Keep the outfit light and professional. No black top, no off-shoulder clothes, no floral wallpaper, "
            "no park, no evening glamour, no corporate office clutter."
        ),
        (
            "You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. "
            "Image 2 is the first generated photo and must be used as the style anchor for outfit, location, "
            "lighting, color grading and overall look. Generate a second business brand portrait in the same studio session.\n\n"
            "Create a medium portrait with the person standing or seated, hands lightly joined at waist level or resting "
            "naturally, body facing the camera more directly. Same light textured blazer, white top, neutral gray-beige "
            "background and soft professional light.\n\n"
            "Change the crop and hand position from the first frame. Keep the same clean professional mood and outfit."
        ),
        (
            "You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. "
            "Image 2 is the first generated photo and must be used as the style anchor for outfit, location, "
            "lighting, color grading and overall look. Generate the third distinct business brand portrait.\n\n"
            "Create a three-quarter angle portrait, the person turned slightly to one side while still engaging the camera. "
            "Same light blazer and white top, same neutral studio wall, soft shadows, polished expert look.\n\n"
            "Make this frame different through body angle and camera distance. Do not change to a dark suit, "
            "outdoor location or glamour styling."
        ),
    ),
    "travel_portrait": (
        (
            "You are given one uploaded user photo. Use it only as the identity reference. "
            "Keep the same face, age, facial proportions, skin tone, hairstyle direction and natural expression. "
            "Transform this person into a warm travel portrait.\n\n"
            "Generate a photorealistic portrait in a charming old European town street with stone walls, warm beige "
            "buildings, cobblestone path and soft daylight. The person wears a beige linen jacket, cardigan or light "
            "trench over a white top. Chest-up framing, relaxed smile, travel lifestyle mood.\n\n"
            "Keep the location as old town/travel street. No studio, no business blazer look, no modern office, "
            "no beach, no winter clothing."
        ),
        (
            "You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. "
            "Image 2 is the first generated photo and must be used as the style anchor for outfit, location, "
            "lighting, color grading and overall look. Generate a second photo from the same travel portrait session.\n\n"
            "Create a medium portrait in the same narrow street, body turned slightly three-quarters, one hand gently "
            "touching the lapel/cardigan or holding a small strap. Same beige travel outfit, white top, cobblestone "
            "street and warm old-town background.\n\n"
            "Change the pose and gaze from the first frame. Keep the same travel location and warm color palette."
        ),
        (
            "You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. "
            "Image 2 is the first generated photo and must be used as the style anchor for outfit, location, "
            "lighting, color grading and overall look. Generate the third distinct photo from this travel session.\n\n"
            "Create a wider portrait with the person walking slowly along a stone wall or turning back slightly on a "
            "cobblestone street. More of the old town alley is visible, same beige jacket/cardigan, same white top, "
            "soft daylight, relaxed travel expression.\n\n"
            "The third frame should be more side-view or walking-oriented. Do not change to a different city style, "
            "studio background or business outfit."
        ),
    ),
    "park_walk": (
        (
            "You are given one uploaded user photo. Use it only as the identity reference. "
            "Keep the same face, age, facial proportions, skin tone, hairstyle direction and natural expression. "
            "Transform this person into a calm park walk portrait.\n\n"
            "Generate a photorealistic portrait in a green park with trees and a soft path in the background. "
            "The person wears a mint, pale green or light pastel cardigan over a white top. Chest-up framing, relaxed "
            "natural smile, soft daylight, fresh calm spring/summer palette.\n\n"
            "Keep the outfit mint/white and the location green park. No black clothes, no studio, no business suit, "
            "no evening light, no winter snow."
        ),
        (
            "You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. "
            "Image 2 is the first generated photo and must be used as the style anchor for outfit, location, "
            "lighting, color grading and overall look. Generate a second photo from the same park walk session.\n\n"
            "Create a medium portrait by a park bench or railing, the person leaning lightly or resting hands naturally, "
            "possibly holding a light tote bag or cardigan edge. Same mint cardigan, white top, green trees and soft park daylight.\n\n"
            "Change hand position, crop and body angle from the first frame. Keep the same outfit and fresh green park mood."
        ),
        (
            "You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. "
            "Image 2 is the first generated photo and must be used as the style anchor for outfit, location, "
            "lighting, color grading and overall look. Generate the third distinct photo from this park walk session.\n\n"
            "Create a wider walking portrait on the park path, the person standing or slowly walking with hands relaxed, "
            "body turned slightly to the side, trees framing the background. Same mint cardigan, white top, soft daylight "
            "and natural green color grading.\n\n"
            "The third frame should be wider and more lifestyle-oriented than the first two. Do not change to city street, "
            "studio, black outfit or formal business styling."
        ),
    ),
}

PHOTOSHOOT_PROMPT_PACK_V1_STYLE_IDS: frozenset[str] = frozenset(PHOTOSHOOT_PROMPT_PACK_V1.keys())

# Authoring source for catalog JSON; also used when framePrompts missing in catalog.
FRAME_PROMPTS_BY_STYLE_ID: dict[str, list[str]] = {
    "business_portrait": [
        'You are given one uploaded user photo. Use it only as the identity reference. Keep the same face, age, facial proportions, skin tone, hairstyle direction and natural expression.\n\nGenerate a photorealistic business portrait: shoulders-up, direct confident gaze, light neutral background, soft professional studio light, light blouse or restrained blazer. Resume/profile quality.',
        'You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, color grading and overall look. Generate frame 2 of this business portrait session.\n\nMedium chest-up portrait, three-quarter head turn, calm professional expression, hands not visible. Same outfit, background and soft business light.\n\nMust differ from frame 0: medium crop, three-quarter angle, no direct frontal gaze. Do not repeat the same pose, crop, camera distance, arm position, gaze direction, background framing, or composition from the other frames.',
        'You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, color grading and overall look. Generate frame 3 of this business portrait session.\n\nWider chest-up or waist-up business portrait, hands folded calmly at waist level, body slightly angled, confident approachable expression. Same professional outfit and neutral backdrop.\n\nMust differ from frames 0 and 1: wider framing, visible hands, waist-level composition. Do not repeat the same pose, crop, camera distance, arm position, gaze direction, background framing, or composition from the other frames.',
    ],
    "studio_portrait": [
        'You are given one uploaded user photo. Use it only as the identity reference. Keep the same face, age, facial proportions, skin tone, hairstyle direction and natural expression.\n\nGenerate a photorealistic premium studio portrait: warm gray-beige backdrop, soft volumetric light, neutral elegant outfit. Close chest-up framing, direct gaze, calm light smile. Clean high-end studio mood.',
        'You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, color grading and overall look. Generate frame 2 of this studio portrait session.\n\nMedium chest-up portrait, head tilted slightly, shoulders angled three-quarters, soft smile, one hand resting near collar or lapels. Same gray-beige studio, same outfit and soft light.\n\nMust differ from frame 0: medium distance, three-quarter shoulders, head tilt, hand visible. Do not repeat the same pose, crop, camera distance, arm position, gaze direction, background framing, or composition from the other frames.',
        'You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, color grading and overall look. Generate frame 3 of this studio portrait session.\n\nWider waist-up studio portrait, person seated or standing with relaxed arms, gaze gently away from camera, more negative space around subject. Same backdrop, outfit and premium soft light.\n\nMust differ from frames 0 and 1: wider crop, seated/standing full torso, averted gaze, more space. Do not repeat the same pose, crop, camera distance, arm position, gaze direction, background framing, or composition from the other frames.',
    ],
    "evening_look": [
        'You are given one uploaded user photo. Use it only as the identity reference. Keep the same face, age, facial proportions, skin tone, hairstyle direction and natural expression.\n\nGenerate an elegant evening-style portrait: shoulders or chest-up, warm soft interior light, closed elegant blouse or jacket, blurred neutral background, minimal jewelry, natural skin.',
        'You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, color grading and overall look. Generate frame 2 of this evening portrait session.\n\nMedium portrait, body turned three-quarters, confident calm pose, gaze slightly off-camera. Same elegant outfit, warm interior light and soft background.\n\nMust differ from frame 0: medium distance, three-quarter body, off-camera gaze. Do not repeat the same pose, crop, camera distance, arm position, gaze direction, background framing, or composition from the other frames.',
        'You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, color grading and overall look. Generate frame 3 of this evening portrait session.\n\nWider waist-up portrait, relaxed arm position, gentle side glance, more room visible in soft interior blur. Same outfit, palette and warm light.\n\nMust differ from frames 0 and 1: widest crop, waist-up, side glance, more background visible. Do not repeat the same pose, crop, camera distance, arm position, gaze direction, background framing, or composition from the other frames.',
    ],
    "premium_portrait": [
        'You are given one uploaded user photo. Use it only as the identity reference. Keep the same face, age, facial proportions, skin tone, hairstyle direction and natural expression.\n\nGenerate a premium studio portrait: dark gray/graphite backdrop, soft volumetric light, graphite jacket over light closed blouse, closest chest-up crop, elegant restrained high-end mood.',
        'You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, color grading and overall look. Generate frame 2 of this premium portrait session.\n\nMedium chest-up portrait, subtle body turn, calm confident gaze, minimalist magazine quality. Same graphite outfit and studio light.\n\nMust differ from frame 0: medium distance, body turn, different head angle. Do not repeat the same pose, crop, camera distance, arm position, gaze direction, background framing, or composition from the other frames.',
        'You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, color grading and overall look. Generate frame 3 of this premium portrait session.\n\nWider waist-up premium portrait, gaze slightly away, editorial negative space, realistic skin, same graphite styling and soft volumetric light.\n\nMust differ from frames 0 and 1: widest crop, averted gaze, editorial spacing. Do not repeat the same pose, crop, camera distance, arm position, gaze direction, background framing, or composition from the other frames.',
    ],
    "summer_photoshoot": [
        'You are given one uploaded user photo. Use it only as the identity reference. Keep the same face, age, facial proportions, skin tone, hairstyle direction and natural expression. Transform this person into a bright summer portrait.\n\nGenerate a photorealistic close head-and-shoulders summer portrait in soft golden-hour sunlight. Light summer dress or airy white/cream blouse, park greenery or sunny terrace softly blurred behind. Direct gentle gaze into camera, relaxed smile, warm vibrant natural colors, fresh vacation mood.\n\nFrame 0 is the identity and style anchor: closest crop, frontal chest-up, main summer look.',
        'You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, color grading and overall look. Generate frame 2 of this summer photoshoot.\n\nCreate a medium chest-up portrait, body turned three-quarters to the camera, one hand visible resting naturally or touching hair/sunhat strap. Gaze slightly off-camera or over the shoulder. Same summer outfit, same park/terrace location, same warm sunlight and color palette.\n\nMust differ from frame 0: medium camera distance, three-quarter body angle, visible hand pose, off-center gaze. Do not repeat the same pose, crop, camera distance, arm position, gaze direction, background framing, or composition from the other frames.',
        'You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, color grading and overall look. Generate frame 3 of this summer photoshoot.\n\nCreate a wider waist-up or full-body lifestyle summer portrait on a sunny path or terrace, person walking slowly or standing with relaxed arms, camera slightly lower showing more sky and environment. Same light summer outfit, same golden-hour light, joyful vacation atmosphere.\n\nMust differ from frames 0 and 1: widest crop, walking or side-standing pose, more environment, different camera height. Do not repeat the same pose, crop, camera distance, arm position, gaze direction, background framing, or composition from the other frames.',
    ],
    "winter_photoshoot": [
        'You are given one uploaded user photo. Use it only as the identity reference. Keep the same face, age, facial proportions, skin tone, hairstyle direction and natural expression.\n\nGenerate a cozy winter close portrait: warm coat or wool jacket, soft snow blurred behind, calm daylight, natural skin, closest head-and-shoulders crop, gentle smile.',
        'You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, color grading and overall look. Generate frame 2 of this winter photoshoot.\n\nMedium portrait on a winter park path, body turned three-quarters, hands in pockets or holding coat collar, cozy atmosphere, same winter outfit and soft snow light.\n\nMust differ from frame 0: medium distance, outdoor path context, three-quarter turn, hand pose. Do not repeat the same pose, crop, camera distance, arm position, gaze direction, background framing, or composition from the other frames.',
        'You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, color grading and overall look. Generate frame 3 of this winter photoshoot.\n\nWider waist-up winter lifestyle portrait, person walking slowly in snow or standing sideways, more trees and path visible, rosy natural cheeks. Same coat and winter palette.\n\nMust differ from frames 0 and 1: widest crop, walking/side pose, more environment. Do not repeat the same pose, crop, camera distance, arm position, gaze direction, background framing, or composition from the other frames.',
    ],
    "expert_photoshoot": [
        'You are given one uploaded user photo. Use it only as the identity reference. Keep the same face, age, facial proportions, skin tone, hairstyle direction and natural expression.\n\nGenerate a trustworthy expert portrait: shoulders-up, smart casual or business-casual, neutral background, soft professional light, calm confident direct gaze.',
        'You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, color grading and overall look. Generate frame 2 of this expert photoshoot.\n\nMedium chest-up portrait, slight head turn, approachable specialist expression, same outfit and backdrop.\n\nMust differ from frame 0: medium crop, three-quarter angle, softer expression. Do not repeat the same pose, crop, camera distance, arm position, gaze direction, background framing, or composition from the other frames.',
        'You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, color grading and overall look. Generate frame 3 of this expert photoshoot.\n\nWider waist-up portrait, relaxed confident posture, hands visible resting naturally, suitable for website hero. Same expert styling and light.\n\nMust differ from frames 0 and 1: wider framing, visible hands, presentation-ready composition. Do not repeat the same pose, crop, camera distance, arm position, gaze direction, background framing, or composition from the other frames.',
    ],
    "personal_brand": [
        'You are given one uploaded user photo. Use it only as the identity reference. Keep the same face, age, facial proportions, skin tone, hairstyle direction and natural expression.\n\nGenerate a personal-brand portrait: close crop, modern confident look, pleasant background, soft light, open natural expression, social-media ready.',
        'You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, color grading and overall look. Generate frame 2 of this personal-brand session.\n\nMedium chest-up portrait, three-quarter angle, confident pose, engaging eye contact or slight off-camera look. Same outfit, location and warm grading.\n\nMust differ from frame 0: medium distance, angled body, different gaze. Do not repeat the same pose, crop, camera distance, arm position, gaze direction, background framing, or composition from the other frames.',
        'You are given Image 1 and Image 2. Image 1 is the original user photo and must be used for identity. Image 2 is the first generated photo and must be used as the style anchor for outfit, location, lighting, color grading and overall look. Generate frame 3 of this personal-brand session.\n\nWider lifestyle portrait with light smile, relaxed arms, more environment visible, trustworthy professional mood. Same brand styling throughout.\n\nMust differ from frames 0 and 1: widest crop, lifestyle context, relaxed arms. Do not repeat the same pose, crop, camera distance, arm position, gaze direction, background framing, or composition from the other frames.',
    ],
    **{style_id: list(frames) for style_id, frames in PHOTOSHOOT_PROMPT_PACK_V1.items()},
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


def append_kie_vertical_portrait_instruction(prompt: str) -> str:
    """Kie image-to-image format guard (vertical 3:4 portrait)."""
    return f"{prompt}\n\n{KIE_VERTICAL_PORTRAIT_FORMAT_INSTRUCTION}"


def build_kie_photoshoot_frame_prompt(
    client_style_id: str,
    style: PhotoshootStyle,
    *,
    frame_index: int,
    output_count: int,
    user_description: str | None = None,
    series_reference_mode: str = "legacy",
) -> str:
    """Build Kie photoshoot instruction for one frame (vertical 3:4 portrait)."""
    prompt = build_photoshoot_frame_prompt(
        client_style_id,
        style,
        frame_index=frame_index,
        output_count=output_count,
        user_description=user_description,
        series_reference_mode=series_reference_mode,
    )
    return append_kie_vertical_portrait_instruction(prompt)


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
