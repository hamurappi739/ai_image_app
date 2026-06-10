import 'package:ai_image_generator/models/generated_image_item.dart';
import 'package:ai_image_generator/utils/gallery_item_key.dart';

/// One row in the Gallery grid: a single image or a photoshoot group.
class GalleryDisplayItem {
  const GalleryDisplayItem({
    required this.description,
    required this.createdAt,
    required this.imageUrls,
    this.photoshootId,
    this.hideKey,
  });

  final String description;
  final DateTime createdAt;
  final List<String> imageUrls;
  final String? photoshootId;
  final String? hideKey;

  bool get isPhotoshootGroup =>
      photoshootId != null && photoshootId!.isNotEmpty;
}

String? galleryPhotoshootStyleTitle(String description) {
  const prefix = 'Фотосессия: ';
  if (description.startsWith(prefix)) {
    final title = description.substring(prefix.length).trim();
    return title.isEmpty ? null : title;
  }
  return null;
}

String galleryPhotoshootPhotoCountLabel(int count) => '$count фото';

List<GalleryDisplayItem> groupGalleryItems(List<GeneratedImageItem> items) {
  if (items.isEmpty) {
    return const [];
  }

  final singles = <GalleryDisplayItem>[];
  final groups = <String, List<GeneratedImageItem>>{};

  for (final item in items) {
    final photoshootId = item.photoshootId?.trim();
    if (photoshootId == null || photoshootId.isEmpty) {
      singles.add(
        GalleryDisplayItem(
          description: item.description,
          createdAt: item.createdAt,
          imageUrls: [item.imageUrl],
          hideKey: galleryImageHideKey(item),
        ),
      );
      continue;
    }
    groups.putIfAbsent(photoshootId, () => []).add(item);
  }

  final grouped = groups.entries.map((entry) {
    final groupItems = List<GeneratedImageItem>.from(entry.value)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final newestCreatedAt = groupItems
        .map((item) => item.createdAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    return GalleryDisplayItem(
      description: groupItems.first.description,
      createdAt: newestCreatedAt,
      imageUrls: groupItems.map((item) => item.imageUrl).toList(),
      photoshootId: entry.key,
    );
  });

  final displayItems = [...singles, ...grouped]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return displayItems;
}
