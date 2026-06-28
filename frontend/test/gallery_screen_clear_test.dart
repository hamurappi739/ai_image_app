import 'package:ai_image_generator/models/generated_image_item.dart';
import 'package:ai_image_generator/screens/gallery_screen.dart';
import 'package:ai_image_generator/widgets/gallery_clear_confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('showGalleryClearConfirmDialog confirms before clearing', (tester) async {
    var confirmed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async {
                    confirmed = await showGalleryClearConfirmDialog(context);
                  },
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(confirmed, isFalse);
    expect(find.text('Очистить галерею?'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Очистить'),
      ),
    );
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
  });

  testWidgets('GalleryScreen clear asks for confirmation before onClearGallery', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    var cleared = false;
    final sampleImage = GeneratedImageItem(
      id: 'img-1',
      description: 'Test photo',
      imageUrl: 'https://example.com/photo.jpg',
      createdAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GalleryScreen(
          images: [sampleImage],
          hiddenImageKeys: const {},
          hiddenPhotoshootIds: const {},
          onHideImage: (_) {},
          onHidePhotoshoot: (_) {},
          onOpenTemplates: () {},
          onOpenPhotoshoots: () {},
          onOpenBuy: () {},
          onClearGallery: () => cleared = true,
          onRetry: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Очистить'));
    await tester.pumpAndSettle();

    expect(cleared, isFalse);
    expect(find.text('Очистить галерею?'), findsOneWidget);

    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(cleared, isFalse);

    await tester.tap(find.text('Очистить'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Очистить'),
      ),
    );
    await tester.pumpAndSettle();

    expect(cleared, isTrue);
  });
}
