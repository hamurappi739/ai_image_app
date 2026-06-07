import 'package:ai_image_generator/models/generated_image_item.dart';

/// Stable local key for hiding a single gallery image (not a photoshoot group).
String galleryImageHideKey(GeneratedImageItem item) {
  final id = item.id?.trim();
  if (id != null && id.isNotEmpty) {
    return 'id:$id';
  }
  return 'url:${item.imageUrl}';
}

List<GeneratedImageItem> filterVisibleGalleryImages(
  List<GeneratedImageItem> items, {
  required Set<String> hiddenImageKeys,
  required Set<String> hiddenPhotoshootIds,
}) {
  return items.where((item) {
    final photoshootId = item.photoshootId?.trim();
    if (photoshootId != null && photoshootId.isNotEmpty) {
      return !hiddenPhotoshootIds.contains(photoshootId);
    }
    return !hiddenImageKeys.contains(galleryImageHideKey(item));
  }).toList();
}
