import 'package:ai_image_generator/widgets/preview_asset_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('previewAssetDecodeCachePx caps at 900px', () {
    expect(previewAssetDecodeCachePx(200, 2), 400);
    expect(previewAssetDecodeCachePx(600, 3), 900);
    expect(previewAssetDecodeCachePx(800, 3), 900);
  });

  testWidgets('asset stays visible when network preview fails', (
    WidgetTester tester,
  ) async {
    const placeholderKey = Key('preview-placeholder');
    const assetPath = 'assets/previews/templates/business_portrait.jpg';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            height: 240,
            child: PreviewAssetImage(
              assetPath: assetPath,
              networkUrl: 'https://example.com/missing-catalog-preview.jpg',
              placeholder: SizedBox(key: placeholderKey),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(placeholderKey), findsNothing);
    expect(find.byType(Image), findsWidgets);
  });

  testWidgets('asset-only preview does not show placeholder', (
    WidgetTester tester,
  ) async {
    const placeholderKey = Key('preview-placeholder');

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            height: 240,
            child: PreviewAssetImage(
              assetPath: 'assets/previews/templates/business_portrait.jpg',
              placeholder: SizedBox(key: placeholderKey),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byKey(placeholderKey), findsNothing);
    expect(find.byType(Image), findsOneWidget);
  });
}
