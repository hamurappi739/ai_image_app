# Environment / config checklist

Режимы запуска backend и правила для `.env`. **Не коммитить** `backend/.env`.

Связанные документы: [demo_release_checklist.md](demo_release_checklist.md), [production_safety_checklist.md](production_safety_checklist.md), [gemini_test_checklist.md](gemini_test_checklist.md).

---

## A. Общие правила

| Правило | Почему |
|---------|--------|
| **Никогда не коммитить** `backend/.env` | Содержит секреты |
| `backend/.env.example` — только **placeholders** | Шаблон для команды |
| Production: секреты через **secure env / CI secrets** | Не в репозитории |
| **`TEST_USER_ID`** — только development | В production fallback отключён в коде; в env переменная должна быть **пустой** |
| **Mock payment** (`/payments/rustore/mock-verify*`) — только `ENVIRONMENT=development` | Не реальная оплата |
| **`/debug/*`** — только development | Иначе 404 |
| Frontend **не начисляет** баланс | Только backend verification |

Скопировать шаблон:

```powershell
copy backend\.env.example backend\.env
# Заполнить SUPABASE_* и при необходимости GEMINI_API_KEY локально
```

---

## B. Local development safe mode

**Назначение:** ежедневная разработка без риска — mock-изображения, без списаний, без расхода Gemini.

| Переменная | Значение |
|------------|----------|
| `ENVIRONMENT` | `development` |
| `IMAGE_PROVIDER` | `mock` |
| `ENABLE_CREDIT_CONSUMPTION` | `false` |
| `ENABLE_PHOTOSHOOT_GENERATION` | `false` |
| `PHOTOSHOOT_OUTPUT_COUNT` | `1` (не используется, пока фотосессии выключены) |

Опционально: `TEST_USER_ID=<uuid>` для Flutter без Supabase Auth.

**Поведение:** генерации через placeholder; баланс в UI из API, но не списывается; фотосессии → `501` если generation off.

---

## C. Demo mode with balance consumption

**Назначение:** демо APK / презентация — полная логика баланса, mock-изображения, mock-пополнение в **Пакеты**, Gemini **не** тратится.

| Переменная | Значение |
|------------|----------|
| `ENVIRONMENT` | `development` |
| `IMAGE_PROVIDER` | `mock` |
| `ENABLE_CREDIT_CONSUMPTION` | `true` |
| `ENABLE_PHOTOSHOOT_GENERATION` | `true` |
| `PHOTOSHOOT_OUTPUT_COUNT` | `3` |

Нужны: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` (и при Auth — `SUPABASE_ANON_KEY`).

**Поведение:** списание после успешной генерации; mock-verify пополняет баланс; 3 mock-кадра на фотосессию.

Подробнее: [demo_release_checklist.md](demo_release_checklist.md) раздел A.

---

## D. Gemini safe test mode

**Назначение:** проверка **реального** Gemini; баланс **не** списывается; **осторожно** — каждая генерация тратит Gemini API.

| Переменная | Значение |
|------------|----------|
| `ENVIRONMENT` | `development` |
| `IMAGE_PROVIDER` | `gemini` |
| `ENABLE_CREDIT_CONSUMPTION` | `false` |
| `ENABLE_PHOTOSHOOT_GENERATION` | `true` |
| `PHOTOSHOOT_OUTPUT_COUNT` | `3` |

Обязательно: `GEMINI_API_KEY` в локальном `.env` (не коммитить).

**Поведение:** реальные изображения в Storage/Галерея; без списания paid/free через consumption.

Подробнее: [gemini_test_checklist.md](gemini_test_checklist.md).

---

## E. Future production mode

**Назначение:** публичный или закрытый production-запуск. **Пока не развёрнут.**

| Переменная / правило | Значение |
|----------------------|----------|
| `ENVIRONMENT` | `production` |
| `IMAGE_PROVIDER` | `gemini` |
| `ENABLE_CREDIT_CONSUMPTION` | `true` |
| `ENABLE_PHOTOSHOOT_GENERATION` | `true` |
| `PHOTOSHOOT_OUTPUT_COUNT` | `3` |
| `TEST_USER_ID` | **пусто / отсутствует** |
| Debug endpoints | **404** |
| Mock payment | **404** |
| Клиент | **Authorization: Bearer** обязателен |
| CORS | Явный список trusted origins (не `*`) |
| RuStore | Real server verification **до** платного запуска |

Секреты: `GEMINI_API_KEY`, `SUPABASE_SERVICE_ROLE_KEY` — только secure storage.

См. [production_safety_checklist.md](production_safety_checklist.md).

---

## F. Dangerous combinations

| Комбинация | Риск | Действие |
|------------|------|----------|
| `ENVIRONMENT=production` + `TEST_USER_ID` задан | Обход auth в dev-логике / путаница | **Не использовать**; оставить `TEST_USER_ID` пустым |
| `ENVIRONMENT=production` + `IMAGE_PROVIDER=mock` | Пользователи видят заглушки | **Не для** публичного запуска |
| `ENVIRONMENT=production` + `ENABLE_CREDIT_CONSUMPTION=false` | Бесплатные генерации для всех с токеном | Только **временный** internal test, не публичный релиз |
| Mock-verify в демо | Воспринимается как оплата | Это **не** RuStore; только development |
| `POST /debug/add-balance` | Ручное начисление | Только dev; **не** для пользователей в production |
| `GEMINI_API_KEY` в git / в логах | Утечка | Только `.env` / secrets |
| `SUPABASE_SERVICE_ROLE_KEY` на клиенте | Полный доступ к БД | **Только backend** |

---

## G. Quick commands (PowerShell)

Предполагается: `cd backend`, venv активирован, `.env` с Supabase заполнен.

### Safe local mode

```powershell
cd C:\Users\shuly\Desktop\ai_image_app\backend
$env:ENVIRONMENT='development'
$env:IMAGE_PROVIDER='mock'
$env:ENABLE_CREDIT_CONSUMPTION='false'
$env:ENABLE_PHOTOSHOOT_GENERATION='false'
$env:PHOTOSHOOT_OUTPUT_COUNT='1'
python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

### Demo mode (mock + balance)

```powershell
cd C:\Users\shuly\Desktop\ai_image_app\backend
$env:ENVIRONMENT='development'
$env:IMAGE_PROVIDER='mock'
$env:ENABLE_CREDIT_CONSUMPTION='true'
$env:ENABLE_PHOTOSHOOT_GENERATION='true'
$env:PHOTOSHOOT_OUTPUT_COUNT='3'
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### Gemini safe test

```powershell
cd C:\Users\shuly\Desktop\ai_image_app\backend
$env:ENVIRONMENT='development'
$env:IMAGE_PROVIDER='gemini'
$env:ENABLE_CREDIT_CONSUMPTION='false'
$env:ENABLE_PHOTOSHOOT_GENERATION='true'
$env:PHOTOSHOOT_OUTPUT_COUNT='3'
python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

> Переменные в `$env:` переопределяют `.env` на время сессии. Для постоянного режима можно править `backend/.env` локально (не коммитить).

### Проверка текущего режима (development)

```powershell
curl http://127.0.0.1:8000/debug/config
```

В production `GET /debug/config` вернёт **404**.

---

## H. Flutter API base URL (`API_BASE_URL`)

`ApiService.baseUrl` читает `--dart-define=API_BASE_URL=...`. Если не задан:

| Платформа | URL по умолчанию |
|-----------|------------------|
| Web / Chrome | `http://127.0.0.1:8000` |
| Android (и др.) | `http://10.0.2.2:8000` |

**Chrome, локальный backend:**

```powershell
cd frontend
flutter run -d chrome
```

**Chrome, внешний backend:**

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=https://your-backend.example.com
```

**Android emulator / debug APK (✅ проверено на эмуляторе):**

Backend на хосте:

```powershell
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

`--host 0.0.0.0` нужен, чтобы эмулятор достучался до API на ПК. Адрес backend с точки зрения эмулятора: **`http://10.0.2.2:8000`**.

```powershell
cd frontend
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8000
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

**`flutter run` без APK:**

```powershell
flutter run -d emulator-5554
```

**Smoke test на эмуляторе (✅):** **Профиль** (баланс), **Создать**, **Пакеты** (demo-пополнение), **Фотосессии**, **Галерея**. Подробнее: [demo_release_checklist.md](demo_release_checklist.md) §D.

**Русский ввод:** в Chrome работает; на эмуляторе — от раскладки клавиатуры; блокировки в приложении нет; на физическом телефоне — проверить отдельно.

**Debug APK, LAN / production backend (не эмулятор):**

```powershell
flutter build apk --debug --dart-define=API_BASE_URL=https://your-backend.example.com
```

Подробнее: [backend_deploy_plan.md](backend_deploy_plan.md) §8.

---

## Сводная таблица

| Режим | `IMAGE_PROVIDER` | Consumption | Photoshoot gen | Gemini cost |
|-------|------------------|-------------|----------------|-------------|
| Safe local | mock | off | off | нет |
| Demo | mock | on | on (3) | нет |
| Gemini safe test | gemini | off | on (3) | **да** |
| Production (future) | gemini | on | on (3) | да |
