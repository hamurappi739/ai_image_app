# Backend deploy plan

План будущего деплоя **FastAPI backend** на публичный HTTPS. **Реальный деплой не выполнен** — только подготовка кода, Docker и документация.

Связанные документы: [env_config_checklist.md](env_config_checklist.md), [production_safety_checklist.md](production_safety_checklist.md), [rustore_payments_plan.md](rustore_payments_plan.md), [demo_release_checklist.md](demo_release_checklist.md).

---

## 1. Что сейчас

| Сейчас | Ограничение |
|--------|-------------|
| Backend локально: `uvicorn app.main:app --host 0.0.0.0 --port 8000` | Доступен только в вашей сети |
| Flutter **Chrome**: `http://127.0.0.1:8000` (fallback без dart-define) | Только на этом компьютере |
| Flutter **Android emulator**: `http://10.0.2.2:8000` | Только emulator → host |
| Flutter **телефон в Wi‑Fi**: `http://<IP-компьютера>:8000` | Только одна Wi‑Fi сеть |
| `ENVIRONMENT=development` в локальном `.env` | Debug + mock payments включены |
| APK с LAN IP | Работает **только** пока телефон видит ваш ПК |

**Для удалённых пользователей** нужен публичный **HTTPS** backend URL и release-сборка Flutter с `--dart-define=API_BASE_URL=...`.

---

## 2. Что нужно для production

| Компонент | Зачем |
|-----------|--------|
| Сервер / облако (Railway, Render, Fly.io, VPS, RU cloud) | Постоянный процесс uvicorn |
| **HTTPS domain** | Обязателен для release APK и браузера |
| **Env variables** на хостинге | См. §3 — без коммита в git |
| **Supabase** keys | Auth, profiles, generations, `payment_transactions`, Storage |
| **Gemini** key | Если `IMAGE_PROVIDER=gemini` |
| **CORS** `ALLOWED_ORIGINS` | Для Flutter web / admin UI |
| `ENVIRONMENT=production` | Отключает debug, mock payments, `TEST_USER_ID` |
| RuStore verification | Отдельный этап — [rustore_payments_plan.md](rustore_payments_plan.md) |

---

## 3. Safe production env (пример без секретов)

Задавать через dashboard хостинга или secrets manager. **Не коммитить.**

```env
ENVIRONMENT=production
APP_VERSION=0.1.0
PORT=8000

ENABLE_CREDIT_CONSUMPTION=true
IMAGE_PROVIDER=gemini
ENABLE_PHOTOSHOOT_GENERATION=true
PHOTOSHOOT_OUTPUT_COUNT=3

SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=<anon-key>
SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
SUPABASE_STORAGE_BUCKET=generated-images

GEMINI_API_KEY=<gemini-key>
GEMINI_MODEL=gemini-2.5-flash-image

FREE_GENERATIONS_LIMIT=3

# Пусто в production — auth только Bearer
TEST_USER_ID=

# Flutter web / admin (через запятую)
ALLOWED_ORIGINS=https://your-domain.com
```

---

## 4. Demo backend env (локально / презентация)

```env
ENVIRONMENT=development
ENABLE_CREDIT_CONSUMPTION=true
IMAGE_PROVIDER=mock
ENABLE_PHOTOSHOOT_GENERATION=true
PHOTOSHOOT_OUTPUT_COUNT=3
```

Mock-пополнение в **Купить** работает через `POST /payments/rustore/mock-verify` (только development).

---

## 5. Команды локального запуска

### Demo backend (mock + списание баланса)

```powershell
cd backend
# .env: ENVIRONMENT=development, IMAGE_PROVIDER=mock,
# ENABLE_CREDIT_CONSUMPTION=true, ENABLE_PHOTOSHOOT_GENERATION=true
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### Gemini safe test (без списания)

```powershell
# Временно в .env: IMAGE_PROVIDER=gemini, ENABLE_CREDIT_CONSUMPTION=false
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### Production-like local test

```powershell
$env:ENVIRONMENT='production'
$env:TEST_USER_ID=''
python -m uvicorn app.main:app --port 8001
# Ожидание: /debug/* → 404, mock-verify → 404, /balance без Bearer → 401
```

---

## 6. Flutter API_BASE_URL

Реализовано в `frontend/lib/services/api_service.dart` — **fallback не менять**.

| Сценарий | URL |
|----------|-----|
| Chrome, локальный backend | `http://127.0.0.1:8000` (default) |
| Android emulator | `http://10.0.2.2:8000` (default) |
| Телефон в той же Wi‑Fi | `http://<IP-компьютера>:8000` (dart-define) |
| **Production APK** | **HTTPS** публичный backend |

### Локальная разработка

```powershell
cd frontend
flutter run -d chrome
flutter run -d emulator-5554
```

### Телефон в LAN (debug)

```powershell
flutter build apk --debug --dart-define=API_BASE_URL=http://192.168.x.x:8000
```

### Production release APK

```powershell
flutter build apk --release `
  --dart-define=API_BASE_URL=https://your-backend-domain.com `
  --dart-define=SUPABASE_URL=https://xxx.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

`API_BASE_URL` логируется один раз в debug-консоль при старте, не показывается в UI.

---

## 7. Docker (подготовлено, deploy не выполнен)

```powershell
cd backend
docker build -t ai-image-backend .
docker run --rm -p 8000:8000 `
  -e ENVIRONMENT=development `
  -e PORT=8000 `
  # ... остальные env через -e или --env-file (файл вне git)
  ai-image-backend
```

- `backend/Dockerfile` — Python 3.12, uvicorn на `0.0.0.0:${PORT}`
- `backend/.dockerignore` — `.env`, `.venv`, `__pycache__`, `.git`
- **`.env` не копируется в образ** — только runtime env

---

## 8. Health / readiness

| Endpoint | Назначение | Секреты |
|----------|------------|---------|
| `GET /health` | Liveness (load balancer) | **Нет** |
| `GET /ready` | Readiness (config flags) | **Нет** |

**Пример `/health`:**

```json
{
  "status": "ok",
  "environment": "development",
  "version": "0.1.0"
}
```

**Пример `/ready`:** проверяет наличие Supabase/Gemini env (флаги `*_configured`), `production_safe` (нет `TEST_USER_ID` в production). **Без** тяжёлых запросов в Supabase.

---

## 9. CORS

| Режим | `ALLOWED_ORIGINS` | Поведение |
|-------|-------------------|-----------|
| Development | пусто | `*` (все origin — для Flutter web на localhost) |
| Production | `https://app.example.com,...` | Только перечисленные origin |
| Production | пусто | Браузерные клиенты заблокированы; **mobile APK** не зависит от CORS |

Код: `app/cors.py` → `cors_allow_origins()`.

---

## 10. Что нельзя

- Коммитить `.env` с ключами
- Хранить `SUPABASE_SERVICE_ROLE_KEY` во Flutter
- Включать `/debug/*` в production (`ENVIRONMENT=production` → **404**)
- Включать mock payments в production (`mock-verify` → **404**)
- Использовать `TEST_USER_ID` в production (игнорируется auth, но env нужно очистить)
- Начислять баланс без server-side verification (см. payments plan)
- Копировать `.env` в Docker image

---

## 11. TODO перед реальным deploy

- [ ] Выбрать hosting (PaaS / VPS / RU cloud)
- [ ] Настроить domain + HTTPS (Let's Encrypt / CDN)
- [ ] Задать production env на сервере
- [ ] Применить Supabase migrations
- [ ] Проверить `GET /health` и `GET /ready`
- [ ] Проверить `GET /catalog/templates` и `/catalog/photoshoots`
- [ ] Smoke: auth → balance → generate → gallery → photoshoot
- [ ] Собрать release APK с HTTPS `API_BASE_URL`
- [ ] RuStore real payments — отдельный этап
- [ ] Мониторинг / логирование (5xx, Gemini, Supabase)

---

## 12. Deployment steps (draft)

1. Выбрать hosting.
2. Собрать Docker image или установить `requirements.txt`.
3. Задать env из §3.
4. Запустить: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`.
5. `GET https://<api>/health` → `status: ok`.
6. `GET https://<api>/ready` → `status: ready` (после настройки Supabase/Gemini).
7. `GET https://<api>/debug/config` → **404** (production).
8. Собрать Flutter APK с production URL.
9. Smoke test на телефоне.

Pre-release: [production_safety_checklist.md](production_safety_checklist.md).

---

## Hosting options (кратко)

| Тип | Примеры |
|-----|---------|
| Managed PaaS | Railway, Render, Fly.io |
| VPS | Hetzner, DigitalOcean, Selectel, Timeweb, Yandex Cloud |

Для MVP часто достаточно одного контейнера uvicorn + env из dashboard.
