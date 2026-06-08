# Backend deploy plan

План будущего деплоя **FastAPI backend** для внешних пользователей. **Реальный деплой не выполнен** — только документация.

Связанные документы: [env_config_checklist.md](env_config_checklist.md), [production_safety_checklist.md](production_safety_checklist.md), [demo_release_checklist.md](demo_release_checklist.md), [rustore_integration_plan.md](rustore_integration_plan.md).

---

## 1. Current state

| Сейчас | Для внешних пользователей |
|--------|---------------------------|
| Backend локально: `uvicorn app.main:app` на порту **8000** | Публичный **HTTPS** endpoint |
| Flutter web: `http://127.0.0.1:8000` | Production API URL |
| Flutter Android dev: `http://10.0.2.2:8000` (emulator) | Тот же публичный URL в release-сборке |
| `ENVIRONMENT=development` в committed `.env` | `ENVIRONMENT=production` на сервере |
| Supabase: Auth, `profiles`, balance, `generations`, Storage | Тот же проект Supabase (production review) |

Backend уже использует Supabase REST (httpx) для профилей, баланса, истории, `payment_transactions`, Storage bucket `generated-images`.

---

## 2. Hosting options

Выбор хостинга — **отдельное решение** команды. Варианты:

### Managed PaaS (проще старт)

| Платформа | Плюсы | Минусы |
|-----------|-------|--------|
| **Railway** | Быстрый deploy, env vars, HTTPS | Зависимость от региона/цены |
| **Render** | Free/low tiers, health checks | Cold start на free tier |
| **Fly.io** | Глобальные регионы, Docker | Чуть сложнее настройка |

Подходят для MVP: один контейнер/процесс uvicorn, env из dashboard.

### VPS / cloud VM (больше контроля)

- Полный контроль: nginx/Caddy, systemd, firewall
- Примеры: Hetzner, DigitalOcean, AWS EC2, GCP Compute

### Российские облака (если нужна юрисдикция / latency)

- **Selectel**, **Timeweb Cloud**, **Yandex Cloud** — возможны как self-managed VPS или managed containers
- RuStore и аудитория в РФ могут влиять на выбор региона

**Рекомендация на этапе плана:** начать с managed PaaS для скорости; перейти на VPS при росте нагрузки или требованиях compliance.

---

## 3. Required production env

Задавать через **secure env** на хостинге (не в git). См. [env_config_checklist.md](env_config_checklist.md) раздел E.

| Переменная | Production значение | Примечание |
|------------|---------------------|------------|
| `ENVIRONMENT` | `production` | Включает auth guards, отключает debug/mock |
| `IMAGE_PROVIDER` | `gemini` | Не `mock` для публичного запуска |
| `ENABLE_CREDIT_CONSUMPTION` | `true` | Списание баланса |
| `ENABLE_PHOTOSHOOT_GENERATION` | `true` | Реальные фотосессии |
| `PHOTOSHOOT_OUTPUT_COUNT` | `3` | По продукту |
| `SUPABASE_URL` | `https://….supabase.co` | Secret / env |
| `SUPABASE_ANON_KEY` | JWT anon | Для backend auth validation + Flutter |
| `SUPABASE_SERVICE_ROLE_KEY` | service role | **Только backend**, never client |
| `GEMINI_API_KEY` | API key | Secret |
| `SUPABASE_STORAGE_BUCKET` | `generated-images` | Или production bucket name |
| `FREE_GENERATIONS_LIMIT` | `3` | По продукту |
| `CORS_ALLOWED_ORIGINS` | *(future)* | См. раздел 6 — пока в коде `*` для dev |

### Запрещено / пусто в production

| Переменная | Правило |
|------------|---------|
| `TEST_USER_ID` | **Не задавать** — fallback только development |
| Mock payments | Недоступны (`404`) при `ENVIRONMENT=production` |
| `/debug/*` | **404** в production |
| Секреты в репозитории | **Никогда** |

### Future (RuStore)

Когда появится server-side verification:

```env
# TODO — имена уточнить при интеграции
# RUSTORE_API_KEY=
# RUSTORE_APP_ID=
```

---

## 4. Production startup command

Базовая команда:

```bash
python -m uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}
```

| Контекст | Порт |
|----------|------|
| Railway / Render / Fly.io | `$PORT` из env хостинга |
| Локально | `8000` |
| За reverse proxy | uvicorn на внутреннем порту, HTTPS на nginx/Caddy |

Опционально для production: `--workers N` (несколько воркеров) — после нагрузочного теста.

**Build:** убедиться, что на сервере установлены зависимости из `backend/requirements.txt` (или Docker image).

---

## 5. Health checks

**Endpoint:** `GET /health`

**Ожидание:**

```json
{"status": "ok"}
```

Использовать для:

- Load balancer / PaaS health probe
- Post-deploy smoke test
- Uptime monitoring

Не требует Authorization.

---

## 6. CORS

| Сейчас (development) | Production (цель) |
|----------------------|-------------------|
| `allow_origins=["*"]` в `main.py` | Явный список **trusted origins** |
| `allow_credentials=False` | Согласовать с web-клиентом |

**Зафиксировать перед запуском:**

- Flutter **mobile** APK часто не ограничивается CORS так же, как browser — но **Flutter web** и любой admin UI нуждаются в разрешённых origin.
- Примеры будущих origin: `https://app.example.com`, `https://admin.example.com`
- Переменная `CORS_ALLOWED_ORIGINS` — **планируется** в config (сейчас не в коде; final review при деплое)
- Не использовать `*` с `allow_credentials=True`

См. [production_safety_checklist.md](production_safety_checklist.md).

---

## 7. Supabase production checklist

Перед деплоем backend:

- [ ] Применены **все migrations** (`backend/db/migrations/`, `backend/migrations/`)
  - `001_initial_schema.sql`
  - `002_add_photoshoot_id_to_generations.sql`
  - `003_add_profile_balance_fields.sql`
  - `004_create_payment_transactions.sql`
- [ ] Таблица **`profiles`**: поля `paid_image_generations`, `paid_photoshoots`, free generations
- [ ] Таблица **`payment_transactions`** существует
- [ ] Таблица **`generations`** с `photoshoot_id` где нужно
- [ ] Storage bucket **`generated-images`** (или production name) создан
- [ ] **RLS / policies** — финальный review для production
- [ ] **`SUPABASE_SERVICE_ROLE_KEY`** — только на backend, не в Flutter
- [ ] **`SUPABASE_ANON_KEY`** — Flutter Supabase Auth (`--dart-define`)
- [ ] Storage policies: upload/read согласованы с backend paths `{folder}/{user_id}/...`

---

## 8. Flutter API base URL

Реализовано в `ApiService.baseUrl` (`frontend/lib/services/api_service.dart`):

| Сборка | Backend URL |
|--------|-------------|
| Web dev (без dart-define) | `http://127.0.0.1:8000` |
| Android emulator (без dart-define) | `http://10.0.2.2:8000` |
| Любая платформа + `--dart-define=API_BASE_URL=...` | Указанный URL (trailing `/` убирается) |

**Chrome, локальный backend:**

```powershell
cd frontend
flutter run -d chrome
```

**Chrome, внешний backend:**

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=https://your-backend.example.com
```

**Android emulator, локальный backend:**

```powershell
flutter run -d emulator-5554
```

**Debug APK, внешний backend:**

```powershell
flutter build apk --debug --dart-define=API_BASE_URL=https://your-backend.example.com
```

**Release APK (будущий production):**

```powershell
flutter build apk --release `
  --dart-define=API_BASE_URL=https://api.your-domain.com `
  --dart-define=SUPABASE_URL=https://xxx.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

В debug-сборке base URL один раз пишется в консоль (`debugPrint`), не в UI.

Проверить на **реальном телефоне**: `/health`, `/balance` с Bearer, генерация.

---

## 9. Deployment steps (draft)

1. **Выбрать hosting** (Railway / Render / Fly / VPS / RU cloud).
2. **Создать backend service** (Python 3.11+, install `requirements.txt`).
3. **Добавить env variables** из раздела 3 (secrets в dashboard).
4. **Применить Supabase migrations** на production project.
5. **Задеплоить backend** (git push / Docker / manual).
6. **Проверить** `GET https://<api>/health` → `{"status":"ok"}`.
7. **Проверить** `GET https://<api>/debug/config` → **404** (production).
8. **Проверить** `GET https://<api>/balance` без `Authorization` → **401**.
9. **Собрать Flutter APK** с production `API_BASE_URL` + Supabase dart-define.
10. **Smoke test на телефоне:** вход → баланс → создать → галерея → фотосессия.

Дополнительно: [production_safety_checklist.md](production_safety_checklist.md) pre-release checklist.

---

## 10. Not production yet

| Область | Статус |
|---------|--------|
| Реальный деплой backend | **Не выполнен** |
| RuStore real payment | Не подключён |
| Release signing (Android) | Не настроен |
| Trusted CORS | Не финализирован в коде |
| Supabase RLS production review | Pending |
| Real purchase verification | Pending |
| Monitoring / logging | Не настроен |
| Configurable API URL в Flutter | ✅ `API_BASE_URL` dart-define |

---

## 11. Monitoring / logging (future)

Минимальный набор после деплоя:

| Категория | Что логировать / алертить |
|-----------|---------------------------|
| **Request logs** | Method, path, status, latency (без тел запросов с PII) |
| **Errors** | 5xx rate, unhandled exceptions (Sentry / hosted logs) |
| **Gemini** | Failures, timeouts, rate limits |
| **Payments** | Verification failures (будущий RuStore endpoint) |
| **Supabase** | REST timeouts, 5xx от PostgREST |
| **Storage** | Upload failures, bucket errors |
| **Health** | `/health` probe failures → paging |

Не логировать: `GEMINI_API_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, полные Bearer tokens.

---

## Quick reference

| Документ | Зачем |
|----------|--------|
| [env_config_checklist.md](env_config_checklist.md) | Env presets |
| [production_safety_checklist.md](production_safety_checklist.md) | Auth, debug, isolation |
| [demo_release_checklist.md](demo_release_checklist.md) | Debug APK demo |
| [rustore_integration_plan.md](rustore_integration_plan.md) | Оплата после деплоя |
