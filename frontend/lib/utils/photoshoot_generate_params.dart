import '../utils/gallery_display_title.dart';

const customPhotoshootStyleId = 'custom_photoshoot';

/// Description field for POST /photoshoots/generate — only custom flow sends user text.
String? photoshootGenerateDescription({
  required String styleId,
  String? userDescription,
}) {
  if (styleId.trim() != customPhotoshootStyleId) {
    return null;
  }
  final trimmed = userDescription?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

/// Local gallery label after catalog template generation (server stores the same).
String templateGalleryDescription(String templateTitle) {
  return '$galleryTemplatePrefix$templateTitle';
}
