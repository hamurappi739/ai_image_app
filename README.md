# AI Image App

**Flutter + FastAPI** приложение для AI-генерации изображений.

Сейчас проект в **MVP / demo-mode** для ежедневной разработки: по умолчанию **`IMAGE_PROVIDER=mock`**. **Реальная Gemini-генерация была успешно проверена вручную** — результат сохраняется в **Supabase Storage** и отображается в **Галерее**. **Загрузка фото** (фотосессии) и **платежи** — следующие этапы.

**Статус авторизации:** добавлена **базовая авторизация** через Supabase Auth (вкладка **Профиль**: вход / регистрация / выход) с loading states для auth-действий. Работает при запуске Flutter с **`--dart-define=SUPABASE_URL=...`** и **`SUPABASE_ANON_KEY=...`**; после входа токен уходит в backend через **`ApiService`**. Backend автоматически создаёт профиль пользователя при первом **`/generate`** или **`/generations`** (profile auto-sync). **Без** Flutter Supabase config приложение продолжает работать в **demo-mode** (development fallback `TEST_USER_ID`). Подробнее: [docs/flutter_auth_setup.md](docs/flutter_auth_setup.md), [docs/project_status.md](docs/project_status.md).

**Фотосессии (demo):** можно выбрать фото локально, увидеть preview и для **бесплатного** сценария отправить выбранное фото на backend через **`multipart/form-data`**. Backend пока только **валидирует** файл (JPEG/PNG/WebP, до 10 MB) и возвращает placeholder **`501`**; реальная обработка и сохранение результатов — следующий этап.

**Backend / Supabase:** **реальная Gemini-генерация проверена вручную** — Gemini → data URL → Supabase Storage (`generated-images`) → **`public_url`** в response и **Галерея**. По умолчанию приложение работает в **`IMAGE_PROVIDER=mock`** для безопасной разработки без расхода API. Ошибки и **таймауты** Supabase REST: при недоступности БД — **`503`** вместо необработанного **`500`** traceback.

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
- Вкладка **Фотосессии** — готовые стили (бесплатные и 100 ₽), выбор фото, multipart upload (бесплатно)
- Вкладка **Профиль** — вход / регистрация через Supabase Auth (при dart-define)
- Вкладка **Пакеты** (без реальной оплаты)
- Supabase: таблицы **`profiles`**, **`generations`**, **`credit_transactions`**
- Backend: списание бесплатных / платных генераций **подготовлено** (`ENABLE_CREDIT_CONSUMPTION`)
- Backend: **Gemini → Storage → Галерея** проверен вручную; по умолчанию **`IMAGE_PROVIDER=mock`**
- Backend: безопасная обработка **Supabase timeouts** (`503`)

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
| [docs/gemini_test_checklist.md](docs/gemini_test_checklist.md) | Чек-лист безопасного ручного теста Gemini |
| [docs/flutter_auth_setup.md](docs/flutter_auth_setup.md) | Запуск Flutter с Supabase Auth |

---

## UX правила

**В пользовательском UI не использовать:** промпт, кредиты, токены.

**Использовать:** описание, идея, изображение, генерации, пакеты генераций, фотосессии.

---

## Что пока demo-mode

- **Постоянная** Gemini-генерация в dev (по умолчанию **mock**; Gemini — только контролируемые ручные тесты)
- **Загрузка** пользовательского фото (фотосессии)
- **RuStore Billing**
- Подтверждение email, восстановление пароля, production без `TEST_USER_ID`
- **Production security** (debug routes, CORS, RLS)

Gemini provider реализован и **успешно проверен вручную**; по умолчанию используется **`IMAGE_PROVIDER=mock`**.  
Повторный ручной тест Gemini — только по [docs/gemini_test_checklist.md](docs/gemini_test_checklist.md), **без лишних повторов**.

---

## Перед production

- Удалить или защитить **`/debug/*`** endpoints
- Убрать **`TEST_USER_ID` fallback**; обязательный Bearer в production
- Доработать auth: email confirmation, восстановление пароля
- Подключить **реальные платежи**
- Защитить **CORS**
- Проверить **Supabase RLS**
- **Не коммитить** `.env`
- Включить **Gemini в production** — после проверки стоимости/лимитов и production cleanup
