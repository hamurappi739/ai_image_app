class GeneratedImageItem {
  const GeneratedImageItem({
    this.id,
    required this.description,
    required this.imageUrl,
    required this.createdAt,
    this.photoshootId,
    this.thumbnailUrl,
  });

  final String? id;
  final String description;
  final String imageUrl;
  final DateTime createdAt;
  final String? photoshootId;
  final String? thumbnailUrl;

  /// URL for gallery card previews; falls back to [imageUrl].
  String get previewUrl {
    final thumb = thumbnailUrl?.trim();
    if (thumb != null && thumb.isNotEmpty) {
      return thumb;
    }
    return imageUrl;
  }
}
