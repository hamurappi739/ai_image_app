# Управление каталогом шаблонов и фотосессий

Каталог приложения хранится в JSON-файлах внутри Flutter-проекта. Это позволяет добавлять и редактировать шаблоны без изменения логики экранов.

## Где лежат файлы

| Файл | Назначение |
|------|------------|
| `frontend/assets/catalog/templates.json` | Шаблоны «Фото по шаблону» |
| `frontend/assets/catalog/photoshoots.json` | Готовые фотосессии |
| `frontend/assets/previews/templates/` | Preview-картинки шаблонов |
| `frontend/assets/previews/photoshoots/` | Preview-картинки фотосессий (по 3 на стиль) |

Подключение в `frontend/pubspec.yaml`:

```yaml
assets:
  - assets/catalog/
  - assets/previews/templates/
  - assets/previews/photoshoots/
  - assets/guides/
```

## Как добавить новый шаблон

1. Откройте `frontend/assets/catalog/templates.json`.
2. Добавьте объект в массив:

```json
{
  "id": "my_new_template",
  "title": "Название в карточке",
  "category": "Для себя",
  "shortDescription": "Короткий текст под названием (1–2 строки).",
  "prompt": "Полный промпт для генерации…",
  "previewAsset": "assets/previews/templates/my_new_template.jpg",
  "priceImages": 1,
  "isActive": true,
  "sortOrder": 70
}
```

3. Положите картинку `my_new_template.jpg` в `frontend/assets/previews/templates/`.
4. Пересоберите и перезапустите приложение.

**Категории шаблонов** (поле `category`):

- `Для себя`
- `Для работы`
- `Для семьи`
- `Для продажи`

## Как добавить новую фотосессию

1. Откройте `frontend/assets/catalog/photoshoots.json`.
2. Добавьте объект:

```json
{
  "id": "my_photoshoot",
  "title": "Название фотосессии",
  "category": "Популярное сейчас",
  "shortDescription": "Короткое описание в карточке.",
  "prompt": "Полный промпт фотосессии (серия из 3 фото)…",
  "previewAssets": [
    "assets/previews/photoshoots/my_photoshoot_1.jpg",
    "assets/previews/photoshoots/my_photoshoot_2.jpg",
    "assets/previews/photoshoots/my_photoshoot_3.jpg"
  ],
  "priceImages": 3,
  "isActive": true,
  "sortOrder": 50,
  "badge": "Для себя",
  "isFree": false
}
```

3. Добавьте три jpg в `frontend/assets/previews/photoshoots/`.
4. Пересоберите приложение.

**Категории фотосессий** (поле `category`):

- `Популярное сейчас`
- `Для себя`
- `Для работы`
- `Атмосферные`

Дополнительные поля для UI (не влияют на генерацию):

- `badge` — подпись на карточке («Популярно», «Для работы» и т.д.)
- `isFree` — бесплатная фотосессия для теста (`true` / `false`)

## Рекомендуемые размеры preview

| Тип | Соотношение | Примерный размер |
|-----|-------------|------------------|
| Шаблон (карточка) | 4:3 или 16:9 | 800×600 или 960×540 px |
| Фотосессия (1 из 3) | 1:1 | 400×400 px |

Формат: **JPG**. Если файла нет — показывается цветной placeholder.

## isActive

- `true` — элемент виден в каталоге.
- `false` — скрыт из UI, но остаётся в JSON (удобно временно отключать).

## sortOrder

Число для сортировки внутри категории. Меньшее значение — выше в списке. Шаг 10 оставляет место для вставок (`10`, `20`, `30`…).

## Почему нужна новая сборка APK

JSON и картинки входят в assets Flutter-приложения на этапе сборки. После изменения файлов нужен **hot restart** в разработке или **новая сборка APK/IPA** для пользователей — без этого старая версия каталога останется в установленном приложении.

## Следующий этап — remote catalog

Планируется вынести каталог на backend (например Supabase): приложение будет подгружать JSON по сети и обновлять каталог без переустановки. Текущая локальная схема — подготовка к этому: те же поля и структура переедут на сервер.

## Генератор JSON из промптов

При массовом обновлении промптов можно пересобрать JSON:

```bash
python frontend/tools/generate_catalog_json.py
```

Скрипт читает `lib/data/app_prompts.dart` и перезаписывает оба JSON-файла.

## Загрузка в приложении

`CatalogService` (`lib/services/catalog_service.dart`) загружается при старте в `main()`. Если JSON повреждён — используется минимальный fallback (1 шаблон + 1 фотосессия), приложение не падает.
