from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field, model_validator


class AddCreditsRequest(BaseModel):
    amount: int
    description: str | None = None


class AddBalanceRequest(BaseModel):
    paid_image_generations: int = 0
    paid_photoshoots: int = 0


class BalanceResponse(BaseModel):
    free_generations_limit: int
    free_generations_used: int
    free_generations_remaining: int
    paid_image_generations: int
    paid_photoshoots: int
    total_available_images: int = 0
    photoshoot_image_cost: int = 3
    available_photoshoots_by_images: int = 0
    consumption_enabled: bool = False


class GenerateRequest(BaseModel):
    prompt: str


class PhotoshootGenerateRequest(BaseModel):
    style_id: str
    style_title: str | None = None


class PhotoshootGenerateResponse(BaseModel):
    status: Literal["success"] = "success"
    images: list[str]
    style_id: str
    style_title: str
    image_urls: list[str]
    output_count: int
    photoshoot_id: str
    balance: BalanceResponse | None = None
    description: str | None = None

    @model_validator(mode="before")
    @classmethod
    def _sync_image_fields(cls, data: object) -> object:
        if not isinstance(data, dict):
            return data
        urls = data.get("images") or data.get("image_urls") or []
        data = {**data, "images": urls, "image_urls": urls}
        data.setdefault("status", "success")
        return data


class PhotoshootFrameStatusItem(BaseModel):
    index: int
    status: Literal["queued", "generating", "done", "error"]


class PhotoshootJobStartResponse(BaseModel):
    job_id: str
    status: Literal["queued"] = "queued"


class PhotoshootJobStatusResponse(BaseModel):
    status: Literal["queued", "running", "success", "error"]
    message: str = ""
    frames: list[PhotoshootFrameStatusItem] = Field(default_factory=list)
    images: list[str] = Field(default_factory=list)
    photoshoot_id: str | None = None
    style_id: str | None = None
    style_title: str | None = None
    output_count: int | None = None
    balance: BalanceResponse | None = None
    description: str | None = None


class GenerateResponse(BaseModel):
    image_url: str
    prompt: str
    payment_type: str | None = None
    credit_consumed: bool = False
    remaining_free_generations: int | None = None
    remaining_paid_credits: int | None = None
    balance: BalanceResponse | None = None


class GenerationItem(BaseModel):
    id: str
    prompt: str
    image_url: str
    payment_type: str
    photoshoot_id: str | None = None
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


class HealthResponse(BaseModel):
    status: Literal["ok"]
    environment: str
    version: str


class ReadyChecks(BaseModel):
    config_loaded: bool
    supabase_configured: bool
    supabase_auth_configured: bool
    gemini_required: bool
    gemini_configured: bool
    kie_required: bool
    kie_configured: bool
    production_safe: bool


class ReadyResponse(BaseModel):
    status: Literal["ready", "not_ready"]
    environment: str
    checks: ReadyChecks


class RuStoreMockVerifyRequest(BaseModel):
    package_id: str
    provider_payment_id: str


class PaymentAddedBalance(BaseModel):
    paid_image_generations: int
    paid_photoshoots: int


class RuStoreMockVerifyResponse(BaseModel):
    status: Literal["verified", "already_processed"]
    package_id: str
    added: PaymentAddedBalance
    balance: BalanceResponse


class RuStoreMockVerifyCustomRequest(BaseModel):
    amount_rub: int
    paid_photoshoots: int = 0
    provider_payment_id: str


class RuStoreMockVerifyCustomResponse(BaseModel):
    status: Literal["verified", "already_processed"]
    package_id: str
    amount_rub: int
    added: PaymentAddedBalance
    unused_rub: int
    balance: BalanceResponse


class RuStoreVerifyRequest(BaseModel):
    """Future production body for server-side RuStore verification."""

    package_id: str
    provider_payment_id: str
    purchase_token: str | None = None


class RuStoreVerifyResponse(BaseModel):
    status: Literal["verified", "already_processed"]
    package_id: str
    added: PaymentAddedBalance
    balance: BalanceResponse


class DebugConfigResponse(BaseModel):
    """Safe subset of settings for GET /debug/config (development only)."""

    environment: str
    image_provider: str
    template_image_provider: str
    photoshoot_image_provider: str
    config_env_file: str
    config_env_file_exists: bool
    env_file_image_provider: str | None = None
    os_image_provider: str | None = None
    env_file_out_of_sync: bool = False
    credit_consumption_enabled: bool
    gemini_model: str
    gemini_api_key_configured: bool
    kie_image_model: str
    kie_api_key_configured: bool
    kie_image_resolution: str
    kie_image_aspect_ratio: str
    supabase_temp_storage_bucket: str
    kie_max_photoshoot_tasks: int
    supabase_url_configured: bool
    supabase_anon_key_configured: bool
    supabase_service_role_key_configured: bool
    test_user_id_configured: bool
    photoshoot_output_count: int
    photoshoot_generation_enabled: bool
    photoshoot_series_reference_mode: str


class CatalogTemplatePhotoInput(BaseModel):
    id: str
    field: str
    label: str


class CatalogTemplateFieldInput(BaseModel):
    id: str
    label: str
    type: str


class CatalogTemplateInputRequirements(BaseModel):
    photos: list[CatalogTemplatePhotoInput] = Field(default_factory=list)
    fields: list[CatalogTemplateFieldInput] = Field(default_factory=list)


class CatalogTemplateItem(BaseModel):
    id: str
    title: str
    category: str
    shortDescription: str
    prompt: str
    previewAsset: str
    previewUrl: str | None = None
    priceImages: int = 1
    isActive: bool = True
    sortOrder: int = 0
    generationBlocked: bool = False
    generationBlockedMessage: str | None = None
    inputRequirements: CatalogTemplateInputRequirements | None = None


class CatalogPhotoshootItem(BaseModel):
    id: str
    title: str
    category: str
    shortDescription: str
    prompt: str
    framePrompts: list[str] = Field(default_factory=list)
    previewAssets: list[str] = Field(default_factory=list)
    previewUrls: list[str] = Field(default_factory=list)
    priceImages: int = 3
    isActive: bool = True
    sortOrder: int = 0
    badge: str | None = None
    isFree: bool = False


class CatalogTemplatesResponse(BaseModel):
    items: list[CatalogTemplateItem]
    source: str = "backend"
    version: str = "1"


class CatalogPhotoshootsResponse(BaseModel):
    items: list[CatalogPhotoshootItem]
    source: str = "backend"
    version: str = "1"
