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
| **Connect data URL storage helper to /generate** | ✅ | `POST /generate` загружает `data:image/...` в Storage → `public_url`; mock mode без изменений |
| **Manual Gemini API test passed** | ✅ | Контролируемый ручной тест: `IMAGE_PROVIDER=gemini`, `ENABLE_CREDIT_CONSUMPTION=false` |
| **Gemini result stored in Supabase Storage** | ✅ | Generated image загружен в bucket `generated-images`, response содержит `public_url` |
| **Generated image public_url displayed in Gallery** | ✅ | Галерея показала реальную картинку по Storage URL |
| **Backend photoshoot style catalog** | ✅ | `photoshoot_styles.py`: 8 стилей, `instruction`, `get_photoshoot_style`; `/photoshoots/generate` валидирует `style_id` |
| **PhotoshootService** | ✅ | `photoshoot_service.py`: Gemini → Storage → `image_urls` + **`generations`** history |
| **Save photoshoot results to generation history** | ✅ | `create_generation_record`; `prompt`: `Фотосессия: …`; без списаний |
| **GeminiPhotoshootProvider** | ✅ | Реальный вызов `google-genai`: photo + `style.instruction` → data URLs |
| **Photoshoot output count runtime limit** | ✅ | `PHOTOSHOOT_OUTPUT_COUNT` env (1–3, default **1**); catalog product target — **3** |
| **Photoshoot generation safety switch** | ✅ | `ENABLE_PHOTOSHOOT_GENERATION` (default **false**); без флага — **501**, Gemini не вызывается |
| **Manual Gemini photoshoot test passed** | ✅ | Uploaded photo → Gemini → Storage → `image_urls` с `public_url`; `PHOTOSHOOT_OUTPUT_COUNT=1` |
| **Photoshoot result stored in Supabase Storage** | ✅ | Результат в bucket `generated-images` (`photoshoots/…`); `public_url` в response |
| **Gemini photoshoot generation** | ✅ | Реализовано и проверено вручную; по умолчанию выключено через safety switch |
| **Flutter photoshoot result handling** | ✅ | `PhotoshootGenerateResponse`: парсинг `image_urls` при **200** |
| **Photoshoot result added to Gallery** | ✅ | Успешные `image_urls` → локальная Галерея, описание «Фотосессия: …» |
| **Manual Flutter photoshoot-to-gallery test passed** | ✅ | Flutter UI + `ENABLE_PHOTOSHOOT_GENERATION=true`; после теста **`false`** |
| **Controlled 3-output photoshoot test** | ✅ | `PHOTOSHOOT_OUTPUT_COUNT=3` через Flutter UI; 1 photo → 3 images |
| **Storage upload for 3 photoshoot results** | ✅ | 3 файла в bucket `generated-images` (`photoshoots/…`) |
| **History save for 3 photoshoot results** | ✅ | 3 записи в `generations`; `GET /generations` возвращает все три |
| **Backend photoshoot grouping id (`photoshoot_id`)** | ✅ | Nullable column + index; все результаты одной фотосессии — один `photoshoot_id`; обычные генерации — `null` |

### Flutter UI MVP (детали)

- **Создать:** описание, подсказки, быстрые идеи, `POST /generate`, результат + «Открыть в Галерее»
- **Фотосессии:** 8 preview-карточек → bottom sheet: выбор фото, preview, multipart upload (бесплатно); при успехе — результат в **Галерею**; при **501** — placeholder-сообщение
- **Галерея:** `GET /generations` + локальные новые; **Очистить** (только на устройстве); empty state; без падения при недоступном backend
- **Пакеты:** 199 / 499 / 1199 ₽ (UI без реальной оплаты)
- **Профиль:** вход / регистрация / выход (при Supabase dart-define)

**UX:** в пользовательском UI **не** использовать «промпт», «кредиты», «токены» (см. [app_design_strategy.md](app_design_strategy.md)).

---

## Частично / подготовлено

| Этап | Статус | Примечание |
|------|--------|------------|
| **Gemini provider implementation** | ✅ | Код провайдера готов: `GeminiImageProvider` + `google-genai`; `mock` остаётся режимом по умолчанию |
| **Gemini manual API test** | ✅ | Ручной тест пройден: Gemini → Storage → `public_url` → Галерея; после теста `IMAGE_PROVIDER=mock` |
| **Supabase credits** | 🔶 | Backend: profiles, generations, `ENABLE_CREDIT_CONSUMPTION`; Flutter **без** Supabase SDK |
| **История в галерее** | 🔶 | С Bearer token — история по auth user; без входа — dev fallback |

---

## Следующие крупные этапы

1. **Flutter Gallery: group records with same `photoshoot_id` into one photoshoot card** — 1 фотосессия = 1 карточка/группа, внутри 3 изображения (например «Фотосессия: Студийный портрет», «3 изображения»).
2. **Show 3 results inside one photoshoot detail screen/card** — экран/карточка деталей фотосессии в Галерее.
3. **Add payment before paid photoshoot generation** — оплата перед обработкой платных стилей (100 ₽).
4. **Maybe add separate photoshoot history type later** — отдельный тип/метка в истории (опционально).
5. **Решить, когда включать `IMAGE_PROVIDER=gemini` для обычной разработки** — сейчас по умолчанию `mock` для безопасности и экономии квот.
6. **Проверить стоимость / лимиты Gemini** — перед регулярным использованием и production.
7. **Позже включить `ENABLE_CREDIT_CONSUMPTION=true`** — после полной проверки списаний free/paid и записи в `generations`.
8. **Безопасные интеграционные тесты backend** — использовать `ENABLE_CREDIT_CONSUMPTION=false`, чтобы не списывать генерации из Supabase.
9. **Use public/signed URLs** — сейчас bucket public; для private bucket позже — signed URL.
10. **Auth: улучшения UX** — подтверждение email (если Supabase tребует email confirmation).
11. **Восстановление пароля** — добавить reset password flow.
12. **Убрать development `TEST_USER_ID` fallback** перед production (обязательный Bearer / auth user id).
13. **Синхронизация баланса генераций** с аккаунтом после auth.
14. **Удаление изображений из аккаунта/backend** — после авторизации (не только локальная «Очистить»).
15. **RuStore Billing** — пакеты генераций на вкладке «Пакеты».
16. **Production cleanup** — удалить или защитить `/debug/*` endpoints; CORS, секреты, RLS.

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
