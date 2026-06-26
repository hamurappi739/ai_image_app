import 'package:ai_image_generator/services/api_service.dart';
import 'package:ai_image_generator/utils/gallery_image_proxy_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isSupabaseGeneratedImageUrl accepts generated-images public URL', () {
    const url =
        'https://cvzzceastvlbcxsckoqd.supabase.co/storage/v1/object/public/'
        'generated-images/generations/user/test.jpg';

    expect(isSupabaseGeneratedImageUrl(url), isTrue);
  });

  test('isSupabaseGeneratedImageUrl rejects other hosts and paths', () {
    expect(
      isSupabaseGeneratedImageUrl(
        'https://evil.example.com/storage/v1/object/public/'
        'generated-images/a.jpg',
      ),
      isFalse,
    );
    expect(
      isSupabaseGeneratedImageUrl(
        'https://cvzzceastvlbcxsckoqd.supabase.co/storage/v1/object/public/'
        'other-bucket/a.jpg',
      ),
      isFalse,
    );
    expect(
      isSupabaseGeneratedImageUrl('http://cvzzceastvlbcxsckoqd.supabase.co/a.jpg'),
      isFalse,
    );
  });

  test('galleryImageDisplayUrl proxies Supabase generated-images URL', () {
    const original =
        'https://cvzzceastvlbcxsckoqd.supabase.co/storage/v1/object/public/'
        'generated-images/generations/abc/photo.jpg';

    final display = galleryImageDisplayUrl(original);
    final uri = Uri.parse(display);

    expect(uri.path, '/image-proxy');
    expect(uri.queryParameters['url'], original);
    expect(display.startsWith('${ApiService.baseUrl}/image-proxy?url='), isTrue);
  });

  test('galleryImageDisplayUrl leaves mock and non-Supabase URLs unchanged', () {
    const mockUrl = 'https://placehold.co/400x600/png?text=Demo';
    const otherUrl = 'https://cdn.example.com/photo.jpg';

    expect(galleryImageDisplayUrl(mockUrl), mockUrl);
    expect(galleryImageDisplayUrl(otherUrl), otherUrl);
  });
}
