# Roadmap

Этапы разработки **AI Image Generator**. Статус на текущий MVP.

---

## Выполнено

| Этап | Статус | Примечание |
|------|--------|------------|
| **Backend MVP** | ✅ | FastAPI: `GET /health`, `POST /generate` (mock image URL), Supabase credits через REST + httpx, debug endpoints |
| **GET /generations** | ✅ | История из `generations` (Bearer user id или dev fallback `TEST_USER_ID`), limit 1–100, новые сверху |
| **Flutter UI MVP** | ✅ | 5 вкладок (русский UI), premium-стиль, responsive карточки |
| **Галерея + backend** | ✅ | При старте `fetchGenerations()`; новые кадры после генерации — сразу сверху |
| **Фильтр debug в UI** | ✅ | Скрытие служебных записей (`debug test prompt` и т.п.) в галерее; Supabase не трогаем |
| **Локальная очистка Галереи** | ✅ | Кнопка «Очистить» — только in-memory на устройстве; backend/Supabase не меняются |
| **Навигация Создать ↔ Галерея** | ✅ | «Открыть в Галерее», «Создать первое изображение» |
| **Demo UI загрузки фото (Фотосессии)** | ✅ | Bottom sheet: стиль, badge, заглушка upload, «Что получится»; без файлов и backend |
| **Provider switch (`IMAGE_PROVIDER`)** | ✅ | `mock` по умолчанию; `gemini` через `GeminiImageProvider` |
| **Backend bearer token auth support** | ✅ | `Authorization: Bearer` → Supabase Auth REST; в development без токена — fallback `TEST_USER_ID` |
| **Frontend ApiService bearer token preparation** | ✅ | `setAccessToken` после входа; Bearer в `POST /generate` и `GET /generations` |
| **Basic Flutter Supabase Auth UI** | ✅ | Вкладка **Профиль**: вход / регистрация / выход |
| **Sign in / sign up form in Profile tab** | ✅ | Email + пароль; мягкие ошибки без технических деталей |
| **Access token passed to ApiService after login** | ✅ | Общий `ApiService` в `MainShell`; галерея перезагружается после входа/выхода |
| **Backend accepts Bearer token** | ✅ | `get_current_user()` → `CurrentUser { id, email }` из Supabase Auth |
| **Profile auto-create/sync** | ✅ | `ensure_profile_exists` на `GET /generations` и `POST /generate` (credit path) |
| **Development fallback check after auth/profile sync** | ✅ | Проверены оба режима: с Supabase Auth и без config через `TEST_USER_ID` fallback |
| **Auth loading states** | ✅ | В Профиле: loading для входа/регистрации/выхода, временно disabled кнопки и поля |
| **Local photo picker for photoshoot demo** | ✅ | Во вкладке «Фотосессии» можно выбрать фото локально через `image_picker` |
| **Photo preview in photoshoot modal** | ✅ | После выбора фото показывается preview в modal и «Фото выбрано» |
| **Backend photoshoot endpoint placeholder** | ✅ | `POST /photoshoots/generate` добавлен; сейчас возвращает `501` |
| **Frontend connected to photoshoot placeholder endpoint** | ✅ | Бесплатный сценарий Фотосессий вызывает `POST /photoshoots/generate` |
| **Backend multipart upload validation for photoshoots** | ✅ | `POST /photoshoots/generate` валидирует `photo` по типу и размеру (до 10 MB) |
| **Flutter multipart upload for photoshoots** | ✅ | Бесплатный сценарий отправляет выбранное фото через `multipart/form-data` |
| **Backend validation of uploaded photos** | ✅ | JPEG/PNG/WebP, max 10 MB; файл не сохраняется на сервере |
| **Graceful placeholder handling** | ✅ | `501` → «Обработка фото будет добавлена позже», без технических деталей в UI |
| **Backend storage service placeholder** | ✅ | `SupabaseStorageService` (httpx REST); `SUPABASE_STORAGE_BUCKET` в config/`.env.example`; не вызывается из текущих endpoints |
| **Supabase REST timeout/error handling** | ✅ | Централизованная обработка httpx в `supabase_service.py`; timeout → **503** `Supabase is temporarily unavailable` |
| **Debug storage upload test endpoint** | ✅ | `POST /debug/storage-test` — in-memory upload в bucket (только development) |
| **Supabase Storage bucket created** | ✅ | Bucket `generated-images` создан в Supabase Storage; для MVP — public |
| **Debug storage upload test passed** | ✅ | `POST /debug/storage-test` проверен: upload успешен, `public_url` открывается в браузере |
| **Generated image data URL storage helper** | ✅ | `upload_generated_image_data_url` в `storage_service.py`; PNG/JPEG/WebP data URL, max 10 MB; не подключён к `/generate` |
| **Debug storage image test passed** | ✅ | `POST /debug/storage-image-test` проверен: 1×1 PNG data URL → Storage, `public_url` открывается в браузере |
| **Connect data URL storage helper to /generate** | ✅ | `POST /generate` загружает `data:image/...` в Storage → `public_url`; mock mode без изменений |
| **Manual Gemini API test passed** | ✅ | Контролируемый ручной тест: `IMAGE_PROVIDER=gemini`, `ENABLE_CREDIT_CONSUMPTION=false` |
| **Gemini result stored in Supabase Storage** | ✅ | Generated image загружен в bucket `generated-images`, response содержит `public_url` |
| **Generated image public_url displayed in Gallery** | ✅ | Галерея показала реальную картинку по Storage URL |
| **Backend photoshoot style catalog** | ✅ | `photoshoot_styles.py`: 8 стилей, `instruction`, `get_photoshoot_style`; `/photoshoots/generate` валидирует `style_id` |
| **PhotoshootService** | ✅ | `photoshoot_service.py`: Gemini → Storage → `image_urls` + **`generations`** history |
| **Save photoshoot results to generation history** | ✅ | `create_generation_record`; `prompt`: `Фотосессия: …`; без списаний |
| **GeminiPhotoshootProvider** | ✅ | Реальный вызов `google-genai`: photo + `style.instruction` → data URLs |
| **Photoshoot output count runtime limit** | ✅ | `PHOTOSHOOT_OUTPUT_COUNT` env (1–3, default **1**); catalog product target — **3** |
| **Photoshoot generation safety switch** | ✅ | `ENABLE_PHOTOSHOOT_GENERATION` (default **false**); без флага — **501**, Gemini не вызывается |
| **Manual Gemini photoshoot test passed** | ✅ | Uploaded photo → Gemini → Storage → `image_urls` с `public_url`; `PHOTOSHOOT_OUTPUT_COUNT=1` |
| **Photoshoot result stored in Supabase Storage** | ✅ | Результат в bucket `generated-images` (`photoshoots/…`); `public_url` в response |
| **Gemini photoshoot generation** | ✅ | Реализовано и проверено вручную; по умолчанию выключено через safety switch |
| **Flutter photoshoot result handling** | ✅ | `PhotoshootGenerateResponse`: парсинг `image_urls` при **200** |
| **Photoshoot result added to Gallery** | ✅ | Успешные `image_urls` → локальная Галерея, описание «Фотосессия: …» |
| **Manual Flutter photoshoot-to-gallery test passed** | ✅ | Flutter UI + `ENABLE_PHOTOSHOOT_GENERATION=true`; после теста **`false`** |
| **Controlled 3-output photoshoot test** | ✅ | `PHOTOSHOOT_OUTPUT_COUNT=3` через Flutter UI; 1 photo → 3 images |
| **Storage upload for 3 photoshoot results** | ✅ | 3 файла в bucket `generated-images` (`photoshoots/…`) |
| **History save for 3 photoshoot results** | ✅ | 3 записи в `generations`; `GET /generations` возвращает все три |
| **Backend photoshoot grouping id (`photoshoot_id`)** | ✅ | Nullable column + index; все результаты одной фотосессии — один `photoshoot_id`; обычные генерации — `null` |
| **Flutter Gallery photoshoot grouping by `photoshoot_id`** | ✅ | Записи с одинаковым non-null `photoshoot_id` → одна карточка; `null` — отдельные карточки |
| **Grouped photoshoot card UI** | ✅ | Мини-сетка 1/2/3 изображения; «Создано по описанию», «N изображений», дата |
| **First-run onboarding** | ✅ | 5 экранов; «Далее», «Пропустить», «Начать»; `onboarding_completed`; не повторяется |
| **Onboarding mentions contextual help** | ✅ | На экране «Галерея»: «Помощь» в правом верхнем углу раздела |
| **Create tab contextual help** | ✅ | Кнопка **«Помощь»**; автопоказ при первом открытии; `create_help_seen` |
| **Photoshoots tab contextual help** | ✅ | Кнопка **«Помощь»**; автопоказ при первом открытии; `photoshoots_help_seen` |
| **Mixed packages UI** | ✅ | Вкладка **«Пакеты»**: 199/499/999 ₽, «С фотосессиями» / «Только изображения», бейджи, «Оплата скоро» |
| **Custom amount calculator UI** | ✅ | Блок **«Своя сумма»**: 200–100 000 ₽, выбор фотосессий, расчёт изображений |
| **Package amount validation** | ✅ | Мин/макс сумма, ошибки под полем, disabled-поведение кнопки оплаты |
| **Android packages layout polish** | ✅ | Адаптивная высота карточек, читаемые размеры на mobile, без overflow |
| **Packages help UI** | ✅ | `PacksHelpDialog` + кнопка **«Помощь»** (без автопоказа) |
| **Section help button (text)** | ✅ | **«Помощь»** вместо **?** на **Создать**, **Фотосессии**, **Пакеты** |
| **Backend paid photoshoot protection** | ✅ | Платные стили → **`402`** до Gemini/Storage/`generations`; бесплатные — как раньше |
| **Richer photoshoot cards** | ✅ | Каталог-style UI: gradient placeholder preview, название, описание, цена/«Бесплатно» |
| **“3 фото” label on photoshoot cards** | ✅ | Чип **«3 фото»** на карточке и в bottom sheet |
| **Upload photo recommendations in photoshoot dialog** | ✅ | Блок **«Какое фото лучше загрузить»** в bottom sheet |
| **Placeholder result examples** | ✅ | **«Пример результата»** — 3 мини-заглушки «Фото 1–3» (не реальные assets) |
| **Create tab photo picker UI** | ✅ | Блок **«Фото для образа»**, **«Добавить фото»** (`image_picker`); фото не уходит на backend |
| **Create tab selected photo preview** | ✅ | Preview выбранного фото на вкладке **«Создать»** |
| **Create tab remove selected photo** | ✅ | Кнопка **«Убрать фото»** |
| **Updated Create contextual help for photo input** | ✅ | Шаг **«Фото для образа»** в `CreateHelpDialog` |
| **Custom photoshoot UI placeholder** | ✅ | Карточка **«Своя фотосессия»** (**«Скоро»**, **«3 фото»**) + dialog; backend не вызывается |
| **Custom photoshoot photo picker** | ✅ | **«Добавить фото»**, preview, **«Убрать фото»** в dialog |
| **Custom photoshoot description field** | ✅ | Поле **«Ваши пожелания»** (multiline) |
| **Custom photoshoot helper text** | ✅ | Блок **«Как описать лучше»** + шаг в `PhotoshootsHelpDialog` |
| **Generation progress modal** | ✅ | `GenerationProgressDialog` — блокирующее окно по центру, затемнённый фон, `CircularProgressIndicator` |
| **Create generation countdown** | ✅ | **«Создать»**: ~60 с, заголовок «Создаём изображение», «Обычно это занимает до минуты.» |
| **Photoshoot generation countdown** | ✅ | **Фотосессии** (бесплатно + backend): ~120 с, «Готовим фотосессию», «Фотосессия может занять до двух минут.» |
| **Dimmed blocking loading overlay** | ✅ | `barrierDismissible: false`, `PopScope(canPop: false)`; при 0 с — «Почти готово, ждём результат...» |
| **Create free generation notice** | ✅ | `_CreateBalanceInfoCard` на **«Создать»**: free/paid из `GET /balance`, демо-режим, подсказки при исчерпании free |
| **Create generation progress dialog** | ✅ | `GenerationProgressDialog` на **«Создать»** (~60 с, затемнённый фон) |
| **Create guidance for with-photo / without-photo** | ✅ | Блок **«Как получить хороший результат»**: переключатель без/с фото, примеры (человек / предмет), общие советы |
| **Categorized Create ideas** | ✅ | **«Попробуйте идею»**: категории + `ExpansionTile`; режимы **«Без фото»** / **«С фото»** |
| **Clickable Create ideas** | ✅ | Tap по идее → текст в поле описания; фото и генерация не меняются автоматически |
| **Backend balance model** | ✅ | Migration `003_add_profile_balance_fields.sql`; `GET /balance`; `POST /debug/add-balance` (dev) |
| **Profile balance fields** | ✅ | `paid_image_generations`, `paid_photoshoots` in `profiles`; `paid_credits` retained |
| **Flutter balance display** | ✅ | `GET /balance` в **Профиль**, **Пакеты**, динамический баннер на **«Создать»** |
| **Balance spending rules** | ✅ | `/generate`: free → `paid_image_generations`; `/photoshoots/generate`: −1 `paid_photoshoots`; `balance` в response; **402** + SnackBar |
| **Mock photoshoot debit testing** | ✅ | `IMAGE_PROVIDER=mock` + `ENABLE_PHOTOSHOOT_GENERATION=true` → mock `placehold.co` без Gemini; полный flow: history + списание `paid_photoshoots` |
| **Min custom amount 10 ₽** | ✅ | `_customAmountMin = 10` во вкладке **«Пакеты»** |

### Flutter UI MVP (детали)

- **Onboarding:** 5 экранов при первом запуске; после «Начать» / «Пропустить» — основное приложение
- **Создать:** описание, баннер 3 бесплатных генераций, **категоризированные кликабельные идеи** (без/с фото), подсказки без/с фото, modal ожидания (~60 с), **UI-каркас фото** (picker/preview/убрать; backend позже), **контекстная помощь**, `POST /generate` по описанию, «Открыть в Галерее»
- **Фотосессии:** **каталог** (8 стилей + **«Своя фотосессия»** UI-каркас), рекомендации и примеры-заглушки в sheet; готовые стили: bottom sheet → multipart upload (бесплатно); **«Своя фотосессия»** — только dialog, SnackBar «будет добавлена позже»
- **Галерея:** `GET /generations` + локальные новые; **группировка фотосессий** по `photoshoot_id`; **Очистить** (только на устройстве); empty state; без падения при недоступном backend
- **Пакеты:** смешанная экономика **199 / 499 / 999 ₽**, переключатель режимов, **«Своя сумма»** (мин. **10 ₽**), валидация суммы, **«Помощь»**, баннер баланса; **оплата / RuStore — не подключены**
- **Профиль:** вход / регистрация / выход (при Supabase dart-define)

**UX (следующие задачи):** **backend** фото+описание на **«Создать»**, **prompts (качество)**, **RuStore** после покупки — см. [app_design_strategy.md](app_design_strategy.md) и § **«Ближайший порядок работ»** ниже.

---

## Монетизация и пакеты (новая экономика)

**Модель:** обычное изображение ≈ **10 ₽**, фотосессия ≈ **100 ₽** (3 изображения). Пакеты включают **и** фотосессии, **и** обычные изображения. Подробнее: [app_design_strategy.md](app_design_strategy.md) §8, [project_status.md](project_status.md).

### Выполнено (пакеты и монетизация UI)

| Задача | Статус |
|--------|--------|
| Mixed packages UI, «Своя сумма», validation (200–100 000 ₽), Android layout, **«Помощь»** | ✅ |

**Оплата и RuStore пока не подключены.** UI пакетов — **placeholder** («Оплата скоро»).

### Ближайший порядок работ (требования руководства)

| # | Задача | Статус |
|---|--------|--------|
| 1 | **Снизить мин. сумму «Своя сумма» до 10 ₽** во frontend (1 изображение = 10 ₽; макс. 100 000 ₽) | ✅ |
| 2 | **Create tab UX** — баннер баланса, progress dialog, подсказки/идеи без·с фото, категории, кликабельные идеи | ✅ |
| 3 | **Показ баланса** в **«Профиль»**, **«Пакеты»**, **«Создать»** (*бесплатные / изображения / фотосессии*; не «кредиты») | ✅ |
| 4 | **Generation progress modal** + обратный отсчёт (**Создать** ~60 с, **Фотосессии** ~120 с) | ✅ |
| 5 | **Backend endpoint: photo + description** (одно изображение) | **следующий** |
| 6 | **Connect Create photo mode to backend** | план |
| 7 | **Backend prompts — качество** (лица, без коллажа, one image) | план |
| 8 | **Backend balance model** — `GET /balance`, profile fields | ✅ |
| 9 | **Flutter balance display** — `GET /balance` в Профиль / Пакеты / Создать | ✅ |
| 10 | **Spending rules** — списание `paid_image_generations` / `paid_photoshoots`; `balance` в response | ✅ |
| 11 | **RuStore / real paid balance flow** — верификация, начисление после покупки | план |

### Баланс и правила генерации (детализация)

**Старт:**

- **UI (готово):** `_CreateBalanceInfoCard` на **«Создать»** — free/paid из API, демо-режим при `consumption_enabled=false`.
- **Backend (готово при `ENABLE_CREDIT_CONSUMPTION=true`):** **3 бесплатные** — только для **`POST /generate`**; затем `paid_image_generations`; фотосессии — `paid_photoshoots`.

**После исчерпания бесплатных:**

- **`POST /generate`** — только при **платном** балансе изображений (или аналог в `profiles`).
- **Платные фотосессии** — только после оплаты **или** при наличии **фотосессий на балансе** (backend **402** уже есть; frontend — понятное «пополните баланс» → **Пакеты**).

**Позже в UI:** краткий остаток на **«Создать»** и **«Фотосессии»** перед кнопкой генерации.

### Качество генераций (backend prompts, план)

Улучшить instruction для **`POST /generate`** и фото-сценариев (не показывать пользователю как «промпт»):

- realistic high-quality image
- natural face
- no distorted face
- no extra faces
- no collage / grid
- **one final image**, если не запрошена фотосессия из нескольких результатов

**Фотосессии:** каждый output — **отдельная фотография** (уже в product/backend; усилить при доработке prompts).

### «Создать» — идеи и подсказки (реализовано во Flutter)

- **Баннер:** «Вам доступно 3 бесплатные генерации» (UI; backend-учёт — позже).
- **«Попробуйте идею»:** режимы **«Без фото»** / **«С фото»**; категории в раскрывающихся блоках; **клик** → поле описания.
- **«Как получить хороший результат»:** те же режимы; **текстовые** примеры (не кликабельны); для **«С фото»** — человек / предмет.

**Будущее (backend):** endpoint **photo + description**; подключение блока **«Фото для образа»**; см. § **«Следующие крупные этапы»**.

---

## Частично / подготовлено

| Этап | Статус | Примечание |
|------|--------|------------|
| **Gemini provider implementation** | ✅ | Код провайдера готов: `GeminiImageProvider` + `google-genai`; `mock` остаётся режимом по умолчанию |
| **Gemini manual API test** | ✅ | Ручной тест пройден: Gemini → Storage → `public_url` → Галерея; после теста `IMAGE_PROVIDER=mock` |
| **Supabase credits / balance** | 🔶 | `GET /balance`, списание free/paid реализовано; **по умолчанию** `ENABLE_CREDIT_CONSUMPTION=false` (демо); RuStore / начисление после покупки — позже |
| **История в галерее** | 🔶 | С Bearer token — история по auth user; без входа — dev fallback |

---

## Следующие крупные этапы

После блока **«Ближайший порядок работ»** (см. выше): curated-примеры, backend **«Создать»** / **«Своя фотосессия»**, production cleanup.

### Ближайший UX (генерация и каталог)

1. **Replace placeholders with real curated example images** — на карточках каталога и в блоке «Пример результата» вместо gradient-заглушек.
2. **Improve visual branding and final art direction** — единый визуальный язык каталога фотосессий.
3. **Backend endpoint for photo + description single-image generation** — новый или расширенный API (не ломая текущий `POST /generate` по тексту).
4. **Connect Create photo input to backend** — отправка выбранного фото + описания с вкладки **«Создать»**.
5. **Save photo-based generation results to Gallery/history** — один результат в **Галерею** / `generations`.
6. **Backend endpoint for custom photoshoot** — API для **«Своей фотосессии»** (фото + текст пользователя).
7. **Connect custom photoshoot to Gemini** — генерация набора изображений по пользовательскому описанию.
8. **Payment logic for custom photoshoot if needed** — монетизация (если потребуется).
9. **Save custom photoshoot results to Gallery/history** — результаты в **Галерею** / `generations` с **`photoshoot_id`**.

### Далее (после UX-блока)

6. **Photoshoot detail view in Gallery** (опционально).
7. **Product mode: `PHOTOSHOOT_OUTPUT_COUNT=3` by default** — после решения стоимости и лимитов Gemini (сейчас default **1**, generation disabled).
8. **Maybe add separate photoshoot history type later** — отдельный тип/метка в истории (опционально).
9. **Решить, когда включать `IMAGE_PROVIDER=gemini` для обычной разработки** — сейчас по умолчанию `mock` для безопасности и экономии квот.
10. **Проверить стоимость / лимиты Gemini** — перед регулярным использованием и production.
11. **Позже включить `ENABLE_CREDIT_CONSUMPTION=true`** — после полной проверки списаний free/paid и записи в `generations`.
12. **Безопасные интеграционные тесты backend** — использовать `ENABLE_CREDIT_CONSUMPTION=false`, чтобы не списывать генерации из Supabase.
13. **Use public/signed URLs** — сейчас bucket public; для private bucket позже — signed URL.
14. **Auth: улучшения UX** — подтверждение email (если Supabase tребует email confirmation).
15. **Восстановление пароля** — добавить reset password flow.
16. **Убрать development `TEST_USER_ID` fallback** перед production (обязательный Bearer / auth user id).
17. **Синхронизация баланса генераций** с аккаунтом после auth.
18. **Удаление изображений из аккаунта/backend** — после авторизации (не только локальная «Очистить»).
19. **RuStore Billing** — см. раздел **«Монетизация и пакеты»** выше (после **balance UI + backend balance model**).
20. **Production cleanup** — удалить или защитить `/debug/*` endpoints; CORS, секреты, RLS.

---

## Дальше (после MVP)

11. **Release** — публикация в RuStore, мониторинг, поддержка  
12. **Шаблоны / CMS** — каталог фотосессий с backend, A/B карточек  
13. **Watermark / preview quality** — preview vs полное качество после оплаты  

---

## Связанные документы

- [app_design_strategy.md](app_design_strategy.md) — вкладки и UX
- [api_contract.md](api_contract.md) — `POST /generate`, `GET /generations`
- [product_strategy.md](product_strategy.md) — монетизация
