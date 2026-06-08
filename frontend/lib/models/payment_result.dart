import 'user_balance.dart';

enum PaymentResultStatus {
  verified,
  alreadyProcessed,
  failed,
}

enum PaymentFailureReason {
  unavailable,
  serviceUnavailable,
  generic,
}

class PaymentResult {
  const PaymentResult({
    required this.status,
    required this.packageId,
    required this.addedImageGenerations,
    required this.addedPhotoshoots,
    this.amountRub,
    this.unusedRub,
    this.balance,
    this.failureReason,
  });

  final PaymentResultStatus status;
  final String packageId;
  final int? amountRub;
  final int addedImageGenerations;
  final int addedPhotoshoots;
  final int? unusedRub;
  final UserBalance? balance;
  final PaymentFailureReason? failureReason;

  bool get isVerified => status == PaymentResultStatus.verified;
  bool get isAlreadyProcessed => status == PaymentResultStatus.alreadyProcessed;
  bool get isFailed => status == PaymentResultStatus.failed;
}
