from datetime import datetime, timezone

from fastapi import Depends, FastAPI, File, Form, Header, HTTPException, Query, UploadFile
from fastapi.middleware.cors import CORSMiddleware

from app.auth import CurrentUser, get_current_user
from app.config import settings
from app.schemas import (
    AddCreditsRequest,
    DebugConfigResponse,
    DebugStorageTestResponse,
    GenerateRequest,
    GenerateResponse,
    GenerationItem,
    GenerationsListResponse,
)
from app.services.image_service import generate_image
from app.services.credits_service import (
    add_paid_credits,
    consume_generation,
    determine_generation_payment,
)
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

    if not settings.enable_credit_consumption:
        return GenerateResponse(
            image_url=generate_image(prompt),
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

    image_url = generate_image(prompt)
    try:
        result = consume_generation(
            profile, decision["payment_type"], prompt, image_url
        )
    except RuntimeError as exc:
        raise HTTPException(status_code=500, detail=str(exc))

    updated_profile = result["profile"]
    remaining_free = max(
        settings.free_generations_limit - updated_profile["free_generations_used"],
        0,
    )
    return GenerateResponse(
        image_url=image_url,
        prompt=prompt,
        payment_type=decision["payment_type"],
        credit_consumed=True,
        remaining_free_generations=remaining_free,
        remaining_paid_credits=updated_profile["paid_credits"],
    )


@app.post("/photoshoots/generate")
def generate_photoshoot(
    style_id: str = Form(...),
    style_title: str | None = Form(default=None),
    photo: UploadFile | None = File(default=None),
    user: CurrentUser = Depends(get_current_user),
):
    _ensure_profile_for_user(user)

    _ = style_id
    _ = style_title

    if photo is None:
        raise HTTPException(status_code=400, detail="Photo is required")

    if photo.content_type not in _ALLOWED_PHOTOSHOOT_CONTENT_TYPES:
        raise HTTPException(status_code=400, detail="Unsupported photo format")

    file_bytes = photo.file.read(_MAX_PHOTOSHOOT_FILE_SIZE_BYTES + 1)
    if len(file_bytes) > _MAX_PHOTOSHOOT_FILE_SIZE_BYTES:
        raise HTTPException(status_code=400, detail="Photo is too large")

    raise HTTPException(
        status_code=501,
        detail="Photoshoot image processing is not implemented yet",
    )
