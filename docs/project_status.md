# Project Status — AI Image App

Краткий технический статус для нового чата в Cursor или разработчика. Обновляйте при смене архитектуры или крупных этапов.

---

## 1. Краткое описание

- **Мобильное / кроссплатформенное приложение** на **Flutter** (сейчас основная разработка UI — **Chrome / web**).
- **Backend** — **FastAPI**, генерация изображений, учёт генераций, история.
- **Supabase (PostgreSQL)** — профили, история генераций (`generations`), транзакции (`credit_transactions`).
- Проект в стадии **MVP / demo-mode**: mock-генерация, заглушки оплаты и загрузки фото, dev-пользователь `TEST_USER_ID`.
- **`IMAGE_PROVIDER`**: `mock` (по умолчанию, безопасный режим) → **`MockImageProvider`**; `gemini` → **`GeminiImageProvider`** (реализован в backend, но не используется по умолчанию).

### Подготовка к авторизации (backend + frontend)

- **Backend:** `get_current_user_id()` принимает **`Authorization: Bearer <access_token>`** и валидирует токен через Supabase Auth REST; при **отсутствии** заголовка в **`ENVIRONMENT=development`** используется fallback **`TEST_USER_ID`** (как раньше для локальной разработки).
- **Frontend:** `ApiService` подготовлен к будущему access token (`setAccessToken` + общие headers); **сейчас токен не передаётся**, отдельного экрана входа/регистрации **нет**.
- Текущий Flutter UI продолжает работать через **development fallback** на стороне backend (без Bearer в запросах).

---

## 2. Текущая структура проекта

| Папка | Назначение |
|-------|------------|
| `backend/` | FastAPI, Supabase REST (httpx), `ImageService` + providers |
| `frontend/` | Flutter app (`lib/main.dart`, `lib/services/api_service.dart`) |
| `docs/` | Контракт API, дизайн, roadmap, demo script |

---

## 3. Как запустить backend

**Windows PowerShell:**

```powershell
cd C:\Users\shuly\Desktop\ai_image_app\backend
.\.venv\Scripts\python.exe -m uvicorn app.main:app --reload
```

- URL: **http://127.0.0.1:8000**
- Проверка: **`GET /health`** → `{"status":"ok"}`
- Переменные: скопировать `backend/.env.example` → `backend/.env` (не коммитить)

---

## 4. Как запустить frontend

```powershell
cd C:\Users\shuly\Desktop\ai_image_app\frontend
flutter pub get
flutter run -d chrome
```

| Платформа | Backend URL (`ApiService`) |
|-----------|----------------------------|
| Web / Chrome | `http://127.0.0.1:8000` |
| Android emulator (позже) | `http://10.0.2.2:8000` |

- **Android-сборка** пока отложена (Gradle / SSL при загрузке плагинов).
- Перед демо убедиться, что backend запущен.

---

## 5. Backend endpoints

### Публичные (MVP)

| Метод | Путь | Назначение |
|-------|------|------------|
| GET | `/health` | Жив ли сервер |
| POST | `/generate` | Генерация по тексту (сейчас mock URL) |
| GET | `/generations` | История генераций (`?limit=1..100`, по умолчанию 20) |

### `POST /generate`

- **`IMAGE_PROVIDER=mock`** (по умолчанию) → `MockImageProvider`: placeholder `image_url`.
- **`IMAGE_PROVIDER=gemini`** + `GEMINI_API_KEY` → `GeminiImageProvider`: Gemini API, `image_url` как `data:image/...;base64,...`.
- Ручной тест с `IMAGE_PROVIDER=gemini` был **остановлен/отложен** из-за отсутствия баланса/доступа к платным запросам.
- Приложение возвращено в **`IMAGE_PROVIDER=mock`**.
- Для следующего Gemini-теста заранее проверить баланс, квоты и доступ к модели.
- В backend auth helper `get_current_user_id()` поддерживает `Authorization: Bearer <token>` через Supabase Auth REST (`/auth/v1/user`).
- Если заголовка нет в development — остаётся fallback на `TEST_USER_ID`; в non-development без токена — `401`.
- **`ENABLE_CREDIT_CONSUMPTION=false`** (безопасный режим тестов): **не списывает** генерации из Supabase и не выполняет запись в `generations`.
- **`ENABLE_CREDIT_CONSUMPTION=true`**: профиль по user id (из Bearer token или dev fallback `TEST_USER_ID`), списание free/paid, запись в Supabase (`generations`, `credit_transactions`).

### `GET /generations`

- С Bearer token: user id берётся из Supabase Auth REST.
- Без токена в development: пользователь = **`TEST_USER_ID`** из `backend/.env`.
- Ответ: список из таблицы **`generations`** (новые сверху).
- В non-development без токена: `401` (`Authorization required`).

### Development only

**`/debug/*`** — только для разработки. **`GET /debug/config`** — безопасный helper: флаги конфигурации без секретов (доступен только при `ENVIRONMENT=development`, иначе 404). **Не вызывать** из production Flutter. Перед релизом — **удалить или защитить все** `/debug/*` routes.

Примеры: `/debug/config`, `/debug/supabase`, `/debug/profile`, `/debug/history`, `/debug/consume-generation`, `/debug/add-credits`.

Подробнее: [api_contract.md](api_contract.md), [dev_notes.md](dev_notes.md).

---

## 6. Frontend вкладки

Нижняя навигация (русский UI): **Создать · Фотосессии · Галерея · Пакеты · Профиль**.

### Создать

- Ввод **описания**, быстрые идеи, блок **«Как получить хороший результат»**.
- **`POST /generate`** через `ApiService`.
- Результат: `Image.network` или **fallback-preview** при ошибке загрузки.
- Кнопка **«Открыть в Галерее»**.
- Frontend скрывает технические ошибки генерации: в UI показывается только понятное сообщение для пользователя.
- Ошибки backend/Gemini (и HTTP-детали) должны логироваться/обрабатываться на backend, без вывода технических деталей в UI.

### Фотосессии

- 8 готовых стилей: **3 бесплатных**, **5 × 100 ₽**.
- Карточки → **bottom sheet** (demo будущей **загрузки фото**).
- Реальной загрузки файлов, обработки и оплаты **нет**.

### Галерея

- При старте: **`GET /generations`** (тихо при ошибке backend).
- Скрывает служебные **debug**-описания в UI.
- Новые результаты сессии — **сверху** после генерации.
- **«Очистить»** — только локальный список; **Supabase не удаляется**.

### Пакеты

| Цена | Объём |
|------|--------|
| 199 ₽ | 25 изображений |
| 499 ₽ | 100 изображений |
| 1199 ₽ | 250 изображений |

- Кнопка «Скоро»; **RuStore** не подключён.

### Профиль

- Placeholder: вход, будущие разделы, безопасность.

---

## 7. Supabase

### Таблицы

| Таблица | Назначение |
|---------|------------|
| `profiles` | Пользователь, `free_generations_used`, `paid_credits` |
| `generations` | История: prompt, `image_url`, `payment_type` |
| `credit_transactions` | Аудит начислений/списаний |

### Подключение

- Backend → **REST API + httpx** (`app/services/supabase_service.py`).
- **Не использовать** Python-пакет **`supabase`** (конфликт зависимостей).
- Миграции: `backend/db/migrations/`.
- **`backend/.env`** — реальные ключи; **не в git** (есть `.env.example`).

---

## 8. UX правила

**Не использовать в видимом UI:** промпт, кредиты, токены.

**Использовать:** описание, идея, изображение, генерации, пакеты генераций, фотосессии.

См. [app_design_strategy.md](app_design_strategy.md).

---

## 9. Что сейчас demo / заглушка

- **Gemini** в production-потоке (по умолчанию mock / placehold.co; ручной тест с ключом — отдельно).
- **Загрузка** пользовательского фото (фотосессии).
- **RuStore Billing** и оплата фотосессий 100 ₽.
- **Авторизация** (Supabase Auth во Flutter).
- Полноценная **история по аккаунту** (не `TEST_USER_ID`).
- **Удаление** изображений из backend.
- **Production security** (debug routes, CORS, RLS audit).

---

## 10. Что важно перед production

- Удалить или **защитить** `/debug/*`.
- Заменить **`TEST_USER_ID`** на **auth user id**.
- Включить **авторизацию** end-to-end.
- Подключить **реальные платежи** (RuStore).
- Ограничить **CORS** доверенными origin.
- Проверить **RLS** policies в Supabase.
- **Не коммитить** `.env` и service role key.
- Включить **реальную генерацию** (Gemini).
- **Storage** для изображений (не только внешние URL).

---

## 11. Последняя стабильная точка

- **UI-MVP** проверен вручную (Flutter web).
- Backend **`/generate`** и **`/generations`** работают при настроенном `.env`.
- **Flutter web** + backend на `127.0.0.1:8000`.
- Перед новым крупным шагом: **`git status`** чистый или осознанный коммит.

---

## Связанные документы

| Документ | Зачем |
|----------|--------|
| [api_contract.md](api_contract.md) | HTTP API |
| [app_design_strategy.md](app_design_strategy.md) | UX, вкладки |
| [roadmap.md](roadmap.md) | Этапы |
| [demo_script.md](demo_script.md) | Сценарий демо |
| `frontend/README.md` | Запуск Flutter |
| `backend/README.md` | Env, endpoints |
