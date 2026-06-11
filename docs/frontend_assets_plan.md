# Frontend preview assets plan

Локальные иллюстрации для карточек **«Фото по шаблону»**, **«Фотосессии»** и hero на **«Главной»**. Сейчас UI использует Flutter placeholders; реальные файлы подключаются постепенно.

**Подробный чеклист (имена, папки, MVP pack):** [preview_assets_checklist.md](preview_assets_checklist.md).

## Структура папок

```
frontend/assets/previews/
├── templates/     # превью шаблонов «Фото по шаблону»
├── photoshoots/   # превью стилей фотосессий
└── common/        # общие (hero главной и т.п.)
```

Подключение в `frontend/pubspec.yaml`:

```yaml
assets:
  - assets/previews/templates/
  - assets/previews/photoshoots/
  - assets/previews/common/
```

## Как включить asset в UI

1. Положить файл в нужную папку (например `assets/previews/templates/portrait_soft.png`).
2. Убедиться, что путь описан в `lib/assets/preview_asset_paths.dart`.
3. Добавить путь в whitelist `PreviewAssetRegistry.availableAssets` в `lib/assets/preview_asset_registry.dart`.
4. Запустить `flutter pub get` и пересобрать приложение.

Пока путь **не** в whitelist, `PreviewAssetImage` **не** вызывает `Image.asset` — показывается текущий Flutter placeholder (без краша и без ошибок в консоли).

## Список планируемых файлов

### Templates (`assets/previews/templates/`)

| Файл | Назначение |
|------|------------|
| `portrait_soft.png` | Нежный / красивый портрет |
| `social_profile.png` | Фото для соцсетей |
| `winter_portrait.png` | Зимний портрет |
| `summer_portrait.png` | Летний портрет |
| `business_portrait.png` | Деловой портрет |
| `resume_photo.png` | Фото для резюме |
| `family_photo.png` | Семейное фото |
| `product_photo.png` | Фото товара / одежды |
| `interior_photo.png` | Интерьер |

### Photoshoots (`assets/previews/photoshoots/`)

| Файл | Стиль (`style_id`) |
|------|-------------------|
| `studio_portrait.png` | Студийный портрет |
| `business_portrait.png` | Деловой портрет |
| `city_portrait.png` | Городской портрет |
| `evening_style.png` | Вечерний образ |
| `winter_photoshoot.png` | Зимняя фотосессия |
| `home_portrait.png` | Домашний портрет |
| `travel_portrait.png` | Портрет в путешествии |
| `premium_portrait.png` | Премиум-портрет |
| `custom_photoshoot.png` | Своя фотосессия |

### Common (`assets/previews/common/`)

| Файл | Назначение |
|------|------------|
| `home_hero.png` | Hero-блок на главной |

## Требования к картинкам

- **Формат:** PNG или WebP (предпочтительно WebP для меньшего веса).
- **Ориентация:** вертикальный или квадратный кадр (карточки обрезают через `BoxFit.cover`).
- **Размер:** лёгкие файлы (ориентир — до ~150–250 KB на превью; не полноразмерные фото).
- **Стиль:** мягкий, «премиальный», единая палитра с приложением; без серых технических заглушек.
- **Контент:** иллюстрации или стилизованные образы; **без реальных персональных данных** и без узнаваемых лиц без прав.
- **Источник:** только локальные файлы в репозитории; **без загрузки из интернета** в runtime.

## Код

| Файл | Роль |
|------|------|
| `lib/assets/preview_asset_paths.dart` | Константы путей и map id → path |
| `lib/assets/preview_asset_registry.dart` | Whitelist готовых assets |
| `lib/widgets/preview_asset_image.dart` | Безопасный виджет: asset или placeholder |

Модели:

- `PhotoTemplate.previewAssetPath` / `effectivePreviewAssetPath`
- `_PhotoshootStyle.previewAssetPath` / `effectivePreviewAssetPath`

## Текущее состояние

- Папки созданы; изображений пока нет.
- `PreviewAssetRegistry.availableAssets` пуст — везде fallback на Flutter placeholders.
- Поведение приложения (выбор шаблона, фотосессии, генерация, оплата) не меняется.
