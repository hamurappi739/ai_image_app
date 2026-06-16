"""Payment orchestration: dispatch verification and re-export verification API.

- ``package_catalog`` — server-side package definitions (amounts, image counts).
- ``payment_verification`` — mock (development) and future RuStore verification.
- ``routes/payments.py`` — HTTP endpoints and environment guards.
"""

from __future__ import annotations

from typing import Literal

from app.services.payment_verification import (
    CustomPaymentVerifyResult,
    PaymentVerifyResult,
    RealRuStoreVerificationNotImplementedError,
    mock_verify_custom_amount_purchase,
    mock_verify_rustore_purchase,
    verify_real_rustore_payment,
)

VerificationMode = Literal["mock", "rustore"]

__all__ = [
    "CustomPaymentVerifyResult",
    "PaymentVerifyResult",
    "RealRuStoreVerificationNotImplementedError",
    "VerificationMode",
    "mock_verify_custom_amount_purchase",
    "mock_verify_rustore_purchase",
    "verify_and_credit_package_purchase",
    "verify_real_rustore_payment",
]


def verify_and_credit_package_purchase(
    *,
    user_id: str,
    email: str | None,
    package_id: str,
    provider_payment_id: str,
    verification_mode: VerificationMode = "mock",
    purchase_token: str | None = None,
) -> PaymentVerifyResult:
    """Route a package purchase to the correct verification backend."""
    if verification_mode == "mock":
        return mock_verify_rustore_purchase(
            user_id=user_id,
            email=email,
            package_id=package_id,
            provider_payment_id=provider_payment_id,
        )
    if verification_mode == "rustore":
        return verify_real_rustore_payment(
            user_id=user_id,
            email=email,
            package_id=package_id,
            provider_payment_id=provider_payment_id,
            purchase_token=purchase_token,
        )
    raise ValueError(f"Unknown verification_mode: {verification_mode!r}")
