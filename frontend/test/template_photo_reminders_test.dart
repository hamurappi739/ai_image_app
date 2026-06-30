import 'package:ai_image_generator/utils/gallery_download_common.dart';
import 'package:ai_image_generator/utils/template_photo_reminders.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('templatePhotoUploadReminder', () {
    test('returns family reminder', () {
      final text = templatePhotoUploadReminder('family_photo');
      expect(text, isNotNull);
      expect(text!, contains('одну фотографию'));
      expect(text, contains('семьи'));
    });

    test('returns child photo reminder', () {
      final text = templatePhotoUploadReminder('photo_with_child');
      expect(text, isNotNull);
      expect(text!, contains('ребёнок'));
    });

    test('returns null for other templates', () {
      expect(templatePhotoUploadReminder('business_portrait'), isNull);
    });
  });

  group('resolveGalleryDownloadUrl', () {
    test('unwraps image-proxy query parameter', () {
      const original =
          'https://example.supabase.co/storage/v1/object/public/generated-images/a.jpg';
      final proxy =
          'http://10.0.2.2:8000/image-proxy?url=${Uri.encodeComponent(original)}';

      expect(resolveGalleryDownloadUrl(proxy), original);
    });

    test('returns direct url unchanged', () {
      const url = 'https://cdn.example.com/photo.png';
      expect(resolveGalleryDownloadUrl(url), url);
    });
  });

  test('gallery download success message mentions gallery', () {
    expect(galleryDownloadSuccessMessage, contains('галерею'));
  });
}
