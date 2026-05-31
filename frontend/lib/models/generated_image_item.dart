class GeneratedImageItem {
  const GeneratedImageItem({
    this.id,
    required this.description,
    required this.imageUrl,
    required this.createdAt,
    this.photoshootId,
  });

  final String? id;
  final String description;
  final String imageUrl;
  final DateTime createdAt;
  final String? photoshootId;
}
