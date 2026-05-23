# Roadmap

Этапы разработки **AI Image Generator**. Статус на текущий MVP.

---

## Выполнено

| Этап | Статус | Примечание |
|------|--------|------------|
| **Backend MVP** | ✅ | FastAPI: `GET /health`, `POST /generate` (mock image URL), Supabase credits через REST + httpx, debug endpoints |
| **Flutter UI MVP** | ✅ | 5 вкладок (русский UI), premium-стиль, responsive карточки |
| **Локальная история сессии** | ✅ | После генерации — запись in-memory; **Галерея** показывает сетку; сброс при перезапуске приложения |
| **Навигация Создать ↔ Галерея** | ✅ | «Открыть в Галерее», «Создать первое изображение» |

### Flutter UI MVP (детали)

- **Создать:** описание, подсказки, быстрые идеи, `POST /generate`, результат + «Открыть в Галерее»
- **Фотосессии:** 8 preview-карточек (заглушка, без upload/оплаты)
- **Галерея:** empty state или история текущей сессии
- **Пакеты:** 199 / 499 / 1199 ₽ (UI без реальной оплаты)
- **Профиль:** placeholder авторизации и настроек

**UX:** в пользовательском UI **не** использовать «промпт», «кредиты», «токены» (см. [app_design_strategy.md](app_design_strategy.md)).

---

## Частично / подготовлено

| Этап | Статус | Примечание |
|------|--------|------------|
| **Gemini integration** | 🔶 | Код подготовлен; в production пока **mock** (`placehold.co`) |
| **Supabase credits** | 🔶 | Backend: profiles, generations, `ENABLE_CREDIT_CONSUMPTION`; Flutter **без** Supabase |

---

## Следующие крупные этапы

1. **Реальная Gemini-генерация** — включить настоящие `image_url` вместо placeholder.
2. **Загрузка пользовательского фото** — для фотосессий (img2img / face), UI «добавить фото».
3. **Авторизация** — Supabase Auth, профиль, синхронизация баланса генераций.
4. **Сохранение истории на backend / Supabase** — персистентная галерея, `GET` истории, привязка к пользователю.
5. **RuStore Billing** — оплата пакетов генераций и фотосессий (100 ₽).
6. **Production cleanup** — удалить или защитить `/debug/*` endpoints; проверить CORS, секреты, RLS.

---

## Дальше (после MVP)

7. **Release** — публикация в RuStore, мониторинг, поддержка  
8. **Шаблоны / CMS** — каталог фотосессий с backend, A/B карточек  
9. **Watermark / preview quality** — preview vs полное качество после оплаты  

---

## Связанные документы

- [app_design_strategy.md](app_design_strategy.md) — вкладки и UX
- [api_contract.md](api_contract.md) — `POST /generate`
- [product_strategy.md](product_strategy.md) — монетизация
