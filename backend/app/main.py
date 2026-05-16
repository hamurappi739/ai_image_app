from fastapi import FastAPI, HTTPException

from app.schemas import GenerateRequest, GenerateResponse
from app.services.image_service import generate_mock_image

app = FastAPI(title="AI Image Generator API")


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/generate", response_model=GenerateResponse)
def generate(body: GenerateRequest):
    prompt = body.prompt.strip()
    if not prompt:
        raise HTTPException(status_code=400, detail="Prompt cannot be empty")
    return GenerateResponse(image_url=generate_mock_image(prompt), prompt=prompt)
