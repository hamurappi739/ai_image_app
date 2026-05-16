# AI Image Generator

Мобильное приложение для генерации изображений с помощью AI.

## Структура проекта

| Папка | Описание |
|-------|----------|
| `backend/` | FastAPI API |
| `frontend/` | Flutter клиент |
| `docs/` | Документация и план разработки |

## Быстрый старт (backend)

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate   # Windows
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Проверка: [http://127.0.0.1:8000/health](http://127.0.0.1:8000/health)

## Roadmap

См. [docs/roadmap.md](docs/roadmap.md).
