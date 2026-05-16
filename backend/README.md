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
    └── image_service.py # Логика генерации (сейчас mock)
.env.example             # Шаблон переменных окружения
```

## Endpoints

| Метод | Путь | Описание |
|-------|------|----------|
| GET | `/health` | Проверка работоспособности |
| POST | `/generate` | Mock-генерация изображения по prompt |

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
