import '../models/payment_result.dart';
import 'api_service.dart';

/// Orchestrates balance top-up: development mock verification today,
/// RuStore Pay SDK + backend verification in the future.
///
/// Future RuStore Pay SDK flow (not implemented):
/// 1. Call RuStore Pay SDK from Android (purchase UI / payment).
/// 2. Receive purchase / payment id from RuStore.
/// 3. Send purchase id to backend verification endpoint (server-side only).
/// 4. Backend credits balance after verification.
/// 5. Frontend updates UI from verification response or refreshes GET /balance.
///
/// Do not use deprecated RuStore BillingClient SDK for new integration.
class PaymentService {
  PaymentService({required ApiService apiService}) : _apiService = apiService;

  final ApiService _apiService;

  /// Development demo: fixed package top-up via backend mock-verify.
  Future<PaymentResult> purchasePackageDemo(String packageId) async {
    final providerPaymentId =
        'dev-package-$packageId-${DateTime.now().millisecondsSinceEpoch}';

    try {
      final response = await _apiService.mockVerifyRuStorePayment(
        packageId: packageId,
        providerPaymentId: providerPaymentId,
      );
      return _mapPackageResponse(response);
    } on MockPaymentUnavailableException {
      return _failedResult(packageId: packageId, reason: PaymentFailureReason.unavailable);
    } on MockPaymentServiceUnavailableException {
      return _failedResult(
        packageId: packageId,
        reason: PaymentFailureReason.serviceUnavailable,
      );
    } catch (_) {
      return _failedResult(packageId: packageId, reason: PaymentFailureReason.generic);
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
      return _failedResult(packageId: packageId, reason: PaymentFailureReason.unavailable);
    } on MockPaymentServiceUnavailableException {
      return _failedResult(
        packageId: packageId,
        reason: PaymentFailureReason.serviceUnavailable,
      );
    } catch (_) {
      return _failedResult(packageId: packageId, reason: PaymentFailureReason.generic);
    }
  }

  // Future RuStore Pay SDK: steps 1–3 above, then map backend response to PaymentResult.
  Future<PaymentResult> purchasePackageWithRuStore(String packageId) {
    throw UnimplementedError('RuStore Pay SDK is not connected');
  }

  // Future RuStore Pay SDK: custom amount via RuStore, then backend verification.
  Future<PaymentResult> purchaseCustomAmountWithRuStore({
    required int amountRub,
    required int paidPhotoshoots,
  }) {
    throw UnimplementedError('RuStore Pay SDK is not connected');
  }

  PaymentResult _mapPackageResponse(MockVerifyRuStorePaymentResponse response) {
    return PaymentResult(
      status: response.status == 'already_processed'
          ? PaymentResultStatus.alreadyProcessed
          : PaymentResultStatus.verified,
      packageId: response.packageId,
      addedImageGenerations: response.added.paidImageGenerations,
      addedPhotoshoots: response.added.paidPhotoshoots,
      balance: response.balance,
    );
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
