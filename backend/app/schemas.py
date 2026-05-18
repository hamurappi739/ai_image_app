from pydantic import BaseModel


class GenerateRequest(BaseModel):
    prompt: str


class GenerateResponse(BaseModel):
    image_url: str
    prompt: str
    payment_type: str | None = None
    credit_consumed: bool = False
    remaining_free_generations: int | None = None
    remaining_paid_credits: int | None = None
