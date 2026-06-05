# Database Schema (Supabase / PostgreSQL)

Будущая схема БД для **AI Image Generator**.

**Контекст:** Flutter → FastAPI → Supabase; генерация через Gemini; монетизация — free limit + paid credits; оплата — RuStore Billing.

**MVP:** `FREE_GENERATIONS_LIMIT=3` (задаётся в backend env, не в таблице).

---

## Обзор таблиц

| Таблица | Назначение |
|---------|------------|
| `profiles` | Профиль пользователя и баланс (free used + paid images + paid photoshoots; legacy `paid_credits`) |
| `generations` | История генераций изображений |
| `credit_transactions` | Аудит начислений и списаний кредитов |

---

## 1. `profiles`

**Назначение:** один профиль на пользователя — учёт бесплатного лимита и платного баланса (**изображения** + **фотосессии**).

### Поля

| Поле | Тип | Ограничения | Описание |
|------|-----|-------------|----------|
| `id` | `uuid` | PRIMARY KEY | Идентификатор пользователя |
| `email` | `text` | NULL | Email (опционально, из Auth) |
| `free_generations_used` | `integer` | DEFAULT `0`, ≥ 0 | Сколько бесплатных генераций уже использовано |
| `paid_credits` | `integer` | DEFAULT `0`, ≥ 0 | **Legacy / internal:** платные кредиты для текущего `ENABLE_CREDIT_CONSUMPTION` path; в UI не показывать как «кредиты» |
| `paid_image_generations` | `integer` | DEFAULT `0`, ≥ 0 | Платный остаток **обычных изображений** (вкладка **Создать**) |
| `paid_photoshoots` | `integer` | DEFAULT `0`, ≥ 0 | Платный остаток **фотосессий** |
| `created_at` | `timestamptz` | DEFAULT `now()` | Создание записи |
| `updated_at` | `timestamptz` | DEFAULT `now()` | Последнее обновление баланса |

### Пояснения

- **`id`** в будущем должен совпадать с **`auth.users.id`** (Supabase Auth): при регистрации создаётся строка в `profiles` с тем же UUID.
- **`free_generations_used`** — счётчик использованных free-генераций; сравнивается с `FREE_GENERATIONS_LIMIT` на backend (3 для MVP).
- **`paid_image_generations`** / **`paid_photoshoots`** — целевая продуктовая модель для UI: *«осталось: N изображений и M фотосессий»* (см. `GET /balance`).
- **`paid_credits`** — сохранено для обратной совместимости; списание через старый credits path; **не удалять** до миграции spending rules.

### Миграция

Поля `paid_image_generations` и `paid_photoshoots` добавлены в **`003_add_profile_balance_fields.sql`**.

### Пример SQL (актуальный фрагмент)

```sql
create table profiles (
  id uuid primary key,
  email text,
  free_generations_used integer not null default 0,
  paid_credits integer not null default 0,
  paid_image_generations integer not null default 0,
  paid_photoshoots integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
```

---

## 2. `generations`

**Назначение:** история всех генераций для экрана «Мои работы» и аналитики.

### Поля

| Поле | Тип | Ограничения | Описание |
|------|-----|-------------|----------|
| `id` | `uuid` | PRIMARY KEY | ID генерации |
| `user_id` | `uuid` | FK → `profiles(id)` | Владелец |
| `prompt` | `text` | NOT NULL | Текст запроса |
| `image_url` | `text` | NOT NULL | URL результата |
| `payment_type` | `text` | NOT NULL | `free` или `paid` |
| `created_at` | `timestamptz` | DEFAULT `now()` | Время генерации |

### Пояснения

- **`payment_type`**: только `free` или `paid` — как была оплачена конкретная генерация.
- **Расширения позже** (не в MVP-схеме, но заложить в дизайне):
  - `model_name` — например `gemini-2.5-flash-image`
  - `provider` — `gemini`
  - `status` — `pending`, `completed`, `failed`
  - `error_message` — текст ошибки при сбое

### Пример SQL (черновик)

```sql
create table generations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id),
  prompt text not null,
  image_url text not null,
  payment_type text not null check (payment_type in ('free', 'paid')),
  created_at timestamptz not null default now()
);
```

---

## 3. `credit_transactions`

**Назначение:** неизменяемый журнал всех изменений баланса (покупки, списания за генерацию, админ, возвраты).

### Поля

| Поле | Тип | Ограничения | Описание |
|------|-----|-------------|----------|
| `id` | `uuid` | PRIMARY KEY | ID транзакции |
| `user_id` | `uuid` | FK → `profiles(id)` | Пользователь |
| `amount` | `integer` | NOT NULL | **+** начисление, **−** списание |
| `transaction_type` | `text` | NOT NULL | Тип операции |
| `source` | `text` | NOT NULL | Источник |
| `description` | `text` | NULL | Человекочитаемый комментарий |
| `external_payment_id` | `text` | NULL | ID платежа RuStore / webhook |
| `created_at` | `timestamptz` | DEFAULT `now()` | Время записи |

### `transaction_type` (значения)

| Значение | Смысл |
|----------|--------|
| `purchase` | Покупка пакета кредитов |
| `generation_spend` | Списание 1 credit за генерацию |
| `admin_adjustment` | Ручная корректировка |
| `refund` | Возврат |

### `source` (значения)

| Значение | Смысл |
|----------|--------|
| `free` | Связано с бесплатным лимитом (если логируем отдельно) |
| `paid` | Платный баланс |
| `rustore` | Покупка через RuStore Billing |
| `admin` | Действие администратора |
| `system` | Автоматика backend |

### Пояснения

- **`amount`**: положительный — пополнение (`+25` за пакет), отрицательный — списание (`-1` за генерацию).
- **`external_payment_id`** — связь с RuStore / webhook для идемпотентности и поддержки («почему не начислились кредиты»).

### Пример SQL (черновик)

```sql
create table credit_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id),
  amount integer not null,
  transaction_type text not null,
  source text not null,
  description text,
  external_payment_id text,
  created_at timestamptz not null default now()
);
```

---

## Business logic

Лимит **`FREE_GENERATIONS_LIMIT`** читается на **FastAPI** из env (MVP: `3`), не хранится в БД.

Перед каждой генерацией (в транзакции):

1. **Free path**  
   Если `free_generations_used < FREE_GENERATIONS_LIMIT`:
   - разрешить генерацию;
   - `payment_type = 'free'`;
   - `free_generations_used += 1`;
   - при необходимости — запись в `credit_transactions` (опционально, `source = free`).

2. **Paid path**  
   Иначе, если `paid_credits > 0`:
   - разрешить генерацию;
   - `payment_type = 'paid'`;
   - `paid_credits -= 1`;
   - `credit_transactions`: `amount = -1`, `transaction_type = generation_spend`, `source = paid`.

3. **Отказ**  
   Иначе:
   - backend возвращает ошибку: **`"No available generations"`**;
   - генерация и запись в `generations` не создаются.

После успешной генерации:

- вставка в **`generations`** (`prompt`, `image_url`, `payment_type`);
- обновление **`profiles.updated_at`**.

Покупка пакета (RuStore, позже):

- `paid_credits += N`;
- `credit_transactions`: `amount = +N`, `transaction_type = purchase`, `source = rustore`, `external_payment_id = …`.

---

## Связи (ER, кратко)

```
auth.users (Supabase)
       │
       │ 1:1
       ▼
   profiles ─────┬──────────────┐
       │          │              │
       │ 1:N      │ 1:N          │
       ▼          ▼              │
 generations   credit_transactions
```

---

## Future improvements

Не входят в первую миграцию, но планируются:

| Область | Что добавить |
|---------|----------------|
| **RLS policies** | Пользователь видит только свои `profiles`, `generations`, `credit_transactions`; backend/service role для webhook |
| **Indexes** | `(user_id, created_at desc)` на `generations`; `(user_id, created_at)` на `credit_transactions`; уникальный индекс на `external_payment_id` где не null |
| **Webhook idempotency** | Уникальность `external_payment_id` + проверка дубликата перед `paid_credits += N` |
| **Image storage** | Supabase Storage вместо только внешнего URL; поле `storage_path` в `generations` |
| **Moderation** | Флаги `is_blocked`, лог отклонённых prompt; интеграция с safety API |
| **User deletion / GDPR** | Cascade или soft-delete; анонимизация `email`; удаление объектов в Storage; экспорт данных по запросу |

---

## Связь с другими документами

- [product_strategy.md](product_strategy.md) — продуктовая модель и пакеты кредитов
- [roadmap.md](roadmap.md) — этап «Supabase credits»
