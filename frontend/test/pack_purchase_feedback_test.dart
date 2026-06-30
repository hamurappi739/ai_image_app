import 'package:ai_image_generator/models/payment_result.dart';
import 'package:ai_image_generator/models/user_balance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pack purchase success shows snackbar and updates balance', (
    WidgetTester tester,
  ) async {
    UserBalance? updatedBalance;

    await tester.pumpWidget(
      MaterialApp(
        home: _PackPurchaseHarness(
          onBalanceUpdated: (balance) => updatedBalance = balance,
        ),
      ),
    );

    await tester.tap(find.text('buy'));
    await tester.pumpAndSettle();

    expect(updatedBalance?.paidImageGenerations, 20);
    expect(find.text('Пакет добавлен'), findsOneWidget);
  });

  testWidgets('pack purchase unavailable shows snackbar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: _PackPurchaseHarness(unavailable: true),
      ),
    );

    await tester.tap(find.text('buy'));
    await tester.pumpAndSettle();

    expect(find.text('Покупка временно недоступна'), findsOneWidget);
  });
}

class _PackPurchaseHarness extends StatefulWidget {
  const _PackPurchaseHarness({
    this.onBalanceUpdated,
    this.unavailable = false,
  });

  final ValueChanged<UserBalance>? onBalanceUpdated;
  final bool unavailable;

  @override
  State<_PackPurchaseHarness> createState() => _PackPurchaseHarnessState();
}

class _PackPurchaseHarnessState extends State<_PackPurchaseHarness> {
  Future<void> _presentPaymentResult(PaymentResult result) async {
    if (result.isFailed) {
      if (result.failureReason == PaymentFailureReason.unavailable) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Покупка временно недоступна')),
        );
      }
      return;
    }

    if (result.balance != null) {
      widget.onBalanceUpdated?.call(result.balance!);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Пакет добавлен')),
    );
  }

  Future<void> _buy() async {
    if (widget.unavailable) {
      await _presentPaymentResult(
        const PaymentResult(
          status: PaymentResultStatus.failed,
          packageId: 'package_499_20_images',
          addedImageGenerations: 0,
          addedPhotoshoots: 0,
          failureReason: PaymentFailureReason.unavailable,
        ),
      );
      return;
    }

    await _presentPaymentResult(
      PaymentResult(
        status: PaymentResultStatus.verified,
        packageId: 'package_499_20_images',
        addedImageGenerations: 20,
        addedPhotoshoots: 0,
        balance: const UserBalance(
          freeGenerationsLimit: 3,
          freeGenerationsUsed: 0,
          freeGenerationsRemaining: 3,
          paidImageGenerations: 20,
          paidPhotoshoots: 0,
          totalAvailableImages: 23,
          photoshootImageCost: 3,
          availablePhotoshootsByImages: 6,
          consumptionEnabled: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ElevatedButton(
        onPressed: _buy,
        child: const Text('buy'),
      ),
    );
  }
}
