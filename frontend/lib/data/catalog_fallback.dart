import '../models/catalog_entries.dart';

/// Minimal embedded catalog used when JSON assets fail to load.
class CatalogFallback {
  CatalogFallback._();

  static const templates = [
    CatalogTemplateEntry(
      id: 'beautiful_portrait',
      title: 'Красивый портрет',
      category: 'Для себя',
      shortDescription: 'Мягкий свет и аккуратный образ для красивого фото.',
      prompt:
          'Создай реалистичный красивый портрет по загруженному фото. '
          'Сохрани лицо, возраст, основные черты, форму лица, цвет глаз '
          'и узнаваемость человека.',
      previewAsset: 'assets/previews/templates/beautiful_portrait.jpg',
      priceImages: 1,
      isActive: true,
      sortOrder: 10,
    ),
  ];

  static const photoshoots = [
    CatalogPhotoshootEntry(
      id: 'studio_portrait',
      title: 'Студийный портрет',
      category: 'Популярное сейчас',
      shortDescription: 'Классическая студийная серия с мягким светом.',
      prompt:
          'Создай серию из 3 студийных портретов по исходному фото. '
          'Сохрани лицо, возраст, форму лица, цвет глаз, черты '
          'и узнаваемость человека во всех кадрах.',
      previewAssets: [
        'assets/previews/photoshoots/studio_portrait_1.jpg',
        'assets/previews/photoshoots/studio_portrait_2.jpg',
        'assets/previews/photoshoots/studio_portrait_3.jpg',
      ],
      priceImages: 3,
      isActive: true,
      sortOrder: 10,
      badge: 'Популярно',
      isFree: true,
    ),
  ];
}
