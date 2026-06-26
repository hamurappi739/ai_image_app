import 'package:ai_image_generator/widgets/gallery_result_image.dart';
import 'package:ai_image_generator/widgets/visual_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('loading placeholder shows slow message when requested', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GalleryImageLoadingPlaceholder(showSlowMessage: true),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Загружаем фото…'), findsOneWidget);
  });

  testWidgets('error placeholder shows readable fallback', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GalleryImageErrorPlaceholder(),
        ),
      ),
    );

    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(find.text('Не удалось загрузить фото'), findsOneWidget);
  });

  testWidgets('empty url uses mock preview instead of network image', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GalleryResultImage(url: ''),
        ),
      ),
    );

    expect(find.byType(Image), findsNothing);
    expect(find.byType(VisualPlaceholder), findsOneWidget);
  });
}
