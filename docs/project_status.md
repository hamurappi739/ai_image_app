# Project Status — AI Image App

Краткий технический статус для нового чата в Cursor или разработчика. Обновляйте при смене архитектуры или крупных этапов.

---

## 1. Краткое описание

- **Мобильное / кроссплатформенное приложение** на **Flutter** (сейчас основная разработка UI — **Chrome / web**).
- **Backend** — **FastAPI**, генерация изображений, учёт генераций, история.
- **Supabase (PostgreSQL)** — профили, история генераций (`generations`), транзакции (`credit_transactions`).
- Проект в стадии **MVP / demo-mode**: mock-генерация, заглушки оплаты и загрузки фото, dev-пользователь `TEST_USER_ID`.
- **`IMAGE_PROVIDER`**: `mock` (по умолчанию, безопасный режим) → **`MockImageProvider`**; `gemini` → **`GeminiImageProvider`** (реализован в backend, но не используется по умолчанию).

### Авторизация (текущий статус)

- **Flutter, вкладка Профиль:** базовая авторизация через Supabase Auth (вход / регистрация / выход).
- **Auth loading states:** для входа, регистрации и выхода есть локальные состояния загрузки; во время выполнения auth-действия кнопки временно disabled (и поля формы временно недоступны при входе/регистрации).
- **Ошибки для пользователя:** технические ошибки Supabase не показываются; вместо этого отображаются мягкие пользовательские сообщения.
- **Supabase Auth во Flutter** включается **только** при запуске с **`--dart-define=SUPABASE_URL=...`** и **`--dart-define=SUPABASE_ANON_KEY=...`** (`Supabase.initialize` в `main.dart`).
- **Без dart-define:** авторизация в UI недоступна; приложение работает в **demo / development fallback** (`TEST_USER_ID` на backend).
- **После входа:** access token из `AuthService` передаётся в **`ApiService.setAccessToken(...)`** → backend получает **`Authorization: Bearer`**.
- **Backend:** `get_current_user()` валидирует Bearer через Supabase Auth REST (`/auth/v1/user`) → **`CurrentUser { id, email }`**.
- **Profiles auto-create/sync:** backend автоматически вызывает **`ensure_profile_exists`** для пользователя на **`GET /generations`** и **`POST /generate`**; если профиля нет, создаёт строку в `profiles` (`free_generations_used=0`, `paid_credits=0`) и мягко синхронизирует `email` без перезаписи уже заполненного значения.
- **Работает в двух режимах:** и для Bearer token пользователя, и для development fallback **`TEST_USER_ID`**.
- **Проверено после auto-sync:**  
  1) запуск с Supabase Auth config + вход в аккаунт;  
  2) запуск без Supabase config через development fallback.  
  В обоих режимах вкладки **Создать** и **Галерея** работают (генерация и загрузка истории).

---

## 2. Текущая структура проекта

| Папка | Назначение |
|-------|------------|
| `backend/` | FastAPI, Supabase REST (httpx), `ImageService` + providers, `SupabaseStorageService` (placeholder) |
| `frontend/` | Flutter app (`lib/main.dart`, `lib/services/api_service.dart`) |
| `docs/` | Контракт API, дизайн, roadmap, demo script |

---

## 3. Как запустить backend

**Windows PowerShell:**

```powershell
cd C:\Users\shuly\Desktop\ai_image_app\backend
.\.venv\Scripts\python.exe -m uvicorn app.main:app --reload
```

- URL: **http://127.0.0.1:8000**
- Проверка: **`GET /health`** → `{"status":"ok"}`
- Переменные: скопировать `backend/.env.example` → `backend/.env` (не коммитить)

---

## 4. Как запустить frontend

```powershell
cd C:\Users\shuly\Desktop\ai_image_app\frontend
flutter pub get
flutter run -d chrome
```

**С Supabase Auth** (локально, ключи не в git):

```powershell
flutter run -d chrome --dart-define=SUPABASE_URL=YOUR_SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

См. [flutter_auth_setup.md](flutter_auth_setup.md).

| Платформа | Backend URL (`ApiService`) |
|-----------|----------------------------|
| Web / Chrome | `http://127.0.0.1:8000` |
| Android emulator (позже) | `http://10.0.2.2:8000` |

- **Android-сборка** пока отложена (Gradle / SSL при загрузке плагинов).
- Перед демо убедиться, что backend запущен.

---

## 5. Backend endpoints

### Supabase Storage

- Backend **Supabase Storage service** подготовлен: **`app/services/storage_service.py`** — `SupabaseStorageService` (REST через **httpx**, без Python SDK `supabase`).
- **`SUPABASE_STORAGE_BUCKET`** добавлен в **`app/config.py`** и **`backend/.env.example`** (по умолчанию `generated-images`).
- **Bucket `generated-images` создан** в Supabase Storage и предназначен для **будущего хранения generated images** (результаты текстовой генерации и фотосессий).
- Для MVP bucket настроен как **public** — `get_public_url` / `upload_bytes` возвращают рабочий URL без signed URLs.
- Базовые методы: `build_storage_path`, `upload_bytes`, `get_public_url`.
- **Helper `upload_generated_image_data_url(user_id, data_url, folder="generations")`** — загрузка generated image data URL в Storage:
  - принимает data URL вида `data:image/png;base64,...`, `data:image/jpeg;base64,...`, `data:image/webp;base64,...`;
  - **валидирует** формат (PNG / JPEG / WebP) и **размер до 10 MB**;
  - декодирует base64, собирает storage path через `build_storage_path`, загружает bytes в bucket **`generated-images`**;
  - возвращает **`public_url`**.
- Ошибки валидации helper: **`400`** — `Invalid image data`, `Unsupported image format`, `Image is too large`.
- **`POST /generate`** подключён к helper: если provider вернул **`data:image/...`**, backend загружает в Storage и возвращает **`public_url`** (в response и в **`generations.image_url`** при `ENABLE_CREDIT_CONSUMPTION=true`). **Mock mode** (`placehold.co`) — **без изменений**, Storage не вызывается.
- **Ручной Gemini-тест успешно пройден:** временно `IMAGE_PROVIDER=gemini`, `ENABLE_CREDIT_CONSUMPTION=false` → Gemini вернул реальное изображение → backend загрузил в bucket **`generated-images`** → frontend получил **`public_url`** → **Галерея** показала реальную картинку. После теста **`IMAGE_PROVIDER` возвращён на `mock`**.
- **Ручной Gemini photoshoot test успешно пройден:** `ENABLE_PHOTOSHOOT_GENERATION=true`, `PHOTOSHOOT_OUTPUT_COUNT=1` → **`POST /photoshoots/generate`** принял uploaded photo → Gemini вернул photoshoot image → backend загрузил результат в bucket **`generated-images`** (`photoshoots/…`) → response содержит **`image_urls`** с **`public_url`**. После теста **`ENABLE_PHOTOSHOOT_GENERATION=false`**.
- **`POST /photoshoots/generate`** при **`ENABLE_PHOTOSHOOT_GENERATION=true`**: Gemini → Storage → **`image_urls`** + запись каждого результата в **`generations`** (`prompt`: `Фотосессия: …`).
- **`POST /debug/storage-test`** (development only) — **успешно проверен**: backend загружает маленький in-memory тестовый файл в Storage и возвращает **`public_url`**; **`public_url` проверен вручную** в браузере.
- **`POST /debug/storage-image-test`** (development only) — **успешно проверен**: вызывает **`upload_generated_image_data_url`** с тестовым **1×1 PNG** data URL; **`public_url` открыт вручную** в браузере.
- **Следующий этап:** решить, когда включать **`IMAGE_PROVIDER=gemini`** для обычной разработки; проверить стоимость/лимиты; позже **`ENABLE_CREDIT_CONSUMPTION=true`**.
- Исходные пользовательские фото для фотосессий **не планируется** хранить долго без необходимости.

### Supabase REST — ошибки и таймауты

- Все Supabase REST-запросы в **`supabase_service.py`** идут через централизованную обёртку **httpx**.
- **ConnectTimeout**, **ReadTimeout**, **ConnectError** и другие transport-ошибки обрабатываются **безопасно** (без секретов в логах и ответах).
- При недоступности Supabase или timeout backend возвращает **`503`** с `detail`: **`Supabase is temporarily unavailable`** — не необработанный **`500`** с traceback.
- **`GET /health`** не зависит от Supabase и отвечает всегда.
- При нормальной работе Supabase **`GET /generations`** и остальные flows ведут себя как раньше; бизнес-ошибки (например, неуспешный HTTP-ответ БД) по-прежнему **`500`** с понятным `detail`.

### Публичные (MVP)

| Метод | Путь | Назначение |
|-------|------|------------|
| GET | `/health` | Жив ли сервер |
| POST | `/generate` | Генерация по тексту (mock по умолчанию; Gemini + Storage проверен вручную) |
| GET | `/generations` | История генераций (`?limit=1..100`, по умолчанию 20) |

### `POST /generate`

- **`IMAGE_PROVIDER=mock`** (по умолчанию, **текущий безопасный режим разработки**) → `MockImageProvider`: placeholder `image_url` (`placehold.co`); Storage **не используется**.
- **`IMAGE_PROVIDER=gemini`** + `GEMINI_API_KEY` → `GeminiImageProvider`: Gemini API → data URL; **`POST /generate`** загружает data URL в Storage и возвращает **`public_url`**. **Ручной тест успешно пройден** (см. §11).
- Для ручного Gemini-теста использовать **`ENABLE_CREDIT_CONSUMPTION=false`** — без списания генераций из Supabase.
- После любого Gemini-теста **обязательно** вернуть **`IMAGE_PROVIDER=mock`** (см. [gemini_test_checklist.md](gemini_test_checklist.md)).
- В backend auth helper `get_current_user()` поддерживает `Authorization: Bearer <token>` через Supabase Auth REST (`/auth/v1/user`).
- Если заголовка нет в development — остаётся fallback на `TEST_USER_ID`; в non-development без токена — `401`.
- **`ENABLE_CREDIT_CONSUMPTION=false`** (безопасный режим тестов): **не списывает** генерации из Supabase и не выполняет запись в `generations`.
- **`ENABLE_CREDIT_CONSUMPTION=true`**: профиль по user id (из Bearer token или dev fallback `TEST_USER_ID`), auto-sync профиля через `ensure_profile_exists`, списание free/paid, запись в Supabase (`generations`, `credit_transactions`).

### `POST /photoshoots/generate`

- Backend принимает `multipart/form-data`: `style_id`, `style_title`, `photo`.
- **Catalog стилей** (`app/services/photoshoot_styles.py`): backend валидирует `style_id`, хранит `title`, `price_rub`, `is_free`, `output_count=3`, `instruction` для Gemini-генерации.
- **`PhotoshootService`** + **`GeminiPhotoshootProvider`** (`app/services/photoshoot_service.py`): uploaded photo + `style.instruction` → Gemini → data URLs → Supabase Storage (`photoshoots/…`) → **`public_url`** в ответе.
- **Известная проблема (Gemini):** иногда возвращал **коллаж/сетку** из нескольких кадров в одном изображении. **Backend prompt обновлён:** каждый вызов Gemini просит **ровно одну standalone photo** (без collage/grid/contact sheet); стили catalog больше не содержат «Create 3 photos» в одном instruction.
- Runtime limit: **`PHOTOSHOOT_OUTPUT_COUNT`** (env, default **1**, max **3**); product target в catalog — **3** изображения.
- Использует ту же auth-логику: Bearer token или development fallback `TEST_USER_ID`; перед обработкой — profile auto-sync.
- Валидирует формат файла: **JPEG / PNG / WebP**, максимум **10 MB**.
- Неизвестный `style_id` → **`400`** `Unknown photoshoot style`.
- **Платные стили** (`is_free=false`) → **`402`** `Payment is required for this photoshoot style` — **до** чтения фото; Gemini, Storage и **`generations`** **не вызываются** (backend protection; верификация оплаты — позже).
- При успехе возвращает **`200`** с `style_id`, `style_title`, `image_urls`, `output_count`.
- **Safety switch (по умолчанию):** **`ENABLE_PHOTOSHOOT_GENERATION=false`** — Gemini **не вызывается**; после валидации **`501`** `Photoshoot generation is disabled in development mode`.
- **Controlled test:** временно **`ENABLE_PHOTOSHOOT_GENERATION=true`** + **`PHOTOSHOOT_OUTPUT_COUNT=1`** (или **3** для product test) + **`GEMINI_API_KEY`**; **после теста вернуть `ENABLE_PHOTOSHOOT_GENERATION=false`** и **`PHOTOSHOOT_OUTPUT_COUNT=1`**.
- **Product target:** **3 изображения** на фотосессию — **проверен вручную** (`PHOTOSHOOT_OUTPUT_COUNT=3`, см. §11); catalog `output_count=3`.
- Требует **`GEMINI_API_KEY`** (при включённой генерации); без ключа → **`500`** `GEMINI_API_KEY is not configured`.
- Backend **не сохраняет** загруженное исходное фото, **не списывает** генерации/оплату.
- При успешной фотосессии (**`ENABLE_PHOTOSHOOT_GENERATION=true`**) каждый **`image_url`** записывается в **`generations`** (`prompt`: **`Фотосессия: <style.title>`**, `payment_type`: **`free`** / **`paid`**, общий **`photoshoot_id`** на все результаты одной сессии).
- **`GET /generations`** возвращает **`photoshoot_id`** (если есть); **Flutter Gallery** группирует записи с одинаковым non-null **`photoshoot_id`** в **одну карточку фотосессии** (мини-сетка изображений, подпись «N изображений»). Записи с **`photoshoot_id=null`** — отдельные обычные карточки.
- **Ручной Gemini photoshoot test пройден:** uploaded photo → Gemini image → Storage → **`image_urls`** (см. §11).

### `GET /generations`

- С Bearer token: `CurrentUser` из Supabase Auth REST; перед выборкой — **`ensure_profile_exists`**.
- Без токена в development: **`TEST_USER_ID`** + auto-create профиля при необходимости.
- Ответ: список из таблицы **`generations`** (новые сверху); каждая запись может содержать **`photoshoot_id`** (`null` для обычных генераций и legacy rows).
- В non-development без токена: `401` (`Authorization required`).

### Development only

**`/debug/*`** — только для разработки. **`GET /debug/config`** — безопасный helper: флаги конфигурации без секретов (доступен только при `ENVIRONMENT=development`, иначе 404). **Не вызывать** из production Flutter. Перед релизом — **удалить или защитить все** `/debug/*` routes.

Примеры: `/debug/config`, `/debug/supabase`, `/debug/storage-test`, `/debug/storage-image-test`, `/debug/profile`, `/debug/history`, `/debug/consume-generation`, `/debug/add-credits`.

Подробнее: [api_contract.md](api_contract.md), [dev_notes.md](dev_notes.md).

---

## 6. Frontend вкладки

Нижняя навигация (русский UI): **Создать · Фотосессии · Галерея · Пакеты · Профиль**.

### First-run onboarding и контекстная помощь

**First-run onboarding (реализовано):**

- При **первом запуске** — **5 экранов** обучалки (`onboarding_completed` в `shared_preferences`).
- На каждом экране: **«Далее»**, **«Пропустить»**; на последнем — **«Начать»**.
- После завершения или пропуска **больше не показывается** на этом устройстве.
- Темы: возможности приложения, **«Создать»**, **«Фотосессии»**, хорошее исходное фото, **«Галерея»**.
- На экране **«Галерея»** указано: повторную помощь можно открыть **кнопкой помощи в правом верхнем углу раздела**.
- Debug (только dev): **Профиль** → «Показать обучалку снова».

**Контекстная помощь по вкладкам (реализовано):**

| Вкладка | Автопоказ | Ручной доступ | Ключ prefs |
|---------|-----------|---------------|------------|
| **Создать** | При **первом** открытии вкладки | Иконка **?** справа сверху | `create_help_seen` |
| **Фотосессии** | При **первом** открытии вкладки | Иконка **?** справа сверху | `photoshoots_help_seen` |

- Диалог: 4 коротких шага, **«Далее»** / **«Понятно»**; после закрытия — флаг «видели помощь».
- Повторное открытие через **?** доступно **всегда**.

### Создать

- Ввод **описания**, быстрые идеи, блок **«Как получить хороший результат»**.
- **UI-каркас «фото + описание» (реализовано):** блок **«Фото для образа»** — **«Добавить фото»** (`image_picker`), **preview** выбранного фото, **«Убрать фото»**; фото только **локально** в state экрана (не backend, не Gallery, не `shared_preferences`).
- **Сейчас фото не отправляется на backend.** При нажатии «Создать» с выбранным фото — мягкий SnackBar: *«Создание по фото будет добавлено позже. Сейчас изображение создаётся по описанию.»* — затем обычная генерация по тексту.
- **Контекстная помощь** (см. выше): 4 блока — готовые идеи, описание, **фото для будущего одиночного образа** (UI есть, backend позже), где результат.
- **`POST /generate`** через `ApiService` — **текст → одно изображение** (как раньше).
- **План (backend):** подключить **фото + описание → одно изображение**; см. [app_design_strategy.md](app_design_strategy.md) §10.
- Результат: `Image.network` или **fallback-preview** при ошибке загрузки.
- Кнопка **«Открыть в Галерее»**.
- Frontend скрывает технические ошибки генерации: в UI показывается только понятное сообщение для пользователя.
- Ошибки backend/Gemini (и HTTP-детали) должны логироваться/обрабатываться на backend, без вывода технических деталей в UI.

### Фотосессии

- **Каталог карточек (реализовано):** вкладка ближе к **каталогу готовых образов** — у каждой карточки gradient **placeholder preview** (место под будущий пример результата), **название**, **«3 фото»**, **«Бесплатно»** / **«100 ₽»**, короткое **описание**; платные визуально мягко отличаются (рамка, акцент). **Реальные curated-примеры** — позже.
- **Bottom sheet выбранной фотосессии:** блок **«Какое фото лучше загрузить»** (лицо видно, не размыто, освещение, тень, пояс/полный рост); блок **«Пример результата»** — 3 **placeholder-миниатюры** («Фото 1–3»), не реальные изображения.
- **Контекстная помощь** (см. выше): стиль, хорошее фото, что получится, Галерея одной карточкой.
- 8 готовых стилей: **3 бесплатных**, **5 × 100 ₽**.
- Карточки → **bottom sheet** с локальным выбором фото через Flutter (`image_picker`).
- В modal после выбора показывается preview и статус **«Фото выбрано»** (preview только в UI, до закрытия окна).
- **Flutter** (бесплатный сценарий) отправляет выбранное фото на backend через **`multipart/form-data`** (`style_id`, `style_title`, `photo`).
- **Backend** валидирует **JPEG / PNG / WebP** и размер до **10 MB**; исходное фото на сервере не сохраняется.
- **Flutter Photoshoots** принимает успешный backend response с **`image_urls`** (`PhotoshootGenerateResponse`).
- По умолчанию **`ENABLE_PHOTOSHOOT_GENERATION=false`**: после валидации backend возвращает **`501`**; Flutter показывает «Обработка фото будет добавлена позже» (Gemini не вызывается) — **safe mode проверен**.
- При **`ENABLE_PHOTOSHOOT_GENERATION=true`**: Gemini → **`200`** с `image_urls` (1–3) → modal закрывается → результаты в **Галерею** → SnackBar **«Фотосессия готова»** → переход на вкладку **Галерея**. После перезагрузки истории с backend записи с общим **`photoshoot_id`** отображаются **одной карточкой-группой**.
- **Controlled 3-output test пройден** через Flutter UI (см. §11); после теста **`ENABLE_PHOTOSHOOT_GENERATION=false`**, **`PHOTOSHOOT_OUTPUT_COUNT=1`** (safe mode возвращён).
- Платные фотосессии: Flutter пока **не отправляет** фото на backend → **«Оплата будет добавлена позже»**; backend **дополнительно защищён** — платный `style_id` → **`402`** без Gemini/Storage/`generations`, даже при `ENABLE_PHOTOSHOOT_GENERATION=true`.
- Запись в backend **`generations`** выполняется; **оплата** и **«Своя фотосессия»** — следующие этапы (см. roadmap).

### Галерея

- При старте: **`GET /generations`** (тихо при ошибке backend).
- **Группировка фотосессий:** записи с одинаковым non-null **`photoshoot_id`** → **одна карточка** с несколькими preview; legacy / обычные записи с **`photoshoot_id=null`** — **отдельные карточки**.
- Скрывает служебные **debug**-описания в UI.
- Новые результаты сессии — **сверху** после **Создать** или фотосессии.
- **«Очистить»** — только локальный список; **Supabase не удаляется**.
- **Safe mode после тестов:** **`ENABLE_PHOTOSHOOT_GENERATION=false`**, **`PHOTOSHOOT_OUTPUT_COUNT=1`**.

### Продуктовые UX-требования (дальше)

| Приоритет | Требование | Статус |
|-----------|------------|--------|
| — | **First-run onboarding** (5 экранов, «Далее» / «Пропустить» / «Начать») | ✅ |
| — | **Контекстная помощь** — «Создать» и «Фотосессии» | ✅ |
| — | **Каталог карточек фотосессий** — «3 фото», цена/«Бесплатно», placeholder preview, рекомендации и примеры-заглушки в sheet | ✅ |
| — | **«Создать» — UI-каркас фото** (picker, preview, убрать фото; без backend) | ✅ |
| 1 | **Реальные curated-примеры** на карточках и в sheet (вместо gradient placeholders) | план |
| 2 | **«Создать» — backend:** фото + **описание** → **одно** изображение + запись в **Галерею** | план |
| 3 | **«Своя фотосессия»** — фото + свои пожелания + текст-помощник | план |
| 4 | **Visual branding / art direction** для каталога фотосессий | план |
| 5 | **Помощь для «Пакетов»** — после проработки цен и оплаты | план |
| 6 | **Оплата** платных фотосессий (RuStore + backend payment verification) | план |

**Аудитория:** обычные пользователи **40–60+**; простой UI, крупные действия; в UI **не** prompt / tokens / credits.

### Пакеты

| Цена | Объём |
|------|--------|
| 199 ₽ | 25 изображений |
| 499 ₽ | 100 изображений |
| 1199 ₽ | 250 изображений |

- Кнопка «Скоро»; **RuStore** не подключён.

### Профиль

- **С Supabase config:** форма входа/регистрации, карточка «Вы вошли», кнопка **Выйти**; мягкие SnackBar при ошибках.
- **Без Supabase config:** placeholder «Вход недоступен в этом запуске» + подсказка про `dart-define`.
- Блок **Безопасность** при включённом Supabase.

---

## 7. Supabase

### Таблицы

| Таблица | Назначение |
|---------|------------|
| `profiles` | Пользователь, `free_generations_used`, `paid_credits` |
| `generations` | История: prompt, `image_url`, `payment_type` |
| `credit_transactions` | Аудит начислений/списаний |

### Подключение

- Backend → **REST API + httpx** (`app/services/supabase_service.py`).
- **Не использовать** Python-пакет **`supabase`** (конфликт зависимостей).
- Миграции: `backend/db/migrations/`.
- **`backend/.env`** — реальные ключи; **не в git** (есть `.env.example`).

---

## 8. UX правила

**Не использовать в видимом UI:** промпт, кредиты, токены.

**Использовать:** описание, идея, изображение, генерации, пакеты генераций, фотосессии.

См. [app_design_strategy.md](app_design_strategy.md).

---

## 9. Что сейчас demo / заглушка

- **Gemini** в production-потоке (по умолчанию mock / placehold.co; ручной тест с ключом — отдельно).
- **Оплата** платных фотосессий и RuStore Billing.
- **Подтверждение email**, восстановление пароля (см. roadmap).
- Убрать **development `TEST_USER_ID` fallback** перед production.
- **Удаление** изображений из backend.
- **Production security** (debug routes, CORS, RLS audit).

---

## 10. Что важно перед production

- Удалить или **защитить** `/debug/*`.
- Убрать **`TEST_USER_ID` fallback**; обязательный Bearer в non-development.
- Доработать auth: email confirmation UX, восстановление пароля.
- Подключить **реальные платежи** (RuStore).
- Ограничить **CORS** доверенными origin.
- Проверить **RLS** policies в Supabase.
- **Не коммитить** `.env` и service role key.
- Включить **реальную генерацию** (Gemini) в production — после проверки стоимости/лимитов и production cleanup.

---

## 11. Последняя стабильная точка

После подключения **storage helper** к **`POST /generate`** (data URL → Supabase Storage → `public_url`) выполнен **полный контрольный прогон** проекта.

### Текущий безопасный режим

- **`IMAGE_PROVIDER=mock`** — mock-генерация по умолчанию; Storage не вызывается для обычных запросов
- **`ENABLE_CREDIT_CONSUMPTION=false`** — без списания генераций и без записи в `generations` через `/generate`
- **`ENABLE_PHOTOSHOOT_GENERATION=false`** — photoshoot Gemini выключен по умолчанию (защита от случайных кликов во Flutter)
- **Gemini provider** реализован и **успешно проверен вручную** (Gemini → Storage → `public_url` → Галерея); для ежедневной разработки остаётся **`mock`**
- **Gemini photoshoot** реализован и **успешно проверен вручную** (backend + Flutter Gallery); по умолчанию выключен через **`ENABLE_PHOTOSHOOT_GENERATION=false`**

### Ручной Gemini-тест (пройден)

| Шаг | Результат |
|-----|-----------|
| Временно `IMAGE_PROVIDER=gemini` | ✅ |
| `ENABLE_CREDIT_CONSUMPTION=false` (без списания) | ✅ |
| Gemini вернул реальное изображение | ✅ |
| Backend загрузил в bucket **`generated-images`** | ✅ |
| Frontend получил **`image_url` как `public_url`** | ✅ |
| **Галерея** показала реальную картинку | ✅ |
| После теста **`IMAGE_PROVIDER=mock`** | ✅ |

### Ручной Gemini photoshoot test (пройден)

| Шаг | Результат |
|-----|-----------|
| Временно `ENABLE_PHOTOSHOOT_GENERATION=true` | ✅ |
| `PHOTOSHOOT_OUTPUT_COUNT=1` | ✅ |
| `POST /photoshoots/generate` принял uploaded photo | ✅ |
| Gemini вернул photoshoot image | ✅ |
| Backend загрузил в bucket **`generated-images`** | ✅ |
| Response содержит **`image_urls`** с **`public_url`** | ✅ |
| После теста **`ENABLE_PHOTOSHOOT_GENERATION=false`** | ✅ |

### Ручной Flutter photoshoot-to-gallery test (пройден)

| Шаг | Результат |
|-----|-----------|
| `ENABLE_PHOTOSHOOT_GENERATION=true` + Flutter UI (бесплатная фотосессия) | ✅ |
| Backend вернул **`image_urls`** | ✅ |
| Flutter добавил результат в **Галерею** (описание «Фотосессия: …») | ✅ |
| SnackBar **«Фотосессия готова»** + переход на вкладку **Галерея** | ✅ |
| После теста **`ENABLE_PHOTOSHOOT_GENERATION=false`** (safe mode) | ✅ |
| При **`false`**: placeholder «Обработка фото будет добавлена позже» | ✅ |

### Controlled 3-output photoshoot test (пройден)

| Шаг | Результат |
|-----|-----------|
| `ENABLE_PHOTOSHOOT_GENERATION=true`, **`PHOTOSHOOT_OUTPUT_COUNT=3`** | ✅ |
| Flutter UI: один uploaded photo → **3 generated photos** | ✅ |
| Backend сохранил **3 файла** в Supabase Storage (`photoshoots/…`) | ✅ |
| Backend записал **3 записи** в **`generations`** | ✅ |
| **`GET /generations`** вернул **3 свежие** photoshoot-записи с общим **`photoshoot_id`** | ✅ |
| **Flutter Gallery** группирует их в **одну карточку** с 3 изображениями | ✅ |
| После теста **`ENABLE_PHOTOSHOOT_GENERATION=false`**, **`PHOTOSHOOT_OUTPUT_COUNT=1`** | ✅ |
| **`git status`** чистый после теста | ✅ |

### Проверено — Backend

| Проверка | Результат |
|----------|-----------|
| `python -m compileall app` | ✅ проходит |
| `GET /health` | ✅ работает |
| `GET /debug/config` | ✅ работает |
| `GET /generations` | ✅ работает |
| `POST /debug/storage-test` | ✅ работает |
| `POST /debug/storage-image-test` | ✅ работает |

Дополнительно: **`POST /generate`** с **`IMAGE_PROVIDER=gemini`** — полный flow Gemini → Storage → **`public_url`** проверен вручную; **`GET /generations`** / **Галерея** отображают Storage URL. **`POST /photoshoots/generate`** + Flutter — photoshoot flow Gemini → Storage → **`generations`** → **Галерея** (в т.ч. после перезапуска через **`GET /generations`**).

### Проверено — Frontend (Flutter web)

| Проверка | Результат |
|----------|-----------|
| `flutter analyze` | ✅ проходит |
| Flutter web запуск (`flutter run -d chrome`) | ✅ запускается |
| Mock generation (вкладка **Создать**) | ✅ работает |
| Fallback-preview при ошибке загрузки картинки | ✅ отображается |
| Кнопка **«Открыть в Галерее»** | ✅ работает |
| **Галерея** — загрузка истории | ✅ грузится |
| **Фотосессии** — выбор фото и upload на backend | ✅ работают |
| **Галерея** — группировка фотосессий по **`photoshoot_id`** | ✅ |
| **First-run onboarding** (5 экранов) | ✅ |
| **Контекстная помощь** — вкладки **Создать** и **Фотосессии** | ✅ |
| Бесплатная фотосессия (safe mode) → «Обработка фото будет добавлена позже» | ✅ |
| Платная фотосессия → «Оплата будет добавлена позже» | ✅ |
| **Профиль** без `--dart-define` (fallback / demo mode) | ✅ работает |
| **Профиль** с `--dart-define` (Supabase Auth mode) | ✅ работает |

**Авторизация:** вход через Профиль + Bearer token → **Создать** / **Галерея** проверены в обоих режимах (с Supabase config и через development fallback `TEST_USER_ID`).

### Инфраструктура

- **Supabase Storage:** bucket `generated-images`; Gemini → Storage → **`public_url`** проверен вручную
- **Flutter web** + backend на `127.0.0.1:8000`

### Перед следующим большим этапом

- **`git status`** должен быть **чистым** (после controlled test — проверено)
- **`backend/.env`** не коммитить; после test: **`ENABLE_PHOTOSHOOT_GENERATION=false`**, **`PHOTOSHOOT_OUTPUT_COUNT=1`** (safe mode)
- Следующие шаги (UX, см. [roadmap.md](roadmap.md)): **реальные примеры на карточках** → **backend для фото+описание на «Создать»** → **своя фотосессия** → **art direction** → **помощь для «Пакетов»** → **RuStore / оплата**; затем product mode **`PHOTOSHOOT_OUTPUT_COUNT=3`**

---

## Связанные документы

| Документ | Зачем |
|----------|--------|
| [api_contract.md](api_contract.md) | HTTP API |
| [app_design_strategy.md](app_design_strategy.md) | UX, вкладки |
| [roadmap.md](roadmap.md) | Этапы |
| [demo_script.md](demo_script.md) | Сценарий демо |
| [flutter_auth_setup.md](flutter_auth_setup.md) | Запуск Flutter с Supabase Auth |
| `frontend/README.md` | Запуск Flutter |
| `backend/README.md` | Env, endpoints |
