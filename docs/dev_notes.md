# Development Notes

Заметки для локальной разработки **AI Image Generator** (backend + Supabase + credits).

---

## 1. Temporary debug endpoints

Временные routes в FastAPI для отладки без полноценной авторизации.

| Метод | Путь | Назначение |
|-------|------|------------|
| GET | `/debug/supabase` | Проверка подключения к Supabase (REST, `profiles`, `limit 1`) |
| GET | `/debug/profile` | Профиль тестового пользователя по `TEST_USER_ID` |
| GET | `/debug/credits` | Решение credit logic (`free` / `paid` / отказ) без списания |
| POST | `/debug/consume-generation` | **Запись в БД:** списание free/paid, `generations`, `credit_transactions` |
| POST | `/debug/add-credits` | **Запись в БД:** ручное начисление `paid_credits` тестовому пользователю |

### Примеры

```bash
curl http://127.0.0.1:8000/debug/supabase
curl http://127.0.0.1:8000/debug/profile
curl http://127.0.0.1:8000/debug/credits
curl -X POST http://127.0.0.1:8000/debug/consume-generation
curl -X POST http://127.0.0.1:8000/debug/add-credits \
  -H "Content-Type: application/json" \
  -d "{\"amount\": 25}"
```

---

## 2. Important warning

- Все **`/debug/*`** endpoints — **только для development**.
- Перед **production** их нужно:
  - **удалить**, или
  - **закрыть авторизацией** (admin / service account), или
  - **отключить** через environment flag (например, только при `ENVIRONMENT=development`).

Особенно опасны:

- **`POST /debug/consume-generation`** — реально списывает лимиты и пишет историю.
- **`POST /debug/add-credits`** — реально увеличивает `paid_credits` без оплаты.

Не оставлять эти routes открытыми в публичном API.

---

## 3. Local development env

Файл **`backend/.env`** используется **только локально** и **не коммитится** в Git (см. корневой `.gitignore`: `backend/.env`).

Типичные переменные в `backend/.env`:

| Переменная | Назначение |
|------------|------------|
| `GEMINI_API_KEY` | Ключ Google AI / Gemini (когда включена реальная генерация) |
| `SUPABASE_URL` | URL проекта Supabase |
| `SUPABASE_ANON_KEY` | Публичный ключ (в основном для Flutter) |
| `SUPABASE_SERVICE_ROLE_KEY` | Серверный ключ backend (REST, обход RLS) |
| `TEST_USER_ID` | UUID строки в `profiles` для dev-тестов |
| `ENABLE_CREDIT_CONSUMPTION` | Включить списание кредитов в `POST /generate` |

Шаблон без секретов: `backend/.env.example`.

---

## 4. Flutter UI vs backend API

- **Интерфейс Flutter** сейчас на **русском** (вкладки: Создать, Фотосессии, Галерея, Пакеты, Профиль).
- **Backend API** (JSON-поля, `detail` ошибок, env) остаётся на **английском** — это нормально.
- Технические поля ответа не показывать пользователю как есть:

| API (внутреннее) | Показ в UI |
|------------------|------------|
| `credit_consumed` | Генерации обновлены / списание учтено |
| `remaining_free_generations` | Бесплатных осталось |
| `remaining_paid_credits` | Купленных осталось |
| `paid_credits` (баланс) | Купленные генерации, осталось генераций |

В UI **не** использовать слова credits, tokens, кредиты.

Только вкладка **Создать** вызывает `POST /generate`. **Фотосессии**, **Галерея**, **Пакеты** — без backend (пока).

---

## 5. Current backend modes

Флаг **`ENABLE_CREDIT_CONSUMPTION`** управляет `POST /generate`.

### `ENABLE_CREDIT_CONSUMPTION=false` (по умолчанию)

- Принимает `prompt`, проверяет, что не пустой.
- Возвращает **mock** `image_url` и `prompt`.
- **Не** читает `profiles`, **не** списывает кредиты, **не** пишет в Supabase.

### `ENABLE_CREDIT_CONSUMPTION=true`

- Использует **`TEST_USER_ID`** из `.env` (временная замена auth).
- Загружает профиль → `determine_generation_payment()`.
- При отказе → `402` (`No available generations`).
- Mock image → **`consume_generation()`** (PATCH `profiles`, POST `generations`, POST `credit_transactions`).
- Ответ с `payment_type`, `credit_consumed`, остатками free/paid.

Для полного цикла в dev обычно нужны: настроенный Supabase, миграция `backend/db/migrations/001_initial_schema.sql`, строка в `profiles` с id = `TEST_USER_ID`.

---

## 6. Before production checklist

- [ ] Удалить или защитить все **`/debug/*`** endpoints
- [ ] Заменить логику **`TEST_USER_ID`** на реальную **аутентификацию** (Supabase JWT / session)
- [ ] Включить **RLS policies** в Supabase (см. TODO в миграции)
- [ ] Добавить **валидацию payment webhooks** (RuStore Billing, idempotency)
- [ ] Добавить **rate limiting** на API
- [ ] Настроить **error logging** и мониторинг (Sentry / аналог)
- [ ] Проверить **secret management** (нет ключей в репозитории, rotation)
- [ ] Определить **image storage** (Supabase Storage vs CDN, срок жизни URL)
- [ ] Зафиксировать **production environment variables** (отдельный `.env` / secrets manager)
- [ ] Отключить или ограничить **`ENABLE_CREDIT_CONSUMPTION`** / dev-only флаги в prod
- [ ] Провести review **Gemini** safety / moderation для user prompts

---

## 7. Тексты шаблонов и фотосессий

Расширенные описания для UI и генерации — в **[app_prompts.md](app_prompts.md)**:

| Раздел | Количество | Короткий текст | Длинный текст |
|--------|------------|----------------|---------------|
| Фото по шаблону | 17 | Карточка | Поле **Свой запрос** |
| Фотосессии | 15 | Карточка | `description` в `/photoshoots/generate` |
| Своя фотосессия | 5 чипов | Подпись чипа | Поле описания в модалке |

В коде: `frontend/lib/data/app_prompts.dart`. После правки **app_prompts.md** синхронизировать Dart-файл. Backend quality rules — `gemini_quality_instructions.py`; fallback стилей — `photoshoot_styles.py`.

---

## Связанные документы

- [app_prompts.md](app_prompts.md) — тексты шаблонов, фотосессий и чипов
- [database_schema.md](database_schema.md) — схема БД
- [product_strategy.md](product_strategy.md) — продукт и генерации
- [roadmap.md](roadmap.md) — этапы проекта
- `backend/README.md` — запуск API и описание endpoints
