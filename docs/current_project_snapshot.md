# Current project snapshot

**Дата снимка:** май 2026  
**Стадия:** MVP / demo-mode — функциональный продукт для демо и доработки, **не** production release.

Краткий обзор «как есть сейчас» для нового чата, демо или планирования следующих шагов.  
Детали: [project_status.md](project_status.md), [roadmap.md](roadmap.md), [README.md](../README.md).

---

## 1. Текущее состояние приложения

**AI Image App** — мобильное (Flutter) и кроссплатформенное приложение для **генерации фото** с backend на **FastAPI** и данными в **Supabase**.

| Аспект | Состояние |
|--------|-----------|
| **Аудитория** | Основной UX-фокус — **женщины 40+** и обычные пользователи: простой русский UI, крупные действия, без слов «промпт», «кредиты», «токены» |
| **Язык UI** | Русский |
| **Навигация** | Burger / **drawer**; баланс в меню и на экранах покупки/профиля, **не** в шапке разделов |
| **Режим проекта** | Demo / MVP: mock-генерация по умолчанию; реальный **Gemini** проверен вручную в safe mode |

### Логика «от простого к сложному»

Пользователь ведётся от готовых сценариев к своей идее:

1. **Фото по шаблону** — выбрать готовый вариант → описание подставится автоматически → своё фото → создать одно фото.
2. **Фотосессии** — выбрать стиль → загрузить фото → получить **серию из 3 фото** в одном направлении.
3. **Свой запрос** — описать идею самому (с фото или без) → одно фото.

Главный вход с **Главной**: «Начать создавать» → **Фото по шаблону**. После успешной генерации — переход в **Готовые фото**.

---

## 2. Готовые frontend-разделы

Все перечисленные разделы **реализованы в UI** (Flutter), на русском языке.

| Раздел | Назначение | Статус |
|--------|------------|--------|
| **Главная** | Welcome-экран, hero, CTA «Начать создавать» | ✅ |
| **Фото по шаблону** | 17 шаблонов по категориям; «Выбрать» → **Свой запрос** | ✅ |
| **Фотосессии** | 15 стилей, подборки, chips-категории, bottom sheet | ✅ |
| **Своя фотосессия** | Промо-блок + модалка, чипы-идеи, свой текст | ✅ |
| **Свой запрос** | Режимы «Без фото» / «С фото», идеи, создание фото | ✅ |
| **Готовые фото** | История, группировка фотосессий, просмотр, success-блок | ✅ |
| **Купить** | Единая валюта **изображения**; варианты 1/3/9/20/50 фото (39–999 ₽); баланс + «Как это работает»; demo top-up | ✅ (demo) |
| **Профиль** | Supabase Auth: вход / регистрация / выход, баланс | ✅ |
| **Помощь** | Hub + контекстные диалоги по разделам | ✅ |
| **Burger / drawer menu** | Все разделы + баланс + «Купить» | ✅ |

Дополнительно: **first-run onboarding** (5 экранов), **Трендовые фотосессии** (скролл к популярному блоку).

Preview на карточках — **Flutter placeholders** (gradient / `VisualPlaceholder`); реальные локальные картинки **ещё не подключены** (см. §6).

---

## 3. Готовые backend-возможности

**Стек:** FastAPI, Supabase REST (profiles, generations, credit_transactions, payment_transactions), Supabase Storage (`generated-images`).

### Основные endpoints

| Метод | Путь | Назначение |
|-------|------|------------|
| GET | `/health` | Проверка сервера |
| POST | `/generate` | Генерация по текстовому описанию (JSON) |
| POST | `/generate-with-photo` | Генерация по фото + описанию (multipart) |
| POST | `/photoshoots/generate` | Фотосессия: стиль + фото + опционально **description** → до 3 `image_urls` |
| GET | `/balance` | Баланс: бесплатные фото, платные фото, фотосессии |
| GET | `/generations` | История генераций (лимит, новые сверху) |

### Оплата (development)

| Метод | Путь | Назначение |
|-------|------|------------|
| POST | `/payments/rustore/mock-verify` | Demo-пополнение готовым пакетом |
| POST | `/payments/rustore/mock-verify-custom` | Demo-пополнение «Своя сумма» |

### Провайдеры генерации

| Режим | `IMAGE_PROVIDER` | Поведение |
|-------|------------------|-----------|
| **Mock** (по умолчанию в committed `.env`) | `mock` | Placeholder-URL (`placehold.co`), без Gemini API |
| **Gemini** | `gemini` | Реальная генерация → Supabase Storage → `public_url`; проверен smoke test в safe mode |

### Фотосессии — поле `description`

- **Готовые стили:** Flutter передаёт **расширенный style prompt** в `description` (тексты из [app_prompts.md](app_prompts.md)).
- **Своя фотосессия** (`style_id=custom_photoshoot`): `description` = текст пользователя или чипа.
- Backend: при непустом `description` использует его как основу инструкции Gemini; иначе — `style.instruction` из каталога `photoshoot_styles.py`.

### Прочее

- **Bearer auth** через Supabase; dev fallback `TEST_USER_ID` только при `ENVIRONMENT=development` без токена.
- **Quality instructions:** `gemini_quality_instructions.py` (лица, без коллажа, 3 отдельных кадра фотосессии).
- **Debug endpoints** (`/debug/*`) — только development.

Контракт API: [api_contract.md](api_contract.md).

---

## 4. Баланс и оплата

| Правило | Значение |
|---------|----------|
| Бесплатные генерации | **3** на старте (`free_generations_used` / лимит в профиле) |
| Единица списания | **изображения** (1 фото = 1 изображение) |
| Фотосессия | **3 изображения** (`PHOTOSHOOT_OUTPUT_COUNT=3`, один `photoshoot_id`) |
| Варианты покупки (UI) | **1 / 3 / 9 / 20 / 50** фото → **39 / 99 / 249 / 499 / 999 ₽** |

**Demo / mock payments:** ✅ — экран **«Купить изображения»** вызывает backend mock-verify через `PaymentService`; **деньги не списываются**; баланс обновляется в drawer, Профиле и на экранах. Frontend **не** начисляет баланс сам.

**Real RuStore:** ❌ **TODO** — SDK, server verification, production payment flow. Foundation на backend готов (`payment_transactions`, idempotency). План: [rustore_integration_plan.md](rustore_integration_plan.md).

**Committed `.env` (безопасная разработка):** `ENABLE_CREDIT_CONSUMPTION=false` — списание выключено. Для демо со списанием — временный env (см. §7).

---

## 5. Промпты

| Факт | Детали |
|------|--------|
| **Расширенные промпты** | ✅ Встроены в приложение |
| **Источник текстов** | [app_prompts.md](app_prompts.md) |
| **Код** | `frontend/lib/data/app_prompts.dart` |
| **Фото по шаблону (17)** | Короткое описание на карточке; **большой промпт** → поле **«Свой запрос»** после «Выбрать» |
| **Фотосессии (15)** | Короткое описание на карточке; **style prompt** → `description` в `POST /photoshoots/generate` |
| **Своя фотосессия (5 чипов)** | Деловой образ, Нежный портрет, Городская прогулка, Вечерний образ, Фото для соцсетей — полные тексты в поле описания |

Системные правила качества Gemini **не** показываются пользователю (только backend).

---

## 6. Preview assets

| Факт | Детали |
|------|--------|
| **План и структура** | ✅ [preview_assets_checklist.md](preview_assets_checklist.md) |
| **Реальные файлы** | ❌ Пока **не добавлены** в `frontend/assets/previews/` |
| **Текущий UI** | Gradient / `VisualPlaceholder` / `PreviewAssetImage` с fallback |
| **Полный каталог (план)** | 40 файлов: common, templates (17), photoshoots (15), custom, onboarding (4) |
| **MVP pack (первый этап)** | 8 файлов: hero, 2 шаблона, товар, 2 фотосессии, good/bad photo example |

Краткий обзор кода подключения: [frontend_assets_plan.md](frontend_assets_plan.md).

---

## 7. Demo / mock режим

### Committed `.env` (ежедневная разработка)

| Переменная | Типичное значение |
|------------|-------------------|
| `IMAGE_PROVIDER` | `mock` |
| `ENABLE_CREDIT_CONSUMPTION` | `false` |
| `ENABLE_PHOTOSHOOT_GENERATION` | `false` |

Безопасно: нет расхода Gemini, нет списания баланса.

### Режим демо на устройстве (проверено)

Для полного цикла на **физическом Android** (debug APK + LAN backend):

| Переменная | Значение |
|------------|----------|
| `IMAGE_PROVIDER` | `mock` |
| `ENABLE_CREDIT_CONSUMPTION` | `true` |
| `ENABLE_PHOTOSHOOT_GENERATION` | `true` |
| `PHOTOSHOOT_OUTPUT_COUNT` | `3` |

Backend: `uvicorn … --host 0.0.0.0 --port 8000`  
Flutter APK: `--dart-define=API_BASE_URL=http://<LAN-IP-ПК>:8000`

**Проверено:** debug APK на телефоне — Главная, drawer, шаблоны → Свой запрос, фотосессии (3 mock-кадра), Купить, Готовые фото, Помощь. Подробнее: [demo_release_checklist.md](demo_release_checklist.md).

### Gemini safe test (отдельно)

`IMAGE_PROVIDER=gemini`, `ENABLE_CREDIT_CONSUMPTION=false` — все три flow работают, баланс не списывается. Чеклист: [gemini_test_checklist.md](gemini_test_checklist.md).

---

## 8. Что осталось

| Задача | Статус |
|--------|--------|
| Реальные **preview-картинки** (по [preview_assets_checklist.md](preview_assets_checklist.md)) | План готов, файлы не добавлены |
| **Production backend deploy** (публичный HTTPS) | Не выполнен — [backend_deploy_plan.md](backend_deploy_plan.md) |
| Публичный **`API_BASE_URL`** (HTTPS) для release-сборок | Не настроен |
| **Real RuStore** payment verification + SDK | TODO |
| **Release signing** (keystore, не debug keys) | TODO |
| **AAB / release build** | TODO |
| Проверка на **нескольких Android-устройствах** | Частично (один телефон) |
| Финальная **очистка debug/dev** endpoints перед production | TODO — [production_safety_checklist.md](production_safety_checklist.md), [production_cleanup_checklist.md](production_cleanup_checklist.md) |
| CORS trusted origins, Supabase RLS review | TODO |
| Email confirmation, password recovery (auth) | TODO |

---

## 9. Важные ограничения

| Ограничение | Правило |
|-------------|---------|
| **`.env`** | **Не коммитить** в git; только локально / secrets manager |
| **Secret keys** | **Не** вставлять в frontend; `SUPABASE_SERVICE_ROLE_KEY` и `GEMINI_API_KEY` — **только backend** |
| **`/debug/*`** | Только **`ENVIRONMENT=development`**; в production — удалить или защитить |
| **Mock payments** | `mock-verify` / `mock-verify-custom` — только **development** |
| **Production API** | **`Authorization: Bearer`** обязателен; без токена → **401** |
| **Dev fallback** | `TEST_USER_ID` — только development без Bearer |
| **Supabase** | Service role — **только backend**; Flutter — anon key + user session |
| **UI терминология** | Не показывать: prompt, credits, tokens, package (использовать: фото, баланс, купить, описание) |

---

## Связанные документы

| Документ | Зачем |
|----------|--------|
| [project_status.md](project_status.md) | Подробный технический статус |
| [roadmap.md](roadmap.md) | Этапы и backlog |
| [app_prompts.md](app_prompts.md) | Тексты промптов |
| [preview_assets_checklist.md](preview_assets_checklist.md) | План preview-картинок |
| [demo_release_checklist.md](demo_release_checklist.md) | Сборка APK и demo-сценарий |
| [api_contract.md](api_contract.md) | HTTP API |
| [app_design_strategy.md](app_design_strategy.md) | UX и дизайн-принципы |
