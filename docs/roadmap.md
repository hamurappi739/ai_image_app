# Roadmap

Этапы разработки **AI Image Generator**. Статус на текущий MVP.

---

## Выполнено

| Этап | Статус | Примечание |
|------|--------|------------|
| **Backend MVP** | ✅ | FastAPI: `GET /health`, `POST /generate` (mock image URL), Supabase credits через REST + httpx, debug endpoints |
| **GET /generations** | ✅ | История из таблицы `generations` для `TEST_USER_ID`, limit 1–100, сортировка новые сверху |
| **Flutter UI MVP** | ✅ | 5 вкладок (русский UI), premium-стиль, responsive карточки |
| **Галерея + backend** | ✅ | При старте `fetchGenerations()`; новые кадры после генерации — сразу сверху |
| **Фильтр debug в UI** | ✅ | Скрытие служебных записей (`debug test prompt` и т.п.) в галерее; Supabase не трогаем |
| **Локальная очистка Галереи** | ✅ | Кнопка «Очистить» — только in-memory на устройстве; backend/Supabase не меняются |
| **Навигация Создать ↔ Галерея** | ✅ | «Открыть в Галерее», «Создать первое изображение» |
| **Demo UI загрузки фото (Фотосессии)** | ✅ | Bottom sheet: стиль, badge, заглушка upload, «Что получится»; без файлов и backend |
| **Provider switch (`IMAGE_PROVIDER`)** | ✅ | `mock` по умолчанию; `gemini` через `GeminiImageProvider` |

### Flutter UI MVP (детали)

- **Создать:** описание, подсказки, быстрые идеи, `POST /generate`, результат + «Открыть в Галерее»
- **Фотосессии:** 8 preview-карточек → demo bottom sheet будущей загрузки фото (без реальной обработки)
- **Галерея:** `GET /generations` + локальные новые; **Очистить** (только на устройстве); empty state; без падения при недоступном backend
- **Пакеты:** 199 / 499 / 1199 ₽ (UI без реальной оплаты)
- **Профиль:** placeholder авторизации и настроек

**UX:** в пользовательском UI **не** использовать «промпт», «кредиты», «токены» (см. [app_design_strategy.md](app_design_strategy.md)).

---

## Частично / подготовлено

| Этап | Статус | Примечание |
|------|--------|------------|
| **Gemini provider implementation** | ✅ | Код провайдера готов: `GeminiImageProvider` + `google-genai`; `mock` остаётся режимом по умолчанию |
| **Gemini manual API test** | 🔶 | Pending: прошлый ручной тест отложен из-за отсутствия баланса/доступа к платным запросам |
| **Backend Authorization Bearer token support** | ✅ | `get_current_user_id()` поддерживает Bearer token через Supabase Auth REST + dev fallback `TEST_USER_ID` |
| **Supabase credits** | 🔶 | Backend: profiles, generations, `ENABLE_CREDIT_CONSUMPTION`; Flutter **без** Supabase SDK |
| **История в галерее** | 🔶 | Загрузка есть; полноценная **персональная** история по аккаунту — после auth |

---

## Следующие крупные этапы

1. **Ручной тест Gemini (контролируемый)** — заранее пополнить баланс или подтвердить доступ к Gemini API/квотам, выполнить один тестовый `POST /generate` с коротким prompt.
2. **После успешного Gemini-теста** — принять решение по хранению результата (`generated image URL/data`) для production-потока.
3. **Безопасные интеграционные тесты backend** — использовать `ENABLE_CREDIT_CONSUMPTION=false`, чтобы не списывать генерации из Supabase.
4. **Flutter auth integration step** — добавить авторизацию во Flutter и передавать access token в `ApiService` (`Authorization: Bearer ...`).
5. **Реальная загрузка пользовательского фото** — image picker, отправка снимка на backend (фотосессии).
6. **Обработка фото через backend** — генерация **3 изображений** в выбранном стиле по загруженному фото.
7. **Платная фотосессия** — оплата **100 ₽** (RuStore) перед запуском платных стилей.
8. **Результаты фотосессии в Галерее** — сохранение трёх кадров в историю пользователя (backend + UI).
9. **Авторизация** — Supabase Auth, профиль, синхронизация баланса генераций.
10. **Сохранение истории на аккаунт** — `GET /generations` по auth user id; без `TEST_USER_ID`.
11. **Удаление изображений из аккаунта/backend** — после авторизации (не только локальная «Очистить»).
12. **RuStore Billing** — пакеты генераций на вкладке «Пакеты».
13. **Production cleanup** — удалить или защитить `/debug/*` endpoints; CORS, секреты, RLS.

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
