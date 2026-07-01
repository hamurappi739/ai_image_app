import 'package:ai_image_generator/models/generated_image_item.dart';
import 'package:ai_image_generator/utils/gallery_display_title.dart';
import 'package:ai_image_generator/utils/gallery_item_key.dart';

export 'package:ai_image_generator/utils/gallery_display_title.dart'
    show galleryPhotoshootStyleTitle, gallerySinglePhotoTitle;

/// One row in the Gallery grid: a single image or a photoshoot group.
class GalleryDisplayItem {
  const GalleryDisplayItem({
    required this.description,
    required this.createdAt,
    required this.imageUrls,
    this.thumbnailUrls,
    this.photoshootId,
    this.hideKey,
  });

  final String description;
  final DateTime createdAt;
  final List<String> imageUrls;
  final List<String>? thumbnailUrls;
  final String? photoshootId;
  final String? hideKey;

  bool get isPhotoshootGroup =>
      photoshootId != null && photoshootId!.isNotEmpty;

  String get displayTitle => isPhotoshootGroup
      ? galleryPhotoshootStyleTitle(description)
      : gallerySinglePhotoTitle(description);

  /// Preview URLs for gallery cards; falls back per frame to [imageUrls].
  List<String> get previewUrls => List<String>.generate(
        imageUrls.length,
        (index) {
          final thumbs = thumbnailUrls;
          if (thumbs != null && index < thumbs.length) {
            final thumb = thumbs[index].trim();
            if (thumb.isNotEmpty) {
              return thumb;
            }
          }
          return imageUrls[index];
        },
        growable: false,
      );
}

String galleryPhotoshootPhotoCountLabel(int count) => '$count фото';

String formatGalleryDisplayDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
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
          thumbnailUrls: item.thumbnailUrl != null
              ? [item.previewUrl]
              : null,
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
    final thumbs = groupItems
        .map((item) => item.previewUrl)
        .toList(growable: false);
    final hasDistinctThumbs = groupItems.any(
      (item) =>
          item.thumbnailUrl != null && item.thumbnailUrl!.trim().isNotEmpty,
    );

    return GalleryDisplayItem(
      description: groupItems.first.description,
      createdAt: newestCreatedAt,
      imageUrls: groupItems.map((item) => item.imageUrl).toList(),
      thumbnailUrls: hasDistinctThumbs ? thumbs : null,
      photoshootId: entry.key,
    );
  });

  final displayItems = [...singles, ...grouped]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return displayItems;
}
