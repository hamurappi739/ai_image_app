from app.services.supabase_service import (
    insert_credit_transaction,
    insert_generation,
    update_profile,
)


def determine_generation_payment(profile: dict, free_limit: int) -> dict:
    free_generations_used = profile.get("free_generations_used", 0)
    paid_credits = profile.get("paid_credits", 0)

    if free_generations_used < free_limit:
        return {
            "allowed": True,
            "payment_type": "free",
            "reason": None,
        }
    if paid_credits > 0:
        return {
            "allowed": True,
            "payment_type": "paid",
            "reason": None,
        }
    return {
        "allowed": False,
        "payment_type": None,
        "reason": "No available generations",
    }


def consume_generation(
    profile: dict, payment_type: str, prompt: str, image_url: str
) -> dict:
    user_id = profile["id"]

    if payment_type == "free":
        new_free_generations_used = profile["free_generations_used"] + 1
        updated_profile = update_profile(
            user_id, {"free_generations_used": new_free_generations_used}
        )
        generation = insert_generation(
            {
                "user_id": user_id,
                "prompt": prompt,
                "image_url": image_url,
                "payment_type": "free",
            }
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
        if profile["paid_credits"] <= 0:
            raise RuntimeError("No paid credits available")
        new_paid_credits = profile["paid_credits"] - 1
        updated_profile = update_profile(user_id, {"paid_credits": new_paid_credits})
        generation = insert_generation(
            {
                "user_id": user_id,
                "prompt": prompt,
                "image_url": image_url,
                "payment_type": "paid",
            }
        )
        transaction = insert_credit_transaction(
            {
                "user_id": user_id,
                "amount": -1,
                "transaction_type": "generation_spend",
                "source": "paid",
                "description": "Paid credit spent",
            }
        )
    else:
        raise RuntimeError("Invalid payment type")

    return {
        "profile": updated_profile,
        "generation": generation,
        "transaction": transaction,
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
