from datetime import datetime

from pydantic import BaseModel, Field


class AddCreditsRequest(BaseModel):
    amount: int
    description: str | None = None


class GenerateRequest(BaseModel):
    prompt: str


class PhotoshootGenerateRequest(BaseModel):
    style_id: str
    style_title: str | None = None


class GenerateResponse(BaseModel):
    image_url: str
    prompt: str
    payment_type: str | None = None
    credit_consumed: bool = False
    remaining_free_generations: int | None = None
    remaining_paid_credits: int | None = None


class GenerationItem(BaseModel):
    id: str
    prompt: str
    image_url: str
    payment_type: str
    created_at: datetime


class GenerationsListResponse(BaseModel):
    generations: list[GenerationItem] = Field(default_factory=list)


class DebugStorageTestResponse(BaseModel):
    """Safe response for POST /debug/storage-test (development only)."""

    status: str
    bucket: str
    path: str
    public_url: str


class DebugStorageImageTestResponse(BaseModel):
    """Safe response for POST /debug/storage-image-test (development only)."""

    status: str
    public_url: str
    path_or_note: str


class DebugStorageImagePersistResponse(BaseModel):
    """Safe response for POST /debug/storage-image-persist (development only)."""

    status: str
    bucket: str
    path: str
    public_url: str
    persisted: bool


class DebugConfigResponse(BaseModel):
    """Safe subset of settings for GET /debug/config (development only)."""

    environment: str
    image_provider: str
    credit_consumption_enabled: bool
    gemini_model: str
    gemini_api_key_configured: bool
    supabase_url_configured: bool
    supabase_anon_key_configured: bool
    supabase_service_role_key_configured: bool
    test_user_id_configured: bool
    photoshoot_output_count: int
