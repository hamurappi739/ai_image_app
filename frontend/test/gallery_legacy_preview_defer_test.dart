import 'package:ai_image_generator/models/gallery_display_item.dart';
import 'package:ai_image_generator/models/generated_image_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legacy gallery rows defer full preview after auto-load limit', () {
    final createdAt = DateTime(2026, 5, 29);
    final items = List<GeneratedImageItem>.generate(
      8,
      (index) => GeneratedImageItem(
        description: 'Legacy $index',
        imageUrl: 'https://example.com/full-$index.jpg',
        createdAt: createdAt.add(Duration(minutes: index)),
      ),
    );

    final grouped = groupGalleryItems(items);
    expect(grouped.every((item) => !item.hasDedicatedThumbnails), isTrue);

    expect(shouldDeferLegacyGalleryPreview(grouped[0], 0), isFalse);
    expect(shouldDeferLegacyGalleryPreview(grouped[5], 5), isTrue);
  });
}
