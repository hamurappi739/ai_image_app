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

### Поле `image_url` в ответе

| Режим | `image_url` в response |
|-------|------------------------|
| **`IMAGE_PROVIDER=mock`** (по умолчанию) | Обычный mock URL (`placehold.co`); **Storage не используется** |
| **`IMAGE_PROVIDER=gemini`** | Provider может вернуть `data:image/...;base64,...`; backend **автоматически загружает** изображение в Supabase Storage (bucket `generated-images`) и возвращает **`public_url`** |

- Если provider вернул **обычную ссылку** (не data URL) — backend возвращает её **без изменений**.
- Если provider вернул **data URL** — в response и в `generations.image_url` (при включённом credit consumption) сохраняется **Storage `public_url`**, не base64.
- Ошибки Storage upload: **`400`** (некорректный data URL / формат / размер), **`503`** (`Supabase Storage is temporarily unavailable`), **`500`** (конфигурация / upload failed) — без секретов и stack trace в ответе.

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
**Позже:** тот же endpoint с **id авторизованного пользователя** из Supabase Auth (JWT / session).

### Flutter (вкладка «Галерея»)

**Уже используется:** `ApiService.fetchGenerations()` при старте приложения → `GET /generations?limit=20`.

- Поле `prompt` в JSON отображается в UI как **описание** (не слово «промпт»).
- Служебные dev-записи с текстом вроде `debug test prompt` **фильтруются на клиенте** (не показываются пользователю).
- Ошибки загрузки (backend выключен, 500) **не** показываются техническим SnackBar; галерея остаётся usable (empty state или только локально добавленные кадры).
- Новые результаты после **`POST /generate`** или успешной **`POST /photoshoots/generate`** добавляются в список **сразу сверху**, без повторного `GET`.
- Записи фотосессий из **`GET /generations`** имеют `prompt`: **`Фотосессия: <style.title>`** (например `Фотосессия: Студийный портрет`).

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
| `prompt` | string | Текст запроса при генерации или описание фотосессии (`Фотосессия: …`) |
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
| `image_url` | string | URL | Ссылка на результат: mock URL (`placehold.co`) или Supabase Storage **`public_url`** после Gemini data URL upload |
| `prompt` | string | — | Очищенный prompt, отправленный на генерацию |
| `payment_type` | string \| null | `null`, `"free"`, `"paid"` | Как оплачена генерация; `null` если списание отключено |
| `credit_consumed` | boolean | — | `true` если кредит списан в Supabase |
| `remaining_free_generations` | int \| null | ≥ 0 | Остаток бесплатных генераций после запроса |
| `remaining_paid_credits` | int \| null | ≥ 0 | Остаток платных кредитов после запроса |

При `credit_consumed: false` поля остатков обычно `null`.

---

## 6. POST /photoshoots/generate

**Назначение:** подготовка будущей фотосессии (выбор стиля + загрузка фото + генерация 3 изображений).

**Headers:** `Content-Type: multipart/form-data`

**Auth:**

- `Authorization: Bearer <access_token>` — пользователь из Supabase Auth REST;
- без токена в `development` — fallback `TEST_USER_ID`;
- без токена вне `development` — `401`.

**Request body (multipart/form-data, текущий MVP):**

| Поле | Тип | Описание |
|------|-----|----------|
| `style_id` | string | Идентификатор выбранного стиля (обязательно); backend проверяет по **catalog** |
| `style_title` | string \| null | Человекочитаемое название стиля (опционально; **источник правды — catalog на backend**) |
| `photo` | file | Фото пользователя (обязательно) |

**Поддерживаемые `style_id` (backend catalog):**

| `style_id` | Название | Бесплатно |
|------------|----------|-----------|
| `studio_portrait` | Студийный портрет | да |
| `business_portrait` | Деловой портрет | да |
| `home_portrait` | Домашний портрет | да |
| `premium_portrait` | Премиум-портрет | нет (100 ₽) |
| `winter_photoshoot` | Зимняя фотосессия | нет (100 ₽) |
| `city_portrait` | Городской портрет | нет (100 ₽) |
| `evening_look` | Вечерний образ | нет (100 ₽) |
| `travel_portrait` | Портрет в путешествии | нет (100 ₽) |

- Неизвестный `style_id` → **`400`** `Unknown photoshoot style`
- Alias: Flutter может отправлять `urban_portrait` — backend принимает как `city_portrait`

**Валидация файла:**

- Допустимые форматы (`content_type`): `image/jpeg`, `image/png`, `image/webp`
- Максимальный размер: **10 MB**
- Неподдерживаемый формат → `400` `Unsupported photo format`
- Слишком большой файл → `400` `Photo is too large`
- Неизвестный `style_id` → `400` `Unknown photoshoot style`

**Текущее поведение (после валидации style/photo):**

| `ENABLE_PHOTOSHOOT_GENERATION` | Поведение |
|--------------------------------|-----------|
| **`false`** (по умолчанию) | **`501`** `Photoshoot generation is disabled in development mode` — Gemini **не вызывается** (защита от случайных кликов) |
| **`true`** | Gemini → Supabase Storage → запись в **`generations`** → **`200 OK`** с `image_urls` |

Runtime limit: **`PHOTOSHOOT_OUTPUT_COUNT`** (env, default **1**, диапазон **1–3**). Для controlled test рекомендуется **`PHOTOSHOOT_OUTPUT_COUNT=1`**. **Product target:** **3 изображения** на фотосессию (catalog `output_count=3`; включить после проверки стоимости).

При успехе (**`ENABLE_PHOTOSHOOT_GENERATION=true`**) для каждого `image_url` создаётся запись в **`generations`**:
- `prompt`: **`Фотосессия: <style.title>`** (из catalog)
- `image_url`: Storage **`public_url`**
- `payment_type`: **`free`** для бесплатных стилей, **`paid`** для платных (платные сейчас не вызываются из Flutter без оплаты)

**`GET /generations`** возвращает записи фотосессий вместе с обычными генерациями. Списания генераций и оплата **не выполняются**.

### Response `501` (generation disabled)

```json
{
  "detail": "Photoshoot generation is disabled in development mode"
}
```

Flutter обрабатывает **`501`** мягко: «Обработка фото будет добавлена позже».

### Response `200` (generation enabled)

```json
{
  "style_id": "studio_portrait",
  "style_title": "Студийный портрет",
  "image_urls": ["https://..."],
  "output_count": 1
}
```

| Поле | Тип | Описание |
|------|-----|----------|
| `style_id` | string | Идентификатор стиля из catalog |
| `style_title` | string | Название стиля из catalog |
| `image_urls` | string[] | Public URL результатов в Supabase Storage (`photoshoots/…`) |
| `output_count` | int | Фактическое число сгенерированных изображений (≤ `PHOTOSHOOT_OUTPUT_COUNT`) |

### Ошибки генерации

| HTTP | Условие |
|------|---------|
| **500** | `GEMINI_API_KEY is not configured` |
| **500** | `Failed to save photoshoot result` |
| **502** | `Gemini did not return a photoshoot image` |
| **502** | `Gemini photoshoot generation failed: status=…, message=…` (без секретов; message ≤ 300 символов) |
| **501** | `Photoshoot generation is disabled in development mode` (`ENABLE_PHOTOSHOOT_GENERATION=false`) |

**Будущее поведение:** product target — **3 изображения** на фотосессию; отдельный тип истории фотосессий (опционально).

### Flutter (вкладка «Фотосессии»)

- Бесплатный сценарий: `ApiService.generatePhotoshoot(...)` отправляет `multipart/form-data` с полями `style_id`, `style_title`, `photo`.
- При **`501`** (по умолчанию `ENABLE_PHOTOSHOOT_GENERATION=false`): мягкое сообщение «Обработка фото будет добавлена позже».
- При **`200`** (`ENABLE_PHOTOSHOOT_GENERATION=true`): backend возвращает `image_urls` (Flutter пока не отображает — отдельный шаг).
- При **`400`** (тип/размер): понятное сообщение про JPEG/PNG/WebP до 10 МБ.
- Платные сценарии пока не отправляют multipart на backend.

---

## 7. Development-only endpoints

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

## 8. Flutter UI mapping

Текущее Flutter-приложение (русский UI, нижняя навигация). См. [app_design_strategy.md](app_design_strategy.md).

| Вкладка (RU) | Backend сейчас | Статус |
|--------------|----------------|--------|
| **Создать** | `POST /generate` через `ApiService.generateImage()` | **Работает** |
| **Фотосессии** | `POST /photoshoots/generate` (multipart) | По умолчанию **501** (safety switch); при `ENABLE_PHOTOSHOOT_GENERATION=true` → `image_urls` |
| **Галерея** | `GET /generations` при старте + локально новые сверху | **Работает** (dev: `TEST_USER_ID`; фильтр debug в UI) |
| **Пакеты** | — | UI-заглушка под будущую оплату (RuStore) |
| **Профиль** | — | Placeholder |

- **Production / release** Flutter **не должен** вызывать `/debug/*` (только ручная отладка backend).
- **Фотосессии:** бесплатный сценарий — multipart upload; по умолчанию **501** (`ENABLE_PHOTOSHOOT_GENERATION=false`); при включённой генерации → `image_urls` (Flutter пока не показывает); платные — «Оплата будет добавлена позже». **Пакеты:** SnackBar «будет добавлено позже», без записи в БД.
- **Создать:** при `402` в UI — переход к идее покупки **пакета генераций** (не слово «кредиты»).

---

## 9. Flutter notes

- **Основной рабочий endpoint:** `POST /generate` (вкладка **Создать**).
- **Фотосессии:** `POST /photoshoots/generate` — `multipart/form-data`; **`ENABLE_PHOTOSHOOT_GENERATION=false`** по умолчанию → **501**; при **`true`** → Gemini + Storage + **`generations`**; test `output_count=1`, product target **3**; без списаний.
- **`GET /generations`** — галерея при старте; после auth — тот же endpoint с user id авторизованного пользователя.
- **Не вызывать** `/debug/*` из release-сборки.
- **Не хранить** `SUPABASE_SERVICE_ROLE_KEY` во Flutter.
- При **`HTTP 402`** — сообщение про окончание генераций и экран **Пакеты** (позже RuStore).
- Поля ответа `credit_consumed`, `remaining_paid_credits` — **технические**; в UI: «генерации обновлены», «бесплатных / купленных осталось» (см. [dev_notes.md](dev_notes.md)).
- **`image_url`** — mock (`placehold.co`) по умолчанию; при Gemini data URL — Supabase Storage **`public_url`**.
- Base URL: Web `127.0.0.1:8000`, Android emulator `10.0.2.2:8000` (`ApiService` + `kIsWeb`).
- Опционально: `GET /health` для проверки связи с backend.

---

## 10. Связанные документы

- [dev_notes.md](dev_notes.md) — debug endpoints и env
- [product_strategy.md](product_strategy.md) — пакеты и фотосессии
- `backend/README.md` — запуск сервера
