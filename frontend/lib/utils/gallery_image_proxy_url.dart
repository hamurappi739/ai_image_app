import '../services/api_service.dart';

/// Public Supabase Storage path prefix for persisted gallery images.
const kSupabaseGeneratedImagesPathPrefix =
    '/storage/v1/object/public/generated-images/';

/// Fallback project host when `SUPABASE_URL` is not passed via `--dart-define`.
const kDefaultSupabaseProjectHost = 'cvzzceastvlbcxsckoqd.supabase.co';

const _supabaseUrlFromEnvironment = String.fromEnvironment('SUPABASE_URL');

String? _configuredSupabaseHost() {
  final trimmed = _supabaseUrlFromEnvironment.trim();
  if (trimmed.isEmpty) return null;
  return Uri.tryParse(trimmed)?.host.toLowerCase();
}

/// True when [url] points at our Supabase public `generated-images` bucket.
bool isSupabaseGeneratedImageUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || uri.scheme != 'https') return false;

  final host = uri.host.toLowerCase();
  final allowedHost = _configuredSupabaseHost() ?? kDefaultSupabaseProjectHost;
  if (host != allowedHost) return false;

  return uri.path.startsWith(kSupabaseGeneratedImagesPathPrefix);
}

/// Display URL for gallery [Image.network] — proxied for Supabase generated images.
String galleryImageDisplayUrl(String originalUrl) {
  final trimmed = originalUrl.trim();
  if (!isSupabaseGeneratedImageUrl(trimmed)) return trimmed;

  return Uri.parse('${ApiService.baseUrl}/image-proxy')
      .replace(queryParameters: {'url': trimmed})
      .toString();
}
