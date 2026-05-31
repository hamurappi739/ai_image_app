import 'package:ai_image_generator/models/generated_image_item.dart';

/// One row in the Gallery grid: a single image or a photoshoot group.
class GalleryDisplayItem {
  const GalleryDisplayItem({
    required this.description,
    required this.createdAt,
    required this.imageUrls,
    this.photoshootId,
  });

  final String description;
  final DateTime createdAt;
  final List<String> imageUrls;
  final String? photoshootId;

  bool get isPhotoshootGroup =>
      photoshootId != null && photoshootId!.isNotEmpty && imageUrls.length > 1;
}

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

String galleryImageCountLabel(int count) {
  if (count <= 1) {
    return '';
  }
  final mod10 = count % 10;
  final mod100 = count % 100;
  if (mod10 == 1 && mod100 != 11) {
    return '$count изображение';
  }
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return '$count изображения';
  }
  return '$count изображений';
}
