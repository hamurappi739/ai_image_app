"""Perceptual similarity checks for photoshoot generated frames."""

from __future__ import annotations

import re
from dataclasses import dataclass
from io import BytesIO

from fastapi import HTTPException
from PIL import Image

from app.services.storage_service import storage_service

_PERCEPTUAL_DHASH_WIDTH = 9
_PERCEPTUAL_DHASH_HEIGHT = 8
PERCEPTUAL_DUPLICATE_MAX_HAMMING = 5

KIE_DUPLICATE_RETRY_PROMPT_SUFFIX = (
    "The previous result was too similar. Regenerate this frame with a clearly "
    "different crop, body angle, hand position, gaze and background framing."
)

KIE_FRAME_FAIL_RETRY_PROMPT_SUFFIX = (
    "Regenerate this frame as a clearly different photo. Keep the same identity "
    "and style, but use a new pose, camera distance, composition, and background "
    "arrangement. Do not repeat the previous frame."
)

KIE_FRAME_FAIL_RETRY_PROMPT_SUFFIX_FRAME0 = (
    "Regenerate this frame as a clean, high-quality opening photo for the series. "
    "Keep the same identity and selected style, but use a stable composition, "
    "natural pose, clear face, and photorealistic result."
)


def kie_frame_fail_retry_prompt_suffix(frame_index: int) -> str:
    if frame_index <= 0:
        return KIE_FRAME_FAIL_RETRY_PROMPT_SUFFIX_FRAME0
    return KIE_FRAME_FAIL_RETRY_PROMPT_SUFFIX


def kie_generation_error_reason(exc: Exception) -> str:
    reason = str(exc).strip()
    return reason or "kie_task_failed"


@dataclass(frozen=True, slots=True)
class DuplicateFrameMatch:
    kind: str
    duplicate_frame_index: int
    perceptual_distance: int | None = None


def _normalize_data_url_payload(data_url: str) -> str:
    match = re.match(
        r"^data:(?P<mime>[^;]+);base64,(?P<payload>.+)$",
        data_url.strip(),
        flags=re.DOTALL,
    )
    if not match:
        return data_url.strip()
    return re.sub(r"\s+", "", match.group("payload"))


def _data_url_image_bytes(data_url: str) -> bytes:
    _content_type, content = storage_service._parse_generated_image_data_url(data_url)
    return content


def _compute_dhash(image_bytes: bytes) -> int | None:
    try:
        image = Image.open(BytesIO(image_bytes)).convert("L")
        image = image.resize(
            (_PERCEPTUAL_DHASH_WIDTH, _PERCEPTUAL_DHASH_HEIGHT),
            Image.Resampling.LANCZOS,
        )
        pixels = list(image.getdata())
        hash_value = 0
        for row in range(_PERCEPTUAL_DHASH_HEIGHT):
            row_offset = row * _PERCEPTUAL_DHASH_WIDTH
            for col in range(_PERCEPTUAL_DHASH_WIDTH - 1):
                left = pixels[row_offset + col]
                right = pixels[row_offset + col + 1]
                hash_value = (hash_value << 1) | (1 if left > right else 0)
        return hash_value
    except Exception:
        return None


def _hamming_distance(left: int, right: int) -> int:
    return (left ^ right).bit_count()


def find_perceptual_near_duplicate(
    data_url: str,
    existing_data_urls: list[str],
) -> DuplicateFrameMatch | None:
    try:
        candidate_bytes = _data_url_image_bytes(data_url)
    except HTTPException:
        return None

    candidate_hash = _compute_dhash(candidate_bytes)
    if candidate_hash is None:
        return None

    for index, previous in enumerate(existing_data_urls):
        try:
            previous_bytes = _data_url_image_bytes(previous)
        except HTTPException:
            continue
        previous_hash = _compute_dhash(previous_bytes)
        if previous_hash is None:
            continue
        distance = _hamming_distance(candidate_hash, previous_hash)
        if distance <= PERCEPTUAL_DUPLICATE_MAX_HAMMING:
            return DuplicateFrameMatch(
                kind="perceptual",
                duplicate_frame_index=index,
                perceptual_distance=distance,
            )
    return None


def find_generated_frame_duplicate(
    data_url: str,
    existing_data_urls: list[str],
) -> DuplicateFrameMatch | None:
    if not existing_data_urls:
        return None

    normalized = _normalize_data_url_payload(data_url)
    try:
        candidate_bytes = _data_url_image_bytes(data_url)
    except HTTPException:
        candidate_bytes = None

    for index, previous in enumerate(existing_data_urls):
        if _normalize_data_url_payload(previous) == normalized:
            return DuplicateFrameMatch(kind="exact", duplicate_frame_index=index)
        if candidate_bytes is not None:
            try:
                if _data_url_image_bytes(previous) == candidate_bytes:
                    return DuplicateFrameMatch(kind="exact", duplicate_frame_index=index)
            except HTTPException:
                continue

    return find_perceptual_near_duplicate(data_url, existing_data_urls)


def is_duplicate_photoshoot_frame(data_url: str, existing_data_urls: list[str]) -> bool:
    return find_generated_frame_duplicate(data_url, existing_data_urls) is not None
