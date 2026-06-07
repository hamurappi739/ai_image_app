"""Payment verification and balance top-up (RuStore foundation; mock verify in development)."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Literal

from fastapi import HTTPException

from app.config import settings
from app.services.balance_service import add_paid_balance, build_balance_response
from app.services.package_catalog import (
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


@dataclass(frozen=True, slots=True)
class PaymentVerifyResult:
    status: PaymentVerifyStatus
    package_id: str
    added_paid_image_generations: int
    added_paid_photoshoots: int
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


# TODO(rustore): implement server-side RuStore purchase verification.
# - Validate purchase token / invoice id against RuStore API (server credentials only).
# - Map RuStore product SKU to backend package_id via package_catalog (never trust client amounts).
# - Reject mismatched amount_rub vs catalog before crediting balance.
# - Do not call RuStore from the client; frontend should only send provider_payment_id / token.


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
