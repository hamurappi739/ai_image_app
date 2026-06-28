import 'package:ai_image_generator/widgets/gallery_photoshoot_triplet_preview.dart';
import 'package:ai_image_generator/widgets/gallery_result_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
}
