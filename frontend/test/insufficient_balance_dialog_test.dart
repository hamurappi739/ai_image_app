import 'package:ai_image_generator/models/user_balance.dart';
import 'package:ai_image_generator/widgets/insufficient_balance_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('insufficient images dialog shows title and buy action', (
    WidgetTester tester,
  ) async {
    var openedPacks = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => InsufficientBalanceDialog.showInsufficientImages(
                context,
                onOpenPacks: () => openedPacks = true,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Недостаточно фото'), findsOneWidget);
    expect(find.text('Купить'), findsOneWidget);

    await tester.tap(find.text('Купить'));
    await tester.pumpAndSettle();

    expect(openedPacks, isTrue);
  });

  testWidgets('insufficient photoshoot dialog mentions three images', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () =>
                  InsufficientBalanceDialog.showInsufficientPhotoshoots(
                context,
                onOpenPacks: () {},
                imageCost: UserBalance.defaultPhotoshootImageCost,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
      find.text('Для фотосессии нужно 3 фото'),
      findsOneWidget,
    );
  });

  test('photoshoot availability ignores free generations', () {
    const balance = UserBalance(
      freeGenerationsLimit: 3,
      freeGenerationsUsed: 0,
      freeGenerationsRemaining: 3,
      paidImageGenerations: 2,
      paidPhotoshoots: 0,
      totalAvailableImages: 5,
      photoshootImageCost: 3,
      availablePhotoshootsByImages: 0,
      consumptionEnabled: true,
    );

    expect(balance.isImageGenerationAvailable, isTrue);
    expect(balance.isPhotoshootBalanceAvailable, isFalse);
  });
}
