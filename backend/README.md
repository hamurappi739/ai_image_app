# Backend

FastAPI-сервер для AI Image Generator.

## Запуск

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Сервер: [http://127.0.0.1:8000](http://127.0.0.1:8000)

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
