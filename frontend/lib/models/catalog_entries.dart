class CatalogTemplatePhotoInput {
  const CatalogTemplatePhotoInput({
    required this.id,
    required this.field,
    required this.label,
  });

  final String id;
  final String field;
  final String label;

  factory CatalogTemplatePhotoInput.fromJson(Map<String, dynamic> json) {
    return CatalogTemplatePhotoInput(
      id: json['id'] as String,
      field: json['field'] as String? ?? 'photo',
      label: json['label'] as String,
    );
  }
}

class CatalogTemplateFieldInput {
  const CatalogTemplateFieldInput({
    required this.id,
    required this.label,
    required this.type,
  });

  final String id;
  final String label;
  final String type;

  factory CatalogTemplateFieldInput.fromJson(Map<String, dynamic> json) {
    return CatalogTemplateFieldInput(
      id: json['id'] as String,
      label: json['label'] as String,
      type: json['type'] as String? ?? json['id'] as String,
    );
  }
}

class CatalogTemplateInputRequirements {
  const CatalogTemplateInputRequirements({
    required this.photos,
    required this.fields,
  });

  final List<CatalogTemplatePhotoInput> photos;
  final List<CatalogTemplateFieldInput> fields;

  bool get isMultiInput => photos.length > 1 || fields.isNotEmpty;

  CatalogTemplateFieldInput? fieldByType(String type) {
    for (final field in fields) {
      if (field.type == type) return field;
    }
    return null;
  }

  factory CatalogTemplateInputRequirements.fromJson(Map<String, dynamic> json) {
    final rawPhotos = json['photos'];
    final rawFields = json['fields'];
    return CatalogTemplateInputRequirements(
      photos: rawPhotos is List
          ? rawPhotos
              .whereType<Map<String, dynamic>>()
              .map(CatalogTemplatePhotoInput.fromJson)
              .toList()
          : const [],
      fields: rawFields is List
          ? rawFields
              .whereType<Map<String, dynamic>>()
              .map(CatalogTemplateFieldInput.fromJson)
              .toList()
          : const [],
    );
  }
}

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
    this.generationBlocked = false,
    this.generationBlockedMessage,
    this.inputRequirements,
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
  final bool generationBlocked;
  final String? generationBlockedMessage;
  final CatalogTemplateInputRequirements? inputRequirements;

  factory CatalogTemplateEntry.fromJson(Map<String, dynamic> json) {
    final previewUrl = json['previewUrl'];
    final blockedMessage = json['generationBlockedMessage'];
    final rawRequirements = json['inputRequirements'];
    return CatalogTemplateEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      shortDescription: json['shortDescription'] as String,
      prompt: json['prompt'] as String? ?? '',
      previewAsset: json['previewAsset'] as String,
      previewUrl: previewUrl is String && previewUrl.trim().isNotEmpty
          ? previewUrl.trim()
          : null,
      priceImages: (json['priceImages'] as num?)?.toInt() ?? 1,
      isActive: json['isActive'] as bool? ?? true,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      generationBlocked: json['generationBlocked'] as bool? ?? false,
      generationBlockedMessage:
          blockedMessage is String && blockedMessage.trim().isNotEmpty
              ? blockedMessage.trim()
              : null,
      inputRequirements: rawRequirements is Map<String, dynamic>
          ? CatalogTemplateInputRequirements.fromJson(rawRequirements)
          : null,
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
