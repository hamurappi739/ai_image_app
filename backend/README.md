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
| `IMAGE_PROVIDER` | Провайдер генерации: `mock` (по умолчанию) или `gemini` (зарезервирован) |
| `GEMINI_API_KEY` | Ключ Gemini API |
| `GEMINI_MODEL` | Модель для генерации изображений |
| `FREE_GENERATIONS_LIMIT` | Сколько бесплатных генераций доступно пользователю (MVP: **3** по умолчанию; меняется через env без правок кода) |
| `SUPABASE_URL` | URL проекта Supabase |
| `SUPABASE_ANON_KEY` | Публичный anon key (для Flutter; backend пока не использует) |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role key — **только на сервере** |
| `TEST_USER_ID` | UUID тестового пользователя (только development) |
| `ENABLE_CREDIT_CONSUMPTION` | Включить проверку и списание кредитов в `POST /generate` (по умолчанию `false`) |

### IMAGE_PROVIDER

- **`mock`** (по умолчанию) — `POST /generate` возвращает placeholder URL (`placehold.co`). Режим для MVP и разработки UI.
- **`gemini`** — зарезервирован для следующего этапа. Сейчас **`501`** с текстом `Gemini image generation is not implemented yet` (внешний API **не** вызывается).
- Любое другое значение → **`500`** `Unsupported image provider`.

Логика: `app/services/image_service.py` — **`ImageService`** выбирает provider:

| Класс | `IMAGE_PROVIDER` | Поведение |
|-------|------------------|-----------|
| **`MockImageProvider`** | `mock` | Placeholder URL (работает сейчас) |
| **`GeminiImageProvider`** | `gemini` | Placeholder: **501**, без вызова API |

Публичная точка входа: `generate_image(prompt)`.

### ENABLE_CREDIT_CONSUMPTION

- `ENABLE_CREDIT_CONSUMPTION=false` — `POST /generate` работает **без** проверки и списания кредитов (текущее поведение для разработки).
- `ENABLE_CREDIT_CONSUMPTION=true` — позже будет включать проверку баланса и `consume_generation()` в `/generate` (ещё не подключено).
- По умолчанию для разработки оставляйте **`false`**.

### TEST_USER_ID (development only)

`TEST_USER_ID` нужен для проверки пользовательской и кредитной логики до подключения настоящей авторизации. Задайте UUID существующей строки в `profiles` из Supabase.

**В production использовать `TEST_USER_ID` нельзя** — только реальная auth (Supabase JWT / session).

## Supabase connection

Backend обращается к Supabase через **REST API** (`httpx`), без Python SDK `supabase` (избегаем тяжёлых нативных зависимостей).

- `app/services/supabase_service.py` → `check_supabase_connection()` — GET `{SUPABASE_URL}/rest/v1/...`
- Заголовки: `apikey` и `Authorization: Bearer` с **`SUPABASE_SERVICE_ROLE_KEY`**
- Service role key — полный доступ к БД, обходит RLS; **никогда** не отдавать во Flutter
- **`SUPABASE_ANON_KEY`** — для клиента; backend пока не использует

Проверка в разработке: `GET /debug/supabase` (удалить или защитить перед production).

## Gemini integration preparation

Для будущей реальной генерации через Gemini:

1. Установить `IMAGE_PROVIDER=gemini` (после реализации провайдера).
2. Заполнить `GEMINI_API_KEY`, при необходимости `GEMINI_MODEL` (по умолчанию `gemini-2.5-flash-image`).

Пока `IMAGE_PROVIDER=gemini` **не** вызывает Gemini API — только ответ **501**.

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
    └── credits_service.py  # Проверка free/paid (без списания)
.env.example             # Шаблон переменных окружения
```

## Endpoints

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/health` | Проверка работоспособности |
| GET | `/generations` | История генераций тестового пользователя (`TEST_USER_ID`) |
| GET | `/debug/supabase` | Проверка подключения к Supabase (**только разработка**) |
| GET | `/debug/profile` | Профиль по `TEST_USER_ID` (**только разработка**) |
| GET | `/debug/credits` | Решение free/paid без списания (**только разработка**) |
| GET | `/debug/history` | История генераций и транзакций (**только разработка**) |
| POST | `/debug/consume-generation` | Тестовое списание в Supabase (**только разработка**) |
| POST | `/debug/add-credits` | Ручное начисление paid credits (**только разработка**) |
| POST | `/generate` | Mock-генерация изображения по prompt |

### GET /generations

Список записей из таблицы `generations` для **`TEST_USER_ID`** (dev-mode, без JWT). Сортировка: новые сверху.

Query: `limit` (по умолчанию **20**, минимум **1**, максимум **100**), например `GET /generations?limit=10`.

Поля каждого элемента: `id`, `prompt`, `image_url`, `payment_type`, `created_at`.

- Нет `TEST_USER_ID` → `500` — `"TEST_USER_ID is not configured"`
- Ошибка Supabase → `500` — `"Failed to fetch generations"`
- Нет записей → `200` — `{"generations": []}`

Проверка:

```bash
curl -s "http://127.0.0.1:8000/generations"
curl -s "http://127.0.0.1:8000/generations?limit=5"
```

В production позже: тот же endpoint с **auth user id** вместо `TEST_USER_ID`.

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

#### a) Credit consumption disabled (`ENABLE_CREDIT_CONSUMPTION=false`, по умолчанию)

- Проверка prompt → mock `image_url`
- **Без** чтения профиля, **без** списания, **без** записи в Supabase
- Ответ: `image_url`, `prompt` (остальные поля ответа — значения по умолчанию)

#### b) Credit consumption enabled (`ENABLE_CREDIT_CONSUMPTION=true`)

Для development задайте в `backend/.env`:

```env
ENABLE_CREDIT_CONSUMPTION=true
TEST_USER_ID=<uuid из profiles>
```

Поток: prompt → профиль по `TEST_USER_ID` → `determine_generation_payment` → при отказе `402` → mock image → `consume_generation` (Supabase) → расширенный ответ:

- `image_url`, `prompt`
- `payment_type` (`free` / `paid`)
- `credit_consumed: true`
- `remaining_free_generations`, `remaining_paid_credits`

Ошибки: пустой prompt → `400`; нет `TEST_USER_ID` → `500`; профиль не найден → `404`; нет генераций → `402`.

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
