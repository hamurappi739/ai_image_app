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
| **Auth user data isolation** | ✅ | Bearer → свой `user_id`; dev `TEST_USER_ID` только без токена в development; Flutter очищает Галерею/баланс после выхода; `/debug/*` → `404` вне development |
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
| **Backend photoshoot style catalog** | ✅ | `photoshoot_styles.py`: стили + `instruction`, `get_photoshoot_style`; `/photoshoots/generate` валидирует `style_id` (каталог расширен под 15 UI-стилей) |
| **Extended app prompts (templates + photoshoots + custom chips)** | ✅ | [app_prompts.md](app_prompts.md) → `frontend/lib/data/app_prompts.dart`; шаблоны → **Свой запрос**; фотосессии → `description` в API |
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
| **Gemini quality instructions** | ✅ | `gemini_quality_instructions.py`: `/generate`, `/generate-with-photo`, `/photoshoots/generate`; anti-collage/grid; identity preservation; mock unchanged |
| **Real Gemini smoke test — ordinary generation** | ✅ | Safe mode: `IMAGE_PROVIDER=gemini`, `ENABLE_CREDIT_CONSUMPTION=false` → `POST /generate` → Storage → **Галерея** |
| **Real Gemini smoke test — photo-based generation** | ✅ | Safe mode → `POST /generate-with-photo` → Storage → **Галерея** |
| **Real Gemini smoke test — photoshoots (3 outputs)** | ✅ | Safe mode + `ENABLE_PHOTOSHOOT_GENERATION=true`, `PHOTOSHOOT_OUTPUT_COUNT=3` → `POST /photoshoots/generate` → **Галерея**; баланс не списывается |
| **Storage upload for 3 photoshoot results** | ✅ | 3 файла в bucket `generated-images` (`photoshoots/…`) |
| **History save for 3 photoshoot results** | ✅ | 3 записи в `generations`; `GET /generations` возвращает все три |
| **Backend photoshoot grouping id (`photoshoot_id`)** | ✅ | Nullable column + index; все результаты одной фотосессии — один `photoshoot_id`; обычные генерации — `null` |
| **Flutter Gallery photoshoot grouping by `photoshoot_id`** | ✅ | Записи с одинаковым non-null `photoshoot_id` → одна карточка; `null` — отдельные карточки |
| **Grouped photoshoot card UI** | ✅ | Мини-сетка 1/2/3 изображения; «Создано по описанию», «N изображений», дата |
| **First-run onboarding** | ✅ | 5 экранов; «Далее», «Пропустить», «Начать»; `onboarding_completed`; не повторяется |
| **Onboarding mentions contextual help** | ✅ | На экране «Галерея»: «Помощь» в правом верхнем углу раздела |
| **Create tab contextual help** | ✅ | Кнопка **«Помощь»**; автопоказ при первом открытии; `create_help_seen` |
| **Photoshoots tab contextual help** | ✅ | Кнопка **«Помощь»**; автопоказ при первом открытии; `photoshoots_help_seen` |
| **Mixed packages UI** | ✅ | Вкладка **«Пакеты»** (demo-ready): hero-баланс, 199/499/999 ₽, переключатель с пояснением, карточки **«Выбрать пакет»**, **«Популярно»** на 499 ₽ |
| **Custom amount calculator UI** | ✅ | Блок **«Своя сумма»**: 10–100 000 ₽, правила, **«К оплате»** / **«Вы получите»**, **«Пополнить баланс»** |
| **Package amount validation** | ✅ | Мин/макс сумма, ошибки под полем, disabled-поведение кнопки оплаты |
| **Android packages layout polish** | ✅ | Адаптивная высота карточек, читаемые размеры на mobile, без overflow |
| **Packages help UI** | ✅ | `PacksHelpDialog` + кнопка **«Помощь»** (без автопоказа) |
| **Section help button (text)** | ✅ | **«Помощь»** вместо **?** на **Создать**, **Фотосессии**, **Пакеты** |
| **Backend payment foundation** | ✅ | `payment_service.py`, `package_catalog.py`, idempotent top-up после verification |
| **payment_transactions table** | ✅ | Migration `004_create_payment_transactions.sql`; unique `(provider, provider_payment_id)` |
| **Backend package catalog** | ✅ | 6 пакетов (mix + images-only); суммы только на сервере |
| **Development mock-verify endpoint** | ✅ | `POST /payments/rustore/mock-verify`; проверен вручную (`package_499_mix`) |
| **Duplicate payment protection** | ✅ | Повторный `provider_payment_id` → `already_processed`, баланс не начисляется |
| **Flutter Packs → mock-verify (development)** | ✅ | «Выбрать пакет» → backend top-up; баланс в Пакеты/Профиль/Создать/Фотосессии |
| **Development mock-verify-custom endpoint** | ✅ | `POST /payments/rustore/mock-verify-custom`; backend считает изображения/фотосессии |
| **Flutter «Своя сумма» → mock-verify-custom (development)** | ✅ | «Пополнить баланс» → backend top-up; retry на 503; real RuStore — future |
| **Flutter PaymentService layer** | ✅ | `payment_service.dart` + `PaymentResult`; demo methods; RuStore stubs — future |
| **Android / RuStore readiness audit** | ✅ | `applicationId`, SDK 24/36, manifest, signing TODO; [rustore_integration_plan.md](rustore_integration_plan.md) |
| **Demo / release checklist** | ✅ | [demo_release_checklist.md](demo_release_checklist.md) — debug APK, install, backend modes, demo scenario |
| **Production safety audit** | ✅ | [production_safety_checklist.md](production_safety_checklist.md) — env/auth/debug/mock guards documented |
| **Env / config checklist** | ✅ | [env_config_checklist.md](env_config_checklist.md) — safe, demo, Gemini test, production presets |
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
| **Balance spending rules** | ✅ | `/generate`: free → `paid_image_generations`; `/photoshoots/generate`: −1 `paid_photoshoots`; `balance` в response; **402** → модалка + **Пакеты** |
| **Mock photoshoot debit testing** | ✅ | `IMAGE_PROVIDER=mock` + `ENABLE_PHOTOSHOOT_GENERATION=true` → mock `placehold.co` без Gemini; полный flow: history + списание `paid_photoshoots` |
| **Create photo mode UX** | ✅ | Режим по **тумблеру** (не по файлу); «Создать по фото»; фото обязательно для запуска; удаление фото не сбрасывает режим |
| **Photoshoots demo-ready catalog UI** | ✅ | Intro + баланс, карточки с описаниями/бейджами, модалка «Создать фотосессию» |
| **Packs demo-ready UI** | ✅ | Hero **«Ваш баланс»**, продуктовые карточки пакетов, **«Своя сумма»**, диалог **«Оплата скоро появится»**; карточки одинаковой высоты |
| **Photoshoots final polish** | ✅ | **«3 фото»** (не «до 3»), расширенные описания стилей, **«Пример результата»** в модалке |
| **Photoshoot 3-photo flow** | ✅ | `PHOTOSHOOT_OUTPUT_COUNT` default **3**; response **`photoshoot_id`**; **Галерея** группирует сразу после генерации; списание **1** `paid_photoshoots` |
| **Manual paid image debit check** | ✅ | `POST /generate` + `/generate-with-photo`: free → paid; `balance` в response |
| **Manual mock photoshoot debit check** | ✅ | `POST /photoshoots/generate` + mock provider: −1 `paid_photoshoots`, `balance` в response |
| **Frontend balance refresh after generation** | ✅ | **Профиль** / **Пакеты** / **Создать** обновляются из `balance` в response |
| **Mock photoshoot debit flow (Flutter emulator)** | ✅ | Debug: тестовое фото без галереи; progress dialog; Gallery + balance refresh |
| **Russian text input on Create tab** | ✅ | Кириллица в поле описания; Chrome + Android emulator |
| **Min custom amount 10 ₽** | ✅ | `_customAmountMin = 10` в разделе **«Купить»** |
| **UX-redesign: drawer navigation** | ✅ | Burger menu; нижние вкладки убраны; см. [navigation_redesign_plan.md](navigation_redesign_plan.md) |
| **UX-redesign: Главная welcome + Фото по шаблону** | ✅ | «Начать создавать» → шаблоны; автозаполнение **Свой запрос** |
| **UX-redesign: переименования UI** | ✅ | Свой запрос, Готовые фото, Купить |
| **UX-redesign: Фотосессии** | ✅ | Промо «Своя фотосессия» сверху; популярные / другие стили |
| **UX-redesign: Купить** | ✅ | Человеческие тексты; 1 фото = 10 ₽; 1 фотосессия = 100 ₽ |
| **UX-redesign: Готовые фото** | ✅ | Empty/loading/error; новая терминология в модалках |
| **UX-redesign: onboarding + help** | ✅ | 5 слайдов; `PagedHelpDialog`; help hub по разделам |
| **UX-redesign: debug APK на физическом Android-телефоне** | ✅ | `API_BASE_URL=http://192.168.31.242:8000`; demo mock backend; drawer, шаблоны, **Свой запрос** + фото, все разделы; помощь без overflow — [demo_release_checklist.md](demo_release_checklist.md) § D |
| **UX-redesign: шаблоны по категориям + расширенный каталог** | ✅ | **Фото по шаблону** — категории; больше шаблонов и подборок фотосессий |
| **UX-redesign: визуальные placeholder** | ✅ | Rich preview на карточках шаблонов, фотосессий, помощи |
| **UX-redesign: «Готовые фото» — success + быстрые действия** | ✅ | Баннер после генерации; «Что сделать дальше?»; бейдж «Новое» |
| **UX-redesign: баланс в drawer** | ✅ | «Ваш баланс» в меню; **Профиль**, **Купить**, info-блоки на экранах |
| **Mobile UX-polish: remove balance chip from app headers** | ✅ | Шапка: burger + title + optional help; баланс не конкурирует с заголовком |
| **Mobile UX-polish: compact template cards** | ✅ | Меньше пустоты, крупнее preview, компактнее кнопка «Выбрать» |
| **Mobile UX-polish: separate template categories** | ✅ | Категории в отдельных контейнерах с фоном |
| **Mobile UX-polish: improve custom request layout** | ✅ | Компактные шаги, preview фото, поле описания, блок «Что получится», спокойный баланс |
| **Mobile UX-polish: improve photoshoot card previews** | ✅ | Серия из 3 мини-карточек; компактные карточки каталога |
| **Mobile UX-polish: fix photoshoot overflow** | ✅ | Yellow/black overflow убран на preview фотосессий |
| **Mobile UX-polish: improve mobile screen subtitles** | ✅ | Подзаголовки на полную ширину, без обрезки из-за balance chip |
| **Mobile UX-polish: photoshoot category chips** | ✅ | Chips сверху (Популярное, Для себя, …) со scroll-to-section |
| **Mobile UX-polish: phone verification** | ✅ | Основные экраны проверены на физическом телефоне; `flutter analyze` clean |
| **UX-redesign: мягкие подсказки при нулевом балансе** | ✅ | Диалоги и info-блоки → **Купить** (с режимом каталога) |
| **UX-redesign: профиль как личный кабинет** | ✅ | Фото, Фотосессии, Бесплатные фото |

### Flutter UI MVP (детали)

- **Onboarding:** 5 экранов; путь **шаблон → фотосессия → свой запрос → меню**
- **Фото по шаблону:** шаблоны **по категориям**; «Выбрать» → **Свой запрос** с готовым описанием
- **Свой запрос:** фото → описание → **«Создать фото»**; после успеха → **Готовые фото**
- **Фотосессии:** подборки стилей; «Своя фотосессия» сверху; multipart → **Готовые фото**
- **Готовые фото:** success-блок, быстрые действия, группировка фотосессий, бейдж «Новое»
- **Купить:** 1 фото = 10 ₽, 1 фотосессия = 100 ₽; mock-verify в dev; RuStore — future
- **Баланс:** drawer + **Профиль** + **Купить** + info-блоки (не в шапке); мягкие подсказки при нуле
- **Навигация:** drawer (burger menu); см. [navigation_redesign_plan.md](navigation_redesign_plan.md)

**UX (следующие задачи):** **RuStore** после покупки — см. [app_design_strategy.md](app_design_strategy.md) и § **«Ближайший порядок работ»** ниже.

---

## Монетизация и пакеты (новая экономика)

**Модель:** обычное изображение ≈ **10 ₽**, фотосессия ≈ **100 ₽** (3 изображения). Пакеты включают **и** фотосессии, **и** обычные изображения. Подробнее: [app_design_strategy.md](app_design_strategy.md) §8, [project_status.md](project_status.md).

### Выполнено (пакеты и монетизация UI)

| Задача | Статус |
|--------|--------|
| Mixed packages UI, «Своя сумма», validation (200–100 000 ₽), Android layout, **«Помощь»** | ✅ |

**Реальный RuStore SDK пока не подключён.** Development mock top-up (готовые пакеты + **«Своя сумма»**) работает через backend; production / real payment — **future**.

### Ближайший порядок работ (требования руководства)

| # | Задача | Статус |
|---|--------|--------|
| 1 | **Снизить мин. сумму «Своя сумма» до 10 ₽** во frontend (1 изображение = 10 ₽; макс. 100 000 ₽) | ✅ |
| 2 | **Create tab UX** — баннер баланса, progress dialog, подсказки/идеи без·с фото, категории, кликабельные идеи | ✅ |
| 3 | **Показ баланса** в **«Профиль»**, **«Пакеты»**, **«Создать»** (*бесплатные / изображения / фотосессии*; не «кредиты») | ✅ |
| 4 | **Generation progress modal** + обратный отсчёт (**Создать** ~60 с, **Фотосессии** ~120 с) | ✅ |
| 5 | **Backend endpoint: photo + description** (одно изображение) | ✅ |
| 6 | **Connect Create photo mode to backend** | ✅ |
| 7 | **Backend prompts — качество** (лица, без коллажа, one image) | ✅ |
| 8 | **Backend balance model** — `GET /balance`, profile fields | ✅ |
| 9 | **Flutter balance display** — `GET /balance` в Профиль / Пакеты / Создать | ✅ |
| 10 | **Spending rules** — списание `paid_image_generations` / `paid_photoshoots`; `balance` в response | ✅ |
| 11 | **RuStore / real paid balance flow** — SDK + server verification + frontend purchase | план (backend foundation ✅) |

### Production release (future, не demo)

| Задача | Статус |
|--------|--------|
| **Backend deploy plan (document)** | ✅ | [backend_deploy_plan.md](backend_deploy_plan.md) — hosting, env, steps; no real deploy yet |
| **Production backend deploy** | план | Выполнить по deploy plan на выбранном хостинге |
| **Production env on real hosting** (secure secrets, no TEST_USER_ID) | план |
| **CORS trusted origins** | план |
| **RuStore real env / secrets / verification** | план |
| **Release signing** (keystore, CI secrets) | план |
| **RuStore real payment** | план |
| **Store metadata** (icon, name, listing) | план |

Demo-сборка и чеклист: [demo_release_checklist.md](demo_release_checklist.md).

### Следующие задачи (после проверки списаний)

| Задача | Статус |
|--------|--------|
| **RuStore payment verification** | план |
| **Real purchase → balance top-up** | план |
| **402 UI — insufficient balance** | ✅ | Модалки «Изображения/Фотосессии закончились» + переход в **Пакеты**; предупреждения до генерации |
| **Backend photo + description generation endpoint** | ✅ |
| **Connect Create photo input to backend** | ✅ |
| **Improve prompts for face quality** | ✅ | `gemini_quality_instructions.py` |
| **Extended user-facing descriptions** (17 templates, 15 photoshoots, 5 custom chips) | ✅ | [app_prompts.md](app_prompts.md) |
| **Replace placeholder/gradient examples with curated visuals** | план |
| **Gallery selective hide/delete** | ✅ (hide) | **«Скрыть из Галереи»** — локально на устройстве; backend/Storage не трогаются; удаление на сервере — план |
| **Gallery 2.0 viewer** | ✅ | Просмотр изображения/фотосессии, **Скачать**, локальное скрытие, empty state |

### Баланс и правила генерации (детализация)

**Старт:**

- **UI (готово):** `_CreateBalanceInfoCard` на **«Создать»** — free/paid из API, демо-режим при `consumption_enabled=false`.
- **Backend (готово при `ENABLE_CREDIT_CONSUMPTION=true`):** **3 бесплатные** — только для **`POST /generate`**; затем `paid_image_generations`; фотосессии — `paid_photoshoots`.

**После исчерпания бесплатных:**

- **`POST /generate`** — только при **платном** балансе изображений (или аналог в `profiles`).
- **Платные фотосессии** — только после оплаты **или** при наличии **фотосессий на балансе** (backend **402** уже есть; frontend — понятное «пополните баланс» → **Пакеты**).

**Позже в UI:** краткий остаток на **«Создать»** и **«Фотосессии»** перед кнопкой генерации.

### Качество генераций (backend instructions, реализовано)

Модуль **`app/services/gemini_quality_instructions.py`** — общие правила для Gemini (не показываются пользователю):

- **`POST /generate`:** одно цельное изображение по описанию; без коллажа/сетки; аккуратные лица и анатомия; без текста на кадре, если пользователь не просил.
- **`POST /generate-with-photo`:** входное фото как основа; сохранение узнаваемости; изменение фона/стиля без ломки объекта; одно изображение.
- **`POST /photoshoots/generate`:** **3 последовательных** вызова — по одному полноценному кадру; единый визуальный стиль; не triptych на одном холсте.

**Mock mode** не изменён. При ошибке Gemini (**502**) или Storage — **баланс не списывается**.

### «Создать» — идеи и подсказки (реализовано во Flutter)

- **Баннер:** `_CreateBalanceInfoCard` — free/paid из API; backend-учёт и списание **проверены вручную**.
- **«Попробуйте идею»:** режимы **«Без фото»** / **«С фото»**; категории в раскрывающихся блоках; **клик** → поле описания.
- **«Как получить хороший результат»:** те же режимы; **текстовые** примеры (не кликабельны); для **«С фото»** — человек / предмет.

**Будущее (backend):** endpoint **photo + description**; подключение блока **«Фото для образа»**; см. § **«Следующие крупные этапы»**.

---

## Частично / подготовлено

| Этап | Статус | Примечание |
|------|--------|------------|
| **Gemini provider implementation** | ✅ | Код провайдера готов: `GeminiImageProvider` + `google-genai`; `mock` остаётся режимом по умолчанию |
| **Gemini manual API test (all flows)** | ✅ | Safe mode smoke test: `/generate`, `/generate-with-photo`, `/photoshoots/generate` (3); баланс не списывается; после теста `IMAGE_PROVIDER=mock` |
| **Supabase credits / balance** | 🔶 | Списание free/paid **проверено вручную**; **по умолчанию** `ENABLE_CREDIT_CONSUMPTION=false` (демо); RuStore / начисление после покупки — позже |
| **История в галерее** | 🔶 | С Bearer token — история по auth user; без входа — dev fallback |

---

## Следующие крупные этапы

После блока **«Ближайший порядок работ»** (см. выше): curated preview-изображения, production cleanup.

### После backend payment foundation (план)

| Задача | Статус |
|--------|--------|
| **Реальный RuStore Pay SDK** (клиент) | план |
| **Server-side RuStore verification** (real API, не mock) | план |
| **Frontend purchase flow** — покупка → backend verify → обновление баланса в UI | план |
| **Custom amount через реальную оплату** | план |
| **Production hardening** — RLS на `payment_transactions`, webhook security, мониторинг | план |
| **Более глубокое качество генераций** на разных фото | план |
| **Edge cases ошибок Gemini** (502, пустой ответ, Storage failure) | план |
| **Production deploy** — CORS, убрать `TEST_USER_ID` fallback | план |

### Ближайший UX (после redesign)

| Задача | Статус |
|--------|--------|
| Burger navigation, home, templates, custom request, photoshoot collections, purchase UI | ✅ |
| Ready photos: success state + next actions | ✅ |
| Balance in navigation (drawer, profile, purchase, screen blocks — not header) | ✅ |
| Empty balance guidance (dialogs + info blocks) | ✅ |
| Mobile UX-polish (headers, subtitles, compact cards, overflow fixes) | ✅ |
| ~~Проверка redesigned APK на одном телефоне~~ | ✅ |
| **Реальные маркетинговые preview images/assets** вместо placeholder | план |
| **Полноценная «Своя фотосессия»** (backend + Gemini) | план |
| **Проверка на нескольких Android-устройствах** | план |
| **Production backend deploy** + **публичный HTTPS `API_BASE_URL`** | план |
| **RuStore real payment integration** | план |
| **Release signing** | план |

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

- [app_design_strategy.md](app_design_strategy.md) — UX-стратегия и терминология
- [navigation_redesign_plan.md](navigation_redesign_plan.md) — drawer, разделы, UX-redesign статус
- [api_contract.md](api_contract.md) — `POST /generate`, `GET /generations`
- [product_strategy.md](product_strategy.md) — монетизация
