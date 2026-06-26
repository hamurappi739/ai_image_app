import 'package:ai_image_generator/widgets/gallery_result_image.dart';
import 'package:ai_image_generator/widgets/visual_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    galleryNetworkImageLoadingTimeout = const Duration(seconds: 12);
    galleryNetworkImageSlowLoadHintDelay = const Duration(seconds: 3);
  });

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

  testWidgets('error fallback shows readable message and retry button', (
    WidgetTester tester,
  ) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GalleryImageLoadFailureFallback(
            compact: true,
            isTimeout: false,
            onRetryPressed: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    expect(find.text('Не удалось загрузить фото'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);

    await tester.tap(find.text('Повторить'));
    await tester.pump();
    expect(retried, isTrue);
  });

  testWidgets('timeout fallback shows saved message and open button', (
    WidgetTester tester,
  ) async {
    var opened = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GalleryImageLoadFailureFallback(
            compact: true,
            isTimeout: true,
            onOpenPressed: () => opened = true,
            onRetryPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Фото сохранено, но не загрузилось'), findsOneWidget);
    expect(find.text('Открыть'), findsOneWidget);

    await tester.tap(find.text('Открыть'));
    await tester.pump();
    expect(opened, isTrue);
  });

  testWidgets('legacy error placeholder delegates to error fallback', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GalleryImageErrorPlaceholder(compact: true),
        ),
      ),
    );

    expect(find.text('Не удалось загрузить фото'), findsOneWidget);
  });

  testWidgets('network image errorBuilder shows error fallback', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 240,
            child: GalleryResultImage(
              url: 'https://example.com/broken-gallery-image.jpg',
              compact: true,
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Не удалось загрузить фото'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
  });

  test('galleryImageUrlWithRetry appends cache-busting query param', () {
    expect(
      galleryImageUrlWithRetry('https://example.com/a.jpg', 0),
      'https://example.com/a.jpg',
    );
    expect(
      galleryImageUrlWithRetry('https://example.com/a.jpg', 2),
      'https://example.com/a.jpg?retry=2',
    );
    expect(
      galleryImageUrlWithRetry('https://example.com/a.jpg?token=abc', 1),
      'https://example.com/a.jpg?token=abc&retry=1',
    );
  });

  test('retry generation increments cache-busting query param', () {
    var generation = 0;
    final urls = <String>[];
    for (var i = 0; i < 3; i++) {
      generation = i;
      urls.add(galleryImageUrlWithRetry('https://cdn.example/photo.jpg', generation));
    }

    expect(urls[0], 'https://cdn.example/photo.jpg');
    expect(urls[1], contains('retry=1'));
    expect(urls[2], contains('retry=2'));
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

  testWidgets('mock placeholder url uses VisualPlaceholder not Image.network', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GalleryResultImage(
            url: 'https://placehold.co/400x600/png?text=Demo',
          ),
        ),
      ),
    );

    expect(find.byType(Image), findsNothing);
    expect(find.byType(VisualPlaceholder), findsOneWidget);
  });
}
