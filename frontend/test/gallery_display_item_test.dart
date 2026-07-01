import 'package:ai_image_generator/models/gallery_display_item.dart';
import 'package:ai_image_generator/models/generated_image_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime(2026, 5, 29, 12);

  test('groupGalleryItems uses thumbnail for single card preview', () {
    final item = GeneratedImageItem(
      description: 'Своя идея',
      imageUrl: 'https://cdn.example/full.jpg',
      thumbnailUrl: 'https://cdn.example/thumb.jpg',
      createdAt: createdAt,
    );

    final grouped = groupGalleryItems([item]);

    expect(grouped, hasLength(1));
    expect(grouped.first.imageUrls, ['https://cdn.example/full.jpg']);
    expect(grouped.first.previewUrls, ['https://cdn.example/thumb.jpg']);
  });

  test('groupGalleryItems falls back to image_url without thumbnail', () {
    final item = GeneratedImageItem(
      description: 'Legacy',
      imageUrl: 'https://cdn.example/full.jpg',
      createdAt: createdAt,
    );

    final grouped = groupGalleryItems([item]);

    expect(grouped.first.previewUrls, ['https://cdn.example/full.jpg']);
    expect(grouped.first.thumbnailUrls, isNull);
  });

  test('groupGalleryItems groups photoshoot previews separately from originals', () {
    final items = [
      GeneratedImageItem(
        description: 'Фотосессия: Studio',
        imageUrl: 'https://cdn.example/full-1.jpg',
        thumbnailUrl: 'https://cdn.example/thumb-1.jpg',
        createdAt: createdAt,
        photoshootId: 'ps-1',
      ),
      GeneratedImageItem(
        description: 'Фотосессия: Studio',
        imageUrl: 'https://cdn.example/full-2.jpg',
        thumbnailUrl: 'https://cdn.example/thumb-2.jpg',
        createdAt: createdAt.add(const Duration(seconds: 1)),
        photoshootId: 'ps-1',
      ),
      GeneratedImageItem(
        description: 'Фотосессия: Studio',
        imageUrl: 'https://cdn.example/full-3.jpg',
        thumbnailUrl: 'https://cdn.example/thumb-3.jpg',
        createdAt: createdAt.add(const Duration(seconds: 2)),
        photoshootId: 'ps-1',
      ),
    ];

    final grouped = groupGalleryItems(items);

    expect(grouped, hasLength(1));
    expect(grouped.first.imageUrls, [
      'https://cdn.example/full-1.jpg',
      'https://cdn.example/full-2.jpg',
      'https://cdn.example/full-3.jpg',
    ]);
    expect(grouped.first.previewUrls, [
      'https://cdn.example/thumb-1.jpg',
      'https://cdn.example/thumb-2.jpg',
      'https://cdn.example/thumb-3.jpg',
    ]);
  });
}
