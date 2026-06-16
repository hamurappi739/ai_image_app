"""Payment verification layer: development mock verify and future RuStore verify.

Catalog amounts live in ``package_catalog``; this module only verifies purchases
and credits balance after successful verification. Mock paths are development-only
(callers must guard with ``ENVIRONMENT=development``).
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Literal

from fastapi import HTTPException

from app.config import settings
from app.services.balance_service import add_paid_balance, build_balance_response
from app.services.package_catalog import (
    CUSTOM_AMOUNT_MAX_RUB,
    CUSTOM_AMOUNT_MIN_RUB,
    CUSTOM_AMOUNT_PACKAGE_ID,
    IMAGE_UNIT_RUB,
    PHOTOSHOOT_UNIT_RUB,
    RUSTORE_PROVIDER,
    PaymentPackage,
    get_payment_package,
)
from app.services.supabase_service import (
    DuplicatePaymentTransactionError,
    PaymentTransactionsTableMissingError,
    ensure_profile_exists,
    get_payment_transaction_by_provider,
    get_profile_by_id,
    insert_payment_transaction,
)

PaymentVerifyStatus = Literal["verified", "already_processed"]


class RealRuStoreVerificationNotImplementedError(NotImplementedError):
    """Production RuStore verification is not wired yet."""


@dataclass(frozen=True, slots=True)
class PaymentVerifyResult:
    status: PaymentVerifyStatus
    package_id: str
    added_paid_image_generations: int
    added_paid_photoshoots: int
    balance: dict


@dataclass(frozen=True, slots=True)
class CustomPaymentVerifyResult:
    status: PaymentVerifyStatus
    package_id: str
    amount_rub: int
    added_paid_image_generations: int
    added_paid_photoshoots: int
    unused_rub: int
    balance: dict


def _build_balance(profile: dict) -> dict:
    return build_balance_response(
        profile,
        settings.free_generations_limit,
        consumption_enabled=settings.enable_credit_consumption,
    )


def _validate_provider_payment_id(provider_payment_id: str) -> str:
    normalized = provider_payment_id.strip()
    if not normalized:
        raise HTTPException(status_code=400, detail="provider_payment_id is required")
    return normalized


def _already_processed_result(
    package_id: str,
    profile: dict,
) -> PaymentVerifyResult:
    return PaymentVerifyResult(
        status="already_processed",
        package_id=package_id,
        added_paid_image_generations=0,
        added_paid_photoshoots=0,
        balance=_build_balance(profile),
    )


def _calculate_custom_amount_allocation(
    amount_rub: int,
    paid_photoshoots: int,
) -> tuple[int, int, int]:
    photoshoot_cost = paid_photoshoots * PHOTOSHOOT_UNIT_RUB
    remaining_rub = amount_rub - photoshoot_cost
    paid_image_generations = remaining_rub // IMAGE_UNIT_RUB
    used_rub = photoshoot_cost + paid_image_generations * IMAGE_UNIT_RUB
    unused_rub = amount_rub - used_rub
    return paid_image_generations, paid_photoshoots, unused_rub


def _validate_custom_amount_request(
    amount_rub: int,
    paid_photoshoots: int,
) -> None:
    if amount_rub < CUSTOM_AMOUNT_MIN_RUB:
        raise HTTPException(
            status_code=400,
            detail=f"amount_rub must be at least {CUSTOM_AMOUNT_MIN_RUB}",
        )
    if amount_rub > CUSTOM_AMOUNT_MAX_RUB:
        raise HTTPException(
            status_code=400,
            detail=f"amount_rub must not exceed {CUSTOM_AMOUNT_MAX_RUB}",
        )
    if paid_photoshoots < 0:
        raise HTTPException(
            status_code=400,
            detail="paid_photoshoots must not be negative",
        )
    if paid_photoshoots * PHOTOSHOOT_UNIT_RUB > amount_rub:
        raise HTTPException(
            status_code=400,
            detail="paid_photoshoots cost exceeds amount_rub",
        )


def _custom_payment_transaction_payload(
    *,
    user_id: str,
    provider_payment_id: str,
    amount_rub: int,
    paid_image_generations: int,
    paid_photoshoots: int,
    status: str,
    raw_payload: dict[str, Any] | None,
) -> dict:
    return {
        "user_id": user_id,
        "provider": RUSTORE_PROVIDER,
        "provider_payment_id": provider_payment_id,
        "package_id": CUSTOM_AMOUNT_PACKAGE_ID,
        "amount_rub": amount_rub,
        "paid_image_generations": paid_image_generations,
        "paid_photoshoots": paid_photoshoots,
        "status": status,
        "raw_payload": raw_payload,
    }


def _payment_transaction_payload(
    *,
    user_id: str,
    package: PaymentPackage,
    provider_payment_id: str,
    status: str,
    raw_payload: dict[str, Any] | None,
) -> dict:
    return {
        "user_id": user_id,
        "provider": RUSTORE_PROVIDER,
        "provider_payment_id": provider_payment_id,
        "package_id": package.id,
        "amount_rub": package.amount_rub,
        "paid_image_generations": package.paid_image_generations,
        "paid_photoshoots": package.paid_photoshoots,
        "status": status,
        "raw_payload": raw_payload,
    }


def verify_real_rustore_payment(
    *,
    user_id: str,
    email: str | None,
    package_id: str,
    provider_payment_id: str,
    purchase_token: str | None = None,
) -> PaymentVerifyResult:
    """Verify a RuStore purchase server-side and credit balance.

    TODO(rustore): Implement when RuStore merchant / server verification docs are available:
    - Validate purchase token / invoice id against RuStore API (server credentials only).
    - Map RuStore product SKU to backend ``package_id`` via ``package_catalog``.
    - Reject mismatched ``amount_rub`` vs catalog before crediting balance.
    - Insert ``payment_transactions`` with idempotency on ``provider_payment_id``.
    - Call ``add_paid_balance`` only after successful verification.

    Raises:
        RealRuStoreVerificationNotImplementedError: Always, until implemented.
    """
    _ = (user_id, email, package_id, provider_payment_id, purchase_token)
    raise RealRuStoreVerificationNotImplementedError(
        "RuStore server-side payment verification is not implemented"
    )


def mock_verify_rustore_purchase(
    *,
    user_id: str,
    email: str | None,
    package_id: str,
    provider_payment_id: str,
) -> PaymentVerifyResult:
    """Development-only mock: trusts provider_payment_id without calling RuStore API."""
    package = get_payment_package(package_id)
    payment_id = _validate_provider_payment_id(provider_payment_id)

    try:
        profile = ensure_profile_exists(user_id, email)
    except RuntimeError as exc:
        raise HTTPException(
            status_code=500, detail="Failed to ensure user profile"
        ) from exc

    try:
        existing = get_payment_transaction_by_provider(RUSTORE_PROVIDER, payment_id)
    except PaymentTransactionsTableMissingError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    except RuntimeError as exc:
        raise HTTPException(
            status_code=500, detail="Failed to fetch payment transaction"
        ) from exc

    if existing is not None:
        current_profile = get_profile_by_id(user_id)
        if current_profile is None:
            raise HTTPException(status_code=500, detail="Failed to fetch user profile")
        return _already_processed_result(package.id, current_profile)

    raw_payload = {
        "mode": "mock",
        "package_id": package.id,
        "provider_payment_id": payment_id,
    }

    try:
        insert_payment_transaction(
            _payment_transaction_payload(
                user_id=user_id,
                package=package,
                provider_payment_id=payment_id,
                status="verified",
                raw_payload=raw_payload,
            )
        )
    except DuplicatePaymentTransactionError:
        current_profile = get_profile_by_id(user_id)
        if current_profile is None:
            raise HTTPException(status_code=500, detail="Failed to fetch user profile")
        return _already_processed_result(package.id, current_profile)
    except PaymentTransactionsTableMissingError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    except RuntimeError as exc:
        raise HTTPException(
            status_code=500, detail="Failed to record payment transaction"
        ) from exc

    try:
        updated_profile = add_paid_balance(
            profile,
            package.paid_image_generations,
            package.paid_photoshoots,
        )
    except (ValueError, RuntimeError) as exc:
        raise HTTPException(status_code=500, detail="Failed to update balance") from exc

    return PaymentVerifyResult(
        status="verified",
        package_id=package.id,
        added_paid_image_generations=package.paid_image_generations,
        added_paid_photoshoots=package.paid_photoshoots,
        balance=_build_balance(updated_profile),
    )


def _already_processed_custom_result(
    amount_rub: int,
    profile: dict,
) -> CustomPaymentVerifyResult:
    return CustomPaymentVerifyResult(
        status="already_processed",
        package_id=CUSTOM_AMOUNT_PACKAGE_ID,
        amount_rub=amount_rub,
        added_paid_image_generations=0,
        added_paid_photoshoots=0,
        unused_rub=0,
        balance=_build_balance(profile),
    )


def mock_verify_custom_amount_purchase(
    *,
    user_id: str,
    email: str | None,
    amount_rub: int,
    paid_photoshoots: int,
    provider_payment_id: str,
) -> CustomPaymentVerifyResult:
    """Development-only mock: custom amount top-up without calling RuStore API."""
    _validate_custom_amount_request(amount_rub, paid_photoshoots)
    payment_id = _validate_provider_payment_id(provider_payment_id)
    paid_image_generations, credited_photoshoots, unused_rub = (
        _calculate_custom_amount_allocation(amount_rub, paid_photoshoots)
    )

    try:
        profile = ensure_profile_exists(user_id, email)
    except RuntimeError as exc:
        raise HTTPException(
            status_code=500, detail="Failed to ensure user profile"
        ) from exc

    try:
        existing = get_payment_transaction_by_provider(RUSTORE_PROVIDER, payment_id)
    except PaymentTransactionsTableMissingError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    except RuntimeError as exc:
        raise HTTPException(
            status_code=500, detail="Failed to fetch payment transaction"
        ) from exc

    if existing is not None:
        current_profile = get_profile_by_id(user_id)
        if current_profile is None:
            raise HTTPException(status_code=500, detail="Failed to fetch user profile")
        return _already_processed_custom_result(amount_rub, current_profile)

    raw_payload = {
        "mode": "mock_custom",
        "package_id": CUSTOM_AMOUNT_PACKAGE_ID,
        "provider_payment_id": payment_id,
        "request": {
            "amount_rub": amount_rub,
            "paid_photoshoots": paid_photoshoots,
        },
        "calculated": {
            "paid_image_generations": paid_image_generations,
            "paid_photoshoots": credited_photoshoots,
            "unused_rub": unused_rub,
        },
    }

    try:
        insert_payment_transaction(
            _custom_payment_transaction_payload(
                user_id=user_id,
                provider_payment_id=payment_id,
                amount_rub=amount_rub,
                paid_image_generations=paid_image_generations,
                paid_photoshoots=credited_photoshoots,
                status="verified",
                raw_payload=raw_payload,
            )
        )
    except DuplicatePaymentTransactionError:
        current_profile = get_profile_by_id(user_id)
        if current_profile is None:
            raise HTTPException(status_code=500, detail="Failed to fetch user profile")
        return _already_processed_custom_result(amount_rub, current_profile)
    except PaymentTransactionsTableMissingError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    except RuntimeError as exc:
        raise HTTPException(
            status_code=500, detail="Failed to record payment transaction"
        ) from exc

    try:
        updated_profile = add_paid_balance(
            profile,
            paid_image_generations,
            credited_photoshoots,
        )
    except (ValueError, RuntimeError) as exc:
        raise HTTPException(status_code=500, detail="Failed to update balance") from exc

    return CustomPaymentVerifyResult(
        status="verified",
        package_id=CUSTOM_AMOUNT_PACKAGE_ID,
        amount_rub=amount_rub,
        added_paid_image_generations=paid_image_generations,
        added_paid_photoshoots=credited_photoshoots,
        unused_rub=unused_rub,
        balance=_build_balance(updated_profile),
    )
