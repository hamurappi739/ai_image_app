from fastapi import FastAPI, HTTPException

from app.schemas import GenerateRequest, GenerateResponse
from app.services.image_service import generate_mock_image
from app.services.supabase_service import check_supabase_connection

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


@app.post("/generate", response_model=GenerateResponse)
def generate(body: GenerateRequest):
    prompt = body.prompt.strip()
    if not prompt:
        raise HTTPException(status_code=400, detail="Prompt cannot be empty")
    return GenerateResponse(image_url=generate_mock_image(prompt), prompt=prompt)
