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
| `GEMINI_API_KEY` | Ключ Gemini API |
| `GEMINI_MODEL` | Модель для генерации изображений |
| `FREE_GENERATIONS_LIMIT` | Сколько бесплатных генераций доступно пользователю (MVP: **3** по умолчанию; меняется через env без правок кода) |
| `SUPABASE_URL` | URL проекта Supabase |
| `SUPABASE_ANON_KEY` | Публичный anon key (для Flutter; backend пока не использует) |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role key — **только на сервере** |
| `TEST_USER_ID` | UUID тестового пользователя (только development) |

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

Для будущей реальной генерации через Gemini в `.env` понадобятся:

- `GEMINI_API_KEY` — ключ из Google AI Studio
- `GEMINI_MODEL` — по умолчанию `gemini-2.5-flash-image`

В `app/services/image_service.py` уже есть `generate_image_with_gemini()` (пока возвращает mock). Endpoint `POST /generate` по-прежнему использует `generate_mock_image()`.

## Запуск

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Сервер: [http://127.0.0.1:8000](http://127.0.0.1:8000)

## Структура

```
app/
├── main.py              # FastAPI routes
├── config.py            # Настройки из .env (pydantic-settings)
├── schemas.py           # Pydantic-модели запросов/ответов
└── services/
    ├── image_service.py    # Логика генерации (сейчас mock)
    └── supabase_service.py # Supabase REST (httpx + service role)
.env.example             # Шаблон переменных окружения
```

## Endpoints

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/health` | Проверка работоспособности |
| GET | `/debug/supabase` | Проверка подключения к Supabase (**только разработка**) |
| POST | `/generate` | Mock-генерация изображения по prompt |

### GET /debug/supabase (временный)

Проверяет, что backend может подключиться к Supabase (`profiles`, `select id limit 1`). Успех: `{"status": "ok", "supabase": "connected"}`. Ошибка: `500` с `detail: "Supabase connection failed"` (без ключей и данных пользователей).

**Перед production** этот endpoint нужно удалить или защитить (auth, IP allowlist, отключение вне `development`).

### Пример: POST /generate

```bash
curl -X POST http://127.0.0.1:8000/generate ^
  -H "Content-Type: application/json" ^
  -d "{\"prompt\": \"a sunset over mountains\"}"
```

Ответ:

```json
{
  "image_url": "https://placehold.co/1024x1024?text=Generated+Image",
  "prompt": "a sunset over mountains"
}
```

Пустой prompt (после trim) → `400` с телом `{"detail": "Prompt cannot be empty"}`.
