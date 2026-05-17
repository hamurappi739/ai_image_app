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
