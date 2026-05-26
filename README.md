# AI Image App

**Flutter + FastAPI** приложение для AI-генерации изображений.

Сейчас проект в **MVP / demo-mode**: пользовательский flow уже работает. **Реальная генерация** (Gemini), **загрузка фото**, **авторизация** и **платежи** будут подключены следующими этапами.

---

## Что уже готово

- Flutter **web** UI на **русском** языке
- Вкладка **Создать**
- Генерация через backend **`POST /generate`** (demo-mode)
- Результат на экране + **fallback-preview** при ошибке загрузки картинки
- Кнопка **«Открыть в Галерее»**
- **Галерея** загружает историю через **`GET /generations`**
- Новые изображения добавляются **сверху**
- Локальная кнопка **«Очистить»** (без удаления данных в Supabase)
- Вкладка **Фотосессии** — готовые стили (бесплатные и 100 ₽)
- **Demo modal** будущей загрузки фото
- Вкладки **Пакеты** и **Профиль** (placeholder)
- Supabase: таблицы **`profiles`**, **`generations`**, **`credit_transactions`**
- Backend: списание бесплатных / платных генераций **подготовлено** (`ENABLE_CREDIT_CONSUMPTION`)

---

## Структура проекта

| Папка | Назначение |
|-------|------------|
| `backend/` | FastAPI backend |
| `frontend/` | Flutter app |
| `docs/` | Документация |

Подробнее по запуску: `backend/README.md`, `frontend/README.md`.

---

## Быстрый запуск backend

**Windows PowerShell:**

```powershell
cd C:\Users\shuly\Desktop\ai_image_app\backend
.\.venv\Scripts\python.exe -m uvicorn app.main:app --reload
```

| | |
|---|---|
| Backend | http://127.0.0.1:8000 |
| Health check | http://127.0.0.1:8000/health |

Скопируйте `backend/.env.example` → `backend/.env` и заполните Supabase-ключи. **Не коммитьте** `.env`.

---

## Быстрый запуск frontend

```powershell
cd C:\Users\shuly\Desktop\ai_image_app\frontend
flutter pub get
flutter run -d chrome
```

Flutter **web** обращается к backend: **http://127.0.0.1:8000**

Android emulator (позже): **http://10.0.2.2:8000**. Сборка Android пока отложена (Gradle / SSL).

---

## Основные backend endpoints

| Метод | Путь | Назначение |
|-------|------|------------|
| GET | `/health` | Проверка сервера |
| POST | `/generate` | Генерация по описанию |
| GET | `/generations` | История генераций (`?limit=20`) |

- Маршруты **`/debug/*`** — **только development**. Перед production их нужно **удалить или защитить**.
- Flutter **production** не должен вызывать `/debug/*`.

Контракт: [docs/api_contract.md](docs/api_contract.md).

---

## Документация

| Файл | Описание |
|------|----------|
| [docs/project_status.md](docs/project_status.md) | Текущий технический статус |
| [docs/demo_script.md](docs/demo_script.md) | Сценарий показа MVP |
| [docs/app_design_strategy.md](docs/app_design_strategy.md) | UI / UX стратегия |
| [docs/api_contract.md](docs/api_contract.md) | Контракт API |
| [docs/roadmap.md](docs/roadmap.md) | Roadmap |
| [docs/database_schema.md](docs/database_schema.md) | Схема Supabase |

---

## UX правила

**В пользовательском UI не использовать:** промпт, кредиты, токены.

**Использовать:** описание, идея, изображение, генерации, пакеты генераций, фотосессии.

---

## Что пока demo-mode

- Реальная **Gemini**-генерация
- **Загрузка** пользовательского фото (фотосессии)
- **RuStore Billing**
- **Авторизация**
- Полноценное **сохранение истории по аккаунту**
- **Production security** (debug routes, CORS, RLS)

---

## Перед production

- Удалить или защитить **`/debug/*`** endpoints
- Заменить **`TEST_USER_ID`** на **auth user id**
- Подключить **авторизацию**
- Подключить **реальные платежи**
- Защитить **CORS**
- Проверить **Supabase RLS**
- **Не коммитить** `.env`
- Подключить **реальное хранение** изображений
