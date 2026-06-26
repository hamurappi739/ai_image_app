from app.services.balance_service import (
    consume_image_credits,
    determine_image_payment,
)
from app.services.generation_image_url import should_persist_generation_image_url
from app.services.supabase_service import (
    create_generation_record,
    insert_credit_transaction,
    update_profile,
)


def determine_generation_payment(profile: dict, free_limit: int) -> dict:
    decision = determine_image_payment(profile, free_limit, 1)
    if not decision["allowed"]:
        return {
            "allowed": False,
            "payment_type": None,
            "reason": decision["reason"],
        }

    free_generations_used = int(profile.get("free_generations_used") or 0)
    if free_generations_used < free_limit:
        return {
            "allowed": True,
            "payment_type": "free",
            "reason": None,
        }
    return {
        "allowed": True,
        "payment_type": "paid",
        "reason": None,
    }


def consume_generation(
    profile: dict,
    free_limit: int,
    prompt: str,
    image_url: str,
) -> dict:
    if not should_persist_generation_image_url(image_url):
        raise RuntimeError("Generation image URL is not persistable")

    user_id = profile["id"]
    free_generations_used = int(profile.get("free_generations_used") or 0)
    payment_type = "free" if free_generations_used < free_limit else "paid"

    updated_profile = consume_image_credits(profile, free_limit, 1)

    if payment_type == "free":
        generation = create_generation_record(
            user_id=user_id,
            prompt=prompt,
            image_url=image_url,
            payment_type="free",
        )
        transaction = insert_credit_transaction(
            {
                "user_id": user_id,
                "amount": 0,
                "transaction_type": "generation_spend",
                "source": "free",
                "description": "Free generation used",
            }
        )
    elif payment_type == "paid":
        generation = create_generation_record(
            user_id=user_id,
            prompt=prompt,
            image_url=image_url,
            payment_type="paid",
        )
        transaction = insert_credit_transaction(
            {
                "user_id": user_id,
                "amount": -1,
                "transaction_type": "generation_spend",
                "source": "paid",
                "description": "Paid image generation spent",
            }
        )
    else:
        raise RuntimeError("Invalid payment type")

    return {
        "profile": updated_profile,
        "generation": generation,
        "transaction": transaction,
        "payment_type": payment_type,
    }


def add_paid_credits(
    profile: dict, amount: int, description: str | None = None
) -> dict:
    if amount <= 0:
        raise RuntimeError("Amount must be positive")

    user_id = profile["id"]
    new_paid_credits = profile["paid_credits"] + amount
    updated_profile = update_profile(user_id, {"paid_credits": new_paid_credits})
    transaction = insert_credit_transaction(
        {
            "user_id": user_id,
            "amount": amount,
            "transaction_type": "admin_adjustment",
            "source": "admin",
            "description": description or "Manual paid credits adjustment",
        }
    )
    return {"profile": updated_profile, "transaction": transaction}
