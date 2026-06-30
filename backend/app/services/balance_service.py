PHOTOSHOOT_IMAGE_COST = 3


def _free_remaining(profile: dict, free_generations_limit: int) -> int:
    free_used = int(profile.get("free_generations_used") or 0)
    return max(free_generations_limit - free_used, 0)


def paid_image_balance(profile: dict) -> int:
    """Paid image credits only (photoshoots never consume free quota)."""
    return int(profile.get("paid_image_generations") or 0)


def total_available_images(profile: dict, free_generations_limit: int) -> int:
    return _free_remaining(profile, free_generations_limit) + paid_image_balance(profile)


def build_balance_response(
    profile: dict,
    free_generations_limit: int,
    *,
    consumption_enabled: bool = False,
) -> dict:
    """Build public balance payload for GET /balance and debug helpers."""
    free_used = int(profile.get("free_generations_used") or 0)
    remaining_free = _free_remaining(profile, free_generations_limit)
    paid_images = paid_image_balance(profile)
    total_images = remaining_free + paid_images
    return {
        "free_generations_limit": free_generations_limit,
        "free_generations_used": free_used,
        "free_generations_remaining": remaining_free,
        "paid_image_generations": paid_images,
        "paid_photoshoots": int(profile.get("paid_photoshoots") or 0),
        "total_available_images": total_images,
        "available_photos": total_images,
        "photoshoot_image_cost": PHOTOSHOOT_IMAGE_COST,
        "available_photoshoots_by_images": paid_images // PHOTOSHOOT_IMAGE_COST,
        "consumption_enabled": consumption_enabled,
    }


def determine_image_payment(
    profile: dict,
    free_generations_limit: int,
    amount: int,
) -> dict:
    if amount <= 0:
        return {"allowed": False, "reason": "invalid_amount"}
    if total_available_images(profile, free_generations_limit) >= amount:
        return {"allowed": True, "reason": None}
    return {"allowed": False, "reason": "insufficient_images"}


def consume_image_credits(
    profile: dict,
    free_generations_limit: int,
    amount: int,
) -> dict:
    """Spend image credits: free quota first, then paid_image_generations."""
    if amount <= 0:
        raise ValueError("amount must be positive")

    user_id = profile["id"]
    free_used = int(profile.get("free_generations_used") or 0)
    paid_images = paid_image_balance(profile)
    free_remaining = max(free_generations_limit - free_used, 0)

    if free_remaining + paid_images < amount:
        raise RuntimeError("Insufficient image credits")

    from_free = min(free_remaining, amount)
    from_paid = amount - from_free

    updates: dict[str, int] = {}
    if from_free > 0:
        updates["free_generations_used"] = free_used + from_free
    if from_paid > 0:
        updates["paid_image_generations"] = paid_images - from_paid

    from app.services.supabase_service import update_profile

    return update_profile(user_id, updates)


def determine_photoshoot_payment(
    profile: dict,
    free_generations_limit: int,
) -> dict:
    """Photoshoots require paid image balance; free generations do not apply."""
    _ = free_generations_limit
    if paid_image_balance(profile) >= PHOTOSHOOT_IMAGE_COST:
        return {"allowed": True, "reason": None}
    return {"allowed": False, "reason": "insufficient_images"}


def consume_photoshoot(profile: dict, free_generations_limit: int) -> dict:
    """Debit photoshoot cost from paid image balance only."""
    _ = free_generations_limit
    paid_images = paid_image_balance(profile)
    if paid_images < PHOTOSHOOT_IMAGE_COST:
        raise RuntimeError("Insufficient image credits")

    from app.services.supabase_service import update_profile

    user_id = profile["id"]
    return update_profile(
        user_id,
        {"paid_image_generations": paid_images - PHOTOSHOOT_IMAGE_COST},
    )


def add_paid_balance(
    profile: dict,
    paid_image_generations: int,
    paid_photoshoots: int,
) -> dict:
    """Add non-negative amounts to paid image / photoshoot balances."""
    if paid_image_generations < 0 or paid_photoshoots < 0:
        raise ValueError("Balance increments must not be negative")

    from app.services.supabase_service import update_profile

    user_id = profile["id"]
    new_images = paid_image_balance(profile) + paid_image_generations
    new_photoshoots = int(profile.get("paid_photoshoots") or 0) + paid_photoshoots
    return update_profile(
        user_id,
        {
            "paid_image_generations": new_images,
            "paid_photoshoots": new_photoshoots,
        },
    )
