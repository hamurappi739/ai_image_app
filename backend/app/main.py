from fastapi import FastAPI, HTTPException

from app.config import settings
from app.schemas import GenerateRequest, GenerateResponse
from app.services.image_service import generate_mock_image
from app.services.supabase_service import check_supabase_connection, get_profile_by_id

app = FastAPI(title="AI Image Generator API")


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


@app.post("/generate", response_model=GenerateResponse)
def generate(body: GenerateRequest):
    prompt = body.prompt.strip()
    if not prompt:
        raise HTTPException(status_code=400, detail="Prompt cannot be empty")
    return GenerateResponse(image_url=generate_mock_image(prompt), prompt=prompt)
