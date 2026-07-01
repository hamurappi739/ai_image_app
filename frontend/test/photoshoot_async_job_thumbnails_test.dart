import 'package:ai_image_generator/models/gallery_display_item.dart';
import 'package:ai_image_generator/models/generated_image_item.dart';
import 'package:ai_image_generator/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';

List<GeneratedImageItem> galleryItemsFromAsyncPhotoshootResult(
  PhotoshootGenerateResponse result,
) {
  final description = 'Фотосессия: ${result.styleTitle}';
  final createdAt = DateTime(2026, 7, 1, 15, 32);
  final photoshootId = result.photoshootId.trim();
  final items = <GeneratedImageItem>[];
  for (var i = 0; i < result.imageUrls.length; i++) {
    final thumb = i < result.thumbnailUrls.length
        ? result.thumbnailUrls[i]
        : null;
    items.add(
      GeneratedImageItem(
        description: description,
        imageUrl: result.imageUrls[i],
        thumbnailUrl: thumb,
        createdAt: createdAt,
        photoshootId: photoshootId.isEmpty ? null : photoshootId,
      ),
    );
  }
  return items;
}

void main() {
  test('async job status response parses thumbnail_urls', () {
    final status = PhotoshootJobStatusResponse.fromJson({
      'status': 'success',
      'message': 'Photoshoot ready',
      'frames': [
        {'index': 0, 'status': 'done'},
        {'index': 1, 'status': 'done'},
        {'index': 2, 'status': 'done'},
      ],
      'images': [
        'https://cdn.example/generated-1.jpg',
        'https://cdn.example/generated-2.jpg',
        'https://cdn.example/generated-3.jpg',
      ],
      'thumbnail_urls': [
        'https://cdn.example/thumb-1.jpg',
        'https://cdn.example/thumb-2.jpg',
        'https://cdn.example/thumb-3.jpg',
      ],
      'photoshoot_id': 'ps-async',
      'output_count': 3,
      'style_id': 'studio_portrait',
      'style_title': 'Studio Portrait',
    });

    expect(status.thumbnailUrls, hasLength(3));
    expect(status.thumbnailUrls.first, contains('thumb-1'));

    final result = status.toGenerateResponse(
      fallbackStyleId: 'studio_portrait',
      fallbackStyleTitle: 'Studio Portrait',
    );
    expect(result.thumbnailUrls, status.thumbnailUrls);
    expect(result.imageUrls, status.images);
  });

  test('async photoshoot success uses thumbs for preview and full for viewer', () {
    final status = PhotoshootJobStatusResponse.fromJson({
      'status': 'success',
      'message': 'Photoshoot ready',
      'frames': const [],
      'images': [
        'https://cdn.example/generated-1.jpg',
        'https://cdn.example/generated-2.jpg',
        'https://cdn.example/generated-3.jpg',
      ],
      'thumbnail_urls': [
        'https://cdn.example/thumb-1.jpg',
        'https://cdn.example/thumb-2.jpg',
        'https://cdn.example/thumb-3.jpg',
      ],
      'photoshoot_id': 'ps-async',
      'output_count': 3,
      'style_id': 'studio_portrait',
      'style_title': 'Studio Portrait',
    });

    final result = status.toGenerateResponse(
      fallbackStyleId: 'studio_portrait',
      fallbackStyleTitle: 'Studio Portrait',
    );
    final galleryItems = galleryItemsFromAsyncPhotoshootResult(result);
    final display = groupGalleryItems(galleryItems).single;

    expect(display.previewUrls, [
      'https://cdn.example/thumb-1.jpg',
      'https://cdn.example/thumb-2.jpg',
      'https://cdn.example/thumb-3.jpg',
    ]);
    expect(display.imageUrls, [
      'https://cdn.example/generated-1.jpg',
      'https://cdn.example/generated-2.jpg',
      'https://cdn.example/generated-3.jpg',
    ]);
    expect(display.hasDedicatedThumbnails, isTrue);
  });
}
