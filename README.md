# AI Image App

**Flutter + FastAPI** приложение для AI-генерации изображений.

Сейчас проект в **MVP / demo-mode**: committed `.env` — **`IMAGE_PROVIDER=mock`**, **`ENABLE_PHOTOSHOOT_GENERATION=false`**, **`ENABLE_CREDIT_CONSUMPTION=false`**. **Проверены оба режима:** **mock mode** (ежедневная разработка) и **реальный Gemini в safe mode** (`IMAGE_PROVIDER=gemini`, `ENABLE_CREDIT_CONSUMPTION=false`) — все три flow (`/generate`, `/generate-with-photo`, `/photoshoots/generate`) работают, результаты в **Готовых фото**, баланс не списывается. **Списание баланса** (mock) **проверено вручную** при временном `ENABLE_CREDIT_CONSUMPTION=true`. **Оплата:** реальный **RuStore не подключён**; **backend foundation** + dev **mock-verify** (готовые наборы и **«Своя сумма»**); раздел **«Купить»** в development пополняет баланс через backend (frontend не начисляет сам). Подробнее: [project_status.md](docs/project_status.md).

**Навигация (UX-redesign + mobile polish):** **burger/drawer**; баланс в **меню**, **Профиле**, **Купить** и info-блоках (**не** в верхней панели); welcome-**Главная**; главный вход — **Фото по шаблону**; после генерации — **Готовые фото**; при нулевом балансе — мягкие подсказки → **Купить**. См. [navigation_redesign_plan.md](docs/navigation_redesign_plan.md).

**Свой запрос:** free-generation notice, **categorized clickable ideas** (режимы **«Без фото»** / **«С фото»**), подсказки в **«Как получить хороший результат»**, **generation countdown modal** (~60 s). **С фото:** **`POST /generate-with-photo`** (multipart); **без фото:** **`POST /generate`** (JSON). Шаблоны из **Фото по шаблону** автоматически заполняют поле описания **расширенными текстами** из [docs/app_prompts.md](docs/app_prompts.md) (сохранение лица, без искажений, товарные правила).

**Generation UX (Фотосессии):** blocking progress dialog (~120 s) when a real backend request runs; *«Почти готово, ждём результат...»* if the timer ends first.

**Ближайшее (руководство):** **RuStore Pay SDK** в **`PaymentService`** ([roadmap.md](docs/roadmap.md), [rustore_integration_plan.md](docs/rustore_integration_plan.md)). Backend verification foundation **готов**; Android readiness audit **выполнен** (`applicationId` `com.aiimagegenerator.ai_image_generator`, SDK 24/36); release signing и финальный package name — перед публикацией в RuStore. **BillingClient (deprecated) не использовать.**

**Статус авторизации:** Supabase Auth в **Профиле** (вход / регистрация / выход). Bearer token → **`/balance`**, **`/generations`**, генерация. После выхода **Готовые фото** и баланс в UI очищаются. В **production** без `Authorization` backend возвращает **`401`**. Dev fallback **`TEST_USER_ID`** — только `ENVIRONMENT=development` без токена. **RuStore** не подключён. Подробнее: [docs/flutter_auth_setup.md](docs/flutter_auth_setup.md), [docs/project_status.md](docs/project_status.md).

**Фотосессии:** одна фотосессия = **3 фото**; backend возвращает **`image_urls`** (3), **`photoshoot_id`**, списание **1** `paid_photoshoots`; **Готовые фото** группируют по `photoshoot_id`. По умолчанию **`ENABLE_PHOTOSHOOT_GENERATION=false`** (safe mode); **`PHOTOSHOOT_OUTPUT_COUNT=3`** по умолчанию в коде.

**Backend / Supabase:** **полный Gemini smoke test в safe mode пройден** — три flow → Storage → **`public_url`** → **Готовые фото**; баланс не списывается. Для ежедневной разработки — **`IMAGE_PROVIDER=mock`**; **`ENABLE_PHOTOSHOOT_GENERATION=false`** по умолчанию.

---

## Что уже готово

- Flutter **web** UI на **русском** языке
- **UX-redesign + mobile polish:** burger/drawer, баланс в **drawer/Профиль/Купить** (не в шапке), компактные карточки, welcome-**Главная**, **Готовые фото** с success и быстрыми действиями
- **First-run onboarding** (5 экранов) + **контекстная помощь**; help hub
- **Фото по шаблону** — **17** шаблонов **по категориям**, короткое описание + **расширенный промпт** ([app_prompts.md](docs/app_prompts.md)); → **Свой запрос**
- **Фотосессии** — **15** стилей с расширенными style prompt; **`description`** в `/photoshoots/generate`; **«Своя фотосессия»** с длинными чипами; после успеха → **Готовые фото**
- **Свой запрос** — фото → описание → **«Создать фото»** → **Готовые фото**; мягкие подсказки при нулевом балансе
- Генерация через backend **`POST /generate`** (demo-mode)
- Результат на экране + **fallback-preview** при ошибке загрузки картинки
- **Готовые фото** — **`GET /generations`**, группировка фотосессий, success-блок, **«Что сделать дальше?»**
- Новые изображения добавляются **сверху**
- Локальная кнопка **«Очистить»** (без удаления данных в Supabase)
- **Профиль** — вход / регистрация через Supabase Auth (при dart-define)
- **Купить** — mixed UI (**199/499/999 ₽**), **«Фото + фотосессии»** / **«Только фото»**, **«Своя сумма»** (min **10 ₽**), баннер баланса; dev **mock top-up** через backend; **реальный RuStore — не подключён**
- Supabase: таблицы **`profiles`**, **`generations`**, **`credit_transactions`**
- Backend + Flutter: **списание баланса проверено вручную**; UI refresh в **drawer**, **Профиль**, **Купить**, info-блоках на экранах
- **Русский ввод** на **«Свой запрос»** в Chrome; на Android emulator и **физическом телефоне** — от раскладки клавиатуры (блокировки в приложении нет)
- **Redesigned debug APK на физическом Android-телефоне (✅):** LAN `API_BASE_URL=http://192.168.31.242:8000`, demo mock backend; новый UX (drawer, шаблоны, все разделы)
- Backend: **mock mode** и **Gemini safe mode** — все три generation flow **проверены вручную**; результаты в **Готовых фото**
- Backend: **Gemini photoshoot** (3 кадра) + Flutter **Gallery grouping** + **`photoshoot_id`**; по умолчанию **`ENABLE_PHOTOSHOOT_GENERATION=false`**
- Backend: **payment foundation** — `payment_transactions`, package catalog, dev **`POST /payments/rustore/mock-verify`** и **`POST /payments/rustore/mock-verify-custom`**
- **Купить (dev):** **`PaymentService`** → mock-verify → баланс в drawer и на экранах; RuStore SDK — **не подключён**
- **Реальный RuStore Pay SDK** — **не подключён**; Android readiness audit — [rustore_integration_plan.md](docs/rustore_integration_plan.md)
- Backend: **Gemini quality instructions** (`gemini_quality_instructions.py`) — anti-collage/grid, identity preservation, 3 separate photoshoot frames; **mock unchanged**

---

## Структура проекта

| Папка | Назначение |
|-------|------------|
| `backend/` | FastAPI backend |
| `frontend/` | Flutter app |
| `docs/` | Документация |

Подробнее по запуску: `backend/README.md`, `frontend/README.md`.

### Demo APK / release readiness

Сборка debug APK, установка на Android, режимы backend для демо и что **ещё не production** — см. **[docs/demo_release_checklist.md](docs/demo_release_checklist.md)**.

**Проверено на Android emulator:** debug APK с `--dart-define=API_BASE_URL=http://10.0.2.2:8000`, backend `uvicorn … --host 0.0.0.0 --port 8000`.

**Проверено на физическом Android-телефоне (✅, UX-redesign):**

```powershell
# backend (раздел A в demo_release_checklist.md):
# ENABLE_CREDIT_CONSUMPTION=true, IMAGE_PROVIDER=mock,
# ENABLE_PHOTOSHOOT_GENERATION=true, PHOTOSHOOT_OUTPUT_COUNT=3
# python -m uvicorn app.main:app --host 0.0.0.0 --port 8000

flutter build apk --debug --dart-define=API_BASE_URL=http://192.168.31.242:8000
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

Проверены: **Главная**, «Начать создавать» → **Фото по шаблону**, drawer, все разделы меню, шаблон → **Свой запрос**, фото + генерация, **Фотосессии**, **Купить**, **Готовые фото**, **Помощь** (без overflow). Режим: demo mock + списание баланса.

**Для распространения всё ещё нужны:** production backend deploy, публичный HTTPS `API_BASE_URL`, release signing, RuStore, тест на нескольких Android-устройствах.

### Demo user flow (ручная проверка)

1. Открыть приложение → **Главная**
2. Нажать **«Начать создавать»** → **Фото по шаблону**
3. Выбрать шаблон → **Свой запрос** (описание уже заполнено)
4. Добавить своё фото → **«Создать фото»**
5. Откроется **Готовые фото** — success-блок и результат
6. Drawer: проверить **баланс**; при необходимости — **Купить**

Полный UX checklist для APK: [demo_release_checklist.md](docs/demo_release_checklist.md) § **I**.

### Production safety

Debug/mock endpoints только в development; production требует Authorization; чеклист перед релизом — **[docs/production_safety_checklist.md](docs/production_safety_checklist.md)**.

### Environment modes

| Режим | Назначение |
|-------|------------|
| **Safe local** | mock, без списаний, без Gemini |
| **Demo mock + balance** | mock, списания и mock-пополнение для демо |
| **Gemini safe test** | реальный Gemini, без списаний (осторожно с API) |
| **Production** (future) | gemini, consumption on, auth обязателен |

Переменные и PowerShell-команды — **[docs/env_config_checklist.md](docs/env_config_checklist.md)**. Шаблон: `backend/.env.example`.

### Backend deploy / production URL

План деплоя FastAPI на публичный **HTTPS** (env, Docker, health, CORS, Flutter `API_BASE_URL`). Реальный deploy **ещё не выполнен**.

| Локально | Production APK |
|----------|----------------|
| Chrome → `http://127.0.0.1:8000` | `--dart-define=API_BASE_URL=https://your-backend-domain.com` |
| Emulator → `http://10.0.2.2:8000` | HTTPS обязателен |
| Телефон в Wi‑Fi → IP компьютера | Публичный URL, не LAN |

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://your-backend-domain.com
```

Подробнее: **[docs/backend_deploy_plan.md](docs/backend_deploy_plan.md)** · безопасность: **[docs/production_safety_checklist.md](docs/production_safety_checklist.md)**

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

**Chrome, локальный backend (по умолчанию):**

```powershell
cd C:\Users\shuly\Desktop\ai_image_app\frontend
flutter pub get
flutter run -d chrome
```

**Chrome, внешний backend:**

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=https://your-backend.example.com
```

**Android emulator / debug APK (локальный backend на ПК):**

```powershell
# backend (отдельный терминал):
# cd backend
# python -m uvicorn app.main:app --host 0.0.0.0 --port 8000

flutter run -d emulator-5554

# или установка debug APK:
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8000
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

Эмулятор обращается к backend хост-машины по **`http://10.0.2.2:8000`**.

**Debug APK на физическом телефоне (LAN, проверено):**

```powershell
# ПК и телефон в одной Wi‑Fi; backend: --host 0.0.0.0 --port 8000
flutter build apk --debug --dart-define=API_BASE_URL=http://192.168.31.242:8000
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

Замените `192.168.31.242` на LAN IP вашего ПК. Для production-like теста: `https://your-backend.example.com`.

| Платформа | URL по умолчанию (без dart-define) |
|-----------|-------------------------------------|
| Web / Chrome | `http://127.0.0.1:8000` |
| Android emulator | `http://10.0.2.2:8000` |
| Физический телефон | **Нет** рабочего default — нужен `--dart-define=API_BASE_URL=...` (LAN IP или HTTPS) |

Переопределение: `ApiService.baseUrl` ← `--dart-define=API_BASE_URL=...` (см. [backend_deploy_plan.md](docs/backend_deploy_plan.md)).

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
| [docs/navigation_redesign_plan.md](docs/navigation_redesign_plan.md) | UX-redesign: drawer, разделы, статус |
| [docs/flutter_auth_setup.md](docs/flutter_auth_setup.md) | Запуск Flutter с Supabase Auth |
| [docs/app_prompts.md](docs/app_prompts.md) | Тексты шаблонов, фотосессий и чипов «Своя фотосессия» |
| [docs/preview_assets_checklist.md](docs/preview_assets_checklist.md) | План локальных preview-картинок (имена, папки, MVP pack) |
| [docs/current_project_snapshot.md](docs/current_project_snapshot.md) | Итоговый snapshot состояния проекта (MVP / demo) |

---

## UX правила

**Аудитория:** женщины **40+** и обычные пользователи — простой интерфейс, **крупные** понятные действия, **меньше текста, больше визуальных подсказок**.

**В пользовательском UI не использовать:** prompt, промпт, кредиты, токены, credits, tokens, package.

**Использовать:** **фото**, **фотосессия**, **готовые фото**, **купить**, **баланс**, **описание**, **идея**.

**Разделы (drawer):** Главная, Фото по шаблону, Фотосессии, Трендовые фотосессии, Свой запрос, Готовые фото, Купить, Профиль, Помощь.

**Навигация:** burger menu; баланс в drawer и на экранах покупки/профиля (не в шапке); путь **шаблон → Свой запрос → Готовые фото**. [app_design_strategy.md](docs/app_design_strategy.md), [navigation_redesign_plan.md](docs/navigation_redesign_plan.md), [roadmap.md](docs/roadmap.md).

---

## Что пока demo-mode

- **Постоянная** Gemini-генерация в dev (по умолчанию **mock**; Gemini — только контролируемые ручные тесты)
- **Купить** — mixed UI + balance banner; **оплата / RuStore не подключены**
- **Balance debit** — проверено вручную (images + **photo generation** + mock photoshoot); **real purchase top-up** — в плане
- **Расширенные промпты** шаблонов / фотосессий / чипов — ✅ ([app_prompts.md](docs/app_prompts.md))
- **Curated preview-изображения** на карточках (вместо gradient placeholders) — в плане
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
