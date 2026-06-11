# Project Status — AI Image App

Краткий технический статус для нового чата в Cursor или разработчика. Обновляйте при смене архитектуры или крупных этапов.

---

## 1. Краткое описание

- **Мобильное / кроссплатформенное приложение** на **Flutter** (сейчас основная разработка UI — **Chrome / web**).
- **Backend** — **FastAPI**, генерация изображений, учёт генераций, история.
- **Supabase (PostgreSQL)** — профили, история генераций (`generations`), транзакции (`credit_transactions`).
- Проект в стадии **MVP / demo-mode**: mock-генерация, заглушки оплаты и загрузки фото, dev-пользователь `TEST_USER_ID`.
- **Актуальный UI (UX-redesign):** burger/drawer; welcome-**Главная**; пути **Фото по шаблону → Свой запрос → Готовые фото** и **Фотосессии → Готовые фото**; **Купить** при нехватке баланса; мягкие подсказки при нуле. См. [navigation_redesign_plan.md](navigation_redesign_plan.md).
- **Расширенные промпты (✅):** [app_prompts.md](app_prompts.md) — **17** шаблонов (**Фото по шаблону**), **15** стилей (**Фотосессии**), **5** чипов (**Своя фотосессия**); во Flutter — `frontend/lib/data/app_prompts.dart`; шаблон → длинный текст в **Свой запрос**; фотосессия → `description` в **`POST /photoshoots/generate`**.
- **Мобильный UX-polish (✅):** баланс **убран из верхней панели** экранов; шапка лёгкая (**burger + заголовок + опционально «Помощь»**); подзаголовки на полную ширину; компактные карточки шаблонов и фотосессий; разделённые категории шаблонов; улучшен **Свой запрос** (preview фото, поле описания, блок «Что получится»); спокойный блок баланса при наличии платных фото; preview фотосессий без overflow; chips-категории на **Фотосессии**. Баланс — в **drawer**, **Профиле**, **Купить** и отдельных info-блоках на экранах. Проверено на физическом телефоне после polish; `flutter analyze` без ошибок.
- **Demo / mock (committed `.env`):** `IMAGE_PROVIDER=mock`, `ENABLE_CREDIT_CONSUMPTION=false`, `ENABLE_PHOTOSHOOT_GENERATION=false` — безопасная разработка; полный цикл со списанием — временный env из [demo_release_checklist.md](demo_release_checklist.md) § A.
- **`IMAGE_PROVIDER`**: `mock` (по умолчанию, безопасный режим) → **`MockImageProvider`**; `gemini` → **`GeminiImageProvider`** (реализован в backend, но не используется по умолчанию).

### Авторизация (текущий статус)

- **Flutter, вкладка Профиль:** базовая авторизация через Supabase Auth (вход / регистрация / выход).
- **Auth loading states:** для входа, регистрации и выхода есть локальные состояния загрузки; во время выполнения auth-действия кнопки временно disabled (и поля формы временно недоступны при входе/регистрации).
- **Ошибки для пользователя:** технические ошибки Supabase не показываются; вместо этого отображаются мягкие пользовательские сообщения.
- **Supabase Auth во Flutter** включается **только** при запуске с **`--dart-define=SUPABASE_URL=...`** и **`--dart-define=SUPABASE_ANON_KEY=...`** (`Supabase.initialize` в `main.dart`).
- **Без dart-define:** авторизация в UI недоступна; приложение работает в **demo / development fallback** (`TEST_USER_ID` на backend).
- **После входа:** access token из `AuthService` передаётся в **`ApiService.setAccessToken(...)`** → backend получает **`Authorization: Bearer`**; перезагружаются **баланс** и **Галерея** (`GET /balance`, `GET /generations`).
- **После выхода:** токен очищается; локальная **Галерея** и баланс в UI сбрасываются; без токена Flutter **не** запрашивает историю (избегает смешивания с dev `TEST_USER_ID` при настроенном Supabase).
- **Backend:** `get_current_user()` валидирует Bearer через Supabase Auth REST (`/auth/v1/user`) → **`CurrentUser { id, email }`**.
- **Profiles auto-create/sync:** backend автоматически вызывает **`ensure_profile_exists`** для пользователя на **`GET /generations`**, **`GET /balance`** и **`POST /generate`**; если профиля нет, создаёт строку в `profiles` (`free_generations_used=0`, `paid_credits=0`, `paid_image_generations=0`, `paid_photoshoots=0`) и мягко синхронизирует `email` без перезаписи уже заполненного значения.
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
| Android emulator / debug APK | `http://10.0.2.2:8000` (alias хоста ПК; `--dart-define=API_BASE_URL=...` при сборке) |
| Физический Android-телефон (LAN) | IP ПК в Wi‑Fi, напр. `http://192.168.31.242:8000` — **обязателен** `--dart-define=API_BASE_URL=...` |

- **Debug APK на эмуляторе (✅):** `flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8000` → `adb install -r`; backend **`--host 0.0.0.0 --port 8000`**. См. [demo_release_checklist.md](demo_release_checklist.md).
- **Debug APK на физическом телефоне (✅, UX-redesign + UX-polish):** `flutter build apk --debug --dart-define=API_BASE_URL=http://192.168.31.242:8000` → `adb install -r`; backend в **demo mock-режиме** (`ENABLE_CREDIT_CONSUMPTION=true`, `IMAGE_PROVIDER=mock`, `ENABLE_PHOTOSHOOT_GENERATION=true`, `PHOTOSHOOT_OUTPUT_COUNT=3`) с **`--host 0.0.0.0 --port 8000`**. Проверены: **Главная**, drawer, **Фото по шаблону** → **Свой запрос**, фото + генерация, **Фотосессии**, **Купить**, **Готовые фото**, **Помощь**; после UX-polish — без balance chip в шапке, без yellow/black overflow и RenderBox crash на основных экранах. См. [demo_release_checklist.md](demo_release_checklist.md) § **D**, § **I**.
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
- **Полный реальный Gemini smoke test (safe mode) — успешно пройден** (временные env, без изменения committed `.env`):
  - `ENABLE_CREDIT_CONSUMPTION=false`
  - `IMAGE_PROVIDER=gemini`
  - `ENABLE_PHOTOSHOOT_GENERATION=true`
  - `PHOTOSHOOT_OUTPUT_COUNT=3`
  - Проверены все три flow: **`POST /generate`**, **`POST /generate-with-photo`**, **`POST /photoshoots/generate`** — **работают**.
  - Gemini → Supabase Storage (`generated-images`) → **`public_url`** в response; результаты **появляются в Галерее** (локально сразу + через **`GET /generations`** при включённом consumption).
  - В safe mode **баланс не списывается** (`ENABLE_CREDIT_CONSUMPTION=false`); запись в **`generations`** через consume-path **не выполняется**.
  - После теста env **возвращены** на безопасные значения: `IMAGE_PROVIDER=mock`, `ENABLE_PHOTOSHOOT_GENERATION=false` (см. [gemini_test_checklist.md](gemini_test_checklist.md)).
- **`POST /photoshoots/generate`** при **`ENABLE_PHOTOSHOOT_GENERATION=true`** + **`IMAGE_PROVIDER=gemini`**: **3** последовательных вызова Gemini → Storage → **`image_urls`**; при `ENABLE_CREDIT_CONSUMPTION=true` — запись в **`generations`** (`prompt`: `Фотосессия: …`, общий **`photoshoot_id`**).
- **`POST /debug/storage-test`** (development only) — **успешно проверен**: backend загружает маленький in-memory тестовый файл в Storage и возвращает **`public_url`**; **`public_url` проверен вручную** в браузере.
- **`POST /debug/storage-image-test`** (development only) — **успешно проверен**: вызывает **`upload_generated_image_data_url`** с тестовым **1×1 PNG** data URL; **`public_url` открыт вручную** в браузере.
- **Следующий этап:** более глубокая проверка качества на разных фото; edge cases ошибок Gemini; **RuStore** / production deploy. Для ежедневной разработки остаётся **`IMAGE_PROVIDER=mock`**.
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
| POST | `/generate-with-photo` | Генерация по **фото + описанию** (multipart); mock / Gemini; списание как у `/generate`; **Gemini smoke test пройден** (safe mode) |
| GET | `/generations` | История генераций (`?limit=1..100`, по умолчанию 20) |
| GET | `/balance` | Баланс: free remaining + `paid_image_generations` + `paid_photoshoots` |

### `POST /generate`

- **`IMAGE_PROVIDER=mock`** (по умолчанию, **текущий безопасный режим разработки**) → `MockImageProvider`: placeholder `image_url` (`placehold.co`); Storage **не используется**.
- **`IMAGE_PROVIDER=gemini`** + `GEMINI_API_KEY` → `GeminiImageProvider`: Gemini API → data URL; **`POST /generate`** загружает data URL в Storage и возвращает **`public_url`**. **Ручной тест успешно пройден** (см. §11).
- Для ручного Gemini-теста использовать **`ENABLE_CREDIT_CONSUMPTION=false`** — без списания генераций из Supabase.
- После любого Gemini-теста **обязательно** вернуть **`IMAGE_PROVIDER=mock`** (см. [gemini_test_checklist.md](gemini_test_checklist.md)).
- В backend auth helper `get_current_user()` поддерживает `Authorization: Bearer <token>` через Supabase Auth REST (`/auth/v1/user`).
- Если заголовка нет в development — остаётся fallback на `TEST_USER_ID`; в non-development без токена — **`401`** `Authorization required`.
- **`/debug/*`:** только при `ENVIRONMENT=development` (иначе **`404`**); **`POST /debug/add-balance`** начисляет баланс **текущему** пользователю (Bearer или dev fallback).
- **`ENABLE_CREDIT_CONSUMPTION=false`** (безопасный режим тестов): **не списывает** генерации из Supabase и не выполняет запись в `generations`.
- **`ENABLE_CREDIT_CONSUMPTION=true`**: профиль по user id (из Bearer token или dev fallback `TEST_USER_ID`), auto-sync профиля через `ensure_profile_exists`, списание free/paid, запись в Supabase (`generations`, `credit_transactions`).

### `POST /photoshoots/generate`

- Backend принимает `multipart/form-data`: `style_id`, `style_title`, `photo`.
- **Catalog стилей** (`app/services/photoshoot_styles.py`): backend валидирует `style_id`, хранит `title`, `price_rub`, `is_free`, `output_count=3`, `instruction` для Gemini-генерации.
- **`PhotoshootService`** (`app/services/photoshoot_service.py`): выбор провайдера по **`IMAGE_PROVIDER`**:
  - **`mock`** + **`ENABLE_PHOTOSHOOT_GENERATION=true`** → **`MockPhotoshootProvider`**: `placehold.co` URLs без Gemini/Storage; запись в **`generations`**; для **безопасной проверки списания** `paid_photoshoots` без реального Gemini.
  - **`gemini`** → **`GeminiPhotoshootProvider`**: uploaded photo + `style.instruction` → Gemini → Storage (`photoshoots/…`) → **`public_url`**.
- **Качество Gemini (backend):** общий модуль **`app/services/gemini_quality_instructions.py`** — усиленные **instruction** для **`/generate`**, **`/generate-with-photo`**, **`/photoshoots/generate`**: одно цельное изображение, без коллажа/сетки/contact sheet, без лишних вариантов на одном холсте; аккуратные лица и анатомия; сохранение узнаваемости при генерации с фото; фотосессия = **3 отдельных** последовательных вызова (по одному кадру). **Mock mode** не изменён. **RuStore** не подключён.
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

Примеры: `/debug/config`, `/debug/supabase`, `/debug/storage-test`, `/debug/storage-image-test`, `/debug/profile`, `/debug/history`, `/debug/consume-generation`, `/debug/add-credits`, `/debug/add-balance`.

Подробнее: [api_contract.md](api_contract.md), [dev_notes.md](dev_notes.md).

---

## 6. Frontend — навигация и разделы

**Основная навигация:** **burger/drawer** слева сверху; **баланс** в drawer, **Профиле**, **Купить** и отдельных info-блоках на экранах (**не** в верхней панели). Шапка экранов: **burger + заголовок + подзаголовок + опционально «Помощь»**. Нижняя tab bar **убрана**. `IndexedStack` в `MainShell`.

| Раздел (drawer) | Было | Статус |
|-----------------|------|--------|
| **Главная** | — | Welcome; **«Начать создавать»** → **Фото по шаблону** |
| **Фото по шаблону** | — | Шаблоны **по категориям**; визуальные placeholder; → **Свой запрос** |
| **Фотосессии** | вкладка | Подборки стилей; **«Своя фотосессия»** сверху; → **Готовые фото** |
| **Трендовые фотосессии** | — | Пункт меню → прокрутка к трендам на **Фотосессии** |
| **Свой запрос** | **Создать** | Фото → описание → **«Создать фото»** → **Готовые фото** |
| **Готовые фото** | **Галерея** | Success-блок, быстрые действия, бейдж «Новое», группировка фотосессий |
| **Купить** | **Пакеты** | 1 фото = 10 ₽; 1 фотосессия = 100 ₽; mock top-up (dev) |
| **Профиль** | вкладка | Личный кабинет: вход, **Фото / Фотосессии / Бесплатные фото** |
| **Помощь** | — | Hub + контекстная помощь по разделам |

**Пользовательские пути:**

1. **Главная** → **Фото по шаблону** → **Свой запрос** → **Готовые фото**
2. **Фотосессии** → создание → **Готовые фото**
3. **Купить** — при нехватке баланса (диалоги и info-блоки)

Принцип «от простого к сложному»: шаблоны → фотосессии → свой запрос. См. [navigation_redesign_plan.md](navigation_redesign_plan.md), [app_design_strategy.md](app_design_strategy.md).

### First-run onboarding и контекстная помощь

**First-run onboarding (реализовано, обновлено под новую навигацию):**

- При **первом запуске** — **5 экранов** (`onboarding_completed` в `shared_preferences`).
- На каждом экране: **«Далее»**, **«Пропустить»**; на последнем — **«Начать»**; контент прокручивается на маленьких экранах.
- Темы: **Добро пожаловать** → **Начните с шаблона** → **Попробуйте фотосессию** → **Свой запрос** → **Меню слева сверху**.
- Визуальные preview-заглушки вместо длинных текстов; без старых названий «Создать», «Пакеты», «Галерея».
- Debug (только dev): **Профиль** → «Показать обучалку снова».

**Контекстная помощь по разделам (реализовано):**

| Раздел | Автопоказ | Ручной доступ | Ключ prefs |
|--------|-----------|---------------|------------|
| **Главная** | Нет | Кнопка **«Помощь»** | — |
| **Фото по шаблону** | Нет | Кнопка **«Помощь»** | — |
| **Свой запрос** | При **первом** открытии | Кнопка **«Помощь»** | `create_help_seen` |
| **Фотосессии** | При **первом** открытии | Кнопка **«Помощь»** | `photoshoots_help_seen` |
| **Купить** | Нет | Кнопка **«Помощь»** | — |

- Диалоги: `PagedHelpDialog` (пошагово, **«Далее»** / **«Понятно»**) или `PacksHelpDialog` для **Купить**.
- **Помощь** hub: **Главная**, **Фото по шаблону**, **Фотосессии**, **Свой запрос**, **Купить**.

### Продуктовые требования (руководство, план)

| Область | Требование | Статус |
|---------|------------|--------|
| **Качество генераций** | Красивые, аккуратные результаты; без кривых лиц, искажений, лишних людей, коллажей | ✅ backend instructions (`gemini_quality_instructions.py`) |
| **Идеи на «Создать»** | Категории + режимы **«Без фото»** / **«С фото»**; кликабельные идеи → поле описания | ✅ UI |
| **Время генерации / ожидание** | Блокирующее модальное окно с обратным отсчётом (**«Создать»** ~60 с, **«Фотосессии»** ~120 с), затемнённый фон | ✅ |
| **Стартовый баланс** | Динамический баннер на **«Создать»** (`_CreateBalanceInfoCard`) из `GET /balance` | ✅ |
| **Показ баланса** | **Drawer**, **Профиль**, **Купить**, info-блоки на **Свой запрос** / **Фотосессии**; **не** в верхней панели; подписи **Фото / Фотосессии / Бесплатные** | ✅ |
| **Нулевой баланс (мягкий UX)** | Диалоги + info-блоки → **Купить**; без технических `402` / credits в UI | ✅ |
| **Готовые фото — next actions** | Success-блок, «Что сделать дальше?», бейдж «Новое» | ✅ |
| **Генерация при балансе** | Free → paid images; фотосессии — `paid_photoshoots`; списание проверено вручную (см. § **Проверка списаний**) | ✅ |
| **«Как получить хороший результат»** | Режимы **«Без фото»** / **«С фото»**; примеры (человек / предмет); общие советы; примеры **не** кликабельны | ✅ |
| **Мин. пополнение «Своя сумма»** | Мин. **10 ₽** (1 изображение = 10 ₽); макс. **100 000 ₽** | ✅ |
| **Русский ввод на «Свой запрос»** | **Chrome:** кириллица ✅. **Android emulator / физический телефон:** зависит от раскладки клавиатуры; блокировки в приложении не найдено | ✅ |

Подробнее: [app_design_strategy.md](app_design_strategy.md), [roadmap.md](roadmap.md).

### Качество генераций (backend, реализовано)

- Модуль **`app/services/gemini_quality_instructions.py`** оборачивает пользовательское описание **instruction** для Gemini (не в UI).
- **Обычная генерация:** одно законченное изображение; без коллажа, сетки, contact sheet и нескольких вариантов на одном холсте; реалистичные пропорции; аккуратные лица; нормальные руки/пальцы; естественный свет; без текста на кадре, если пользователь явно не просил.
- **С фото:** сохранение узнаваемости человека/объекта; без искажения лица; фон/стиль/атмосфера меняются по запросу, без ломки объекта.
- **Фотосессии:** **3 отдельных** последовательных вызова Gemini (по одному кадру); единый стиль по `style_title`; не triptych на одном холсте.
- **Безопасность:** при **502** (Gemini не вернул изображение) или ошибке Storage — **баланс не списывается**, запись в **`generations`** не создаётся.
- **Mock mode** без изменений.

### Ожидание генерации (модальное окно, реализовано)

Во время реального запроса на backend (**«Создать»** по описанию; **бесплатная фотосессия** с отправкой фото) показывается **блокирующее модальное окно** по центру экрана; **фон приложения затемнён** — пользователь не может случайно нажать другие действия.

| Вкладка | Заголовок | Подзаголовок | Обратный отсчёт |
|---------|-----------|--------------|-----------------|
| **Создать** | «Создаём изображение» | «Обычно это занимает до минуты.» | **60 → 0** сек. (*«Осталось примерно: N сек.»*) |
| **Фотосессии** (бесплатно, запрос на backend) | «Создаём фотосессию…» | «Обычно это занимает около 1–2 минут.» | **120 → 0** сек. |

**Поведение:**

- Backend вернул результат **раньше** — окно **закрывается сразу**.
- Backend вернул **ошибку** — окно закрывается, показывается **существующее** сообщение об ошибке (без технических деталей).
- Таймер дошёл до **0**, запрос **ещё идёт** — окно **не закрывается**; текст: *«Почти готово, ждём результат...»*
- **Платные** фотосессии, **«Своя фотосессия»**, выбранное фото на **«Создать»** без отправки на backend — **без** этого modal (поведение как раньше: SnackBar / placeholder).
- Виджет: `GenerationProgressDialog` (`frontend/lib/widgets/generation_progress_dialog.dart`); таймер очищается при закрытии.

**Цель UX:** пользователь видит, что приложение **работает**, и не думает, что оно **зависло**.

### Баланс пользователя (backend, реализовано)

**Миграция:** `backend/db/migrations/003_add_profile_balance_fields.sql` — в `profiles`:

- `paid_image_generations` (default 0) — платные **изображения**
- `paid_photoshoots` (default 0) — платные **фотосессии**
- `paid_credits` **сохранено** (legacy / текущий credit consumption path)

**`GET /balance`** (Bearer или dev `TEST_USER_ID`):

```json
{
  "free_generations_limit": 3,
  "free_generations_used": 0,
  "free_generations_remaining": 3,
  "paid_image_generations": 0,
  "paid_photoshoots": 0,
  "consumption_enabled": false
}
```

- `free_generations_remaining = max(FREE_GENERATIONS_LIMIT - free_generations_used, 0)`
- `consumption_enabled` — зеркало `ENABLE_CREDIT_CONSUMPTION` (для демо-режима в UI)
- **`ensure_profile_exists`** перед ответом; Supabase timeout → **`503`**
- **Списание (при `ENABLE_CREDIT_CONSUMPTION=true`):**
  - **`POST /generate`:** сначала free, затем `paid_image_generations`; нет баланса → **`402`** `insufficient_images`
  - **`POST /photoshoots/generate`:** −1 `paid_photoshoots`; нет → **`402`** `insufficient_photoshoots`
  - Успешный response содержит **`balance`** с актуальным состоянием
- При **`ENABLE_CREDIT_CONSUMPTION=false`** — списаний нет; UI показывает **демо-режим**

**Development:** **`POST /debug/add-balance`** (`ENVIRONMENT=development`) — JSON `{ paid_image_generations, paid_photoshoots }` добавляет к профилю; ответ как `GET /balance`.

**Flutter:** баланс в **drawer**, **Профиль**, **Купить**, info-блоках на **Свой запрос** / **Фотосессии** (не в шапке); обновление после генерации / покупки; **402** → мягкий диалог с переходом в **«Купить»** (реальный RuStore — не подключён).

### Проверка списаний и mock-фотосессии (ручная, успешно)

**Условия теста:** временный запуск backend с `ENABLE_CREDIT_CONSUMPTION=true` (без изменения committed `.env`); пополнение через **`POST /debug/add-balance`** в development.

**Обычные изображения (`POST /generate`):**

- При `ENABLE_CREDIT_CONSUMPTION=true` сначала списываются **бесплатные генерации** (`free_generations_remaining` уменьшается).
- После `free=0` списываются **`paid_image_generations`**.
- Успешный response содержит актуальный объект **`balance`**.
- При нулевом балансе — **`402`** `insufficient_images` (списание не выполняется).

**Генерация по фото (`POST /generate-with-photo`, проверено):**

- При `ENABLE_CREDIT_CONSUMPTION=true`, `IMAGE_PROVIDER=mock`: mock `image_url`, списание **`paid_image_generations`** (если free=0), **`balance`** в response.
- Порядок: проверка баланса → генерация → списание; при **502** баланс **не уменьшается**.
- Flutter: фото + описание → multipart; **Галерея** и баланс обновляются.

**Mock-фотосессия (`POST /photoshoots/generate`):**

- При `ENABLE_CREDIT_CONSUMPTION=true`, `ENABLE_PHOTOSHOOT_GENERATION=true`, **`IMAGE_PROVIDER=mock`**:
  - Gemini **не вызывается**; backend возвращает mock **`image_urls`** (`placehold.co`).
  - **`paid_photoshoots`** уменьшается на **1** после успешной генерации.
  - Response содержит актуальный **`balance`**.
  - Результаты сохраняются в **`generations`** с общим **`photoshoot_id`** и `prompt`: **`Фотосессия: <style.title>`**.

**Flutter UI (проверено в flow):**

- Баланс обновляется после генерации во вкладках **Профиль**, **Пакеты**, **Создать** (поле `balance` в response + `GET /balance`).
- **Галерея** показывает результат сразу после генерации / фотосессии.
- **Создать:** русский текст в поле описания → успешная генерация.
- **Фотосессии (Android emulator, debug):** автоматическое **тестовое фото** (`MockPhotoshootPhoto`) — без галереи устройства; progress dialog с затемнённым фоном.
- **Замечание:** один раз зафиксирован временный **Supabase timeout** (`503`); повторный запрос прошёл успешно.

### Оплата — backend foundation (реализовано, mock-verify проверен)

- **Backend foundation для RuStore** готов: таблица **`payment_transactions`** (migration **`004_create_payment_transactions.sql`**), **package catalog** на сервере (`package_catalog.py`), сервис **`payment_service.py`**.
- **Начисление баланса** (`paid_image_generations`, `paid_photoshoots`) выполняется **только на backend** после verification; **frontend не должен** сам начислять или «рисовать» купленный баланс без ответа API.
- **Development endpoint:** **`POST /payments/rustore/mock-verify`** — mock-проверка покупки без реального RuStore SDK/API.
- **Ручная проверка mock-verify (успешно):**
  - `package_499_mix` + новый `provider_payment_id` → **`status: verified`**, **+19** изображений, **+3** фотосессии, актуальный **`balance`** в response.
  - Повтор с тем же `provider_payment_id` → **`status: already_processed`**, **`added: {0, 0}`**, баланс **не** начисляется второй раз.
  - Неверный `package_id` → **`400`** `Unknown package_id`; пустой `provider_payment_id` → **`400`** `provider_payment_id is required`.
- **Защита от повторного начисления:** unique **`(provider, provider_payment_id)`** в БД + проверка перед credit.
- **Flutter payment flow:** вкладка **«Пакеты»** вызывает **`PaymentService`** (`frontend/lib/services/payment_service.dart`); UI не обращается к mock-verify напрямую. Сейчас: **`purchasePackageDemo`** / **`purchaseCustomAmountDemo`** → `ApiService` mock-verify → `PaymentResult`; баланс только из **`balance`** в response. Заготовки **`purchasePackageWithRuStore`** / **`purchaseCustomAmountWithRuStore`** — **не реализованы** (будущий RuStore SDK + backend verification).
- **«Своя сумма» (development):** через **`PaymentService.purchaseCustomAmountDemo`** → **`mock-verify-custom`**; retry на **503** в `ApiService`. **Реальный RuStore — future**.
- **Не подключено:** реальный RuStore Pay SDK, server-side RuStore API verification, production payment flow.
- **Android / RuStore readiness audit (✅):** проверены `applicationId`, SDK versions (Flutter defaults: min **24**, target/compile **36**), `MainActivity`, `INTERNET` в main manifest; release signing — debug keys (TODO keystore); deprecated **BillingClient** не использовать — целевой **RuStore Pay SDK**. Подробнее: [rustore_integration_plan.md](rustore_integration_plan.md).
- **Demo / release readiness (✅):** debug APK на **Android emulator** (`API_BASE_URL=http://10.0.2.2:8000`) и на **физическом телефоне** (`API_BASE_URL=http://192.168.31.242:8000`, redesigned UX) — см. [demo_release_checklist.md](demo_release_checklist.md). **Production release** (HTTPS deploy, signing, RuStore, тест на нескольких устройствах) — **future**.
- **Production safety audit (✅):** [production_safety_checklist.md](production_safety_checklist.md) — debug/mock endpoints **development-only**; `TEST_USER_ID` fallback только development; production требует **Authorization**; `/generate` в production без токена → **401**; frontend не начисляет баланс; CORS `*` — TODO для production origins; RLS — финальный review перед релизом.
- **Env / config checklist (✅):** [env_config_checklist.md](env_config_checklist.md) — режимы: safe local, demo mock+balance, Gemini safe test, production future; опасные комбинации; `backend/.env.example` с комментариями.
- **Backend deploy plan (✅, документ):** [backend_deploy_plan.md](backend_deploy_plan.md) — хостинг, production env, health/CORS/Supabase, шаги деплоя, Flutter API URL; **реального деплоя на сервер ещё нет**.

### Фото по шаблону

- Экран **«Шаблоны фото»** (в drawer — **«Фото по шаблону»**); подзаголовок на полную ширину; **без balance chip** в шапке.
- Шаблоны **сгруппированы по категориям** (для себя, для работы, для семьи, для продажи) — **визуально разделённые секции** с фоном; **компактные карточки** (крупнее preview, меньше пустоты).
- **17 шаблонов** с коротким описанием на карточке и **расширенным промптом** в [app_prompts.md](app_prompts.md) (лицо, возраст, свет, без искажений; для товаров — форма, фон, детали).
- **«Выбрать»** → **Свой запрос** с автозаполнением **полного** описания (`requestDescription` из `app_prompts.dart`) + SnackBar *«Описание добавлено. Осталось выбрать фото.»*
- Фото **не** подставляется автоматически; пользователь выбирает своё.
- Прямой вход в **Свой запрос** из drawer — **без** шаблона (пустой экран).

### Свой запрос (бывш. «Создать»)

- **Баннер баланса (реализовано):** `_CreateBalanceInfoCard` / `AppScreenBalanceCard` — free/paid из `GET /balance`; при наличии платного баланса — спокойный блок **«Ваш баланс»** (не warning); warning только при реальном нуле (free=0 и paid=0); демо-режим отдельно.
- **UX-polish:** компактные шаги; **preview** выбранного фото + «Изменить» / «Убрать»; поле описания как input; блок **«Что получится»**; подзаголовок без обрезки.
- Ввод **описания**; **`POST /generate`** — **текст → одно изображение**.
- **Модальное ожидание** при генерации — см. § **«Ожидание генерации»** (~60 с, затемнённый фон, таймер **60 → 0**).
- **«Попробуйте идею» (реализовано):** переключатель **«Без фото»** / **«С фото»** задаёт **режим** (синхронизирован с плашкой и блоком советов); категории в **раскрывающихся блоках**; идеи — **кликабельные** chips → поле описания.
  - **Без фото:** Природа, Город, Дом и интерьер, Праздник, Реклама и товар, Соцсети и аватар (по 3 идеи).
  - **С фото:** «Если на фото человек», «Если на фото предмет или другое».
- **Явный режим (реализовано):** плашка и UI зависят от **тумблера** «Без фото» / «С фото», а не от факта прикрепления файла; тумблер вверху экрана, в «Попробуйте идею» и «Как получить…» — **синхронизированы**; кнопка **«Создать»** / **«Создать по фото»**; modal с фото: *«Создаём изображение по вашему фото…»*.
- **Режим «С фото»:** фото **обязательно** для запуска; без файла — *«Сначала добавьте фото.»*; **«Убрать фото»** не переключает режим; режим **«Без фото»** всегда вызывает **`/generate`** (прикреплённое фото не используется).
- **Подсказки под описанием:** 3 кликабельных примера в режиме «С фото»; **«Как получить…»** — советы выбранного режима **вверху** блока.
- **«Фото для образа» (реализовано):** виден в режиме **«С фото»**; picker, preview, **«Убрать фото»**; endpoint по **режиму**: **`/generate-with-photo`** или **`/generate`**.
- **Списание:** при `ENABLE_CREDIT_CONSUMPTION=true` — проверка баланса → генерация → списание **только после успеха**; при ошибке Gemini (**502**) баланс **не уменьшается**.
- **Mock:** `IMAGE_PROVIDER=mock` → `placehold.co` без Gemini.
- **Нулевой баланс фото:** info-блок *«Фото на балансе закончились»* + **«Купить фото»** над кнопкой создания; диалог *«Фото закончились»* при попытке создать или **402**.
- **После успеха:** автопереход в **Готовые фото** (не только SnackBar).
- **Контекстная помощь:** готовые идеи, описание, фото, где результат.
- Результат: `Image.network` или **fallback-preview** при ошибке загрузки.
- Кнопка **«Открыть в Галерее»**.
- Frontend скрывает технические ошибки генерации: в UI показывается только понятное сообщение для пользователя.
- Ошибки backend/Gemini (и HTTP-детали) должны логироваться/обрабатываться на backend, без вывода технических деталей в UI.

### Фотосессии

- **Модальное ожидание** при бесплатной отправке на backend — см. § **«Ожидание генерации»** (~120 с); платные карточки и **501** safe mode — modal не блокирует лишние сценарии (мягкие сообщения как раньше).
- **План:** платная фотосессия только при оплате или наличии **фотосессий на балансе**; иначе — переход к пополнению (backend уже **402** для платных стилей без оплаты).
- **Intro-блок (реализовано):** подзаголовок на полную ширину; **`AppScreenBalanceCard`** (**Фото / Фотосессии**); chips-категории сверху (Популярное, Для себя, …); **компактные карточки**; preview серии из 3 фото **без overflow**; предупреждение при нулевом балансе → **Купить**.
- **Каталог карточек (реализовано, demo-ready):** gradient preview, **название**, **короткое описание** из [app_prompts.md](app_prompts.md) (2 строки в карточке, полнее в модалке), бейджи **«Бесплатно»** / **«100 ₽»**, **«3 фото»**, **рекомендация**; при генерации бесплатного/оплаченного стиля — **`description`** = расширенный style prompt (серия из 3 кадров).
- **Модалка фотосессии:** **«Что получится»** + **«Пример результата»** (3 gradient-placeholder: «Фото 1–3»); загрузка фото, **«Создать фотосессию»**.
- **Bottom sheet:** блок **«Что получится»**, **«Добавьте фото»** + подсказка, preview, **«Убрать фото»**, кнопка **«Создать фотосессию»**; без фото → *«Сначала добавьте фото.»*
- **Контекстная помощь** (см. выше): стиль, хорошее фото, что получится, Галерея одной карточкой; упоминание **«Своей фотосессии»** (UI есть, backend позже).
- **«Своя фотосессия» — промо-блок (реализовано):** заметный баннер **«Не нашли подходящий стиль?»** **сверху** экрана (не внизу каталога); кнопка **«Создать свой образ»** → dialog *«Скоро здесь можно будет описать свою фотосессию.»* **Backend не вызывается**, баланс **не списывается**.
- **Группировка стилей:** подборки **Популярное**, **Для себя**, **Для работы**, **Атмосферные** — всего **15** стилей.
- **3 бесплатных** (`studio_portrait`, `business_portrait`, `home_portrait`), остальные — **100 ₽**; backend-каталог расширен под все `style_id` (см. `photoshoot_styles.py`).
- Карточки → **bottom sheet** с локальным выбором фото через Flutter (`image_picker`).
- В modal после выбора показывается preview и статус **«Фото выбрано»** (preview только в UI, до закрытия окна).
- **Flutter** отправляет выбранное фото на backend через **`multipart/form-data`** (`style_id`, `style_title`, **`description`** — расширенный style prompt, `photo`).
- **Backend** валидирует **JPEG / PNG / WebP** и размер до **10 MB**; исходное фото на сервере не сохраняется.
- **Flutter Photoshoots** принимает успешный backend response с **`image_urls`** (`PhotoshootGenerateResponse`).
- По умолчанию **`ENABLE_PHOTOSHOOT_GENERATION=false`**: после валидации backend возвращает **`501`**; Flutter показывает «Обработка фото будет добавлена позже» (Gemini не вызывается) — **safe mode проверен**.
- При **`ENABLE_PHOTOSHOOT_GENERATION=true`**: mock или Gemini → **`200`** с **`image_urls`** (default **3**), **`output_count`**, **`photoshoot_id`** → все 3 изображения сразу в **Галерею** одной группой → SnackBar **«Фотосессия готова»**; списание **1** `paid_photoshoots` только после успеха.
- **`PHOTOSHOOT_OUTPUT_COUNT`:** default **3** (override через env для dev); mock возвращает **3 разные** `placehold.co` ссылки; Gemini — **3 последовательных** вызова, один **`photoshoot_id`**.
- **Нулевой баланс фотосессий:** info-блок *«Фотосессии на балансе закончились»* + **«Купить фотосессии»**; диалог при попытке создать или **402** → **Купить** (режим «Фото + фотосессии»).
- **После успеха:** переход в **Готовые фото**.
- Платные фотосессии: Flutter пока **не отправляет** фото на backend → **«Оплата будет добавлена позже»**; backend **дополнительно защищён** — платный `style_id` → **`402`** без Gemini/Storage/`generations`, даже при `ENABLE_PHOTOSHOOT_GENERATION=true`.
- Запись в backend **`generations`** выполняется для **готовых** стилей; **оплата** платных стилей — следующий этап; **backend для «Своей фотосессии»** — см. roadmap.

### Готовые фото (бывш. «Галерея»)

- **`GET /generations`**; loading / error / empty states.
- **После генерации:** автоматический переход с **success-блоком** («Фото готово» / «Фотосессия готова»); можно закрыть баннер.
- **«Что сделать дальше?»** — **Создать ещё фото** (шаблоны), **Сделать фотосессию**, **Купить ещё**; на пустом экране — компактные варианты.
- Свежий результат — бейдж **«Новое»**, подсветка карточки; группировка фотосессий по **`photoshoot_id`** сохранена.
- Карточки: **«Фото»** / **«Фотосессия»**, **«3 фото»**, **«Открыть»** / **«Открыть фотосессию»**; просмотр, скачивание, локальное скрытие.

### Продуктовые UX-требования (дальше)

| Приоритет | Требование | Статус |
|-----------|------------|--------|
| — | **First-run onboarding** (5 экранов, «Далее» / «Пропустить» / «Начать») | ✅ |
| — | **Контекстная помощь** — «Создать» и «Фотосессии» | ✅ |
| — | **Каталог карточек фотосессий** — «3 фото», цена/«Бесплатно», placeholder preview, рекомендации и примеры-заглушки в sheet | ✅ |
| — | **«Создать» — фото + описание** (`POST /generate-with-photo`) | ✅ |
| — | **«Своя фотосессия» — UI-каркас** (карточка, dialog, picker, пожелания, «Как описать лучше»; без backend) | ✅ |
| 1 | **Реальные curated-примеры** на карточках и в sheet (вместо gradient placeholders) | план |
| 2 | **«Создать» — backend:** фото + **описание** → **одно** изображение + запись в **Галерею** | ✅ |
| 3 | **«Своя фотосессия» — backend:** endpoint, Gemini, **Галерея** / `generations` | план |
| 4 | **Visual branding / art direction** для каталога фотосессий | план |
| 5 | **Помощь для «Пакетов»** — `PacksHelpDialog`, кнопка **«Помощь»** | ✅ |
| 6 | **Мин. пополнение «Своя сумма» 10 ₽** | ✅ |
| — | **Баннер баланса на «Создать»** — free/paid, демо-режим | ✅ |
| — | **Подсказки «Как получить хороший результат»** — режимы без/с фото, примеры | ✅ |
| — | **Готовые идеи по категориям** — режимы без/с фото, клик → описание | ✅ |
| — | **Модальное ожидание генерации** — обратный отсчёт, затемнённый фон (**Создать** 60 с, **Фотосессии** 120 с) | ✅ |
| — | **Backend balance model** — `paid_image_generations`, `paid_photoshoots`, `GET /balance` | ✅ |
| 7 | **Flutter:** `GET /balance` в Профиль / Пакеты / Создать + правила списания | ✅ |
| 8 | **Расширенные промпты** (шаблоны, фотосессии, чипы) | ✅ | [app_prompts.md](app_prompts.md) |
| 8b | **Backend prompts — качество лиц и изображений** (`gemini_quality_instructions.py`) | ✅ |
| 9 | **Оплата** — RuStore + real paid flow | план |
| — | **Экономика пакетов** (10 ₽ / изображение, 100 ₽ / фотосессия, смешанные пакеты) | ✅ UI |

**Аудитория:** обычные пользователи **40–60+**; простой UI, крупные действия; в UI **не** prompt / tokens / credits (внутри backend допустимы `paid_credits` — пользователю не показывать).

### Продуктовая экономика (новая модель, в разработке)

**Условные единицы цены (product owner, может уточняться):**

| Тип | Условная цена |
|-----|----------------|
| **Обычное изображение** (вкладка **«Создать»**) | **10 ₽** |
| **Одна фотосессия** (готовый стиль или будущая «Своя») | **100 ₽** |
| **Результат фотосессии** | **3 готовых изображения** за одну фотосессию |

**Принцип:** пакеты **не делят** фотосессии и обычные изображения на разные продукты — пользователь покупает **смешанный пакет** (и фотосессии, и изображения в одном предложении). Отдельно — режим **«Только изображения»** без фотосессий.

**Готовые пакеты (предварительный вариант, цифры можно менять):**

| Цена | С фотосессиями | Расчёт |
|------|----------------|--------|
| **199 ₽** | **1** фотосессия + **9** обычных изображений | 100 ₽ + 99 ₽ ÷ 10 |
| **499 ₽** | **3** фотосессии + **19** обычных изображений | 300 ₽ + 199 ₽ ÷ 10 |
| **999 ₽** | **8** фотосессий + **19** обычных изображений | 800 ₽ + 199 ₽ ÷ 10 |

**Альтернатива «Только изображения»** (переключатель в UI: **«С фотосессиями»** / **«Только изображения»**):

| Цена | Только изображения |
|------|-------------------|
| **199 ₽** | **19** |
| **499 ₽** | **49** |
| **999 ₽** | **99** |

**Режим «Своя сумма»:** сумма **10–100 000 ₽**; stepper фотосессий; backend считает остаток ÷ 10 = изображения (`unused_rub` — остаток ₽, не кратный 10). Примеры: **10 ₽**, 0 фотосессий → **1** изображение; **1000 ₽**, **8** фотосессий → **8** + **20** изображений.

**Статус реализации:** экономика и **Flutter UI «Пакеты»** реализованы; **`PaymentService`** отделяет UI от HTTP; **`GET /balance`** и **списание** (при `ENABLE_CREDIT_CONSUMPTION=true`) — реализованы; **backend foundation** для verified top-up (**`mock-verify`** / **`mock-verify-custom`**, development) — **готов**; **реальный RuStore SDK / настоящая оплата — не подключены** (demo `provider_payment_id` заменится на реальный purchase id от RuStore).

### Купить (бывш. «Пакеты»)

- Заголовок **«Купить»**; подзаголовок: *«Пополните баланс, чтобы создавать фото и фотосессии.»*
- Блок **«Как считается баланс»**: 1 фото = 10 ₽, 1 фотосессия = 100 ₽, фотосессия = 3 фото.
- **Demo-ready UI (Flutter):** hero **«Ваш баланс»** — **Фото / Фотосессии / Бесплатные фото**; *«Сначала используются бесплатные фото, потом купленные.»*
- **Переключатель:** **«Фото + фотосессии»** / **«Только фото»**; секции **«Наборы с фотосессиями»** / **«Наборы фото»**; карточки **«Попробовать»** / **«Самый удобный»** / **«Больше возможностей»**; кнопка **«Купить»**; **«Популярно»** на **499 ₽**.
- **«С фотосессиями»:** 199 ₽ → 1 фотосессия + 9 изображений; 499 ₽ → 3 + 19; 999 ₽ → 8 + 19.
- **«Только изображения»:** 199 ₽ → 19; 499 ₽ → 49; 999 ₽ → 99.
- **«Выбрать пакет» (development):** подтверждение → **`mock-verify`** → **«Баланс пополнен»**; при **403/404** endpoint — fallback **«Оплата скоро появится»**.
- **«Пополнить баланс»** (**«Своя сумма»**, development): подтверждение → **`mock-verify-custom`** → **«Баланс пополнен»**; при **403/404** — fallback **«Оплата скоро появится»**; **реальный RuStore — не подключён**.
- **«Своя сумма»:** правила (мин. **10 ₽**, 10 ₽ / изображение, 100 ₽ / фотосессия); stepper/slider фотосессий; **«К оплате: X ₽»** + **«Вы получите: …»**; валидация *«Минимальная сумма — 10 ₽.»*
- **Помощь:** кнопка **«Помощь»** → `PacksHelpDialog` (без автопоказа).
- **Layout:** адаптивная сетка (1 / 2 / 3 колонки); **одинаковая высота карточек** (в т.ч. с **«Популярно»**); Chrome + Android без overflow.
- **Баланс:** `GET /balance` → **Профиль** (полный), **Пакеты** (hero), **Создать** (`_CreateBalanceInfoCard`); обновление после генерации из `balance` в response.

### Профиль

- **С Supabase config:** форма входа/регистрации, карточка «Вы вошли», кнопка **Выйти**; мягкие SnackBar при ошибках.
- **Без Supabase config:** placeholder «Вход недоступен в этом запуске» + подсказка про `dart-define`.
- Блок **Безопасность** при включённом Supabase.

---

## 7. Supabase

### Таблицы

| Таблица | Назначение |
|---------|------------|
| `profiles` | Пользователь, `free_generations_used`, `paid_credits` (legacy), `paid_image_generations`, `paid_photoshoots` |
| `generations` | История: prompt, `image_url`, `payment_type` |
| `credit_transactions` | Аудит начислений/списаний (legacy credits path) |
| `payment_transactions` | Верифицированные покупки пакетов; idempotency по `(provider, provider_payment_id)` |

### Подключение

- Backend → **REST API + httpx** (`app/services/supabase_service.py`).
- **Не использовать** Python-пакет **`supabase`** (конфликт зависимостей).
- Миграции: `backend/db/migrations/`.
- **`backend/.env`** — реальные ключи; **не в git** (есть `.env.example`).

---

## 8. UX правила

**Не использовать в видимом UI:** промпт, кредиты, токены, credits, tokens.

**Использовать для пользователя:** описание, идея, **фото**, **фотосессия** / **фотосессии**, **готовые фото**, **купить**, **баланс**; *«осталось: N бесплатных фото»* или *«Фото: N, Фотосессии: M»*.

**Внутренняя/backend логика** (Supabase `paid_credits`, `credit_transactions`) может оставаться — в UI **не переводить** как «кредиты».

См. [app_design_strategy.md](app_design_strategy.md) §8.

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
- **Gemini provider** реализован; **полный smoke test всех трёх flow пройден** в safe mode (см. ниже); для ежедневной разработки остаётся **`mock`**
- **Gemini photoshoot** (3 кадра) **проверен в safe mode**; по умолчанию выключен через **`ENABLE_PHOTOSHOOT_GENERATION=false`**
- **Оплата / RuStore** — **не подключены**

### Полный реальный Gemini smoke test в safe mode (пройден)

**Временные env (не коммитить):**

| Переменная | Значение |
|------------|----------|
| `ENABLE_CREDIT_CONSUMPTION` | `false` |
| `IMAGE_PROVIDER` | `gemini` |
| `ENABLE_PHOTOSHOOT_GENERATION` | `true` |
| `PHOTOSHOOT_OUTPUT_COUNT` | `3` |

| Flow | Результат |
|------|-----------|
| **`POST /generate`** (текст) | ✅ Gemini → Storage → **`public_url`** → **Галерея** |
| **`POST /generate-with-photo`** (фото + описание) | ✅ Gemini → Storage → **`public_url`** → **Галерея** |
| **`POST /photoshoots/generate`** (3 кадра) | ✅ **3** `image_urls` с **`public_url`** → **Галерея** (группировка по **`photoshoot_id`**) |
| Баланс в safe mode | ✅ **не списывается** |
| После теста env возвращены | ✅ `IMAGE_PROVIDER=mock`, `ENABLE_PHOTOSHOOT_GENERATION=false` |

### Ранние точечные Gemini-тесты (пройдены ранее)

| Шаг | Результат |
|-----|-----------|
| `POST /generate` + `IMAGE_PROVIDER=gemini`, `ENABLE_CREDIT_CONSUMPTION=false` | ✅ |
| `POST /photoshoots/generate`, `PHOTOSHOOT_OUTPUT_COUNT=1` | ✅ |

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

**Списание баланса (ручная проверка):** при `ENABLE_CREDIT_CONSUMPTION=true` — **`POST /generate`** (free → paid images, `balance` в response); **`POST /photoshoots/generate`** с **`IMAGE_PROVIDER=mock`** (mock URLs, −1 `paid_photoshoots`, `balance` в response). См. § **Проверка списаний и mock-фотосессии**.

### Проверено — Frontend (Flutter web)

| Проверка | Результат |
|----------|-----------|
| `flutter analyze` | ✅ проходит |
| Flutter web запуск (`flutter run -d chrome`) | ✅ запускается |
| Mock generation (вкладка **Создать**) | ✅ работает |
| **«Создать»** — 3 бесплатные генерации (баннер), подсказки без/с фото, идеи по категориям | ✅ |
| **Модальное ожидание генерации** (обратный отсчёт, затемнённый фон) | ✅ |
| Fallback-preview при ошибке загрузки картинки | ✅ отображается |
| Кнопка **«Открыть в Галерее»** | ✅ работает |
| **Галерея** — загрузка истории | ✅ грузится |
| **Фотосессии** — выбор фото и upload на backend | ✅ работают |
| **Галерея** — группировка фотосессий по **`photoshoot_id`** | ✅ |
| **Галерея 2.0** — просмотр, **Скачать**, локальное **«Скрыть из Галереи»** | ✅ |
| **First-run onboarding** (5 экранов) | ✅ |
| **Контекстная помощь** — вкладки **Создать**, **Фотосессии**, **Пакеты** (**«Помощь»**) | ✅ |
| **Вкладка «Пакеты»** — demo-ready UI: hero-баланс, карточки пакетов, «Своя сумма», диалог оплаты, layout web + Android | ✅ |
| Бесплатная фотосессия (safe mode) → «Обработка фото будет добавлена позже» | ✅ |
| Платная фотосессия → «Оплата будет добавлена позже» | ✅ |
| **Профиль** без `--dart-define` (fallback / demo mode) | ✅ работает |
| **Профиль** с `--dart-define` (Supabase Auth mode) | ✅ работает |
| **Списание баланса** — `POST /generate` (free → paid images) + Flutter refresh | ✅ проверено вручную |
| **Mock-фотосессия** — `IMAGE_PROVIDER=mock`, списание `paid_photoshoots`, Gallery | ✅ проверено (curl + Flutter emulator) |
| **Баланс после генерации** — **Профиль** / **Пакеты** / **Создать** | ✅ |
| **Русский ввод** на вкладке **Создать** | ✅ |
| Flutter Android emulator | ✅ `flutter run` и **debug APK** (`API_BASE_URL=http://10.0.2.2:8000`); smoke test разделов; mock-фото для фотосессии в debug |
| Flutter Android **физический телефон** (UX-redesign + UX-polish) | ✅ **debug APK** (`API_BASE_URL=http://192.168.31.242:8000`); drawer, шаблоны → **Свой запрос**, фото + генерация, все разделы; после polish — шапка без balance chip, подзаголовки целиком, компактные карточки, нет overflow/RenderBox crash; backend demo mock (раздел A в [demo_release_checklist.md](demo_release_checklist.md)) |

**Авторизация:** вход через Профиль + Bearer token → **Свой запрос** / **Готовые фото** проверены в обоих режимах (с Supabase config и через development fallback `TEST_USER_ID`).

### Инфраструктура

- **Supabase Storage:** bucket `generated-images`; Gemini → Storage → **`public_url`** проверен вручную
- **Flutter web** + backend на `127.0.0.1:8000`

### Перед следующим большим этапом

- **`git status`** должен быть **чистым** (после controlled test — проверено)
- **`backend/.env`** не коммитить; после test: **`ENABLE_PHOTOSHOOT_GENERATION=false`**, **`PHOTOSHOOT_OUTPUT_COUNT=1`** (safe mode)
- Следующие шаги (см. [roadmap.md](roadmap.md)): **RuStore** → curated preview-изображения → production cleanup

---

## Связанные документы

| Документ | Зачем |
|----------|--------|
| [api_contract.md](api_contract.md) | HTTP API |
| [app_design_strategy.md](app_design_strategy.md) | UX, вкладки |
| [app_prompts.md](app_prompts.md) | Тексты шаблонов, фотосессий и чипов «Своя фотосессия» |
| [current_project_snapshot.md](current_project_snapshot.md) | Краткий snapshot «как есть сейчас» |
| [roadmap.md](roadmap.md) | Этапы |
| [demo_script.md](demo_script.md) | Сценарий демо |
| [demo_release_checklist.md](demo_release_checklist.md) | Debug APK, backend modes, install, not-production |
| [production_safety_checklist.md](production_safety_checklist.md) | Auth, debug/mock guards, isolation, pre-release |
| [env_config_checklist.md](env_config_checklist.md) | ENV presets: safe, demo, Gemini test, production |
| [backend_deploy_plan.md](backend_deploy_plan.md) | Future FastAPI deploy: hosting, env, smoke steps |
| [navigation_redesign_plan.md](navigation_redesign_plan.md) | UX-redesign навигации, drawer, статус задач |
| [flutter_auth_setup.md](flutter_auth_setup.md) | Запуск Flutter с Supabase Auth |
| `frontend/README.md` | Запуск Flutter |
| `backend/README.md` | Env, endpoints |
