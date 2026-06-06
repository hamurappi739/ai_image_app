from datetime import datetime, timezone

from fastapi import Depends, FastAPI, File, Form, Header, HTTPException, Query, UploadFile
from fastapi.middleware.cors import CORSMiddleware

from app.auth import CurrentUser, get_current_user
from app.config import settings
from app.schemas import (
    AddBalanceRequest,
    AddCreditsRequest,
    BalanceResponse,
    DebugConfigResponse,
    DebugStorageImagePersistResponse,
    DebugStorageImageTestResponse,
    DebugStorageTestResponse,
    GenerateRequest,
    GenerateResponse,
    GenerationItem,
    GenerationsListResponse,
    PhotoshootGenerateResponse,
)
from app.services.balance_service import (
    add_paid_balance,
    build_balance_response,
    consume_photoshoot,
    determine_photoshoot_payment,
)
from app.services.image_service import generate_image
from app.services.credits_service import (
    add_paid_credits,
    consume_generation,
    determine_generation_payment,
)
from app.services.photo_generation_service import photo_generation_service
from app.services.photoshoot_styles import get_photoshoot_style
from app.services.photoshoot_service import photoshoot_service
from app.services.storage_service import storage_service
from app.services.supabase_service import (
    check_supabase_connection,
    ensure_profile_exists,
    get_credit_transactions_by_user_id,
    get_generations_by_user_id,
    get_profile_by_id,
)

app = FastAPI(title="AI Image Generator API")


def _require_development_for_debug() -> None:
    """404 unless ENVIRONMENT is ``development`` (case-insensitive)."""
    if settings.environment.strip().lower() != "development":
        raise HTTPException(status_code=404)


def _env_value_configured(value: str | None) -> bool:
    return bool(value and str(value).strip())


# Development only: allow any origin so Flutter web (random localhost port) can call the API.
# Before production, replace allow_origins=["*"] with an explicit list of trusted origins.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health():
    return {"status": "ok"}


def _ensure_profile_for_user(user: CurrentUser) -> None:
    try:
        ensure_profile_exists(user.id, user.email)
    except RuntimeError:
        raise HTTPException(status_code=500, detail="Failed to ensure user profile")


def _store_generated_image_if_needed(user_id: str, image_url: str) -> str:
    """Upload Gemini-style data URLs to Storage; pass through ordinary URLs."""
    if not image_url.startswith("data:image/"):
        return image_url
    return storage_service.upload_generated_image_data_url(
        user_id, image_url, folder="generations"
    )


def _resolve_user_for_image_storage(
    user: CurrentUser | None,
    authorization: str | None,
) -> CurrentUser:
    if user is not None:
        return user
    return get_current_user(authorization=authorization)


def _validate_upload_photo(photo: UploadFile | None) -> tuple[bytes, str]:
    if photo is None:
        raise HTTPException(status_code=400, detail="Photo is required")
    if photo.content_type not in _ALLOWED_PHOTOSHOOT_CONTENT_TYPES:
        raise HTTPException(status_code=400, detail="Unsupported photo format")
    file_bytes = photo.file.read(_MAX_PHOTOSHOOT_FILE_SIZE_BYTES + 1)
    if len(file_bytes) > _MAX_PHOTOSHOOT_FILE_SIZE_BYTES:
        raise HTTPException(status_code=400, detail="Photo is too large")
    return file_bytes, photo.content_type


def _build_generate_response_after_consume(
    image_url: str,
    prompt: str,
    payment_type: str,
    updated_profile: dict,
) -> GenerateResponse:
    balance = build_balance_response(
        updated_profile,
        settings.free_generations_limit,
        consumption_enabled=True,
    )
    return GenerateResponse(
        image_url=image_url,
        prompt=prompt,
        payment_type=payment_type,
        credit_consumed=True,
        remaining_free_generations=balance["free_generations_remaining"],
        remaining_paid_credits=balance["paid_image_generations"],
        balance=balance,
    )


@app.get("/balance", response_model=BalanceResponse)
def get_balance(user: CurrentUser = Depends(get_current_user)):
    try:
        profile = ensure_profile_exists(user.id, user.email)
    except RuntimeError:
        raise HTTPException(status_code=500, detail="Failed to ensure user profile")
    return build_balance_response(
        profile,
        settings.free_generations_limit,
        consumption_enabled=settings.enable_credit_consumption,
    )


@app.get("/generations", response_model=GenerationsListResponse)
def list_generations(
    limit: int = Query(default=20, ge=1, le=100, description="Max items to return"),
    user: CurrentUser = Depends(get_current_user),
):
    _ensure_profile_for_user(user)
    try:
        rows = get_generations_by_user_id(user.id, limit=limit)
    except RuntimeError:
        raise HTTPException(status_code=500, detail="Failed to fetch generations")
    generations = [GenerationItem.model_validate(row) for row in rows]
    return GenerationsListResponse(generations=generations)


@app.get("/debug/config", response_model=DebugConfigResponse)
def debug_config():
    _require_development_for_debug()
    return DebugConfigResponse(
        environment=settings.environment,
        image_provider=settings.image_provider,
        credit_consumption_enabled=settings.enable_credit_consumption,
        gemini_model=settings.gemini_model,
        gemini_api_key_configured=_env_value_configured(settings.gemini_api_key),
        supabase_url_configured=_env_value_configured(settings.supabase_url),
        supabase_anon_key_configured=_env_value_configured(settings.supabase_anon_key),
        supabase_service_role_key_configured=_env_value_configured(
            settings.supabase_service_role_key
        ),
        test_user_id_configured=_env_value_configured(settings.test_user_id),
        photoshoot_output_count=settings.photoshoot_output_count,
        photoshoot_generation_enabled=settings.enable_photoshoot_generation,
    )


@app.get("/debug/supabase")
def debug_supabase():
    try:
        if check_supabase_connection():
            return {"status": "ok", "supabase": "connected"}
    except Exception:
        raise HTTPException(status_code=500, detail="Supabase connection failed")


@app.post("/debug/storage-test", response_model=DebugStorageTestResponse)
def debug_storage_test():
    """Upload a tiny in-memory file to Supabase Storage (development only)."""
    _require_development_for_debug()

    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    filename = f"storage-test-{timestamp}.txt"

    try:
        path = storage_service.build_storage_path(
            user_id="storage-test",
            filename=filename,
            folder="debug",
        )
    except ValueError as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc

    public_url = storage_service.upload_bytes(
        path,
        b"storage test",
        "text/plain",
    )

    return DebugStorageTestResponse(
        status="ok",
        bucket=storage_service.bucket,
        path=path,
        public_url=public_url,
    )


@app.post("/debug/storage-image-test", response_model=DebugStorageImageTestResponse)
def debug_storage_image_test():
    """Upload a tiny PNG data URL via ``upload_generated_image_data_url`` (development only)."""
    _require_development_for_debug()

    if not settings.test_user_id:
        raise HTTPException(status_code=500, detail="TEST_USER_ID is not configured")

    public_url = storage_service.upload_generated_image_data_url(
        settings.test_user_id,
        _DEBUG_TINY_PNG_DATA_URL,
        folder="debug",
    )
    bucket = storage_service.bucket
    path_prefix = f"/object/public/{bucket}/"
    path_or_note = (
        public_url.split(path_prefix, 1)[1]
        if path_prefix in public_url
        else "Uploaded; see public_url"
    )

    return DebugStorageImageTestResponse(
        status="ok",
        public_url=public_url,
        path_or_note=path_or_note,
    )


@app.post("/debug/storage-image-persist", response_model=DebugStorageImagePersistResponse)
def debug_storage_image_persist():
    """Persist a tiny PNG data URL via ``persist_generated_image`` (development only)."""
    _require_development_for_debug()

    if not settings.test_user_id:
        raise HTTPException(status_code=500, detail="TEST_USER_ID is not configured")

    public_url, path = storage_service.persist_generated_image(
        settings.test_user_id,
        _DEBUG_TINY_PNG_DATA_URL,
    )
    if path is None:
        raise HTTPException(status_code=500, detail="Image was not persisted")

    return DebugStorageImagePersistResponse(
        status="ok",
        bucket=storage_service.bucket,
        path=path,
        public_url=public_url,
        persisted=True,
    )


@app.get("/debug/profile")
def debug_profile():
    if not settings.test_user_id:
        raise HTTPException(status_code=500, detail="TEST_USER_ID is not configured")
    try:
        profile = get_profile_by_id(settings.test_user_id)
    except RuntimeError:
        raise HTTPException(status_code=500, detail="Failed to fetch profile")
    if profile is None:
        raise HTTPException(status_code=404, detail="Profile not found")
    return {"status": "ok", "profile": profile}


@app.get("/debug/credits")
def debug_credits():
    if not settings.test_user_id:
        raise HTTPException(status_code=500, detail="TEST_USER_ID is not configured")
    try:
        profile = get_profile_by_id(settings.test_user_id)
    except RuntimeError:
        raise HTTPException(status_code=500, detail="Failed to fetch profile")
    if profile is None:
        raise HTTPException(status_code=404, detail="Profile not found")
    decision = determine_generation_payment(profile, settings.free_generations_limit)
    return {"status": "ok", "profile": profile, "decision": decision}


@app.get("/debug/history")
def debug_history():
    if not settings.test_user_id:
        raise HTTPException(status_code=500, detail="TEST_USER_ID is not configured")
    try:
        profile = get_profile_by_id(settings.test_user_id)
    except RuntimeError:
        raise HTTPException(status_code=500, detail="Failed to fetch profile")
    if profile is None:
        raise HTTPException(status_code=404, detail="Profile not found")
    try:
        generations = get_generations_by_user_id(settings.test_user_id, limit=10)
        transactions = get_credit_transactions_by_user_id(
            settings.test_user_id, limit=10
        )
    except RuntimeError:
        raise HTTPException(status_code=500, detail="Failed to fetch history")
    return {
        "status": "ok",
        "profile": profile,
        "generations": generations,
        "credit_transactions": transactions,
    }


_DEBUG_MOCK_PROMPT = "debug test prompt"
_DEBUG_MOCK_IMAGE_URL = "https://placehold.co/1024x1024?text=Generated+Image"
_DEBUG_TINY_PNG_DATA_URL = (
    "data:image/png;base64,"
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
)
_ALLOWED_PHOTOSHOOT_CONTENT_TYPES = {
    "image/jpeg",
    "image/png",
    "image/webp",
}
_MAX_PHOTOSHOOT_FILE_SIZE_BYTES = 10 * 1024 * 1024


@app.post("/debug/consume-generation")
def debug_consume_generation():
    if not settings.test_user_id:
        raise HTTPException(status_code=500, detail="TEST_USER_ID is not configured")
    try:
        profile = get_profile_by_id(settings.test_user_id)
    except RuntimeError:
        raise HTTPException(status_code=500, detail="Failed to fetch profile")
    if profile is None:
        raise HTTPException(status_code=404, detail="Profile not found")

    decision = determine_generation_payment(profile, settings.free_generations_limit)
    if not decision["allowed"]:
        raise HTTPException(status_code=402, detail=decision["reason"])

    try:
        result = consume_generation(
            profile,
            decision["payment_type"],
            _DEBUG_MOCK_PROMPT,
            _DEBUG_MOCK_IMAGE_URL,
        )
    except RuntimeError as exc:
        raise HTTPException(status_code=500, detail=str(exc))

    return {"status": "ok", "decision": decision, "result": result}


@app.post("/debug/add-balance", response_model=BalanceResponse)
def debug_add_balance(
    request: AddBalanceRequest,
    user: CurrentUser = Depends(get_current_user),
):
    _require_development_for_debug()
    if request.paid_image_generations < 0 or request.paid_photoshoots < 0:
        raise HTTPException(status_code=400, detail="Values must not be negative")
    try:
        profile = ensure_profile_exists(user.id, user.email)
    except RuntimeError:
        raise HTTPException(status_code=500, detail="Failed to ensure user profile")
    try:
        updated_profile = add_paid_balance(
            profile,
            request.paid_image_generations,
            request.paid_photoshoots,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except RuntimeError:
        raise HTTPException(status_code=500, detail="Failed to update balance")
    return build_balance_response(
        updated_profile,
        settings.free_generations_limit,
        consumption_enabled=settings.enable_credit_consumption,
    )


@app.post("/debug/add-credits")
def debug_add_credits(request: AddCreditsRequest):
    if request.amount <= 0:
        raise HTTPException(status_code=400, detail="Amount must be positive")
    if not settings.test_user_id:
        raise HTTPException(status_code=500, detail="TEST_USER_ID is not configured")
    try:
        profile = get_profile_by_id(settings.test_user_id)
    except RuntimeError:
        raise HTTPException(status_code=500, detail="Failed to fetch profile")
    if profile is None:
        raise HTTPException(status_code=404, detail="Profile not found")
    try:
        result = add_paid_credits(profile, request.amount, request.description)
    except RuntimeError as exc:
        raise HTTPException(status_code=500, detail=str(exc))
    return {"status": "ok", "result": result}


@app.post("/generate", response_model=GenerateResponse)
def generate(
    body: GenerateRequest,
    authorization: str | None = Header(default=None),
):
    prompt = body.prompt.strip()
    if not prompt:
        raise HTTPException(status_code=400, detail="Prompt cannot be empty")

    user: CurrentUser | None = None
    if authorization is not None or settings.enable_credit_consumption:
        user = get_current_user(authorization=authorization)

    image_url = generate_image(prompt)
    if image_url.startswith("data:image/"):
        storage_user = _resolve_user_for_image_storage(user, authorization)
        image_url = _store_generated_image_if_needed(storage_user.id, image_url)

    if not settings.enable_credit_consumption:
        return GenerateResponse(
            image_url=image_url,
            prompt=prompt,
        )

    if user is None:
        raise HTTPException(status_code=500, detail="User id resolution failed")
    try:
        profile = ensure_profile_exists(user.id, user.email)
    except RuntimeError:
        raise HTTPException(status_code=500, detail="Failed to ensure user profile")

    decision = determine_generation_payment(profile, settings.free_generations_limit)
    if not decision["allowed"]:
        raise HTTPException(status_code=402, detail=decision["reason"])

    try:
        result = consume_generation(
            profile, decision["payment_type"], prompt, image_url
        )
    except RuntimeError as exc:
        raise HTTPException(status_code=500, detail=str(exc))

    updated_profile = result["profile"]
    return _build_generate_response_after_consume(
        image_url=image_url,
        prompt=prompt,
        payment_type=decision["payment_type"],
        updated_profile=updated_profile,
    )


@app.post("/generate-with-photo", response_model=GenerateResponse)
def generate_with_photo(
    description: str = Form(...),
    photo: UploadFile | None = File(default=None),
    authorization: str | None = Header(default=None),
):
    prompt = description.strip()
    if not prompt:
        raise HTTPException(status_code=400, detail="Description cannot be empty")

    file_bytes, photo_content_type = _validate_upload_photo(photo)

    user: CurrentUser | None = None
    if authorization is not None or settings.enable_credit_consumption:
        user = get_current_user(authorization=authorization)

    profile = None
    payment_decision = None
    if settings.enable_credit_consumption:
        if user is None:
            raise HTTPException(status_code=500, detail="User id resolution failed")
        try:
            profile = ensure_profile_exists(user.id, user.email)
        except RuntimeError:
            raise HTTPException(status_code=500, detail="Failed to ensure user profile")
        payment_decision = determine_generation_payment(
            profile, settings.free_generations_limit
        )
        if not payment_decision["allowed"]:
            raise HTTPException(status_code=402, detail=payment_decision["reason"])

    image_url = photo_generation_service.generate(
        description=prompt,
        photo_bytes=file_bytes,
        photo_content_type=photo_content_type,
    )
    if image_url.startswith("data:image/"):
        storage_user = _resolve_user_for_image_storage(user, authorization)
        image_url = _store_generated_image_if_needed(storage_user.id, image_url)

    if not settings.enable_credit_consumption:
        return GenerateResponse(
            image_url=image_url,
            prompt=prompt,
        )

    try:
        result = consume_generation(
            profile, payment_decision["payment_type"], prompt, image_url
        )
    except RuntimeError as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc

    return _build_generate_response_after_consume(
        image_url=image_url,
        prompt=prompt,
        payment_type=payment_decision["payment_type"],
        updated_profile=result["profile"],
    )


@app.post("/photoshoots/generate", response_model=PhotoshootGenerateResponse)
def generate_photoshoot(
    style_id: str = Form(...),
    style_title: str | None = Form(default=None),
    photo: UploadFile | None = File(default=None),
    user: CurrentUser = Depends(get_current_user),
):
    _ensure_profile_for_user(user)

    style = get_photoshoot_style(style_id)
    _ = style_title  # client hint; backend title from catalog is source of truth

    if not style.is_free:
        raise HTTPException(
            status_code=402,
            detail="Payment is required for this photoshoot style",
        )

    file_bytes, photo_content_type = _validate_upload_photo(photo)

    if not settings.enable_photoshoot_generation:
        raise HTTPException(
            status_code=501,
            detail="Photoshoot generation is disabled in development mode",
        )

    profile = None
    if settings.enable_credit_consumption:
        try:
            profile = ensure_profile_exists(user.id, user.email)
        except RuntimeError:
            raise HTTPException(status_code=500, detail="Failed to ensure user profile")
        photoshoot_decision = determine_photoshoot_payment(profile)
        if not photoshoot_decision["allowed"]:
            raise HTTPException(
                status_code=402,
                detail=photoshoot_decision["reason"],
            )

    image_urls = photoshoot_service.generate_photoshoot(
        user_id=user.id,
        style=style,
        photo_bytes=file_bytes,
        photo_content_type=photo_content_type,
    )

    balance = None
    if settings.enable_credit_consumption:
        try:
            updated_profile = consume_photoshoot(profile)
        except RuntimeError as exc:
            raise HTTPException(status_code=500, detail=str(exc)) from exc
        balance = build_balance_response(
            updated_profile,
            settings.free_generations_limit,
            consumption_enabled=True,
        )

    return PhotoshootGenerateResponse(
        style_id=style.id,
        style_title=style.title,
        image_urls=image_urls,
        output_count=len(image_urls),
        balance=balance,
    )
