import '../models/payment_result.dart';
import 'api_service.dart';

/// Which backend path [PaymentService] uses for purchases.
enum PaymentChannel {
  /// Development demo: backend mock photo-pack (no RuStore SDK, no real charges).
  demo,

  /// Future: RuStore Pay SDK purchase + backend ``/payments/rustore/verify``.
  rustore,
}

/// Orchestrates balance top-up for the UI.
///
/// UI screens (e.g. «Купить») should call [purchasePackage] only — not mock endpoints
/// or RuStore SDK details directly.
///
/// Current flow (demo):
/// 1. [purchasePackage] → backend ``/payments/mock/photo-pack``.
/// 2. Backend credits balance and returns updated ``balance``.
///
/// Future RuStore Pay SDK flow (not implemented):
/// 1. RuStore Pay SDK shows purchase UI on Android.
/// 2. App receives purchase id / token from RuStore.
/// 3. [purchasePackage] → [ApiService.verifyRuStorePayment] → backend verify.
/// 4. Backend verifies with RuStore server-side, credits balance, records transaction.
/// 5. UI updates from verification response.
///
/// Do not use deprecated RuStore BillingClient SDK for new integration.
class PaymentService {
  PaymentService({
    required ApiService apiService,
    PaymentChannel channel = PaymentChannel.demo,
  })  : _apiService = apiService,
        _channel = channel;

  final ApiService _apiService;
  final PaymentChannel _channel;

  /// Primary entry point for package purchases from UI.
  Future<PaymentResult> purchasePackage(String packageId) {
    switch (_channel) {
      case PaymentChannel.demo:
        return _purchasePackageDemo(packageId);
      case PaymentChannel.rustore:
        return purchasePackageWithRuStore(packageId);
    }
  }

  /// Development demo: fixed package top-up via backend mock photo-pack.
  ///
  /// Prefer [purchasePackage] from UI. This method remains for tests and migration.
  Future<PaymentResult> purchasePackageDemo(String packageId) {
    return _purchasePackageDemo(packageId);
  }

  Future<PaymentResult> _purchasePackageDemo(String packageId) async {
    try {
      final response = await _apiService.mockPurchasePhotoPack(
        packageId: packageId,
      );
      return PaymentResult(
        status: PaymentResultStatus.verified,
        packageId: response.packageId,
        addedImageGenerations: response.photosAdded,
        addedPhotoshoots: 0,
        balance: response.balance,
      );
    } on MockPaymentUnavailableException {
      return _failedResult(
        packageId: packageId,
        reason: PaymentFailureReason.unavailable,
      );
    } on MockPaymentServiceUnavailableException {
      return _failedResult(
        packageId: packageId,
        reason: PaymentFailureReason.serviceUnavailable,
      );
    } catch (_) {
      return _failedResult(
        packageId: packageId,
        reason: PaymentFailureReason.generic,
      );
    }
  }

  /// Development demo: custom amount top-up via backend mock-verify-custom.
  Future<PaymentResult> purchaseCustomAmountDemo({
    required int amountRub,
    required int paidPhotoshoots,
  }) async {
    const packageId = 'custom_amount';
    final providerPaymentId =
        'dev-custom-${DateTime.now().millisecondsSinceEpoch}';

    try {
      final response = await _apiService.mockVerifyCustomAmountPayment(
        amountRub: amountRub,
        paidPhotoshoots: paidPhotoshoots,
        providerPaymentId: providerPaymentId,
      );
      return _mapCustomAmountResponse(response);
    } on MockPaymentUnavailableException {
      return _failedResult(
        packageId: packageId,
        reason: PaymentFailureReason.unavailable,
      );
    } on MockPaymentServiceUnavailableException {
      return _failedResult(
        packageId: packageId,
        reason: PaymentFailureReason.serviceUnavailable,
      );
    } catch (_) {
      return _failedResult(
        packageId: packageId,
        reason: PaymentFailureReason.generic,
      );
    }
  }

  /// Future RuStore Pay SDK: purchase UI on device, then backend verification.
  Future<PaymentResult> purchasePackageWithRuStore(String packageId) async {
    // TODO(rustore): invoke RuStore Pay SDK, obtain provider_payment_id / token,
    // then call _apiService.verifyRuStorePayment(...).
    return _failedResult(
      packageId: packageId,
      reason: PaymentFailureReason.unavailable,
    );
  }

  /// Future RuStore Pay SDK: custom amount via RuStore, then backend verification.
  Future<PaymentResult> purchaseCustomAmountWithRuStore({
    required int amountRub,
    required int paidPhotoshoots,
  }) {
    throw UnimplementedError('RuStore Pay SDK is not connected');
  }

  PaymentResult _mapCustomAmountResponse(
    MockVerifyCustomAmountPaymentResponse response,
  ) {
    return PaymentResult(
      status: response.status == 'already_processed'
          ? PaymentResultStatus.alreadyProcessed
          : PaymentResultStatus.verified,
      packageId: response.packageId,
      amountRub: response.amountRub,
      addedImageGenerations: response.added.paidImageGenerations,
      addedPhotoshoots: response.added.paidPhotoshoots,
      unusedRub: response.unusedRub,
      balance: response.balance,
    );
  }

  PaymentResult _failedResult({
    required String packageId,
    required PaymentFailureReason reason,
  }) {
    return PaymentResult(
      status: PaymentResultStatus.failed,
      packageId: packageId,
      addedImageGenerations: 0,
      addedPhotoshoots: 0,
      failureReason: reason,
    );
  }
}
