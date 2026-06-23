"""Resolve and validate template generation inputs for /generate-with-photo."""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import Any

from fastapi import HTTPException, UploadFile

from app.services.catalog_service import get_template_catalog_item

_ALLOWED_CONTENT_TYPES = {
    "image/jpeg",
    "image/png",
    "image/webp",
}
_MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024

_MISSING_INPUTS_DETAIL = "Required template inputs are missing"
_INVALID_CAKE_DIGIT_DETAIL = "Invalid cake digit value"

_CAKE_DIGIT_RE = re.compile(r"^[1-9]\d?$")

_UPLOAD_FIELDS = ("photo", "pet_photo", "child_photo", "baby_photo")


@dataclass(frozen=True)
class ExtraPhotoInput:
    photo_bytes: bytes
    photo_content_type: str


@dataclass(frozen=True)
class TemplateGenerationInputs:
    prompt: str
    photo_bytes: bytes
    photo_content_type: str
    extra_photos: list[ExtraPhotoInput] = field(default_factory=list)


def _read_upload_file(photo: UploadFile) -> tuple[bytes, str]:
    if photo.content_type not in _ALLOWED_CONTENT_TYPES:
        raise HTTPException(status_code=400, detail="Unsupported photo format")
    file_bytes = photo.file.read(_MAX_FILE_SIZE_BYTES + 1)
    if len(file_bytes) > _MAX_FILE_SIZE_BYTES:
        raise HTTPException(status_code=400, detail="Photo is too large")
    return file_bytes, photo.content_type


def _require_upload_file(photo: UploadFile | None) -> tuple[bytes, str]:
    if photo is None:
        raise HTTPException(status_code=400, detail="Photo is required")
    return _read_upload_file(photo)


def validate_cake_digit(value: str | None) -> str:
    if value is None or not str(value).strip():
        raise HTTPException(status_code=400, detail=_MISSING_INPUTS_DETAIL)
    trimmed = str(value).strip()
    if not _CAKE_DIGIT_RE.fullmatch(trimmed):
        raise HTTPException(status_code=400, detail=_INVALID_CAKE_DIGIT_DETAIL)
    return trimmed


def build_template_prompt(catalog_prompt: str, *, cake_digit: str | None) -> str:
    prompt = catalog_prompt.strip()
    if not prompt:
        raise HTTPException(status_code=400, detail="Description cannot be empty")
    if "{digit}" not in prompt:
        return prompt
    digit = validate_cake_digit(cake_digit)
    return prompt.replace("{digit}", digit)


def _uploads_map(
    *,
    photo: UploadFile | None,
    pet_photo: UploadFile | None,
    child_photo: UploadFile | None,
    baby_photo: UploadFile | None,
) -> dict[str, UploadFile | None]:
    return {
        "photo": photo,
        "pet_photo": pet_photo,
        "child_photo": child_photo,
        "baby_photo": baby_photo,
    }


def _resolve_multi_input_template(
    template: dict[str, Any],
    *,
    description: str,
    uploads: dict[str, UploadFile | None],
    cake_digit: str | None,
) -> TemplateGenerationInputs:
    requirements = template.get("inputRequirements")
    if not isinstance(requirements, dict):
        file_bytes, content_type = _require_upload_file(uploads.get("photo"))
        prompt = (template.get("prompt") or description).strip()
        if not prompt:
            raise HTTPException(status_code=400, detail="Description cannot be empty")
        return TemplateGenerationInputs(
            prompt=prompt,
            photo_bytes=file_bytes,
            photo_content_type=content_type,
            extra_photos=[],
        )

    photo_specs = requirements.get("photos")
    if not isinstance(photo_specs, list) or not photo_specs:
        raise HTTPException(status_code=400, detail=_MISSING_INPUTS_DETAIL)

    validated: dict[str, tuple[bytes, str]] = {}
    for spec in photo_specs:
        if not isinstance(spec, dict):
            raise HTTPException(status_code=400, detail=_MISSING_INPUTS_DETAIL)
        upload_field = str(spec.get("field") or "photo").strip()
        if upload_field not in _UPLOAD_FIELDS:
            raise HTTPException(status_code=400, detail=_MISSING_INPUTS_DETAIL)
        upload = uploads.get(upload_field)
        if upload is None:
            raise HTTPException(status_code=400, detail=_MISSING_INPUTS_DETAIL)
        validated[upload_field] = _read_upload_file(upload)

    field_specs = requirements.get("fields")
    resolved_cake_digit: str | None = None
    if isinstance(field_specs, list):
        for field_spec in field_specs:
            if not isinstance(field_spec, dict):
                continue
            field_type = str(field_spec.get("type") or field_spec.get("id") or "").strip()
            if field_type == "cake_digit":
                resolved_cake_digit = validate_cake_digit(cake_digit)

    catalog_prompt = str(template.get("prompt") or "")
    prompt = build_template_prompt(catalog_prompt, cake_digit=resolved_cake_digit)

    user_bytes, user_content_type = validated.get("photo") or _require_upload_file(
        uploads.get("photo")
    )
    extra_photos: list[ExtraPhotoInput] = []
    for spec in photo_specs:
        if not isinstance(spec, dict):
            continue
        upload_field = str(spec.get("field") or "photo").strip()
        if upload_field == "photo":
            continue
        extra = validated.get(upload_field)
        if extra is None:
            raise HTTPException(status_code=400, detail=_MISSING_INPUTS_DETAIL)
        extra_bytes, extra_content_type = extra
        extra_photos.append(
            ExtraPhotoInput(
                photo_bytes=extra_bytes,
                photo_content_type=extra_content_type,
            )
        )

    return TemplateGenerationInputs(
        prompt=prompt,
        photo_bytes=user_bytes,
        photo_content_type=user_content_type,
        extra_photos=extra_photos,
    )


def resolve_template_generation_inputs(
    *,
    template_id: str | None,
    description: str,
    photo: UploadFile | None,
    pet_photo: UploadFile | None = None,
    child_photo: UploadFile | None = None,
    baby_photo: UploadFile | None = None,
    cake_digit: str | None = None,
) -> TemplateGenerationInputs:
    prompt = description.strip()
    uploads = _uploads_map(
        photo=photo,
        pet_photo=pet_photo,
        child_photo=child_photo,
        baby_photo=baby_photo,
    )

    normalized_template_id = (template_id or "").strip()
    if not normalized_template_id:
        file_bytes, content_type = _require_upload_file(photo)
        if not prompt:
            raise HTTPException(status_code=400, detail="Description cannot be empty")
        return TemplateGenerationInputs(
            prompt=prompt,
            photo_bytes=file_bytes,
            photo_content_type=content_type,
            extra_photos=[],
        )

    template = get_template_catalog_item(normalized_template_id)
    if template is None:
        file_bytes, content_type = _require_upload_file(photo)
        if not prompt:
            raise HTTPException(status_code=400, detail="Description cannot be empty")
        return TemplateGenerationInputs(
            prompt=prompt,
            photo_bytes=file_bytes,
            photo_content_type=content_type,
            extra_photos=[],
        )

    if template.get("generationBlocked") is True:
        raise HTTPException(status_code=400, detail=_MISSING_INPUTS_DETAIL)

    return _resolve_multi_input_template(
        template,
        description=prompt,
        uploads=uploads,
        cake_digit=cake_digit,
    )
