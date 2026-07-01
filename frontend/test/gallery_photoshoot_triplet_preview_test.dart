import 'package:ai_image_generator/widgets/gallery_photoshoot_triplet_preview.dart';
import 'package:ai_image_generator/widgets/gallery_result_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpThroughThumbnailLoadFailures(WidgetTester tester) async {
  galleryNetworkImageAutoRetryDelays = const [
    Duration(milliseconds: 10),
    Duration(milliseconds: 10),
  ];
  galleryNetworkImageMaxAutoRetries = 2;
  galleryNetworkImageLoadingTimeout = const Duration(seconds: 30);

  await tester.pump();
  await tester.pump();
  for (var i = 0; i < 24; i++) {
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pump();
  }
}

void main() {
  tearDown(() {
    galleryNetworkImageLoadingTimeout = const Duration(seconds: 22);
    galleryNetworkImageSlowLoadHintDelay = const Duration(seconds: 3);
    galleryNetworkImageMaxAutoRetries = 2;
    galleryNetworkImageAutoRetryDelays = const [
      Duration(milliseconds: 800),
      Duration(milliseconds: 1800),
    ];
  });

  testWidgets('photoshoot triplet preview loads all three network images', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 200,
            child: GalleryPhotoshootTripletPreview(
              imageUrls: const [
                'https://example.com/frame-1.jpg',
                'https://example.com/frame-2.jpg',
                'https://example.com/frame-3.jpg',
              ],
              description: 'Фотосессия: Летняя фотосессия',
            ),
          ),
        ),
      ),
    );

    expect(find.byType(GalleryResultImage), findsNWidgets(3));
    expect(find.byType(GalleryDeferredSeriesFrame), findsNothing);
  });

  testWidgets('missing frame url shows local placeholder without breaking others', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 200,
            child: GalleryPhotoshootTripletPreview(
              imageUrls: const [
                'https://example.com/frame-1.jpg',
                '',
                'https://example.com/frame-3.jpg',
              ],
              description: 'Фотосессия: Летняя фотосессия',
            ),
          ),
        ),
      ),
    );

    expect(find.byType(GalleryResultImage), findsNWidgets(2));
    expect(find.byType(GalleryDeferredSeriesFrame), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('photoshoot triplet preview keeps mock series preview for placeholders', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 200,
            child: GalleryPhotoshootTripletPreview(
              imageUrls: [
                'https://placehold.co/400x600/png',
                'https://placehold.co/400x600/png',
                'https://placehold.co/400x600/png',
              ],
              description: 'Фотосессия: Деловой портрет',
            ),
          ),
        ),
      ),
    );

    expect(find.byType(GalleryResultImage), findsNothing);
    expect(find.byType(GalleryPhotoshootSeriesPreview), findsOneWidget);
  });

  testWidgets(
    'failed thumbnails on narrow width use compact fallback without overflow',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: GalleryPhotoshootTripletPreview(
                imageUrls: const [
                  'https://example.com/broken-frame-1.jpg',
                  'https://example.com/broken-frame-2.jpg',
                  'https://example.com/broken-frame-3.jpg',
                ],
                description: 'Фотосессия: Тест',
              ),
            ),
          ),
        ),
      );

      await _pumpThroughThumbnailLoadFailures(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Фото сохранено, но не загрузилось'), findsNothing);
      expect(find.text('Повторить'), findsNothing);
      expect(find.text('Не загрузилось'), findsNWidgets(3));
    },
  );

  testWidgets(
    'failed thumbnails in dark theme have no overflow',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.dark,
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: GalleryPhotoshootTripletPreview(
                imageUrls: const [
                  'https://example.com/broken-frame-1.jpg',
                  'https://example.com/broken-frame-2.jpg',
                  'https://example.com/broken-frame-3.jpg',
                ],
                description: 'Фотосессия: Тест',
              ),
            ),
          ),
        ),
      );

      await _pumpThroughThumbnailLoadFailures(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Не загрузилось'), findsNWidgets(3));
    },
  );
}
