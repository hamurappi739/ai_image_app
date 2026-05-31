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
- **`POST /photoshoots/generate`** при **`ENABLE_PHOTOSHOOT_GENERATION=true`**: загружает результаты Gemini в Storage и возвращает **`public_url`** в `image_urls` (без записи в `generations`).
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
- Runtime limit: **`PHOTOSHOOT_OUTPUT_COUNT`** (env, default **1**, max **3**); product target в catalog — **3** изображения.
- Использует ту же auth-логику: Bearer token или development fallback `TEST_USER_ID`; перед обработкой — profile auto-sync.
- Валидирует формат файла: **JPEG / PNG / WebP**, максимум **10 MB**.
- Неизвестный `style_id` → **`400`** `Unknown photoshoot style`.
- При успехе возвращает **`200`** с `style_id`, `style_title`, `image_urls`, `output_count`.
- **Safety switch (по умолчанию):** **`ENABLE_PHOTOSHOOT_GENERATION=false`** — Gemini **не вызывается**; после валидации **`501`** `Photoshoot generation is disabled in development mode`.
- **Controlled test:** временно **`ENABLE_PHOTOSHOOT_GENERATION=true`** + **`PHOTOSHOOT_OUTPUT_COUNT=1`** + **`GEMINI_API_KEY`**; **после теста вернуть `false`**.
- **Product target (позже):** **3 изображения** на фотосессию (`PHOTOSHOOT_OUTPUT_COUNT=3` после проверки стоимости; catalog `output_count=3`).
- Требует **`GEMINI_API_KEY`** (при включённой генерации); без ключа → **`500`** `GEMINI_API_KEY is not configured`.
- Backend **не сохраняет** загруженное исходное фото, **не пишет** результаты в `generations`, **не списывает** генерации/оплату.
- **Ручной Gemini photoshoot test пройден:** uploaded photo → Gemini image → Storage → **`image_urls`** с **`public_url`** (см. §11).
- **Пока не подключено** к Галерее / persistence в `generations` (отдельный этап).

### `GET /generations`

- С Bearer token: `CurrentUser` из Supabase Auth REST; перед выборкой — **`ensure_profile_exists`**.
- Без токена в development: **`TEST_USER_ID`** + auto-create профиля при необходимости.
- Ответ: список из таблицы **`generations`** (новые сверху).
- В non-development без токена: `401` (`Authorization required`).

### Development only

**`/debug/*`** — только для разработки. **`GET /debug/config`** — безопасный helper: флаги конфигурации без секретов (доступен только при `ENVIRONMENT=development`, иначе 404). **Не вызывать** из production Flutter. Перед релизом — **удалить или защитить все** `/debug/*` routes.

Примеры: `/debug/config`, `/debug/supabase`, `/debug/storage-test`, `/debug/storage-image-test`, `/debug/profile`, `/debug/history`, `/debug/consume-generation`, `/debug/add-credits`.

Подробнее: [api_contract.md](api_contract.md), [dev_notes.md](dev_notes.md).

---

## 6. Frontend вкладки

Нижняя навигация (русский UI): **Создать · Фотосессии · Галерея · Пакеты · Профиль**.

### Создать

- Ввод **описания**, быстрые идеи, блок **«Как получить хороший результат»**.
- **`POST /generate`** через `ApiService`.
- Результат: `Image.network` или **fallback-preview** при ошибке загрузки.
- Кнопка **«Открыть в Галерее»**.
- Frontend скрывает технические ошибки генерации: в UI показывается только понятное сообщение для пользователя.
- Ошибки backend/Gemini (и HTTP-детали) должны логироваться/обрабатываться на backend, без вывода технических деталей в UI.

### Фотосессии

- 8 готовых стилей: **3 бесплатных**, **5 × 100 ₽**.
- Карточки → **bottom sheet** с локальным выбором фото через Flutter (`image_picker`).
- В modal после выбора показывается preview и статус **«Фото выбрано»** (preview только в UI, до закрытия окна).
- **Flutter** (бесплатный сценарий) отправляет выбранное фото на backend через **`multipart/form-data`** (`style_id`, `style_title`, `photo`).
- **Backend** валидирует **JPEG / PNG / WebP** и размер до **10 MB**; исходное фото на сервере не сохраняется.
- По умолчанию **`ENABLE_PHOTOSHOOT_GENERATION=false`**: после валидации backend возвращает **`501`**; Flutter показывает «Обработка фото будет добавлена позже» (Gemini не вызывается).
- При **`ENABLE_PHOTOSHOOT_GENERATION=true`**: Gemini → **`200`** с `image_urls` (Flutter пока не отображает результаты).
- Платные фотосессии пока **не отправляют** фото на backend → **«Оплата будет добавлена позже»**.
- Реальная обработка, сохранение результатов и оплата — следующие этапы.

### Галерея

- При старте: **`GET /generations`** (тихо при ошибке backend).
- Скрывает служебные **debug**-описания в UI.
- Новые результаты сессии — **сверху** после генерации.
- **«Очистить»** — только локальный список; **Supabase не удаляется**.

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
- **Photoshoot results in Gallery/history** — backend возвращает `image_urls`, Flutter пока не отображает.
- **RuStore Billing** и оплата фотосессий 100 ₽.
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
- **Gemini photoshoot** реализован и **успешно проверен вручную**; по умолчанию выключен через **`ENABLE_PHOTOSHOOT_GENERATION=false`**

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

### Проверено — Backend

| Проверка | Результат |
|----------|-----------|
| `python -m compileall app` | ✅ проходит |
| `GET /health` | ✅ работает |
| `GET /debug/config` | ✅ работает |
| `GET /generations` | ✅ работает |
| `POST /debug/storage-test` | ✅ работает |
| `POST /debug/storage-image-test` | ✅ работает |

Дополнительно: **`POST /generate`** с **`IMAGE_PROVIDER=gemini`** — полный flow Gemini → Storage → **`public_url`** проверен вручную; **`GET /generations`** / **Галерея** отображают Storage URL. **`POST /photoshoots/generate`** с **`ENABLE_PHOTOSHOOT_GENERATION=true`** — photoshoot flow Gemini → Storage → **`image_urls`** проверен вручную (результаты пока не в Галерее).

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
| Бесплатная фотосессия → «Обработка фото будет добавлена позже» | ✅ |
| Платная фотосессия → «Оплата будет добавлена позже» | ✅ |
| **Профиль** без `--dart-define` (fallback / demo mode) | ✅ работает |
| **Профиль** с `--dart-define` (Supabase Auth mode) | ✅ работает |

**Авторизация:** вход через Профиль + Bearer token → **Создать** / **Галерея** проверены в обоих режимах (с Supabase config и через development fallback `TEST_USER_ID`).

### Инфраструктура

- **Supabase Storage:** bucket `generated-images`; Gemini → Storage → **`public_url`** проверен вручную
- **Flutter web** + backend на `127.0.0.1:8000`

### Перед следующим большим этапом

- **`git status`** должен быть **чистым** (или осознанный коммит текущего состояния)
- **`backend/.env`** не коммитить
- Следующий крупный шаг: **подключить photoshoot `image_urls` к Flutter Gallery/history**, затем **3 результата** и **оплата** платных фотосессий

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
