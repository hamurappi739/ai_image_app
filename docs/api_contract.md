# Backend API Contract

Контракт HTTP API для **Flutter** клиента AI Image Generator.

---

## 1. Base URL

| Окружение | URL |
|-----------|-----|
| Локальная разработка (iOS simulator, desktop) | `http://127.0.0.1:8000` |
| Android emulator (хост-машина) | `http://10.0.2.2:8000` |

Префикса `/api/v1` нет — routes в корне.

---

## 2. GET /health

**Назначение:** проверить, что backend запущен и отвечает.

**Response `200`:**

```json
{
  "status": "ok"
}
```

Использовать при старте приложения или в настройках «Проверить соединение».

---

## 3. POST /generate

**Назначение:** генерация изображения по текстовому prompt.

**Headers:** `Content-Type: application/json`

**Request body:**

```json
{
  "prompt": "cat in cyberpunk city"
}
```

| Поле | Тип | Описание |
|------|-----|----------|
| `prompt` | string | Текст запроса (обязательно, не пустой после trim) |

### Response `200` — credit consumption **disabled**

`ENABLE_CREDIT_CONSUMPTION=false` на backend (режим по умолчанию для простой разработки UI).

```json
{
  "image_url": "https://placehold.co/1024x1024?text=Generated+Image",
  "prompt": "cat in cyberpunk city",
  "payment_type": null,
  "credit_consumed": false,
  "remaining_free_generations": null,
  "remaining_paid_credits": null
}
```

### Response `200` — credit consumption **enabled**

`ENABLE_CREDIT_CONSUMPTION=true` на backend (dev с `TEST_USER_ID`; в production — после реальной auth).

```json
{
  "image_url": "https://placehold.co/1024x1024?text=Generated+Image",
  "prompt": "cat in cyberpunk city",
  "payment_type": "free",
  "credit_consumed": true,
  "remaining_free_generations": 2,
  "remaining_paid_credits": 0
}
```

`payment_type` может быть **`"free"`** или **`"paid"`** в зависимости от того, как была оплачена генерация.

### Errors

| HTTP | `detail` (пример) | Когда |
|------|-------------------|--------|
| `400` | `Prompt cannot be empty` | Пустой prompt |
| `402` | `No available generations` | Нет free и paid кредитов (только при включённом credit consumption) |
| `404` | `Profile not found` | Профиль пользователя не найден (dev / будущая auth) |
| `500` | `TEST_USER_ID is not configured` | Backend без тестового пользователя (dev misconfiguration) |

Тело ошибки FastAPI: `{"detail": "..."}` (строка или объект).

---

## 4. Response fields

| Поле | Тип | Значения | Описание |
|------|-----|----------|----------|
| `image_url` | string | URL | Ссылка на сгенерированное изображение (сейчас mock placeholder) |
| `prompt` | string | — | Очищенный prompt, отправленный на генерацию |
| `payment_type` | string \| null | `null`, `"free"`, `"paid"` | Как оплачена генерация; `null` если списание отключено |
| `credit_consumed` | boolean | — | `true` если кредит списан в Supabase |
| `remaining_free_generations` | int \| null | ≥ 0 | Остаток бесплатных генераций после запроса |
| `remaining_paid_credits` | int \| null | ≥ 0 | Остаток платных кредитов после запроса |

При `credit_consumed: false` поля остатков обычно `null`.

---

## 5. Development-only endpoints

**Не использовать во Flutter production.** Не документировать в публичном SDK приложения.

| Метод | Путь | Назначение |
|-------|------|------------|
| GET | `/debug/supabase` | Проверка Supabase |
| GET | `/debug/profile` | Профиль по `TEST_USER_ID` |
| GET | `/debug/credits` | Решение free/paid без списания |
| POST | `/debug/consume-generation` | Тестовое списание в БД |
| POST | `/debug/add-credits` | Ручное начисление paid credits |
| GET | `/debug/history` | История генераций и транзакций |

См. [dev_notes.md](dev_notes.md).

---

## 6. Flutter notes

- **Основной endpoint приложения:** `POST /generate`.
- **Не вызывать** `/debug/*` из release-сборки.
- **Не хранить и не встраивать** `SUPABASE_SERVICE_ROLE_KEY` во Flutter — только backend; клиент в будущем использует `SUPABASE_ANON_KEY` + Supabase Auth.
- При **`HTTP 402`** показывать экран покупки / пополнения кредитов (RuStore Billing позже).
- **`image_url`** сейчас ведёт на mock (`placehold.co`); позже — реальный URL (Gemini / Supabase Storage).
- Для Android emulator укажите base URL `http://10.0.2.2:8000`, для остальных платформ в dev — `http://127.0.0.1:8000`.
- Опционально: `GET /health` перед первым `POST /generate` для диагностики сети.

---

## Связанные документы

- [dev_notes.md](dev_notes.md) — debug endpoints и env
- [product_strategy.md](product_strategy.md) — кредиты и пакеты
- `backend/README.md` — запуск сервера
