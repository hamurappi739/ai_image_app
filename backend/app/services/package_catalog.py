"""Backend-side package catalog — amounts are defined only on the server."""

from __future__ import annotations

from dataclasses import dataclass

from fastapi import HTTPException

RUSTORE_PROVIDER = "rustore"
CUSTOM_AMOUNT_PACKAGE_ID = "custom_amount"
IMAGE_UNIT_RUB = 10
PHOTOSHOOT_UNIT_RUB = 100
CUSTOM_AMOUNT_MIN_RUB = 10
CUSTOM_AMOUNT_MAX_RUB = 100_000

# Current UI offerings (1/3/9/20/50 images). Legacy package ids remain for old transactions.
ACTIVE_IMAGE_PACKAGE_IDS: tuple[str, ...] = (
    "package_39_1_image",
    "package_99_3_images",
    "package_249_9_images",
    "package_499_20_images",
    "package_999_50_images",
)


@dataclass(frozen=True, slots=True)
class PaymentPackage:
    id: str
    amount_rub: int
    paid_image_generations: int
    paid_photoshoots: int


PAYMENT_PACKAGES: dict[str, PaymentPackage] = {
    "package_39_1_image": PaymentPackage(
        id="package_39_1_image",
        amount_rub=39,
        paid_image_generations=1,
        paid_photoshoots=0,
    ),
    "package_99_3_images": PaymentPackage(
        id="package_99_3_images",
        amount_rub=99,
        paid_image_generations=3,
        paid_photoshoots=0,
    ),
    "package_249_9_images": PaymentPackage(
        id="package_249_9_images",
        amount_rub=249,
        paid_image_generations=9,
        paid_photoshoots=0,
    ),
    "package_499_20_images": PaymentPackage(
        id="package_499_20_images",
        amount_rub=499,
        paid_image_generations=20,
        paid_photoshoots=0,
    ),
    "package_999_50_images": PaymentPackage(
        id="package_999_50_images",
        amount_rub=999,
        paid_image_generations=50,
        paid_photoshoots=0,
    ),
    # Legacy development packages (UI no longer offers these).
    "package_199_mix": PaymentPackage(
        id="package_199_mix",
        amount_rub=199,
        paid_image_generations=9,
        paid_photoshoots=1,
    ),
    "package_499_mix": PaymentPackage(
        id="package_499_mix",
        amount_rub=499,
        paid_image_generations=19,
        paid_photoshoots=3,
    ),
    "package_999_mix": PaymentPackage(
        id="package_999_mix",
        amount_rub=999,
        paid_image_generations=19,
        paid_photoshoots=8,
    ),
    "package_199_images": PaymentPackage(
        id="package_199_images",
        amount_rub=199,
        paid_image_generations=19,
        paid_photoshoots=0,
    ),
    "package_499_images": PaymentPackage(
        id="package_499_images",
        amount_rub=499,
        paid_image_generations=49,
        paid_photoshoots=0,
    ),
    "package_999_images": PaymentPackage(
        id="package_999_images",
        amount_rub=999,
        paid_image_generations=99,
        paid_photoshoots=0,
    ),
}


def get_payment_package(package_id: str) -> PaymentPackage:
    normalized = package_id.strip()
    package = PAYMENT_PACKAGES.get(normalized)
    if package is None:
        raise HTTPException(status_code=400, detail="Unknown package_id")
    return package


def list_active_image_packages() -> list[PaymentPackage]:
    """Packages offered in the current «Купить» UI (server source of truth)."""
    return [PAYMENT_PACKAGES[package_id] for package_id in ACTIVE_IMAGE_PACKAGE_IDS]
