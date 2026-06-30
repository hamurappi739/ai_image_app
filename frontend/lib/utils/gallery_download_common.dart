/// Shared helpers for gallery image download across platforms.
library;

const galleryDownloadSuccessMessage = 'Фото сохранено в галерею';
const galleryDownloadFailureMessage = 'Не удалось сохранить фото';

/// Resolves a direct image URL for download (unwraps backend image-proxy if needed).
String resolveGalleryDownloadUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return trimmed;

  final uri = Uri.tryParse(trimmed);
  if (uri == null) return trimmed;

  final path = uri.path;
  if (path.endsWith('/image-proxy') || path.endsWith('image-proxy')) {
    final original = uri.queryParameters['url']?.trim();
    if (original != null && original.isNotEmpty) {
      return original;
    }
  }

  return trimmed;
}

String buildGalleryDownloadFileName({
  required String extension,
  DateTime? now,
}) {
  final timestamp = now ?? DateTime.now();
  final year = timestamp.year.toString().padLeft(4, '0');
  final month = timestamp.month.toString().padLeft(2, '0');
  final day = timestamp.day.toString().padLeft(2, '0');
  final hour = timestamp.hour.toString().padLeft(2, '0');
  final minute = timestamp.minute.toString().padLeft(2, '0');
  final second = timestamp.second.toString().padLeft(2, '0');
  final normalizedExtension = normalizeGalleryDownloadExtension(extension);
  return 'ai-image-$year$month$day-$hour$minute$second.$normalizedExtension';
}

String normalizeGalleryDownloadExtension(String extension) {
  final trimmed = extension.trim().toLowerCase().replaceAll('.', '');
  switch (trimmed) {
    case 'jpeg':
      return 'jpg';
    case 'jpg':
    case 'png':
    case 'webp':
      return trimmed;
    default:
      return 'jpg';
  }
}

String resolveGalleryDownloadExtension({
  required String imageUrl,
  String? contentType,
}) {
  final uri = Uri.tryParse(imageUrl);
  final path = uri?.path.toLowerCase() ?? '';
  if (path.endsWith('.png')) return 'png';
  if (path.endsWith('.webp')) return 'webp';
  if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'jpg';

  final normalizedType = (contentType ?? '').split(';').first.trim().toLowerCase();
  if (normalizedType == 'image/png') return 'png';
  if (normalizedType == 'image/webp') return 'webp';
  if (normalizedType == 'image/jpeg') return 'jpg';

  return 'jpg';
}

bool isGalleryDownloadSaveSuccess(Object? result) {
  if (result is Map) {
    final success = result['isSuccess'];
    if (success is bool) return success;
    final filePath = result['filePath'];
    if (filePath is String && filePath.trim().isNotEmpty) return true;
  }
  if (result is String && result.trim().isNotEmpty) return true;
  return false;
}
