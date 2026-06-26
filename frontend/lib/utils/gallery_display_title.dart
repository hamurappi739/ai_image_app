import '../services/catalog_service.dart';

const galleryTemplatePrefix = 'Шаблон: ';
const galleryPhotoshootPrefix = 'Фотосессия: ';
const galleryCustomIdeaLabel = 'Своя идея';
const galleryCustomPhotoshootLabel = 'Своя фотосессия';
const galleryDefaultPhotoLabel = 'Готовое фото';

/// Short human title for a single gallery photo card or viewer.
String gallerySinglePhotoTitle(String description) {
  final trimmed = description.trim();
  if (trimmed.isEmpty) return galleryDefaultPhotoLabel;

  if (trimmed.startsWith(galleryTemplatePrefix)) {
    final title = trimmed.substring(galleryTemplatePrefix.length).trim();
    return title.isEmpty ? 'Шаблон' : title;
  }

  if (trimmed.startsWith(galleryPhotoshootPrefix)) {
    final title = trimmed.substring(galleryPhotoshootPrefix.length).trim();
    return title.isEmpty ? 'Фотосессия' : title;
  }

  if (trimmed == galleryCustomPhotoshootLabel ||
      trimmed.startsWith('$galleryCustomPhotoshootLabel:')) {
    return galleryCustomPhotoshootLabel;
  }

  if (trimmed == galleryCustomIdeaLabel ||
      trimmed.startsWith('$galleryCustomIdeaLabel:')) {
    return galleryCustomIdeaLabel;
  }

  final templateTitle = _templateTitleForPrompt(trimmed);
  if (templateTitle != null) return templateTitle;

  if (trimmed.length > 80) return galleryCustomIdeaLabel;

  if (trimmed.length <= 48) return trimmed;

  return galleryDefaultPhotoLabel;
}

/// Short style title for a photoshoot group card or viewer.
String galleryPhotoshootStyleTitle(String description) {
  final trimmed = description.trim();
  if (trimmed.isEmpty) return 'Фотосессия';

  if (trimmed == galleryCustomPhotoshootLabel ||
      trimmed.startsWith('$galleryCustomPhotoshootLabel:')) {
    return galleryCustomPhotoshootLabel;
  }

  if (trimmed.startsWith(galleryPhotoshootPrefix)) {
    final title = trimmed.substring(galleryPhotoshootPrefix.length).trim();
    return title.isEmpty ? 'Фотосессия' : title;
  }

  final photoshootTitle = _photoshootTitleForPrompt(trimmed);
  if (photoshootTitle != null) return photoshootTitle;

  if (trimmed.length > 80) return galleryCustomPhotoshootLabel;

  return trimmed.length <= 48 ? trimmed : 'Фотосессия';
}

String? _templateTitleForPrompt(String prompt) {
  final normalized = prompt.trim();
  if (normalized.isEmpty) return null;

  for (final template in CatalogService.instance.templates) {
    if (template.prompt.trim() == normalized) return template.title;
  }
  return null;
}

String? _photoshootTitleForPrompt(String prompt) {
  final normalized = prompt.trim();
  if (normalized.isEmpty) return null;

  for (final style in CatalogService.instance.photoshoots) {
    if (style.prompt.trim() == normalized) return style.title;
  }
  return null;
}
