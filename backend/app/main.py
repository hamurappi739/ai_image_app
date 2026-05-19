from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.schemas import AddCreditsRequest, GenerateRequest, GenerateResponse
from app.services.image_service import generate_mock_image
from app.services.credits_service import (
    add_paid_credits,
    consume_generation,
    determine_generation_payment,
)
from app.services.supabase_service import (
    check_supabase_connection,
    get_credit_transactions_by_user_id,
    get_generations_by_user_id,
    get_profile_by_id,
)

app = FastAPI(title="AI Image Generator API")

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


@app.get("/debug/supabase")
def debug_supabase():
    try:
        if check_supabase_connection():
            return {"status": "ok", "supabase": "connected"}
    except Exception:
        raise HTTPException(status_code=500, detail="Supabase connection failed")


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
def generate(body: GenerateRequest):
    prompt = body.prompt.strip()
    if not prompt:
        raise HTTPException(status_code=400, detail="Prompt cannot be empty")

    if not settings.enable_credit_consumption:
        return GenerateResponse(
            image_url=generate_mock_image(prompt),
            prompt=prompt,
        )

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

    image_url = generate_mock_image(prompt)
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
