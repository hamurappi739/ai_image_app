from fastapi import FastAPI

app = FastAPI(title="AI Image Generator API")


@app.get("/health")
def health():
    return {"status": "ok"}
