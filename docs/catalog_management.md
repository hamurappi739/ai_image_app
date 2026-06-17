# Управление каталогом шаблонов и фотосессий

Каталог приложения хранится в JSON. Есть **локальная копия** внутри Flutter (для офлайн-fallback) и **основная копия на backend** (для обновлений без пересборки APK).

## Где лежат файлы

| Файл | Назначение |
|------|------------|
| `backend/app/catalog/templates.json` | Шаблоны на сервере (remote catalog) |
| `backend/app/catalog/photoshoots.json` | Фотосессии на сервере (remote catalog) |
| `frontend/assets/catalog/templates.json` | Локальный fallback шаблонов |
| `frontend/assets/catalog/photoshoots.json` | Локальный fallback фотосессий |
| `frontend/assets/previews/templates/` | Preview-картинки шаблонов в APK |
| `frontend/assets/previews/photoshoots/` | Preview-картинки фотосессий в APK (по 3 на стиль) |

API (без авторизации):

- `GET /catalog/templates`
- `GET /catalog/photoshoots`

Подключение локальных assets в `frontend/pubspec.yaml`:

```yaml
assets:
  - assets/catalog/
  - assets/previews/templates/
  - assets/previews/photoshoots/
  - assets/guides/
```

## Как обновлять каталог без новой версии APK

### 1. Локальный каталог в APK (fallback)

- Редактируете `frontend/assets/catalog/*.json`
- Кладёте картинки в `frontend/assets/previews/`
- **Пересобираете APK** — пользователи получают новую версию только после установки

Это резервный вариант: приложение использует его, если backend недоступен.

### 2. Remote catalog на backend (обновление без APK)

1. Отредактируйте `backend/app/catalog/templates.json` или `photoshoots.json`
2. Для новых preview используйте **публичные URL** в полях `previewUrl` / `previewUrls` (например Supabase Storage)
3. Убедитесь, что `isActive: true` и задан `sortOrder`
4. Задеплойте или перезапустите backend
5. Пользователь **перезапускает приложение** — `CatalogService` подтянет каталог с API

Картинки по URL не входят в APK: их можно менять на сервере без пересборки.

### 3. Разница между previewAsset и previewUrl

| Поле | Где | Когда использовать |
|------|-----|-------------------|
| `previewAsset` / `previewAssets` | Локальные пути в APK | Картинка уже в приложении, работает офлайн |
| `previewUrl` / `previewUrls` | HTTP(S) ссылка | Новые или обновляемые preview без APK |

Приоритет на экране: если `previewUrl` начинается с `http` — показывается сеть; при ошибке — `previewAsset`; если и его нет — цветной placeholder.

## Как добавить новый remote template

1. Откройте `backend/app/catalog/templates.json`
2. Добавьте объект:

```json
{
  "id": "my_new_template",
  "title": "Название в карточке",
  "category": "Для себя",
  "shortDescription": "Короткий текст под названием.",
  "prompt": "Полный промпт для генерации…",
  "previewAsset": "assets/previews/templates/my_new_template.jpg",
  "previewUrl": "https://your-storage.example.com/previews/my_new_template.jpg",
  "priceImages": 1,
  "isActive": true,
  "sortOrder": 70
}
```

3. Загрузите картинку в Storage и вставьте публичный URL в `previewUrl`
4. Деплой backend → перезапуск приложения у пользователя

Для офлайн-fallback можно продублировать запись в `frontend/assets/catalog/templates.json`.

**Категории шаблонов:** `Для себя`, `Для работы`, `Для семьи`, `Для продажи`

## Как добавить новую remote photoshoot

1. Откройте `backend/app/catalog/photoshoots.json`
2. Добавьте объект:

```json
{
  "id": "my_photoshoot",
  "title": "Название фотосессии",
  "category": "Популярное сейчас",
  "shortDescription": "Короткое описание.",
  "prompt": "Полный промпт фотосессии…",
  "framePrompts": [
    "Кадр 1 из 3: …",
    "Кадр 2 из 3: …",
    "Кадр 3 из 3: …"
  ],
  "previewAssets": [
    "assets/previews/photoshoots/my_photoshoot_1.jpg",
    "assets/previews/photoshoots/my_photoshoot_2.jpg",
    "assets/previews/photoshoots/my_photoshoot_3.jpg"
  ],
  "previewUrls": [
    "https://your-storage.example.com/previews/my_photoshoot_1.jpg",
    "https://your-storage.example.com/previews/my_photoshoot_2.jpg",
    "https://your-storage.example.com/previews/my_photoshoot_3.jpg"
  ],
  "priceImages": 3,
  "isActive": true,
  "sortOrder": 50,
  "badge": "Для себя",
  "isFree": false
}
```

3. `framePrompts` — **3 строки** с промптом каждого кадра (ракурс/поза). Backend использует их при Gemini-генерации; см. [photoshoot_prompt_strategy.md](photoshoot_prompt_strategy.md)
4. `previewUrls` — ровно 3 рабочих HTTP(S) URL для сетевых превью
5. Деплой backend

**Категории фотосессий:** `Популярное сейчас`, `Для себя`, `Для работы`, `Атмосферные`

## Рекомендуемые размеры preview

| Тип | Соотношение | Примерный размер |
|-----|-------------|------------------|
| Шаблон (карточка) | 4:3 или 16:9 | 800×600 или 960×540 px |
| Фотосессия (1 из 3) | 1:1 | 400×400 px |

Формат: **JPG**. Если файла/URL нет — показывается placeholder.

## isActive

- `true` — элемент виден в каталоге (backend отдаёт только активные; frontend дополнительно фильтрует)
- `false` — скрыт из UI

## sortOrder

Число для сортировки внутри категории. Меньшее значение — выше в списке (`10`, `20`, `30`…).

## Загрузка в приложении

`CatalogService` при старте:

1. Пробует `GET /catalog/templates` и `GET /catalog/photoshoots` (timeout ~4 с)
2. При успехе — remote catalog
3. При ошибке — `assets/catalog/*.json`
4. При повреждённом JSON — встроенный минимальный fallback (1 шаблон + 1 фотосессия)

## TODO — следующий этап

- Каталог в таблице Supabase или admin panel, чтобы не редактировать JSON вручную
- Версионирование каталога и кэш на устройстве

## Генератор JSON из промптов

При массовом обновлении промптов в Dart:

```bash
python frontend/tools/generate_catalog_json.py
```

Скрипт перезаписывает **frontend** JSON. После этого скопируйте файлы в `backend/app/catalog/` и добавьте `previewUrl` / `previewUrls` при необходимости.

## Синхронизация frontend ↔ backend

После правок локального каталога:

```bash
python -c "
import json
from pathlib import Path
root = Path('.')
dst = root / 'backend/app/catalog'
dst.mkdir(parents=True, exist_ok=True)
for name, url_field in [('templates.json', 'previewUrl'), ('photoshoots.json', 'previewUrls')]:
    data = json.loads((root / 'frontend/assets/catalog' / name).read_text(encoding='utf-8'))
    for item in data:
        if url_field == 'previewUrl':
            item.setdefault('previewUrl', None)
        else:
            item.setdefault('previewUrls', [])
    (dst / name).write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
"
```

Сохраните существующие `previewUrl` / `previewUrls` на backend перед перезаписью, если они уже заданы.
