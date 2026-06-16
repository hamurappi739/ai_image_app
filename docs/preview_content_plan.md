# План подготовки preview-картинок для каталога

Документ для подготовки реальных картинок-примеров к шаблонам и фотосессиям приложения.  
Источник данных: `frontend/assets/catalog/templates.json` и `frontend/assets/catalog/photoshoots.json` (идентичны backend-каталогу по составу элементов).

---

## 1. Общая логика

| Поле | Где задаётся | Что делает |
|------|--------------|------------|
| `previewAsset` | Локальный JSON + путь в APK | Картинка **внутри приложения** (`frontend/assets/previews/...`) |
| `previewUrl` | Backend JSON (`backend/app/catalog/templates.json`) | Картинка **по ссылке** с сервера |
| `previewAssets` | Локальный JSON | Три картинки в APK для фотосессии |
| `previewUrls` | Backend JSON (`backend/app/catalog/photoshoots.json`) | Три ссылки для фотосессии |

**Как приложение выбирает картинку**

1. Если в backend-каталоге заполнен `previewUrl` / `previewUrls` (начинается с `http`) — показывается сетевая картинка.
2. Если сеть недоступна или URL пустой — используется `previewAsset` / `previewAssets` из каталога (файл в APK).
3. Если файла нет — показывается цветной placeholder (приложение не падает).

**Обновление без пересборки APK**

- Локальные `previewAsset` / `previewAssets` требуют **новой сборки APK**.
- Чтобы менять картинки у уже установивших пользователей — заполняйте **`previewUrl` / `previewUrls`** в `backend/app/catalog/` и деплойте backend.
- Для remote-картинок удобно использовать **Supabase Storage** с публичным bucket: загрузили JPG → скопировали public URL → вставили в backend JSON.

**Связанные файлы**

| Назначение | Путь |
|------------|------|
| Локальный каталог (fallback) | `frontend/assets/catalog/` |
| Backend каталог (remote) | `backend/app/catalog/` |
| Preview шаблонов в APK | `frontend/assets/previews/templates/` |
| Preview фотосессий в APK | `frontend/assets/previews/photoshoots/` |
| Good/bad guide | `frontend/assets/guides/good_photo.jpg`, `bad_photo.jpg` |

---

## 2. Рекомендованные размеры

### Шаблоны (1 картинка на элемент)

| Параметр | Значение |
|----------|----------|
| Размер | **1200×800** или **1280×720** |
| Формат | **JPG** |
| Композиция | Главный объект / лицо **ближе к центру** |
| Обрезка | Карточка использует `BoxFit.cover` — **края могут обрезаться**, не кладите важное у краёв |

### Фотосессии (3 картинки на элемент)

| Параметр | Значение |
|----------|----------|
| Размер | **1024×1024** (квадрат, 1:1) |
| Формат | **JPG** |
| Количество | **3 файла** на одну фотосессию (`{id}_1.jpg`, `_2`, `_3`) |
| Стиль | Три кадра должны выглядеть как **одна серия** (один человек/стиль, единый свет и настроение) |

### Good / bad guide (блок «Как получить хороший результат»)

| Параметр | Значение |
|----------|----------|
| Размер | **1024×1024** |
| Формат | **JPG** |
| Файлы | `frontend/assets/guides/good_photo.jpg`, `frontend/assets/guides/bad_photo.jpg` |
| Смысл | Хороший пример: лицо крупно, светло, чётко. Плохой: темно, мелко, размыто |

---

## 3. Таблица шаблонов

Всего шаблонов: **17**. На каждый — **1** preview-картинка.

| id | Название | Категория | Картинок | Локальный путь (`previewAsset`) | Remote (`previewUrl`) | Статус |
|----|----------|-----------|----------|--------------------------------|----------------------|--------|
| `beautiful_portrait` | Красивый портрет | Для себя | 1 | `assets/previews/templates/beautiful_portrait.jpg` | — | Нужно подготовить |
| `social_photo` | Фото для соцсетей | Для себя | 1 | `assets/previews/templates/social_photo.jpg` | — | Нужно подготовить |
| `winter_portrait` | Зимний портрет | Для себя | 1 | `assets/previews/templates/winter_portrait.jpg` | — | Нужно подготовить |
| `summer_portrait` | Летний портрет | Для себя | 1 | `assets/previews/templates/summer_portrait.jpg` | — | Нужно подготовить |
| `tender_portrait` | Нежный портрет | Для себя | 1 | `assets/previews/templates/gentle_portrait.jpg` | — | Нужно подготовить |
| `vibrant_look` | Яркий образ | Для себя | 1 | `assets/previews/templates/bright_look.jpg` | — | Нужно подготовить |
| `business_portrait` | Деловой портрет | Для работы | 1 | `assets/previews/templates/business_portrait.jpg` | — | Нужно подготовить |
| `resume_photo` | Фото для резюме | Для работы | 1 | `assets/previews/templates/resume_photo.jpg` | — | Нужно подготовить |
| `profile_photo` | Фото для профиля | Для работы | 1 | `assets/previews/templates/profile_photo.jpg` | — | Нужно подготовить |
| `expert_look` | Экспертный образ | Для работы | 1 | `assets/previews/templates/expert_look.jpg` | — | Нужно подготовить |
| `family_photo` | Семейное фото | Для семьи | 1 | `assets/previews/templates/family_photo.jpg` | — | Нужно подготовить |
| `photo_with_child` | Фото с ребёнком | Для семьи | 1 | `assets/previews/templates/child_photo.jpg` | — | Нужно подготовить |
| `festive_look` | Праздничный образ | Для семьи | 1 | `assets/previews/templates/holiday_look.jpg` | — | Нужно подготовить |
| `product_photo` | Фото товара | Для продажи | 1 | `assets/previews/templates/product_photo.jpg` | — | Нужно подготовить |
| `clothing_photo` | Фото одежды | Для продажи | 1 | `assets/previews/templates/clothes_photo.jpg` | — | Нужно подготовить |
| `jewelry_photo` | Фото украшений | Для продажи | 1 | `assets/previews/templates/jewelry_photo.jpg` | — | Нужно подготовить |
| `interior_photo` | Фото интерьера | Для продажи | 1 | `assets/previews/templates/interior_photo.jpg` | — | Нужно подготовить |

> **Примечание:** у `tender_portrait`, `vibrant_look`, `photo_with_child`, `festive_look`, `clothing_photo` имя файла в `previewAsset` отличается от `id` — при сохранении JPG используйте именно путь из таблицы.

Колонку **Remote** заполняйте после загрузки в Supabase Storage, например:  
`https://<project>.supabase.co/storage/v1/object/public/<bucket>/templates/beautiful_portrait.jpg`

---

## 4. Таблица фотосессий

Всего фотосессий: **15**. На каждую — **3** preview-картинки.

| id | Название | Категория | Картинок | Локальные пути (`previewAssets`) | Remote (`previewUrls`) | Статус |
|----|----------|-----------|----------|----------------------------------|------------------------|--------|
| `business_portrait` | Деловой портрет | Популярное сейчас | 3 | `business_portrait_1.jpg`, `_2`, `_3` | — | Нужно подготовить |
| `studio_portrait` | Студийный портрет | Популярное сейчас | 3 | `studio_portrait_1.jpg`, `_2`, `_3` | — | Нужно подготовить |
| `urban_portrait` | Городской портрет | Популярное сейчас | 3 | `urban_portrait_1.jpg`, `_2`, `_3` | — | Нужно подготовить |
| `evening_look` | Вечерний образ | Популярное сейчас | 3 | `evening_look_1.jpg`, `_2`, `_3` | — | Нужно подготовить |
| `tender_photoshoot` | Нежная фотосессия | Для себя | 3 | `tender_photoshoot_1.jpg`, `_2`, `_3` | — | Нужно подготовить |
| `summer_photoshoot` | Летняя фотосессия | Для себя | 3 | `summer_photoshoot_1.jpg`, `_2`, `_3` | — | Нужно подготовить |
| `winter_photoshoot` | Зимняя фотосессия | Для себя | 3 | `winter_photoshoot_1.jpg`, `_2`, `_3` | — | Нужно подготовить |
| `home_portrait` | Домашний портрет | Для себя | 3 | `home_portrait_1.jpg`, `_2`, `_3` | — | Нужно подготовить |
| `expert_photoshoot` | Экспертная фотосессия | Для работы | 3 | `expert_photoshoot_1.jpg`, `_2`, `_3` | — | Нужно подготовить |
| `business_brand` | Бизнес-портрет | Для работы | 3 | `business_brand_1.jpg`, `_2`, `_3` | — | Нужно подготовить |
| `personal_brand` | Фото для личного бренда | Для работы | 3 | `personal_brand_1.jpg`, `_2`, `_3` | — | Нужно подготовить |
| `travel_portrait` | Портрет в путешествии | Атмосферные | 3 | `travel_portrait_1.jpg`, `_2`, `_3` | — | Нужно подготовить |
| `cafe_city` | Кафе и город | Атмосферные | 3 | `cafe_city_1.jpg`, `_2`, `_3` | — | Нужно подготовить |
| `park_walk` | Прогулка в парке | Атмосферные | 3 | `park_walk_1.jpg`, `_2`, `_3` | — | Нужно подготовить |
| `premium_portrait` | Премиум-портрет | Атмосферные | 3 | `premium_portrait_1.jpg`, `_2`, `_3` | — | Нужно подготовить |

Полные пути для локальных файлов:  
`assets/previews/photoshoots/<имя_файла>.jpg`  
(например `assets/previews/photoshoots/studio_portrait_1.jpg`).

Для remote в `backend/app/catalog/photoshoots.json` указывайте массив из **трёх** URL:

```json
"previewUrls": [
  "https://.../studio_portrait_1.jpg",
  "https://.../studio_portrait_2.jpg",
  "https://.../studio_portrait_3.jpg"
]
```

### Good / bad guide (дополнительно)

| Файл | Путь | Размер | Статус |
|------|------|--------|--------|
| Хороший пример | `frontend/assets/guides/good_photo.jpg` | 1024×1024 JPG | Нужно подготовить |
| Плохой пример | `frontend/assets/guides/bad_photo.jpg` | 1024×1024 JPG | Нужно подготовить |

---

## 5. Как добавить картинку локально (в APK)

1. Подготовьте JPG нужного размера (см. раздел 2).
2. Положите файл в нужную папку:
   - шаблон → `frontend/assets/previews/templates/<имя>.jpg`
   - фотосессия → `frontend/assets/previews/photoshoots/<id>_1.jpg` (и `_2`, `_3`)
   - guide → `frontend/assets/guides/good_photo.jpg` или `bad_photo.jpg`
3. Убедитесь, что путь совпадает с полем `previewAsset` / `previewAssets` в `frontend/assets/catalog/*.json`.
4. Проверьте `frontend/pubspec.yaml` — папки `assets/previews/` и `assets/guides/` должны быть подключены.
5. В терминале из `frontend/`:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```
6. Для пользователей — **пересоберите APK** (картинки в assets не обновляются без новой сборки).

---

## 6. Как добавить картинку без новой APK

1. Подготовьте JPG (те же размеры, что в разделе 2).
2. Загрузите файл в **Supabase Storage** (public bucket), например:
   - `catalog-previews/templates/beautiful_portrait.jpg`
   - `catalog-previews/photoshoots/studio_portrait_1.jpg`
3. Скопируйте **public URL** из Supabase.
4. Откройте backend-каталог:
   - шаблон → `backend/app/catalog/templates.json` → поле **`previewUrl`**
   - фотосессия → `backend/app/catalog/photoshoots.json` → массив **`previewUrls`** (3 URL)
5. Сохраните JSON, **перезапустите или задеплойте backend**.
6. Пользователь **перезапускает приложение** — `CatalogService` загрузит каталог с API и покажет новые картинки по ссылке.

Локальные `previewAsset` / `previewAssets` можно оставить как fallback на случай офлайна.

---

## 7. Правила качества

- **Не использовать** кривые лица, лишние пальцы, странные пропорции (даже в примере — пользователь ожидает качество).
- **Не использовать** слишком мелкое лицо — в карточке оно станет ещё меньше.
- **Не использовать** тёмные, шумные или сильно размытые фото.
- **Не использовать** чужие логотипы, водяные знаки, бренды без прав.
- **Стиль картинки** должен соответствовать названию и описанию шаблона (зимний — зимний, деловой — нейтральный фон и т.д.).
- **Фотосессия:** три кадра — одна серия (один герой, похожий свет, одежда и настроение; разные ракурсы, не три разных стиля).
- **Товары / интерьер:** предмет или комната в центре, чистый свет, без лишнего в кадре.
- **Сжатие JPG:** умеренное (качество ~80–85%), чтобы файл был лёгким для мобильной сети.

---

## Чеклист готовности

| Блок | Элементов | Картинок всего | Статус по умолчанию |
|------|-----------|----------------|---------------------|
| Шаблоны | 17 | 17 | Нужно подготовить |
| Фотосессии | 15 | 45 (15×3) | Нужно подготовить |
| Good/bad guide | 2 | 2 | Нужно подготовить |
| **Итого** | **34 позиции** | **64 файла** | |

После подготовки меняйте колонку «Статус» в копии таблицы (или в трекере задач) на «Готово локально» / «Готово remote» / «Готово оба».

См. также: [catalog_management.md](catalog_management.md) — управление каталогом и синхронизация frontend ↔ backend.
