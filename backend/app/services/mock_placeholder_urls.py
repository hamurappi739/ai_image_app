"""Diverse placehold.co URLs for mock/demo generation (no network I/O)."""

from __future__ import annotations

import hashlib
from urllib.parse import quote

_PLACEHOLDER_HOST = "https://placehold.co"

_SINGLE_LABELS = ("Фото готово", "Портрет", "Образ", "Результат")
_PHOTOSHOOT_LABELS = ("Фото 1", "Фото 2", "Фото 3")

_PALETTES: tuple[tuple[str, str], ...] = (
    ("EDE9FF", "5B6CFF"),
    ("E8F4FF", "2563EB"),
    ("F0FDF4", "16A34A"),
    ("FFF7ED", "EA580C"),
    ("FDF2F8", "DB2777"),
    ("F0F9FF", "0284C7"),
    ("F5F3FF", "7C3AED"),
    ("FFFBEB", "D97706"),
    ("ECFDF5", "059669"),
    ("FEF2F2", "DC2626"),
)


def _digest(seed_key: str) -> str:
    return hashlib.sha256(seed_key.encode("utf-8")).hexdigest()


def _palette_for_seed(seed_key: str) -> tuple[str, str]:
    idx = int(_digest(seed_key)[:4], 16) % len(_PALETTES)
    return _PALETTES[idx]


def build_mock_placeholder_url(
    *,
    seed_key: str,
    label: str,
    width: int = 1024,
    height: int = 1024,
) -> str:
    """Build a placehold.co URL with stable colors/text from seed_key."""
    digest = _digest(seed_key)
    bg, fg = _palette_for_seed(seed_key)
    w = width + (int(digest[4:6], 16) % 4) * 12
    h = height + (int(digest[6:8], 16) % 4) * 12
    text = quote(label, safe="")
    return f"{_PLACEHOLDER_HOST}/{w}x{h}/{bg}/{fg}/png?text={text}"


def _single_label(prompt: str) -> str:
    prompt = prompt.strip()
    if prompt:
        short = prompt if len(prompt) <= 28 else f"{prompt[:25].rstrip()}…"
        digest = _digest(f"label:{prompt}")
        if int(digest[:2], 16) % 3 == 0:
            return short
    idx = int(_digest(f"single:{prompt}"), 16) % len(_SINGLE_LABELS)
    return _SINGLE_LABELS[idx]


def build_mock_text_image_url(prompt: str) -> str:
    label = _single_label(prompt)
    return build_mock_placeholder_url(
        seed_key=f"text:{prompt}",
        label=label,
    )


def build_mock_photo_image_url(description: str) -> str:
    label = _single_label(description)
    return build_mock_placeholder_url(
        seed_key=f"photo:{description}",
        label=label,
    )


def build_mock_photoshoot_image_urls(
    *,
    style_id: str,
    style_title: str,
    output_count: int,
    user_description: str | None = None,
) -> list[str]:
    base = user_description.strip() if user_description else style_id
    urls: list[str] = []
    for index in range(output_count):
        if index < len(_PHOTOSHOOT_LABELS):
            label = _PHOTOSHOOT_LABELS[index]
        else:
            label = f"Фото {index + 1}"
        urls.append(
            build_mock_placeholder_url(
                seed_key=f"ps:{base}:{style_id}:{style_title}:{index}",
                label=label,
            )
        )
    return urls


# Default for debug endpoints / backward compatibility
DEFAULT_MOCK_IMAGE_URL = build_mock_text_image_url("Generated Image")
