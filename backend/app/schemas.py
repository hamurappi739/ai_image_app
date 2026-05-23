from datetime import datetime

from pydantic import BaseModel, Field


class AddCreditsRequest(BaseModel):
    amount: int
    description: str | None = None


class GenerateRequest(BaseModel):
    prompt: str


class GenerateResponse(BaseModel):
    image_url: str
    prompt: str
    payment_type: str | None = None
    credit_consumed: bool = False
    remaining_free_generations: int | None = None
    remaining_paid_credits: int | None = None


class GenerationItem(BaseModel):
    id: str
    prompt: str
    image_url: str
    payment_type: str
    created_at: datetime


class GenerationsListResponse(BaseModel):
    generations: list[GenerationItem] = Field(default_factory=list)
