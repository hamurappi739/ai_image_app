# Preview assets — чеклист и план

План локальных **preview-картинок** для UI (не результаты генерации).  
**Сейчас файлы не добавляем** — только согласованные имена, папки и точки использования.

Связанные документы: [frontend_assets_plan.md](frontend_assets_plan.md) (краткий обзор кода), [app_design_strategy.md](app_design_strategy.md) (визуальный стиль).

---

## 1. Общие правила

| Правило | Пояснение |
|---------|-----------|
| **Только локальные файлы** | Картинки лежат в репозитории (`frontend/assets/…`). **Не** загружать превью из интернета в runtime. |
| **Формат** | **WebP** (предпочтительно) или **PNG**. |
| **Пропорции** | Вертикальные или универсальные **4:5** / **3:4**; UI обрезает через `BoxFit.cover`. |
| **Вес** | Лёгкие файлы: ориентир **≤ 150–250 KB** на превью (не полноразмерные фото). |
| **Стиль** | Единая «премиальная» палитра приложения; мягкий свет; без серых технических заглушек. |
| **Контент** | Без персональных данных; без чужих **логотипов и брендов**. |
| **Лица** | Без слишком реалистичных / узнаваемых лиц, если **нет прав** на использование. Допустимы иллюстрации, силуэты, стилизованные образы. |
| **Имена файлов** | Только **латиница**, **lowercase**, **snake_case**, расширение `.webp` или `.png`. |

---

## 2. Папки

Планируемая структура (от корня `frontend/`):

```
frontend/assets/previews/
├── common/                    # общие иллюстрации
├── templates/
│   ├── for_self/
│   ├── work/
│   ├── family/
│   └── sales/
├── photoshoots/
│   ├── popular/
│   ├── for_self/
│   ├── work/
│   └── atmospheric/
└── onboarding/                # onboarding + help
```

**Полные пути в Flutter:** `assets/previews/…` (префикс `assets/` обязателен в `pubspec.yaml` и в коде).

---

## 3. Common assets

Папка: `frontend/assets/previews/common/`

| Файл | Использование |
|------|----------------|
| `home_hero.webp` | **Главная** — hero-блок «Ваш новый образ» |
| `good_photo_example.webp` | **Свой запрос**, **Фотосессии** (bottom sheet), **Помощь** — блок «Хорошее фото» / «Какое фото лучше загрузить» |
| `bad_photo_example.webp` | Те же экраны — блок «Плохое фото» (размытое, тёмное, обрезанное лицо и т.п.) |

---

## 4. Template assets

Раздел **«Фото по шаблону»** (`TemplatePhotoScreen`).  
На карточке шаблона: preview вместо gradient placeholder.

### `templates/for_self/`

| Файл | Шаблон (`id` в приложении) | Название в UI |
|------|----------------------------|---------------|
| `portrait_beauty.webp` | `beautiful_portrait` | Красивый портрет |
| `social_profile.webp` | `social_photo` | Фото для соцсетей |
| `winter_portrait.webp` | `winter_portrait` | Зимний портрет |
| `summer_portrait.webp` | `summer_portrait` | Летний портрет |
| `soft_portrait.webp` | `tender_portrait` | Нежный портрет |
| `bright_style.webp` | `vibrant_look` | Яркий образ |

### `templates/work/`

| Файл | Шаблон (`id`) | Название в UI |
|------|---------------|---------------|
| `business_portrait.webp` | `business_portrait` | Деловой портрет |
| `resume_photo.webp` | `resume_photo` | Фото для резюме |
| `profile_photo.webp` | `profile_photo` | Фото для профиля |
| `expert_style.webp` | `expert_look` | Экспертный образ |

### `templates/family/`

| Файл | Шаблон (`id`) | Название в UI |
|------|---------------|---------------|
| `family_photo.webp` | `family_photo` | Семейное фото |
| `child_photo.webp` | `photo_with_child` | Фото с ребёнком |
| `festive_style.webp` | `festive_look` | Праздничный образ |

### `templates/sales/`

| Файл | Шаблон (`id`) | Название в UI |
|------|---------------|---------------|
| `product_photo.webp` | `product_photo` | Фото товара |
| `clothing_photo.webp` | `clothing_photo` | Фото одежды |
| `jewelry_photo.webp` | `jewelry_photo` | Фото украшений |
| `interior_photo.webp` | `interior_photo` | Фото интерьера |

**Пример полного пути:**  
`assets/previews/templates/for_self/portrait_beauty.webp`

---

## 5. Photoshoot assets

Раздел **«Фотосессии»** (`PhotoshootsScreen`).  
Preview на карточке стиля и в bottom sheet (вместо gradient / мини-сетки-заглушки, где подключено).

### `photoshoots/popular/`

| Файл | Стиль (`style_id`) | Название в UI |
|------|-------------------|---------------|
| `business_photoshoot.webp` | `business_portrait` | Деловой портрет |
| `studio_portrait.webp` | `studio_portrait` | Студийный портрет |
| `city_portrait.webp` | `urban_portrait` (alias → `city_portrait` на backend) | Городской портрет |
| `evening_style.webp` | `evening_look` | Вечерний образ |

### `photoshoots/for_self/`

| Файл | Стиль (`style_id`) | Название в UI |
|------|-------------------|---------------|
| `soft_photoshoot.webp` | `tender_photoshoot` | Нежная фотосессия |
| `summer_photoshoot.webp` | `summer_photoshoot` | Летняя фотосессия |
| `winter_photoshoot.webp` | `winter_photoshoot` | Зимняя фотосессия |
| `home_portrait.webp` | `home_portrait` | Домашний портрет |

### `photoshoots/work/`

| Файл | Стиль (`style_id`) | Название в UI |
|------|-------------------|---------------|
| `expert_photoshoot.webp` | `expert_photoshoot` | Экспертная фотосессия |
| `business_brand.webp` | `business_brand` | Бизнес-портрет |
| `personal_brand.webp` | `personal_brand` | Фото для личного бренда |

### `photoshoots/atmospheric/`

| Файл | Стиль (`style_id`) | Название в UI |
|------|-------------------|---------------|
| `travel_portrait.webp` | `travel_portrait` | Портрет в путешествии |
| `cafe_city.webp` | `cafe_city` | Кафе и город |
| `park_walk.webp` | `park_walk` | Прогулка в парке |
| `premium_portrait.webp` | `premium_portrait` | Премиум-портрет |

**Пример полного пути:**  
`assets/previews/photoshoots/popular/studio_portrait.webp`

---

## 6. Custom photoshoot assets

| Файл | Путь | Использование |
|------|------|---------------|
| `custom_photoshoot.webp` | `frontend/assets/previews/photoshoots/custom_photoshoot.webp` | Промо-блок **«Своя фотосессия»** на экране **Фотосессии**; модалка **«Создать свой образ»** (`style_id`: `custom_photoshoot`) |

---

## 7. Onboarding / help assets

Папка: `frontend/assets/previews/onboarding/`

| Файл | Использование |
|------|----------------|
| `onboarding_templates.webp` | **Onboarding**, экран 2 — «Начните с шаблона» |
| `onboarding_photoshoot.webp` | **Onboarding**, экран 3 — «Попробуйте фотосессию» |
| `onboarding_custom_request.webp` | **Onboarding**, экран 4 — «Свой запрос» |
| `onboarding_menu.webp` | **Onboarding**, экран 5 — «Меню слева сверху» |

Дополнительно (по желанию, не в MVP-паке): те же иллюстрации в **Помощь** hub и контекстных диалогах (**Фото по шаблону**, **Фотосессии**, **Свой запрос**).

---

## 8. Техническая вставка (когда картинки будут готовы)

Порядок работ **без изменения поведения**, если файл ещё не подключён:

1. **Положить файлы** в папки из §2–§7 (имена — строго по таблицам).
2. **`frontend/pubspec.yaml`** — убедиться, что объявлены каталоги assets, например:
   ```yaml
   flutter:
     assets:
       - assets/previews/common/
       - assets/previews/templates/for_self/
       - assets/previews/templates/work/
       - assets/previews/templates/family/
       - assets/previews/templates/sales/
       - assets/previews/photoshoots/popular/
       - assets/previews/photoshoots/for_self/
       - assets/previews/photoshoots/work/
       - assets/previews/photoshoots/atmospheric/
       - assets/previews/photoshoots/
       - assets/previews/onboarding/
   ```
3. **`lib/assets/preview_asset_paths.dart`** — обновить константы путей и maps `templateById` / `photoshootById` под новую структуру папок (сейчас в коде часть путей плоская и с `.png`; при внедрении привести к этому чеклисту).
4. **`lib/assets/preview_asset_registry.dart`** — добавить каждый готовый путь в whitelist `availableAssets`.
5. **Данные каталога** — при необходимости явный `previewAssetPath` в `PhotoTemplate` / `_PhotoshootStyle`; иначе используется `effectivePreviewAssetPath` через `PreviewAssetPaths.*ForId`.
6. **Виджет** `PreviewAssetImage` — если путь **не** в registry или файл отсутствует, показывается **текущий Flutter placeholder** (`VisualPlaceholder`). Fallback **обязан остаться**.
7. **`flutter pub get`** → пересборка → проверка на Chrome и Android (нет overflow, `BoxFit.cover`).

**Не трогать:** API, Supabase, `.env`, логику генерации — только локальные assets и отображение preview.

---

## 9. Минимальный набор для первого этапа (MVP pack)

Стартовый набор **8 файлов** — закрывает главный экран, два типовых шаблона, товар, две фотосессии и подсказки по фото:

| # | Файл | Путь |
|---|------|------|
| 1 | `home_hero.webp` | `common/home_hero.webp` |
| 2 | `portrait_beauty.webp` | `templates/for_self/portrait_beauty.webp` |
| 3 | `business_portrait.webp` | `templates/work/business_portrait.webp` |
| 4 | `product_photo.webp` | `templates/sales/product_photo.webp` |
| 5 | `studio_portrait.webp` | `photoshoots/popular/studio_portrait.webp` |
| 6 | `evening_style.webp` | `photoshoots/popular/evening_style.webp` |
| 7 | `good_photo_example.webp` | `common/good_photo_example.webp` |
| 8 | `bad_photo_example.webp` | `common/bad_photo_example.webp` |

После MVP pack — по приоритету категорий: **popular** фотосессии → **for_self** шаблоны → onboarding (4 экрана) → остальной каталог.

---

## Сводка: сколько файлов

| Группа | Количество |
|--------|------------|
| Common | 3 |
| Templates | 17 |
| Photoshoots | 15 |
| Custom photoshoot | 1 |
| Onboarding / help | 4 |
| **Всего (полный каталог)** | **40** |
| **MVP pack (этап 1)** | **8** |

---

## Чеклист перед коммитом assets

- [ ] Имена файлов: latin, lowercase, snake_case  
- [ ] Формат webp/png, вес в разумных пределах  
- [ ] Нет брендов, персональных данных, спорных лиц  
- [ ] Пути добавлены в `pubspec.yaml`  
- [ ] Пути зарегистрированы в `PreviewAssetRegistry`  
- [ ] Карточки без overflow на узком экране  
- [ ] При удалении файла UI снова показывает placeholder (fallback проверен)
