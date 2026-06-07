# AI Image App

**Flutter + FastAPI** приложение для AI-генерации изображений.

Сейчас проект в **MVP / demo-mode**: committed `.env` — **`IMAGE_PROVIDER=mock`**, **`ENABLE_PHOTOSHOOT_GENERATION=false`**, **`ENABLE_CREDIT_CONSUMPTION=false`**. **Проверены оба режима:** **mock mode** (ежедневная разработка) и **реальный Gemini в safe mode** (`IMAGE_PROVIDER=gemini`, `ENABLE_CREDIT_CONSUMPTION=false`) — все три flow (`/generate`, `/generate-with-photo`, `/photoshoots/generate`) работают, результаты в **Галерее**, баланс не списывается. **Списание баланса** (mock) **проверено вручную** при временном `ENABLE_CREDIT_CONSUMPTION=true`. **Оплата / RuStore не подключены.** Подробнее: [project_status.md](docs/project_status.md).

**Create tab:** free-generation notice, **categorized clickable ideas** (modes **«Без фото»** / **«С фото»**), mode-specific guidance in **«Как получить хороший результат»**, and a **generation countdown modal** (~60 s, dimmed background). **With photo:** **`POST /generate-with-photo`** (multipart); **without photo:** **`POST /generate`** (JSON). Balance debited **only after successful generation**; mock mode works without Gemini.

**Generation UX (Фотосессии):** blocking progress dialog (~120 s) when a real backend request runs; *«Почти готово, ждём результат...»* if the timer ends first.

**Ближайшее (руководство):** **RuStore** + real purchase top-up ([roadmap.md](docs/roadmap.md)). Backend **generation quality** instructions для Gemini **реализованы** (`gemini_quality_instructions.py`). Balance debit flow **manually checked** for regular images, **photo generation**, and mock photoshoots.

**Статус авторизации:** Supabase Auth во вкладке **Профиль** (вход / регистрация / выход). Bearer token передаётся в **`/balance`**, **`/generations`**, **`/generate`**, **`/generate-with-photo`**, **`/photoshoots/generate`**. После выхода Галерея и баланс в UI очищаются; данные разных пользователей не смешиваются. В **production** без `Authorization` backend возвращает **`401`**. Dev fallback **`TEST_USER_ID`** — только `ENVIRONMENT=development` без токена. **RuStore** не подключён. Подробнее: [docs/flutter_auth_setup.md](docs/flutter_auth_setup.md), [docs/project_status.md](docs/project_status.md).

**Фотосессии:** одна фотосессия = **3 фото**; backend возвращает **`image_urls`** (3), **`photoshoot_id`**, списание **1** `paid_photoshoots`; **Галерея** группирует по `photoshoot_id`. По умолчанию **`ENABLE_PHOTOSHOOT_GENERATION=false`** (safe mode); **`PHOTOSHOOT_OUTPUT_COUNT=3`** по умолчанию в коде.

**Backend / Supabase:** **полный Gemini smoke test в safe mode пройден** — `POST /generate`, `POST /generate-with-photo`, `POST /photoshoots/generate` (3 кадра) → Storage → **`public_url`** → **Галерея**; баланс не списывается. Для ежедневной разработки — **`IMAGE_PROVIDER=mock`**; **`ENABLE_PHOTOSHOOT_GENERATION=false`** по умолчанию.

---

## Что уже готово

- Flutter **web** UI на **русском** языке
- **First-run onboarding** (5 экранов) + **контекстная помощь** на **«Создать»**, **«Фотосессии»**, **«Пакеты»** (кнопка **«Помощь»**; автопоказ на **Создать** / **Фотосессии**)
- **Фотосессии — catalog-style cards** + **Custom photoshoot UI placeholder** (photo picker, пожелания, «Как описать лучше»; backend later)
- **Create tab** — free-generation notice; **categorized clickable ideas** (without-photo / with-photo modes); mode-specific **«Как получить хороший результат»**; **generation countdown modal** (~60 s); photo picker + **`POST /generate-with-photo`** when photo selected; **`POST /generate`** by description when no photo
- Генерация через backend **`POST /generate`** (demo-mode)
- Результат на экране + **fallback-preview** при ошибке загрузки картинки
- Кнопка **«Открыть в Галерее»**
- **Галерея** загружает историю через **`GET /generations`** и **группирует фотосессии** по `photoshoot_id`
- Новые изображения добавляются **сверху**
- Локальная кнопка **«Очистить»** (без удаления данных в Supabase)
- Вкладка **Фотосессии** — **каталог** (8 стилей + **«Своя фотосессия»** UI), рекомендации в sheet, multipart upload для готовых стилей → **Галерея**; при запросе на backend — **progress dialog** (~120 с)
- Вкладка **Профиль** — вход / регистрация через Supabase Auth (при dart-define)
- Вкладка **Пакеты** — mixed package UI (**199/499/999 ₽**), **«С фотосессиями»** / **«Только изображения»**, **«Своя сумма»** (min **10 ₽**), баннер баланса; **оплата не подключена**
- Supabase: таблицы **`profiles`**, **`generations`**, **`credit_transactions`**
- Backend + Flutter: **списание баланса проверено вручную** — free → `paid_image_generations`; mock photoshoot → −1 `paid_photoshoots`; `balance` в response; UI refresh в **Профиль** / **Пакеты** / **Создать**
- **Русский ввод** на вкладке **Создать**; **mock-фотосессия** на Android emulator (debug, тестовое фото)
- Backend: **mock mode** и **Gemini safe mode** — все три generation flow **проверены вручную**; результаты в **Галерее**
- Backend: **Gemini photoshoot** (3 кадра) + Flutter **Gallery grouping** + **`photoshoot_id`**; по умолчанию **`ENABLE_PHOTOSHOOT_GENERATION=false`**
- **Оплата / RuStore** — **не подключены** (UI пакетов — placeholder)
- Backend: **Gemini quality instructions** (`gemini_quality_instructions.py`) — anti-collage/grid, identity preservation, 3 separate photoshoot frames; **mock unchanged**

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

**Аудитория:** обычные пользователи, в том числе **40–60+** — простой интерфейс, **крупные** понятные действия.

**В пользовательском UI не использовать:** prompt, промпт, кредиты, токены, credits, tokens.

**Использовать:** описание, идея, **изображение** / **изображений**, **фотосессия** / **фотосессии**, **пакеты**; баланс: *«осталось: N изображений и M фотосессий»* (не «кредиты»).

**Ближайший UX (план):** **402 UI polish** → backend prompts for **face/quality** → curated visuals → **RuStore**. **Готово:** balance display + debit flow (manually checked), **Create photo generation** (`POST /generate-with-photo`), categorized ideas, countdown modal, Russian input. [app_design_strategy.md](docs/app_design_strategy.md), [roadmap.md](docs/roadmap.md).

---

## Что пока demo-mode

- **Постоянная** Gemini-генерация в dev (по умолчанию **mock**; Gemini — только контролируемые ручные тесты)
- **Packages tab** — mixed UI + balance banner; **оплата / RuStore не подключены**
- **Balance debit** — проверено вручную (images + **photo generation** + mock photoshoot); **real purchase top-up** — в плане
- **Generation quality** prompts, **curated examples** — в плане
- **Backend** для **«Своей фотосессии»** (UI-каркас готов), **реальные curated-примеры**
- Подтверждение email, восстановление пароля, production без `TEST_USER_ID`
- **Production security** (debug routes, CORS, RLS)

Gemini provider и **Gemini photoshoot → Flutter Gallery** реализованы и **успешно проверены вручную**; по умолчанию **`IMAGE_PROVIDER=mock`**, **`ENABLE_PHOTOSHOOT_GENERATION=false`**.  
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
