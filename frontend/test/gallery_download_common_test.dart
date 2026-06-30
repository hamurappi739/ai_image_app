import 'package:ai_image_generator/utils/gallery_download_common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildGalleryDownloadFileName uses ai-image timestamp format', () {
    expect(
      buildGalleryDownloadFileName(
        extension: 'jpg',
        now: DateTime(2026, 5, 29, 17, 46, 15),
      ),
      'ai-image-20260529-174615.jpg',
    );
  });

  test('resolveGalleryDownloadExtension prefers URL extension', () {
    expect(
      resolveGalleryDownloadExtension(
        imageUrl:
            'https://example.supabase.co/storage/v1/object/public/generated-images/a.png',
        contentType: 'image/jpeg',
      ),
      'png',
    );
  });

  test('resolveGalleryDownloadExtension falls back to content type', () {
    expect(
      resolveGalleryDownloadExtension(
        imageUrl: 'https://example.supabase.co/storage/v1/object/public/x',
        contentType: 'image/webp',
      ),
      'webp',
    );
  });

  test('isGalleryDownloadSaveSuccess reads plugin result map', () {
    expect(isGalleryDownloadSaveSuccess({'isSuccess': true}), isTrue);
    expect(isGalleryDownloadSaveSuccess({'isSuccess': false}), isFalse);
    expect(isGalleryDownloadSaveSuccess(null), isFalse);
  });

  test('resolveGalleryDownloadUrl unwraps image-proxy', () {
    expect(
      resolveGalleryDownloadUrl(
        'https://api.example.com/image-proxy?url='
        'https%3A%2F%2Fstorage.example.com%2Fphoto.jpg',
      ),
      'https://storage.example.com/photo.jpg',
    );
  });

  test('resolveGalleryDownloadUrl returns direct url unchanged', () {
    const url = 'https://storage.example.com/photo.png';
    expect(resolveGalleryDownloadUrl(url), url);
  });

  test('isGalleryDownloadSaveSuccess accepts filePath map', () {
    expect(
      isGalleryDownloadSaveSuccess({'filePath': '/storage/emulated/0/x.jpg'}),
      isTrue,
    );
  });
}
