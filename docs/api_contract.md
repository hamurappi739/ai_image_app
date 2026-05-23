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

## 4. GET /generations

**Назначение:** список ранее созданных генераций пользователя (история для вкладки **Галерея** / синхронизация с backend).

**Query parameters:**

| Параметр | Тип | По умолчанию | Описание |
|----------|-----|--------------|----------|
| `limit` | int | `20` | Сколько записей вернуть (мин. `1`, макс. `100`) |

Примеры: `GET /generations`, `GET /generations?limit=10`.

**Пользователь (сейчас):** без JWT. Backend читает историю для **`TEST_USER_ID`** из env (только development).  
**Позже:** тот же endpoint с **id авторизованного пользователя** из Supabase Auth.

**Response `200`:**

```json
{
  "generations": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "prompt": "cat in cyberpunk city",
      "image_url": "https://placehold.co/1024x1024?text=Generated+Image",
      "payment_type": "free",
      "created_at": "2026-05-21T12:34:56.789012+00:00"
    }
  ]
}
```

| Поле (элемент) | Тип | Описание |
|----------------|-----|----------|
| `id` | string (uuid) | ID записи в `generations` |
| `prompt` | string | Текст запроса при генерации |
| `image_url` | string | URL результата |
| `payment_type` | string | `"free"` или `"paid"` |
| `created_at` | string (ISO 8601) | Время создания |

Пустая история: `{"generations": []}` — это **нормальный** ответ, не ошибка.

### Errors

| HTTP | `detail` (пример) | Когда |
|------|-------------------|--------|
| `422` | validation error | `limit` &lt; 1 или &gt; 100 |
| `500` | `TEST_USER_ID is not configured` | Нет тестового пользователя в env |
| `500` | `Failed to fetch generations` | Ошибка Supabase REST |

Записи появляются в таблице после `POST /generate` с `ENABLE_CREDIT_CONSUMPTION=true` или `POST /debug/consume-generation`.

---

## 5. POST /generate — response fields

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

## 6. Development-only endpoints

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

## 7. Flutter UI mapping

Текущее Flutter-приложение (русский UI, нижняя навигация). См. [app_design_strategy.md](app_design_strategy.md).

| Вкладка (RU) | Backend сейчас | Статус |
|--------------|----------------|--------|
| **Создать** | `POST /generate` через `ApiService.generateImage()` | **Работает** |
| **Фотосессии** | — | UI-заглушка, **не** вызывает API |
| **Галерея** | `GET /generations` (позже) | Сейчас локальная история сессии во Flutter |
| **Пакеты** | — | UI-заглушка под будущую оплату (RuStore) |
| **Профиль** | — | Placeholder |

- **Production / release** Flutter **не должен** вызывать `/debug/*` (только ручная отладка backend).
- **Фотосессии** и **Пакеты:** кнопки показывают SnackBar «будет добавлено позже», без записи в БД.
- **Создать:** при `402` в UI — переход к идее покупки **пакета генераций** (не слово «кредиты»).

---

## 8. Flutter notes

- **Основной рабочий endpoint:** `POST /generate` (вкладка **Создать**).
- **`GET /generations`** — для синхронизации галереи с backend после auth (пока не подключено во Flutter).
- **Не вызывать** `/debug/*` из release-сборки.
- **Не хранить** `SUPABASE_SERVICE_ROLE_KEY` во Flutter.
- При **`HTTP 402`** — сообщение про окончание генераций и экран **Пакеты** (позже RuStore).
- Поля ответа `credit_consumed`, `remaining_paid_credits` — **технические**; в UI: «генерации обновлены», «бесплатных / купленных осталось» (см. [dev_notes.md](dev_notes.md)).
- **`image_url`** — пока mock (`placehold.co`).
- Base URL: Web `127.0.0.1:8000`, Android emulator `10.0.2.2:8000` (`ApiService` + `kIsWeb`).
- Опционально: `GET /health` для проверки связи с backend.

---

## Связанные документы

- [dev_notes.md](dev_notes.md) — debug endpoints и env
- [product_strategy.md](product_strategy.md) — пакеты и фотосессии
- `backend/README.md` — запуск сервера
