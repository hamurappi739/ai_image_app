"""Resolve and validate template generation inputs for /generate-with-photo."""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import Any

from fastapi import HTTPException, UploadFile

from app.services.catalog_service import get_template_catalog_item
from app.services.gemini_quality_instructions import append_template_reference_prompt_block
from app.services.template_reference_service import load_template_reference_for_catalog_item

_ALLOWED_CONTENT_TYPES = {
    "image/jpeg",
    "image/png",
    "image/webp",
}
_MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024

_MISSING_INPUTS_DETAIL = "Required template inputs are missing"
_INVALID_CAKE_DIGIT_DETAIL = "Invalid cake digit value"
_INVALID_AGE_NUMBER_DETAIL = "Invalid age number value"
_INVALID_CHILD_NAME_DETAIL = "Invalid child name value"

_DIGIT_1_99_RE = re.compile(r"^[1-9]\d?$")
_CHILD_NAME_RE = re.compile(r"^[A-Za-zА-Яа-яЁё\- ]{1,20}$")
_MAX_CHILD_NAME_LEN = 20

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
    reference_photo: ExtraPhotoInput | None = None


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


def _validate_digit_1_99(value: str | None, *, invalid_detail: str) -> str:
    if value is None or not str(value).strip():
        raise HTTPException(status_code=400, detail=_MISSING_INPUTS_DETAIL)
    trimmed = str(value).strip()
    if not _DIGIT_1_99_RE.fullmatch(trimmed):
        raise HTTPException(status_code=400, detail=invalid_detail)
    return trimmed


def validate_cake_digit(value: str | None) -> str:
    return _validate_digit_1_99(value, invalid_detail=_INVALID_CAKE_DIGIT_DETAIL)


def validate_age_number(value: str | None) -> str:
    return _validate_digit_1_99(value, invalid_detail=_INVALID_AGE_NUMBER_DETAIL)


def validate_child_name(value: str | None) -> str:
    if value is None or not str(value).strip():
        raise HTTPException(status_code=400, detail=_MISSING_INPUTS_DETAIL)
    trimmed = str(value).strip()
    if len(trimmed) > _MAX_CHILD_NAME_LEN:
        raise HTTPException(status_code=400, detail=_INVALID_CHILD_NAME_DETAIL)
    if not _CHILD_NAME_RE.fullmatch(trimmed):
        raise HTTPException(status_code=400, detail=_INVALID_CHILD_NAME_DETAIL)
    return trimmed


def build_template_prompt(
    catalog_prompt: str,
    *,
    cake_digit: str | None = None,
    age_number: str | None = None,
    child_name: str | None = None,
) -> str:
    prompt = catalog_prompt.strip()
    if not prompt:
        raise HTTPException(status_code=400, detail="Description cannot be empty")
    if "{digit}" in prompt:
        prompt = prompt.replace("{digit}", validate_cake_digit(cake_digit))
    if "{age_number}" in prompt:
        prompt = prompt.replace("{age_number}", validate_age_number(age_number))
    if "{child_name}" in prompt:
        prompt = prompt.replace("{child_name}", validate_child_name(child_name))
    return prompt


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


def _resolve_configured_fields(
    field_specs: list[Any],
    *,
    cake_digit: str | None,
    age_number: str | None,
    child_name: str | None,
) -> tuple[str | None, str | None, str | None]:
    resolved_cake_digit: str | None = None
    resolved_age_number: str | None = None
    resolved_child_name: str | None = None

    for field_spec in field_specs:
        if not isinstance(field_spec, dict):
            continue
        field_type = str(field_spec.get("type") or field_spec.get("id") or "").strip()
        if field_type == "cake_digit":
            resolved_cake_digit = validate_cake_digit(cake_digit)
        elif field_type == "age_number":
            resolved_age_number = validate_age_number(age_number)
        elif field_type == "child_name":
            resolved_child_name = validate_child_name(child_name)

    return resolved_cake_digit, resolved_age_number, resolved_child_name


def _finalize_template_inputs(
    template: dict[str, Any],
    *,
    prompt: str,
    photo_bytes: bytes,
    photo_content_type: str,
    extra_photos: list[ExtraPhotoInput],
) -> TemplateGenerationInputs:
    template_id = str(template.get("id") or "").strip() or None
    reference_data = load_template_reference_for_catalog_item(template)
    reference_photo = (
        ExtraPhotoInput(
            photo_bytes=reference_data[0],
            photo_content_type=reference_data[1],
        )
        if reference_data is not None
        else None
    )
    final_prompt = append_template_reference_prompt_block(
        prompt,
        template_id=template_id,
        has_reference=reference_photo is not None,
        user_image_count=1 + len(extra_photos),
    )
    return TemplateGenerationInputs(
        prompt=final_prompt,
        photo_bytes=photo_bytes,
        photo_content_type=photo_content_type,
        extra_photos=extra_photos,
        reference_photo=reference_photo,
    )


def _resolve_multi_input_template(
    template: dict[str, Any],
    *,
    description: str,
    uploads: dict[str, UploadFile | None],
    cake_digit: str | None,
    age_number: str | None,
    child_name: str | None,
) -> TemplateGenerationInputs:
    requirements = template.get("inputRequirements")
    if not isinstance(requirements, dict):
        file_bytes, content_type = _require_upload_file(uploads.get("photo"))
        prompt = (template.get("prompt") or description).strip()
        if not prompt:
            raise HTTPException(status_code=400, detail="Description cannot be empty")
        return _finalize_template_inputs(
            template,
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
    resolved_age_number: str | None = None
    resolved_child_name: str | None = None
    if isinstance(field_specs, list):
        (
            resolved_cake_digit,
            resolved_age_number,
            resolved_child_name,
        ) = _resolve_configured_fields(
            field_specs,
            cake_digit=cake_digit,
            age_number=age_number,
            child_name=child_name,
        )

    catalog_prompt = str(template.get("prompt") or "")
    prompt = build_template_prompt(
        catalog_prompt,
        cake_digit=resolved_cake_digit,
        age_number=resolved_age_number,
        child_name=resolved_child_name,
    )

    primary_spec = photo_specs[0]
    if not isinstance(primary_spec, dict):
        raise HTTPException(status_code=400, detail=_MISSING_INPUTS_DETAIL)
    primary_field = str(primary_spec.get("field") or "photo").strip()
    primary_upload = validated.get(primary_field)
    if primary_upload is None:
        raise HTTPException(status_code=400, detail=_MISSING_INPUTS_DETAIL)
    primary_bytes, primary_content_type = primary_upload

    extra_photos: list[ExtraPhotoInput] = []
    for spec in photo_specs[1:]:
        if not isinstance(spec, dict):
            continue
        upload_field = str(spec.get("field") or "photo").strip()
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

    return _finalize_template_inputs(
        template,
        prompt=prompt,
        photo_bytes=primary_bytes,
        photo_content_type=primary_content_type,
        extra_photos=extra_photos,
    )


def _read_optional_upload_file(photo: UploadFile | None) -> ExtraPhotoInput | None:
    if photo is None:
        return None
    file_bytes, content_type = _read_upload_file(photo)
    return ExtraPhotoInput(
        photo_bytes=file_bytes,
        photo_content_type=content_type,
    )


def _resolve_custom_generation(
    *,
    description: str,
    photo: UploadFile | None,
    extra_photo_1: UploadFile | None = None,
    extra_photo_2: UploadFile | None = None,
) -> TemplateGenerationInputs:
    file_bytes, content_type = _require_upload_file(photo)
    prompt = description.strip()
    if not prompt:
        raise HTTPException(status_code=400, detail="Description cannot be empty")

    extra_photos: list[ExtraPhotoInput] = []
    for upload in (extra_photo_1, extra_photo_2):
        extra = _read_optional_upload_file(upload)
        if extra is not None:
            extra_photos.append(extra)

    return TemplateGenerationInputs(
        prompt=prompt,
        photo_bytes=file_bytes,
        photo_content_type=content_type,
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
    extra_photo_1: UploadFile | None = None,
    extra_photo_2: UploadFile | None = None,
    cake_digit: str | None = None,
    age_number: str | None = None,
    child_name: str | None = None,
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
        return _resolve_custom_generation(
            description=prompt,
            photo=photo,
            extra_photo_1=extra_photo_1,
            extra_photo_2=extra_photo_2,
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
        age_number=age_number,
        child_name=child_name,
    )


TEMPLATE_GALLERY_PREFIX = "Шаблон: "
CUSTOM_IDEA_GALLERY_LABEL = "Своя идея"


def resolve_template_history_prompt(template_id: str | None) -> str:
    """Short gallery/DB label for template generations (not the Kie provider prompt)."""
    normalized = (template_id or "").strip()
    if not normalized:
        return CUSTOM_IDEA_GALLERY_LABEL
    template = get_template_catalog_item(normalized)
    if template is None:
        return CUSTOM_IDEA_GALLERY_LABEL
    title = str(template.get("title") or "").strip()
    if not title:
        return CUSTOM_IDEA_GALLERY_LABEL
    return f"{TEMPLATE_GALLERY_PREFIX}{title}"
