from app.services.supabase_service import update_profile


def build_balance_response(
    profile: dict,
    free_generations_limit: int,
    *,
    consumption_enabled: bool = False,
) -> dict:
    """Build public balance payload for GET /balance and debug helpers."""
    free_used = int(profile.get("free_generations_used") or 0)
    remaining_free = max(free_generations_limit - free_used, 0)
    return {
        "free_generations_limit": free_generations_limit,
        "free_generations_used": free_used,
        "free_generations_remaining": remaining_free,
        "paid_image_generations": int(profile.get("paid_image_generations") or 0),
        "paid_photoshoots": int(profile.get("paid_photoshoots") or 0),
        "consumption_enabled": consumption_enabled,
    }


def determine_photoshoot_payment(profile: dict) -> dict:
    paid_photoshoots = int(profile.get("paid_photoshoots") or 0)
    if paid_photoshoots > 0:
        return {"allowed": True, "reason": None}
    return {"allowed": False, "reason": "insufficient_photoshoots"}


def consume_photoshoot(profile: dict) -> dict:
    user_id = profile["id"]
    paid_photoshoots = int(profile.get("paid_photoshoots") or 0)
    if paid_photoshoots <= 0:
        raise RuntimeError("No photoshoots available")
    return update_profile(user_id, {"paid_photoshoots": paid_photoshoots - 1})


def add_paid_balance(
    profile: dict,
    paid_image_generations: int,
    paid_photoshoots: int,
) -> dict:
    """Add non-negative amounts to paid image / photoshoot balances."""
    if paid_image_generations < 0 or paid_photoshoots < 0:
        raise ValueError("Balance increments must not be negative")

    user_id = profile["id"]
    new_images = int(profile.get("paid_image_generations") or 0) + paid_image_generations
    new_photoshoots = int(profile.get("paid_photoshoots") or 0) + paid_photoshoots
    return update_profile(
        user_id,
        {
            "paid_image_generations": new_images,
            "paid_photoshoots": new_photoshoots,
        },
    )
