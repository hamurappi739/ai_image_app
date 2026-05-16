from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI(title="AI Image Generator API")

MOCK_IMAGE_URL = "https://placehold.co/1024x1024?text=Generated+Image"


class GenerateRequest(BaseModel):
    prompt: str


class GenerateResponse(BaseModel):
    image_url: str
    prompt: str


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/generate", response_model=GenerateResponse)
def generate(body: GenerateRequest):
    prompt = body.prompt.strip()
    if not prompt:
        raise HTTPException(status_code=400, detail="Prompt cannot be empty")
    return GenerateResponse(image_url=MOCK_IMAGE_URL, prompt=prompt)
