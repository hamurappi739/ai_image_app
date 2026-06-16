"""Payment HTTP routes: development mock verify and future RuStore verify."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException

from app.auth import CurrentUser, get_current_user
from app.config import settings
from app.schemas import (
    PaymentAddedBalance,
    RuStoreMockVerifyCustomRequest,
    RuStoreMockVerifyCustomResponse,
    RuStoreMockVerifyRequest,
    RuStoreMockVerifyResponse,
    RuStoreVerifyRequest,
    RuStoreVerifyResponse,
)
from app.services.payment_service import (
    RealRuStoreVerificationNotImplementedError,
    mock_verify_custom_amount_purchase,
    mock_verify_rustore_purchase,
    verify_real_rustore_payment,
)

router = APIRouter(tags=["payments"])


def _require_development_for_payment_mock() -> None:
    """404 unless ENVIRONMENT is ``development`` (mock RuStore verify only)."""
    if settings.environment.strip().lower() != "development":
        raise HTTPException(status_code=404)


@router.post("/payments/rustore/mock-verify", response_model=RuStoreMockVerifyResponse)
def rustore_mock_verify_purchase(
    body: RuStoreMockVerifyRequest,
    user: CurrentUser = Depends(get_current_user),
):
    """Development-only mock RuStore purchase verification (no real RuStore API)."""
    _require_development_for_payment_mock()
    result = mock_verify_rustore_purchase(
        user_id=user.id,
        email=user.email,
        package_id=body.package_id,
        provider_payment_id=body.provider_payment_id,
    )
    return RuStoreMockVerifyResponse(
        status=result.status,
        package_id=result.package_id,
        added=PaymentAddedBalance(
            paid_image_generations=result.added_paid_image_generations,
            paid_photoshoots=result.added_paid_photoshoots,
        ),
        balance=result.balance,
    )


@router.post(
    "/payments/rustore/mock-verify-custom",
    response_model=RuStoreMockVerifyCustomResponse,
)
def rustore_mock_verify_custom_amount(
    body: RuStoreMockVerifyCustomRequest,
    user: CurrentUser = Depends(get_current_user),
):
    """Development-only mock RuStore custom amount verification (no real RuStore API)."""
    _require_development_for_payment_mock()
    result = mock_verify_custom_amount_purchase(
        user_id=user.id,
        email=user.email,
        amount_rub=body.amount_rub,
        paid_photoshoots=body.paid_photoshoots,
        provider_payment_id=body.provider_payment_id,
    )
    return RuStoreMockVerifyCustomResponse(
        status=result.status,
        package_id=result.package_id,
        amount_rub=result.amount_rub,
        added=PaymentAddedBalance(
            paid_image_generations=result.added_paid_image_generations,
            paid_photoshoots=result.added_paid_photoshoots,
        ),
        unused_rub=result.unused_rub,
        balance=result.balance,
    )


@router.post(
    "/payments/rustore/verify",
    response_model=RuStoreVerifyResponse,
    responses={501: {"description": "RuStore verification not implemented yet"}},
)
def rustore_verify_purchase(
    body: RuStoreVerifyRequest,
    user: CurrentUser = Depends(get_current_user),
):
    """Production RuStore purchase verification (server-side). Not implemented yet."""
    try:
        result = verify_real_rustore_payment(
            user_id=user.id,
            email=user.email,
            package_id=body.package_id,
            provider_payment_id=body.provider_payment_id,
            purchase_token=body.purchase_token,
        )
    except RealRuStoreVerificationNotImplementedError as exc:
        raise HTTPException(
            status_code=501,
            detail="RuStore payment verification is not implemented yet",
        ) from exc

    return RuStoreVerifyResponse(
        status=result.status,
        package_id=result.package_id,
        added=PaymentAddedBalance(
            paid_image_generations=result.added_paid_image_generations,
            paid_photoshoots=result.added_paid_photoshoots,
        ),
        balance=result.balance,
    )
