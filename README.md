# AI Image App

**Flutter + FastAPI** приложение для AI-генерации изображений.

Сейчас проект в **MVP / demo-mode**: **`IMAGE_PROVIDER=mock`**, **`ENABLE_PHOTOSHOOT_GENERATION=false`**. **Onboarding**, **контекстная помощь** и **каталог фотосессий** реализованы. **«Создать»** — UI picker/preview для будущей генерации **фото + описание → одно изображение** (backend позже). **Ближайший UX** (см. [roadmap.md](docs/roadmap.md)): curated-примеры, backend для Create photo flow, «Своя фотосессия», RuStore.

**Статус авторизации:** добавлена **базовая авторизация** через Supabase Auth (вкладка **Профиль**: вход / регистрация / выход) с loading states для auth-действий. Работает при запуске Flutter с **`--dart-define=SUPABASE_URL=...`** и **`SUPABASE_ANON_KEY=...`**; после входа токен уходит в backend через **`ApiService`**. Backend автоматически создаёт профиль пользователя при первом **`/generate`** или **`/generations`** (profile auto-sync). **Без** Flutter Supabase config приложение продолжает работать в **demo-mode** (development fallback `TEST_USER_ID`). Подробнее: [docs/flutter_auth_setup.md](docs/flutter_auth_setup.md), [docs/project_status.md](docs/project_status.md).

**Фотосессии:** backend + Flutter flow проверен (Storage, **`generations`**, **`photoshoot_id`**, grouped Gallery card). По умолчанию **`ENABLE_PHOTOSHOOT_GENERATION=false`**, **`PHOTOSHOOT_OUTPUT_COUNT=1`** — safe mode после тестов.

**Backend / Supabase:** **реальная Gemini-генерация проверена вручную** — Gemini → data URL → Supabase Storage (`generated-images`) → **`public_url`** в response и **Галерея**. **Gemini photoshoot** (uploaded photo + style) также **проверен вручную** → Storage → `image_urls`; по умолчанию **`ENABLE_PHOTOSHOOT_GENERATION=false`**. Приложение работает в **`IMAGE_PROVIDER=mock`** для безопасной разработки без расхода API.

---

## Что уже готово

- Flutter **web** UI на **русском** языке
- **First-run onboarding** (5 экранов) + **контекстная помощь** на **«Создать»** и **«Фотосессии»** (автопоказ + кнопка **?**)
- **Фотосессии — catalog-style cards:** richer UI, **«3 фото»** labels, upload recommendations, placeholder result examples (real curated images later)
- **Create tab — photo picker/preview UI** for future **photo + description → single image** (backend connection planned later)
- Вкладка **Создать** — описание, `POST /generate`, **UI-каркас фото** (picker, preview, убрать; фото не на backend)
- Генерация через backend **`POST /generate`** (demo-mode)
- Результат на экране + **fallback-preview** при ошибке загрузки картинки
- Кнопка **«Открыть в Галерее»**
- **Галерея** загружает историю через **`GET /generations`** и **группирует фотосессии** по `photoshoot_id`
- Новые изображения добавляются **сверху**
- Локальная кнопка **«Очистить»** (без удаления данных в Supabase)
- Вкладка **Фотосессии** — **каталог карточек** (placeholder preview, «3 фото», цена), рекомендации по фото в sheet, выбор фото, multipart upload; успешный результат → **Галерея**
- Вкладка **Профиль** — вход / регистрация через Supabase Auth (при dart-define)
- Вкладка **Пакеты** (без реальной оплаты)
- Supabase: таблицы **`profiles`**, **`generations`**, **`credit_transactions`**
- Backend: списание бесплатных / платных генераций **подготовлено** (`ENABLE_CREDIT_CONSUMPTION`)
- Backend: **Gemini → Storage → Галерея** проверен вручную; по умолчанию **`IMAGE_PROVIDER=mock`**
- Backend: **Gemini photoshoot** + Flutter **Gallery grouping** + **`generations`** / **`photoshoot_id`**; по умолчанию **`ENABLE_PHOTOSHOOT_GENERATION=false`**
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

**Аудитория:** обычные пользователи, в том числе **40–60+** — простой интерфейс, **крупные** понятные действия.

**В пользовательском UI не использовать:** prompt, промпт, кредиты, токены, credits, tokens.

**Использовать:** описание, идея, изображение, генерации, пакеты генераций, фотосессии.

**Ближайший UX (план):** curated-примеры → **backend для фото+описание на «Создать»** → «Своя фотосессия» → помощь для «Пакетов» → RuStore. Подробнее: [docs/app_design_strategy.md](docs/app_design_strategy.md), [docs/roadmap.md](docs/roadmap.md).

---

## Что пока demo-mode

- **Постоянная** Gemini-генерация в dev (по умолчанию **mock**; Gemini — только контролируемые ручные тесты)
- **Backend для фото+описание на «Создать»** (UI-каркас готов), **«Своя фотосессия»**, **реальные curated-примеры**, **помощь для «Пакетов»**
- **Product photoshoot mode** — постоянный **`PHOTOSHOOT_OUTPUT_COUNT=3`** после решения стоимости/лимитов Gemini
- **RuStore Billing** и оплата фотосессий
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
