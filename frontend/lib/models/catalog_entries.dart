class CatalogTemplateEntry {
  const CatalogTemplateEntry({
    required this.id,
    required this.title,
    required this.category,
    required this.shortDescription,
    required this.prompt,
    required this.previewAsset,
    required this.priceImages,
    required this.isActive,
    required this.sortOrder,
    this.previewUrl,
  });

  final String id;
  final String title;
  final String category;
  final String shortDescription;
  final String prompt;
  final String previewAsset;
  final String? previewUrl;
  final int priceImages;
  final bool isActive;
  final int sortOrder;

  factory CatalogTemplateEntry.fromJson(Map<String, dynamic> json) {
    final previewUrl = json['previewUrl'];
    return CatalogTemplateEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      shortDescription: json['shortDescription'] as String,
      prompt: json['prompt'] as String,
      previewAsset: json['previewAsset'] as String,
      previewUrl: previewUrl is String && previewUrl.trim().isNotEmpty
          ? previewUrl.trim()
          : null,
      priceImages: (json['priceImages'] as num?)?.toInt() ?? 1,
      isActive: json['isActive'] as bool? ?? true,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
}

class CatalogPhotoshootEntry {
  const CatalogPhotoshootEntry({
    required this.id,
    required this.title,
    required this.category,
    required this.shortDescription,
    required this.prompt,
    required this.previewAssets,
    required this.priceImages,
    required this.isActive,
    required this.sortOrder,
    this.previewUrls = const [],
    this.badge,
    this.isFree = false,
  });

  final String id;
  final String title;
  final String category;
  final String shortDescription;
  final String prompt;
  final List<String> previewAssets;
  final List<String> previewUrls;
  final int priceImages;
  final bool isActive;
  final int sortOrder;
  final String? badge;
  final bool isFree;

  factory CatalogPhotoshootEntry.fromJson(Map<String, dynamic> json) {
    final previews = json['previewAssets'];
    final remotePreviews = json['previewUrls'];
    return CatalogPhotoshootEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      shortDescription: json['shortDescription'] as String,
      prompt: json['prompt'] as String,
      previewAssets: previews is List
          ? previews.map((e) => e.toString()).toList()
          : const [],
      previewUrls: remotePreviews is List
          ? remotePreviews
              .map((e) => e.toString().trim())
              .where((url) => url.isNotEmpty)
              .toList()
          : const [],
      priceImages: (json['priceImages'] as num?)?.toInt() ?? 3,
      isActive: json['isActive'] as bool? ?? true,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      badge: json['badge'] as String?,
      isFree: json['isFree'] as bool? ?? false,
    );
  }
}
