# Roadmap

Этапы разработки **AI Image Generator**. Статус на текущий MVP.

---

## Выполнено

| Этап | Статус | Примечание |
|------|--------|------------|
| **Backend MVP** | ✅ | FastAPI: `GET /health`, `POST /generate` (mock image URL), Supabase credits через REST + httpx, debug endpoints |
| **GET /generations** | ✅ | История из `generations` (Bearer user id или dev fallback `TEST_USER_ID`), limit 1–100, новые сверху |
| **Flutter UI MVP** | ✅ | 5 вкладок (русский UI), premium-стиль, responsive карточки |
| **Галерея + backend** | ✅ | При старте `fetchGenerations()`; новые кадры после генерации — сразу сверху |
| **Фильтр debug в UI** | ✅ | Скрытие служебных записей (`debug test prompt` и т.п.) в галерее; Supabase не трогаем |
| **Локальная очистка Галереи** | ✅ | Кнопка «Очистить» — только in-memory на устройстве; backend/Supabase не меняются |
| **Навигация Создать ↔ Галерея** | ✅ | «Открыть в Галерее», «Создать первое изображение» |
| **Demo UI загрузки фото (Фотосессии)** | ✅ | Bottom sheet: стиль, badge, заглушка upload, «Что получится»; без файлов и backend |
| **Provider switch (`IMAGE_PROVIDER`)** | ✅ | `mock` по умолчанию; `gemini` через `GeminiImageProvider` |
| **Backend bearer token auth support** | ✅ | `Authorization: Bearer` → Supabase Auth REST; в development без токена — fallback `TEST_USER_ID` |
| **Frontend ApiService bearer token preparation** | ✅ | `setAccessToken` после входа; Bearer в `POST /generate` и `GET /generations` |
| **Basic Flutter Supabase Auth UI** | ✅ | Вкладка **Профиль**: вход / регистрация / выход |
| **Sign in / sign up form in Profile tab** | ✅ | Email + пароль; мягкие ошибки без технических деталей |
| **Access token passed to ApiService after login** | ✅ | Общий `ApiService` в `MainShell`; галерея перезагружается после входа/выхода |
| **Backend accepts Bearer token** | ✅ | `get_current_user()` → `CurrentUser { id, email }` из Supabase Auth |
| **Profile auto-create/sync** | ✅ | `ensure_profile_exists` на `GET /generations` и `POST /generate` (credit path) |
| **Development fallback check after auth/profile sync** | ✅ | Проверены оба режима: с Supabase Auth и без config через `TEST_USER_ID` fallback |
| **Auth loading states** | ✅ | В Профиле: loading для входа/регистрации/выхода, временно disabled кнопки и поля |
| **Local photo picker for photoshoot demo** | ✅ | Во вкладке «Фотосессии» можно выбрать фото локально через `image_picker` |
| **Photo preview in photoshoot modal** | ✅ | После выбора фото показывается preview в modal и «Фото выбрано» |
| **Backend photoshoot endpoint placeholder** | ✅ | `POST /photoshoots/generate` добавлен; сейчас возвращает `501` |
| **Frontend connected to photoshoot placeholder endpoint** | ✅ | Бесплатный сценарий Фотосессий вызывает `POST /photoshoots/generate` |
| **Backend multipart upload validation for photoshoots** | ✅ | `POST /photoshoots/generate` валидирует `photo` по типу и размеру (до 10 MB) |
| **Flutter multipart upload for photoshoots** | ✅ | Бесплатный сценарий отправляет выбранное фото через `multipart/form-data` |
| **Backend validation of uploaded photos** | ✅ | JPEG/PNG/WebP, max 10 MB; файл не сохраняется на сервере |
| **Graceful placeholder handling** | ✅ | `501` → «Обработка фото будет добавлена позже», без технических деталей в UI |
| **Backend storage service placeholder** | ✅ | `SupabaseStorageService` (httpx REST); `SUPABASE_STORAGE_BUCKET` в config/`.env.example`; не вызывается из текущих endpoints |
| **Supabase REST timeout/error handling** | ✅ | Централизованная обработка httpx в `supabase_service.py`; timeout → **503** `Supabase is temporarily unavailable` |
| **Debug storage upload test endpoint** | ✅ | `POST /debug/storage-test` — in-memory upload в bucket (только development) |
| **Supabase Storage bucket created** | ✅ | Bucket `generated-images` создан в Supabase Storage; для MVP — public |
| **Debug storage upload test passed** | ✅ | `POST /debug/storage-test` проверен: upload успешен, `public_url` открывается в браузере |
| **Generated image data URL storage helper** | ✅ | `upload_generated_image_data_url` в `storage_service.py`; PNG/JPEG/WebP data URL, max 10 MB; не подключён к `/generate` |
| **Debug storage image test passed** | ✅ | `POST /debug/storage-image-test` проверен: 1×1 PNG data URL → Storage, `public_url` открывается в браузере |

### Flutter UI MVP (детали)

- **Создать:** описание, подсказки, быстрые идеи, `POST /generate`, результат + «Открыть в Галерее»
- **Фотосессии:** 8 preview-карточек → bottom sheet: выбор фото, preview, multipart upload (бесплатно); `501` → «Обработка фото будет добавлена позже»
- **Галерея:** `GET /generations` + локальные новые; **Очистить** (только на устройстве); empty state; без падения при недоступном backend
- **Пакеты:** 199 / 499 / 1199 ₽ (UI без реальной оплаты)
- **Профиль:** вход / регистрация / выход (при Supabase dart-define)

**UX:** в пользовательском UI **не** использовать «промпт», «кредиты», «токены» (см. [app_design_strategy.md](app_design_strategy.md)).

---

## Частично / подготовлено

| Этап | Статус | Примечание |
|------|--------|------------|
| **Gemini provider implementation** | ✅ | Код провайдера готов: `GeminiImageProvider` + `google-genai`; `mock` остаётся режимом по умолчанию |
| **Gemini manual API test** | 🔶 | Pending: прошлый ручной тест отложен из-за отсутствия баланса/доступа к платным запросам |
| **Supabase credits** | 🔶 | Backend: profiles, generations, `ENABLE_CREDIT_CONSUMPTION`; Flutter **без** Supabase SDK |
| **История в галерее** | 🔶 | С Bearer token — история по auth user; без входа — dev fallback |

---

## Следующие крупные этапы

1. **Connect Gemini result to Supabase Storage** — после успешного API-теста вызывать `upload_generated_image_data_url` для data URL из `GeminiImageProvider`.
2. **Save `public_url` in `generations`** — записывать Storage URL в `generations.image_url` при списании генерации.
3. **Show stored image URLs in Gallery** — Галерея отображает изображения по Storage URL из истории (`GET /generations`).
4. **Подключить Storage для результатов фотосессий** — результаты обработки в Storage + запись в `generations`.
5. **Ручной тест Gemini (контролируемый)** — заранее пополнить баланс или подтвердить доступ к Gemini API/квотам, выполнить один тестовый `POST /generate` с коротким prompt.
6. **Безопасные интеграционные тесты backend** — использовать `ENABLE_CREDIT_CONSUMPTION=false`, чтобы не списывать генерации из Supabase.
7. **Use public/signed URLs** — сейчас bucket public; для private bucket позже — signed URL.
8. **Auth: улучшения UX** — подтверждение email (если Supabase требует email confirmation).
9. **Восстановление пароля** — добавить reset password flow.
10. **Убрать development `TEST_USER_ID` fallback** перед production (обязательный Bearer / auth user id).
11. **Сохранить или временно обработать исходное фото** — persistence/storage загруженного файла на backend (фотосессии).
12. **Подключить генерацию 3 результатов** — обработка фото и генерация трёх кадров в выбранном стиле.
13. **Подключить оплату для платных фотосессий** — upload + обработка после оплаты.
14. **Синхронизация баланса генераций** с аккаунтом после auth.
15. **Удаление изображений из аккаунта/backend** — после авторизации (не только локальная «Очистить»).
16. **RuStore Billing** — пакеты генераций на вкладке «Пакеты».
17. **Production cleanup** — удалить или защитить `/debug/*` endpoints; CORS, секреты, RLS.

---

## Дальше (после MVP)

11. **Release** — публикация в RuStore, мониторинг, поддержка  
12. **Шаблоны / CMS** — каталог фотосессий с backend, A/B карточек  
13. **Watermark / preview quality** — preview vs полное качество после оплаты  

---

## Связанные документы

- [app_design_strategy.md](app_design_strategy.md) — вкладки и UX
- [api_contract.md](api_contract.md) — `POST /generate`, `GET /generations`
- [product_strategy.md](product_strategy.md) — монетизация
