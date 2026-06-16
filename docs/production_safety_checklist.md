# Production safety checklist

Аудит безопасности перед публичным запуском. **Текущий demo/development flow не отключён.**

Связанные документы: [demo_release_checklist.md](demo_release_checklist.md), [rustore_integration_plan.md](rustore_integration_plan.md), [rustore_payments_plan.md](rustore_payments_plan.md), [api_contract.md](api_contract.md).

**Env mode checklist:** [env_config_checklist.md](env_config_checklist.md).

---

## Environment

| Переменная | Development (сейчас) | Production (цель) |
|------------|----------------------|-------------------|
| `ENVIRONMENT` | `development` | `production` |
| `TEST_USER_ID` | Fallback без Bearer | **Не используется** |
| `ENABLE_CREDIT_CONSUMPTION` | `true` / `false` по сценарию | Обычно `true` |
| `IMAGE_PROVIDER` | `mock` / `gemini` | `gemini` (или policy) |
| `ENABLE_PHOTOSHOOT_GENERATION` | по сценарию | по policy |

**Проверено:** `settings.environment` читается из `.env`; guards сравнивают `strip().lower() == "development"`.

---

## Auth

| Endpoint | Development | Production |
|----------|-------------|------------|
| `GET /balance` | Bearer или `TEST_USER_ID` | **401** без Bearer |
| `GET /generations` | Bearer или `TEST_USER_ID` | **401** без Bearer |
| `POST /generate` | Без Bearer только если `ENVIRONMENT=development` и consumption off | **401** без Bearer (всегда) |
| `POST /generate-with-photo` | То же | **401** без Bearer |
| `POST /photoshoots/generate` | Bearer или `TEST_USER_ID` | **401** без Bearer |
| Mock payment | Bearer или `TEST_USER_ID` + **404** если не development | **401** / **404**, баланс не начисляется |

Реализация: `app/auth.py` → `get_current_user()`; `app/main.py` → `_optional_user_for_generation()` для generate endpoints.

---

## Debug endpoints (development-only)

Все возвращают **404**, если `ENVIRONMENT` ≠ `development`:

| Endpoint |
|----------|
| `GET /debug/config` |
| `GET /debug/supabase` |
| `POST /debug/storage-test` |
| `POST /debug/storage-image-test` |
| `POST /debug/storage-image-persist` |
| `GET /debug/profile` |
| `GET /debug/credits` |
| `GET /debug/history` |
| `POST /debug/consume-generation` |
| `POST /debug/add-balance` |
| `POST /debug/add-credits` |

`GET /debug/config` возвращает только **флаги** (`*_configured`), не секреты.

---

## Mock payments (development-only)

| Endpoint | Guard |
|----------|--------|
| `POST /payments/rustore/mock-verify` | `_require_development_for_payment_mock()` → **404** |
| `POST /payments/rustore/mock-verify-custom` | то же |

| Endpoint | Production behavior |
|----------|---------------------|
| `POST /payments/rustore/verify` | **501** — real RuStore verification not implemented; **no balance credit** |

В production mock-verify **не начисляет** баланс (endpoint недоступен).

**Frontend:** `PaymentService` → `MockPaymentUnavailableException` (403/404/501) → `PaymentFailureReason.unavailable` → UI **«Оплата скоро появится»**; баланс **не** обновляется на клиенте.

---

## Payments (production rules)

- Mock payment endpoints **disabled** in production (`ENVIRONMENT` ≠ `development` → **404**).
- Real payment **verification required** before crediting balance (`POST /payments/rustore/verify`).
- **Backend is source of truth** — amounts from `package_catalog.py`, not from client.
- **Idempotency** by `(provider, provider_payment_id)` in `payment_transactions`.
- **No secrets in frontend** — RuStore server credentials only on backend.
- **No `.env` commit** — keys in secure storage / CI only.
- `verify_real_rustore_payment` must **not** fake-success until RuStore API is wired.

Подробнее: [rustore_payments_plan.md](rustore_payments_plan.md).

---

## Balance integrity

- Начисление paid balance: только backend (`mock_verify_*`, будущий RuStore verify, `add_paid_balance`).
- Списание: `consume_generation` / `consume_photoshoot` при `ENABLE_CREDIT_CONSUMPTION=true`.
- Frontend **никогда** не инкрементирует баланс локально — только из `balance` в API response.
- Идемпотентность платежей: unique `(provider, provider_payment_id)` в `payment_transactions`.

---

## User data isolation

| Данные | Фильтр |
|--------|--------|
| `GET /generations` | `get_generations_by_user_id(user.id)` |
| `GET /balance` | `ensure_profile_exists(user.id)` |
| Генерации в БД | `user_id` текущего пользователя |
| `payment_transactions` | `user_id` из `CurrentUser` |
| Storage paths | `{folder}/{user_id}/...` |

**Проверено:** запросы к Supabase REST с `user_id=eq.{id}`; service role только на backend.

---

## CORS

| Development | Production |
|-------------|------------|
| `ALLOWED_ORIGINS` пусто → `*` | Явный список в `ALLOWED_ORIGINS` |
| `allow_credentials=False` | Не использовать `*` + credentials |

Код: `app/cors.py`. См. [backend_deploy_plan.md](backend_deploy_plan.md) §9.

---

## Deploy / HTTPS

- Публичный backend: **HTTPS** + `ENVIRONMENT=production`
- Flutter release: `--dart-define=API_BASE_URL=https://...`
- Docker: `backend/Dockerfile`; `.env` **не** в образе
- Health: `GET /health`, `GET /ready`

Чеклист: [backend_deploy_plan.md](backend_deploy_plan.md) §11.

---

## Health probes

| Endpoint | Содержимое | Секреты |
|----------|------------|---------|
| `GET /health` | `status`, `environment`, `version` | **Нет** |
| `GET /ready` | Config readiness flags (`supabase_configured`, …) | **Нет** |

Использовать для load balancer / post-deploy smoke. См. [backend_deploy_plan.md](backend_deploy_plan.md) §8.

---

## Supabase RLS

- Backend использует **service role** через httpx REST.
- **Перед production:** финальный review RLS/policies в Supabase для `profiles`, `generations`, `payment_transactions`.
- Клиент не должен обходить backend для мутаций баланса.

---

## Secrets

- `.env` не коммитить (`GEMINI_API_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, …).
- API responses: generic `401` / `500` без stack trace (FastAPI default).
- `GET /debug/config`: только boolean `*_configured`, не значения ключей.
- Избегать `detail=str(exc)` в **публичных** production paths (в debug endpoints допустимо для dev).

---

## Release signing

- Debug APK / debug signing — только для demo.
- RuStore release: production keystore вне git — см. [rustore_integration_plan.md](rustore_integration_plan.md).

---

## RuStore verification

- **Не подключено:** RuStore Pay SDK, server-side RuStore API verify (`verify_real_rustore_payment` → **501**).
- **Готово:** `package_catalog`, `payment_verification`, `routes/payments`, `PaymentService.purchasePackage`, `payment_transactions`.
- Production: mock-verify **отключён**; только verified real purchases через `/payments/rustore/verify`.

---

## Pre-release checklist

- [ ] `ENVIRONMENT=production` на сервере
- [ ] `TEST_USER_ID` пустой или игнорируется (fallback отключён в коде)
- [ ] Все `/debug/*` → 404
- [ ] Mock payment → 404
- [ ] Без `Authorization` → 401 на `/balance`, `/generations`, `/generate`, `/photoshoots/generate`
- [ ] CORS: явные origins
- [ ] Supabase RLS review
- [ ] Секреты в secure storage / CI
- [ ] Release signing + RuStore console
- [ ] `GET /health` и `GET /ready` отвечают на публичном URL
- [ ] `ALLOWED_ORIGINS` задан (если нужен Flutter web)
- [ ] Release APK с HTTPS `API_BASE_URL`

---

## Manual verification commands

**Development (ожидание: работает):**

```powershell
# /debug/config → 200
curl http://127.0.0.1:8000/debug/config
```

**Production-like (ожидание: заблокировано):**

```powershell
cd backend
$env:ENVIRONMENT='production'
python -m uvicorn app.main:app --port 8001
# Другой терминал:
curl http://127.0.0.1:8001/debug/config          # → 404
curl http://127.0.0.1:8001/balance               # → 401
curl -X POST http://127.0.0.1:8001/payments/rustore/mock-verify -H "Content-Type: application/json" -d "{\"package_id\":\"package_499_mix\",\"provider_payment_id\":\"x\"}"  # → 401 or 404
```

Вернуть `ENVIRONMENT=development` для локальной разработки.
