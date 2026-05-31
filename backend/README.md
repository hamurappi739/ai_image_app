# Backend

FastAPI-сервер для AI Image Generator.

## Настройки (.env)

Скопируйте шаблон и при необходимости отредактируйте значения:

```bash
cd backend
copy .env.example .env
```

Файл `.env` не коммитится в git (см. `.gitignore` в корне репозитория). Реальные ключи храните только локально.

| Переменная | Описание |
|------------|----------|
| `APP_NAME` | Название приложения |
| `ENVIRONMENT` | Окружение (`development`, `production`, …) |
| `IMAGE_PROVIDER` | Провайдер генерации: `mock` (по умолчанию, безопасный режим) или `gemini` |
| `GEMINI_API_KEY` | Ключ Gemini API |
| `GEMINI_MODEL` | Модель для генерации изображений |
| `FREE_GENERATIONS_LIMIT` | Сколько бесплатных генераций доступно пользователю (MVP: **3** по умолчанию; меняется через env без правок кода) |
| `SUPABASE_URL` | URL проекта Supabase |
| `SUPABASE_ANON_KEY` | Публичный anon key (используется backend для валидации Bearer token через Supabase Auth REST) |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role key — **только на сервере** |
| `SUPABASE_STORAGE_BUCKET` | Имя bucket в Supabase Storage для сгенерированных изображений (по умолчанию `generated-images`) |
| `TEST_USER_ID` | UUID тестового пользователя (только development) |
| `ENABLE_CREDIT_CONSUMPTION` | Включить проверку и списание кредитов в `POST /generate` (по умолчанию `false`) |
| `ENABLE_PHOTOSHOOT_GENERATION` | Включить реальную Gemini-генерацию в `POST /photoshoots/generate` (по умолчанию **`false`**) |
| `PHOTOSHOOT_OUTPUT_COUNT` | Сколько изображений генерировать за одну фотосессию (**1–3**, по умолчанию **1** для безопасных dev-тестов; product target — **3**) |

### IMAGE_PROVIDER

- **`mock`** (по умолчанию) — `POST /generate` возвращает placeholder URL (`placehold.co`). **Безопасный режим** для MVP, разработки UI и демо без расхода API.
- **`gemini`** — реальная генерация через Google Gen AI SDK (`google-genai`). Вызов API **только** при `IMAGE_PROVIDER=gemini` и настроенном `GEMINI_API_KEY`.
- Любое другое значение → **`500`** `Unsupported image provider`.

Логика: `app/services/image_service.py` — **`ImageService`** выбирает provider:

| Класс | `IMAGE_PROVIDER` | Поведение |
|-------|------------------|-----------|
| **`MockImageProvider`** | `mock` | Placeholder URL (по умолчанию) |
| **`GeminiImageProvider`** | `gemini` | Gemini API → `image_url` как data URL (`data:image/png;base64,...`) |

Публичная точка входа: `generate_image(prompt)`.

#### Включить Gemini

В `backend/.env` (не коммитить; шаблон — `.env.example`):

```env
IMAGE_PROVIDER=gemini
GEMINI_API_KEY=your_key_here
GEMINI_MODEL=gemini-2.5-flash-image
```

- Нет `GEMINI_API_KEY` → **`500`** `GEMINI_API_KEY is not configured`
- Модель без изображения в ответе → **`502`** `Gemini did not return an image`
- Ошибка SDK/API → **`502`** с понятным текстом (без секретов в ответе)

Для ежедневной разработки оставляйте **`IMAGE_PROVIDER=mock`**.

### ENABLE_CREDIT_CONSUMPTION

- `ENABLE_CREDIT_CONSUMPTION=false` — `POST /generate` работает **без** проверки и списания кредитов (текущее поведение для разработки).
- `ENABLE_CREDIT_CONSUMPTION=true` — позже будет включать проверку баланса и `consume_generation()` в `/generate` (ещё не подключено).
- По умолчанию для разработки оставляйте **`false`**.

### ENABLE_PHOTOSHOOT_GENERATION

- **`ENABLE_PHOTOSHOOT_GENERATION=false`** (по умолчанию) — `POST /photoshoots/generate` валидирует multipart, но **не вызывает Gemini**; возвращает **`501`** `Photoshoot generation is disabled in development mode`. Защита от случайных кликов во Flutter.
- **`ENABLE_PHOTOSHOOT_GENERATION=true`** — реальная Gemini-фотосессия (photo + style → Gemini → Storage → `image_urls`). **Только на время ручного теста.**
- Для controlled test также задайте **`PHOTOSHOOT_OUTPUT_COUNT=1`** и **`GEMINI_API_KEY`**.
- **После теста обязательно вернуть `false`** и перезапустить backend.
- Проверка: `GET /debug/config` → `"photoshoot_generation_enabled": false`

### PHOTOSHOOT_OUTPUT_COUNT

- **`PHOTOSHOOT_OUTPUT_COUNT=1`** (по умолчанию) — безопасный режим для controlled dev-тестов фотосессии (меньше Gemini-запросов).
- **`PHOTOSHOOT_OUTPUT_COUNT=3`** — product target: три результата на фотосессию (как в UI и catalog `output_count`).
- Значение **ограничено 1–3**; меньше 1 → **1**, больше 3 → **3**.
- Используется **`GeminiPhotoshootProvider`** при **`ENABLE_PHOTOSHOOT_GENERATION=true`**.
- Проверка: `GET /debug/config` → `"photoshoot_output_count": 1`

### TEST_USER_ID (development only)

`TEST_USER_ID` — UUID для локальной разработки без Bearer token (fallback при `ENVIRONMENT=development`).

**В production использовать `TEST_USER_ID` нельзя** — только реальная auth (Supabase JWT / session).

### Profile auto-create / sync

При **`GET /generations`** и при **`POST /generate`** с включённым **`ENABLE_CREDIT_CONSUMPTION=true`** backend вызывает `ensure_profile_exists(user_id, email)`:

- если строка в `profiles` уже есть — возвращает её (существующий `email` не перезаписывается);
- если нет — создаёт `id`, `free_generations_used=0`, `paid_credits=0`, опционально `email` из Supabase Auth;
- если в профиле `email` пустой, а из токена пришёл email — дописывает email один раз.

Работает для **авторизованного пользователя** (Bearer) и для **development fallback** `TEST_USER_ID` (`email` может быть `None`). Ошибка создания/обновления → **`500`** `Failed to ensure user profile` (без секретов в ответе).

## Supabase connection

Backend обращается к Supabase через **REST API** (`httpx`), без Python SDK `supabase` (избегаем тяжёлых нативных зависимостей).

- `app/services/supabase_service.py` → `check_supabase_connection()` — GET `{SUPABASE_URL}/rest/v1/...`
- Заголовки: `apikey` и `Authorization: Bearer` с **`SUPABASE_SERVICE_ROLE_KEY`**
- Service role key — полный доступ к БД, обходит RLS; **никогда** не отдавать во Flutter
- **`SUPABASE_ANON_KEY`** — для клиента; backend пока не использует
- **Таймауты и сбои соединения** (`ConnectTimeout`, `ReadTimeout`, `ConnectError`, …): централизованная обработка в `supabase_service.py` → **`503`** `Supabase is temporarily unavailable` (без traceback и без секретов в логах). **`GET /health`** Supabase не вызывает.

Проверка в разработке: `GET /debug/supabase`, `GET /debug/config` (удалить или защитить перед production).

## Supabase Storage

`app/services/storage_service.py` — **`SupabaseStorageService`** (REST через **httpx**, без Python SDK `supabase`):

| Метод | Назначение |
|-------|------------|
| `build_storage_path(user_id, filename, folder="generations")` | Ключ объекта: `{folder}/{user_id}/{filename}` |
| `upload_bytes(path, content, content_type)` | `PUT` в Storage API; возвращает public URL |
| `get_public_url(path)` | URL вида `/storage/v1/object/public/{bucket}/{path}` (для private bucket позже — signed URL) |
| `upload_generated_image_data_url(user_id, data_url, folder="generations")` | Декодирует data URL (`image/png`, `image/jpeg`, `image/webp`, до 10 MB), загружает в Storage, возвращает **public URL** |

- **`upload_generated_image_data_url`** — сценарий Gemini → data URL → Storage → `public_url`. Вызывается из **`POST /generate`**, когда provider вернул data URL (`data:image/...`).
- **`POST /generate`**: если `image_url` от provider начинается с **`data:image/`**, backend автоматически загружает изображение в Storage и подменяет **`image_url`** на **`public_url`** (в response и в `generations` при credit consumption). **Mock mode** (`placehold.co`) Storage **не использует**.
- Ошибки валидации data URL: **`400`** — `Invalid image data`, `Unsupported image format`, `Image is too large` (максимум **10 MB**).

- **`SUPABASE_STORAGE_BUCKET`** — имя bucket для сгенерированных изображений (по умолчанию `generated-images`; см. таблицу env выше и `.env.example`).
- Требует **`SUPABASE_URL`**, **`SUPABASE_SERVICE_ROLE_KEY`**, **`SUPABASE_STORAGE_BUCKET`** (шаблон в `.env.example`).
- Service role key **не** логируется и **не** возвращается клиенту.
- **`storage_service.py`** подключён к **`POST /generate`** для data URL; **`POST /photoshoots/generate`** — при **`ENABLE_PHOTOSHOOT_GENERATION=true`**.

### Bucket (MVP)

1. В [Supabase Dashboard](https://supabase.com/dashboard) → **Storage** → **New bucket**.
2. Имя: **`generated-images`** (или значение `SUPABASE_STORAGE_BUCKET` из `.env`) — **bucket должен быть создан** в Supabase Storage.
3. Для MVP bucket **public** (чтобы `get_public_url` / `upload_bytes` возвращали рабочий URL без signed URLs).
4. Перезапустите backend с настроенными `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_STORAGE_BUCKET`.

**Текущий статус:** bucket `generated-images` создан; upload через backend проверен (`POST /debug/storage-test`, `POST /debug/storage-image-test`).

### POST /debug/storage-test (development only)

Внутренний тест **backend → Supabase Storage**: загружает маленький файл `b"storage test"` (`text/plain`) без приёма файла от клиента.

- **Проверен:** backend успешно загружает файл и возвращает **`public_url`**; URL открывается в браузере.
- Только при **`ENVIRONMENT=development`** (иначе **`404`**, как у `GET /debug/config`).
- Успех: `{"status":"ok","bucket":"...","path":"...","public_url":"..."}` — без ключей и секретов.
- Timeout / connection error → **`503`** `Supabase is temporarily unavailable`
- Ошибка upload / конфигурации → **`500`** `Supabase Storage upload failed`

**PowerShell:**

```powershell
Invoke-RestMethod -Uri "http://127.0.0.1:8000/debug/storage-test" -Method Post
```

**curl:**

```bash
curl -s -X POST http://127.0.0.1:8000/debug/storage-test
```

**Перед production** удалить или защитить вместе с остальными `/debug/*` routes. Не вызывать из Flutter release.

### POST /debug/storage-image-test (development only)

Тестирует загрузку **generated image data URL** в Supabase Storage через **`upload_generated_image_data_url`**.

- Загружает маленькую **1×1 PNG data URL** (задана в коде endpoint) в bucket **`generated-images`**.
- **Проверен:** backend успешно загружает PNG data URL и возвращает **`public_url`**; URL **открыт вручную** в браузере.
- **Только development:** доступен при **`ENVIRONMENT=development`** (иначе **`404`**, как у `GET /debug/config`).
- Использует `TEST_USER_ID` из `.env` и folder `debug`.
- Успех: `{"status":"ok","public_url":"...","path_or_note":"..."}` — без ключей и секретов.
- Некорректный data URL / неподдерживаемый формат / размер > 10 MB → **`400`** (см. helper выше).
- Timeout / connection error → **`503`** `Supabase is temporarily unavailable`

**PowerShell:**

```powershell
Invoke-RestMethod -Uri "http://127.0.0.1:8000/debug/storage-image-test" -Method Post
```

**curl:**

```bash
curl -s -X POST http://127.0.0.1:8000/debug/storage-image-test
```

**Перед production** удалить или защитить вместе с остальными `/debug/*` routes. Не вызывать из Flutter release.

## Gemini image generation

Реализовано в **`GeminiImageProvider`** (`google-genai`). По умолчанию **`IMAGE_PROVIDER=mock`** — внешний API не вызывается.

Ручная проверка: задать ключ в локальном `.env`, перезапустить uvicorn, `POST /generate` с коротким описанием.

## Запуск

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Сервер: [http://127.0.0.1:8000](http://127.0.0.1:8000)

## CORS for Flutter web development

Для **Flutter web** (`flutter run -d chrome`) backend отдаёт CORS-заголовки через `CORSMiddleware` в `app/main.py`.

Текущие настройки (только **development**):

- `allow_origins=["*"]`
- `allow_credentials=False`
- `allow_methods=["*"]`, `allow_headers=["*"]`

Это нужно, потому что dev-сервер Flutter слушает случайный порт (`localhost:5173`, `8080`, и т.д.).

**Перед production** замените `allow_origins=["*"]` на явный список доверенных origins (ваш домен, app URL). Не используйте `*` в prod.

## Структура

```
app/
├── main.py              # FastAPI routes
├── config.py            # Настройки из .env (pydantic-settings)
├── schemas.py           # Pydantic-модели запросов/ответов
└── services/
    ├── image_service.py    # ImageService, MockImageProvider, GeminiImageProvider
    ├── supabase_service.py # Supabase REST (httpx + service role)
    ├── storage_service.py  # Supabase Storage REST placeholder (not wired to routes yet)
    └── credits_service.py  # Проверка free/paid (без списания)
.env.example             # Шаблон переменных окружения
```

## Endpoints

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/health` | Проверка работоспособности |
| GET | `/generations` | История генераций текущего пользователя (Bearer token или dev fallback) |
| GET | `/debug/config` | Безопасный снимок настроек без секретов (**только `ENVIRONMENT=development`**) |
| GET | `/debug/supabase` | Проверка подключения к Supabase (**только разработка**) |
| GET | `/debug/profile` | Профиль по `TEST_USER_ID` (**только разработка**) |
| GET | `/debug/credits` | Решение free/paid без списания (**только разработка**) |
| GET | `/debug/history` | История генераций и транзакций (**только разработка**) |
| POST | `/debug/consume-generation` | Тестовое списание в Supabase (**только разработка**) |
| POST | `/debug/add-credits` | Ручное начисление paid credits (**только разработка**) |
| POST | `/debug/storage-test` | Тест upload в Supabase Storage (**только `ENVIRONMENT=development`**) |
| POST | `/debug/storage-image-test` | Тест upload PNG data URL через `upload_generated_image_data_url` (**только development**) |
| POST | `/generate` | Mock-генерация изображения по prompt |
| POST | `/photoshoots/generate` | Multipart валидация фото; Gemini при `ENABLE_PHOTOSHOOT_GENERATION=true`, иначе **501** |

### GET /generations

Список записей из таблицы `generations` для текущего пользователя. Сортировка: новые сверху.

Идентификация пользователя:

- Если передан `Authorization: Bearer <access_token>` — backend валидирует токен через Supabase Auth REST (`/auth/v1/user`) и использует `id` (и `email`, если есть).
- Перед выборкой истории вызывается **`ensure_profile_exists`** — профиль создаётся при первом запросе, если его ещё нет.
- Если заголовка нет и `ENVIRONMENT=development` — используется fallback `TEST_USER_ID`.
- Если заголовка нет и окружение не development — `401` (`Authorization required`).

Query: `limit` (по умолчанию **20**, минимум **1**, максимум **100**), например `GET /generations?limit=10`.

Поля каждого элемента: `id`, `prompt`, `image_url`, `payment_type`, `created_at`.

- Невалидный/просроченный Bearer token → `401` — `"Invalid or expired authorization token"`
- Нет токена в development и не задан `TEST_USER_ID` → `500` — `"TEST_USER_ID is not configured for development mode"`
- Supabase timeout / connection error → `503` — `"Supabase is temporarily unavailable"`
- Ошибка Supabase (неуспешный ответ БД) → `500` — `"Failed to fetch generations"`
- Нет записей → `200` — `{"generations": []}`

Проверка:

```bash
curl -s "http://127.0.0.1:8000/generations"
curl -s "http://127.0.0.1:8000/generations?limit=5"
```

В production ожидается Bearer token; fallback `TEST_USER_ID` предназначен только для development.

### GET /debug/config (временный)

Только при **`ENVIRONMENT=development`**. Иначе **`404`** (endpoint не «светится» как рабочий в production).

Возвращает **только безопасные** поля: окружение, `IMAGE_PROVIDER`, флаг списания кредитов, модель Gemini, **`photoshoot_output_count`**, **`photoshoot_generation_enabled`**, **флаги** «ключ/URL настроены» без значений. **Не** возвращает: `GEMINI_API_KEY`, `SUPABASE_*` ключи, `TEST_USER_ID`, полный `SUPABASE_URL` (только `supabase_url_configured`).

Пример:

```bash
curl -s http://127.0.0.1:8000/debug/config
```

### GET /debug/supabase (временный)

Проверяет, что backend может подключиться к Supabase (`profiles`, `select id limit 1`). Успех: `{"status": "ok", "supabase": "connected"}`. Ошибка: `500` с `detail: "Supabase connection failed"` (без ключей и данных пользователей).

**Перед production** этот endpoint нужно удалить или защитить (auth, IP allowlist, отключение вне `development`).

### GET /debug/profile (временный)

Читает профиль из `profiles` для `TEST_USER_ID` из `.env` (`id`, `email`, `free_generations_used`, `paid_credits`).

- Нет `TEST_USER_ID` → `500` — `"TEST_USER_ID is not configured"`
- Профиль не найден → `404` — `"Profile not found"`
- Успех → `{"status": "ok", "profile": {...}}`

**Перед production** удалить или защитить вместе с остальными `/debug/*` routes.

### GET /debug/credits (временный)

Загружает профиль по `TEST_USER_ID` и вызывает `determine_generation_payment()` — только чтение, **без списания** и без записи в Supabase.

Успех: `{"status": "ok", "profile": {...}, "decision": {"allowed": ..., "payment_type": ..., "reason": ...}}`.

**Перед production** удалить или защитить вместе с остальными `/debug/*` routes.

### GET /debug/history (временный)

Только чтение: последние 10 записей из `generations` и `credit_transactions` для `TEST_USER_ID`, плюс текущий `profile`.

Успех: `{"status": "ok", "profile": {...}, "generations": [...], "credit_transactions": [...]}`.

**Development-only.** Удалить или защитить перед production.

### POST /debug/consume-generation (временный)

**Реально изменяет Supabase:** списывает free/paid, пишет в `generations` и `credit_transactions` (mock prompt и image URL).

1. Профиль по `TEST_USER_ID`
2. `determine_generation_payment()` — если нельзя → `402` с `detail` из `reason`
3. `consume_generation()` — PATCH `profiles`, POST `generations`, POST `credit_transactions`

Успех: `{"status": "ok", "decision": {...}, "result": {"profile", "generation", "transaction"}}`.

**Перед production** удалить или защитить.

### POST /debug/add-credits (временный)

**Реально изменяет Supabase:** увеличивает `profiles.paid_credits` для `TEST_USER_ID` и пишет запись в `credit_transactions` (`admin_adjustment` / `admin`).

Тело запроса:

```json
{
  "amount": 25,
  "description": "Test pack"
}
```

- `amount <= 0` → `400` — `"Amount must be positive"`
- Успех → `{"status": "ok", "result": {"profile", "transaction"}}`

**Только для development.** Удалить или защитить перед production (не замена RuStore Billing).

### POST /generate

Управляется флагом **`ENABLE_CREDIT_CONSUMPTION`** в `backend/.env` (шаблон: `.env.example`).

Для обычного endpoint поддерживается `Authorization: Bearer <access_token>`:

- при переданном токене backend валидирует его через Supabase Auth REST;
- невалидный/просроченный токен → `401` (`Invalid or expired authorization token`);
- без токена в development используется fallback `TEST_USER_ID` только там, где нужен `user_id`.

#### a) Credit consumption disabled (`ENABLE_CREDIT_CONSUMPTION=false`, по умолчанию)

- Проверка prompt → `image_url` от provider (mock или Gemini)
- Если provider вернул **data URL** — upload в Storage, в ответе **`public_url`**
- **Mock mode** — обычный `placehold.co`, Storage **не вызывается**
- **Без** чтения профиля, **без** списания, **без** записи в Supabase
- Ответ: `image_url`, `prompt` (остальные поля ответа — значения по умолчанию)

#### b) Credit consumption enabled (`ENABLE_CREDIT_CONSUMPTION=true`)

Для development задайте в `backend/.env`:

```env
ENABLE_CREDIT_CONSUMPTION=true
TEST_USER_ID=<uuid из profiles>
```

Идентификация пользователя для этой ветки:

- С `Authorization: Bearer <access_token>`: backend получает user id и email через Supabase Auth REST.
- Без заголовка в development: используется fallback `TEST_USER_ID`.
- Без заголовка вне development: `401` (`Authorization required`).

Поток: prompt → генерация → **data URL → Storage `public_url` при необходимости** → **`ensure_profile_exists`** → `determine_generation_payment` → при отказе `402` → `consume_generation` (Supabase, с Storage URL в `generations.image_url`) → расширенный ответ:

- `image_url`, `prompt`
- `payment_type` (`free` / `paid`)
- `credit_consumed: true`
- `remaining_free_generations`, `remaining_paid_credits`

Ошибки: пустой prompt → `400`; невалидный token → `401`; без токена вне development → `401`; нет fallback `TEST_USER_ID` в development → `500`; не удалось создать/обновить профиль → `500` (`Failed to ensure user profile`); нет генераций → `402`.

#### Пример (режим disabled)

```bash
curl -X POST http://127.0.0.1:8000/generate ^
  -H "Content-Type: application/json" ^
  -d "{\"prompt\": \"a sunset over mountains\"}"
```

```json
{
  "image_url": "https://placehold.co/1024x1024?text=Generated+Image",
  "prompt": "a sunset over mountains",
  "payment_type": null,
  "credit_consumed": false,
  "remaining_free_generations": null,
  "remaining_paid_credits": null
}
```

Пустой prompt (после trim) → `400` с `{"detail": "Prompt cannot be empty"}`.

### POST /photoshoots/generate

Endpoint для подготовки фотосессии с multipart-валидацией файла.

Поля `multipart/form-data`:

- `style_id` (строка, обязательно)
- `style_title` (строка, опционально)
- `photo` (файл, обязательно)

Валидация файла:

- Допустимые форматы: `image/jpeg`, `image/png`, `image/webp`
- Максимальный размер: `10 MB`
- Неподдерживаемый формат → `400` `Unsupported photo format`
- Слишком большой файл → `400` `Photo is too large`

Auth-логика сохраняется: Bearer user или development fallback `TEST_USER_ID`.

**Safety switch:** по умолчанию **`ENABLE_PHOTOSHOOT_GENERATION=false`**. После валидации style/photo без включённого флага endpoint возвращает **`501`**:
`Photoshoot generation is disabled in development mode`.

При **`ENABLE_PHOTOSHOOT_GENERATION=true`** + **`GEMINI_API_KEY`**: Gemini → Storage → **`200`** с `image_urls`. Для ручного теста также **`PHOTOSHOOT_OUTPUT_COUNT=1`**. **После теста вернуть `false`.**

Пока не делается: запись результатов в `generations`, списание генераций, оплата.

Пример `curl` (без секретов):

```bash
curl -X POST "http://127.0.0.1:8000/photoshoots/generate" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -F "style_id=studio_portrait" \
  -F "style_title=Студийный портрет" \
  -F "photo=@C:/path/to/photo.jpg;type=image/jpeg"
```

PowerShell (`Invoke-RestMethod`):

```powershell
$form = @{
  style_id = "studio_portrait"
  style_title = "Студийный портрет"
  photo = Get-Item "C:\path\to\photo.jpg"
}
Invoke-RestMethod -Uri "http://127.0.0.1:8000/photoshoots/generate" -Method Post -Form $form
```
