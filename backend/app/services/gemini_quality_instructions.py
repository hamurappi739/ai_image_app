"""Shared English quality instructions for Gemini image generation (not shown in UI)."""

STANDALONE_SINGLE_IMAGE_RULES = (
    "Generate exactly ONE complete, finished image. "
    "The output must be a single scene and a single final photograph or illustration. "
    "Do not create a collage, grid, contact sheet, storyboard, split-screen, "
    "before/after comparison, multiple panels, or multiple variants on one canvas. "
    "Do not place several photos, frames, or versions inside one image."
)

TEXT_ON_IMAGE_RULES = (
    "Do not add text, captions, watermarks, logos, or typography on the image "
    "unless the user description explicitly requests visible text."
)

REALISM_AND_COMPOSITION_RULES = (
    "Use realistic proportions, natural lighting, clean composition, and a polished "
    "final result suitable for a consumer photo app. "
    "Keep faces accurate and undistorted with natural skin texture. "
    "Avoid extra fingers, extra hands, distorted anatomy, duplicate limbs, or extra faces."
)

PHOTO_REALISM_RULES = (
    "Create a highly realistic portrait photograph with photographic detail. "
    "Preserve identity, facial features, face shape, eye color, skin tone, hair, age, "
    "and overall appearance from the reference photo. "
    "Use natural skin texture, lifelike eyes, realistic lighting, believable shadows, "
    "and true-to-life proportions. "
    "The result must look like a real camera photo, not an illustration, CGI, cartoon, "
    "painting, or over-smoothed beauty filter. "
    "Avoid plastic skin, waxy texture, painterly strokes, stylized rendering, "
    "artificial glow, or uncanny facial features."
)

PHOTO_REFERENCE_RULES = (
    "Use the uploaded photo as the primary reference. "
    "Preserve the recognizable identity of the person or main object. "
    "Do not change who the person is unless the user description explicitly asks. "
    "If the user asks to change background, style, lighting, or atmosphere, change those "
    "elements without breaking identity, face structure, or key features."
)

PHOTOSHOOT_SESSION_RULES = (
    "This image is one frame of a photoshoot set. "
    "Each generation call must return exactly ONE separate full photo — never three photos "
    "on one canvas. "
    "Keep the same visual style, wardrobe mood, and color grading as the selected "
    "photoshoot style across the set, while allowing small natural differences in pose, "
    "angle, framing, or composition."
)


def build_text_to_image_instruction(user_description: str) -> str:
    description = user_description.strip()
    return (
        f"User description: {description}\n\n"
        "Create one complete finished image based on the user description. "
        "Do not make a collage, grid, or contact sheet.\n\n"
        f"{STANDALONE_SINGLE_IMAGE_RULES}\n"
        f"{TEXT_ON_IMAGE_RULES}\n"
        f"{REALISM_AND_COMPOSITION_RULES}\n\n"
        "Do not create NSFW content. Return an image only."
    )


def build_photo_edit_instruction(user_description: str) -> str:
    description = user_description.strip()
    return (
        f"User description: {description}\n\n"
        f"{PHOTO_REFERENCE_RULES}\n"
        f"{PHOTO_REALISM_RULES}\n"
        f"{STANDALONE_SINGLE_IMAGE_RULES}\n"
        f"{TEXT_ON_IMAGE_RULES}\n"
        f"{REALISM_AND_COMPOSITION_RULES}\n\n"
        "Return one high-quality photorealistic image only. "
        "Do not create NSFW content. Return an image only."
    )


def build_custom_photoshoot_frame_instruction(
    user_description: str,
    *,
    variation_index: int = 1,
    variation_total: int = 1,
) -> str:
    description = user_description.strip()
    variation_note = ""
    if variation_total > 1:
        variation_note = (
            f"\nThis is photo {variation_index} of {variation_total} in the same custom "
            "photoshoot set. Other photos are generated in separate calls — output only "
            "this one frame. Match the overall style and mood from the user description "
            "but vary pose, angle, or composition slightly."
        )
    return (
        f"Custom photoshoot — user description: {description}\n\n"
        "Create a polished photoshoot image that follows the user description. "
        "Keep one consistent visual style across the set.\n\n"
        f"{PHOTO_REFERENCE_RULES}\n"
        f"{PHOTOSHOOT_SESSION_RULES}\n"
        f"{STANDALONE_SINGLE_IMAGE_RULES}\n"
        f"{TEXT_ON_IMAGE_RULES}\n"
        f"{REALISM_AND_COMPOSITION_RULES}"
        f"{variation_note}\n\n"
        "Do not create NSFW content. Return an image only."
    )


def build_photoshoot_frame_instruction(
    style_instruction: str,
    style_title: str,
    *,
    variation_index: int = 1,
    variation_total: int = 1,
) -> str:
    variation_note = ""
    if variation_total > 1:
        variation_note = (
            f"\nThis is photo {variation_index} of {variation_total} in the same photoshoot. "
            "Other photos are generated in separate calls — output only this one frame. "
            "Match the overall style of the set but vary pose, angle, or composition slightly."
        )
    return (
        f"Photoshoot style: {style_title.strip()}\n"
        f"{style_instruction.strip()}\n\n"
        f"{PHOTO_REFERENCE_RULES}\n"
        f"{PHOTOSHOOT_SESSION_RULES}\n"
        f"{STANDALONE_SINGLE_IMAGE_RULES}\n"
        f"{TEXT_ON_IMAGE_RULES}\n"
        f"{REALISM_AND_COMPOSITION_RULES}"
        f"{variation_note}\n\n"
        "Do not create NSFW content. Return an image only."
    )
