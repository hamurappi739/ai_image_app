# Production Cleanup Checklist

## Цель

Перед релизом убрать development-заглушки, закрыть debug endpoints, включить безопасные production-настройки и убедиться, что пользовательские данные и ключи защищены.

---

## 1. Backend debug endpoints

Перед production нужно **удалить** или **защитить**:

- `/debug/config`
- `/debug/supabase`
- `/debug/profile`
- `/debug/credits`
- `/debug/consume-generation`
- `/debug/add-credits`
- `/debug/history`
- `/debug/storage-test`
- `/debug/storage-image-test`

**Правило:**

- в production debug endpoints **не должны быть доступны публично**
- если оставить временно — только под **admin / auth protection**
- лучше возвращать **`404`** вне `ENVIRONMENT=development`

**Проверка:**

- [ ] Все `/debug/*` недоступны при `ENVIRONMENT=production`
- [ ] Flutter production build **не вызывает** debug endpoints
- [ ] Нет debug routes в публичной API-документации для пользователей

---

## 2. TEST_USER_ID fallback

**Проверить:**

- обычные endpoints **не должны** использовать `TEST_USER_ID` в production
- `/generate` должен брать `user_id` **только** из `Authorization: Bearer` token
- `/generations` должен брать `user_id` **только** из `Authorization: Bearer` token
- `/photoshoots/generate` должен брать `user_id` **только** из `Authorization: Bearer` token

**Перед production:**

- [ ] `ENVIRONMENT=production`
- [ ] `TEST_USER_ID` fallback **отключён**
- [ ] `Authorization` **обязателен** на защищённых endpoints
- [ ] Запрос без токена → **`401`**, не dev fallback

---

## 3. Supabase Auth

**Проверить:**

- [ ] вход / регистрация работают
- [ ] access token передаётся в `ApiService`
- [ ] backend валидирует Bearer token через Supabase Auth REST
- [ ] после входа `/generate` и `/generations` используют **реального пользователя**
- [ ] profile auto-sync (`ensure_profile_exists`) работает

**Что ещё нужно:**

- [ ] UX подтверждения email
- [ ] восстановление пароля
- [ ] нормальные сообщения ошибок входа (без технических деталей Supabase)
- [ ] logout очищает access token в `ApiService`

---

## 4. Supabase RLS

Проверить **RLS policies** для таблиц:

- `profiles`
- `generations`
- `credit_transactions`

**Правила:**

- пользователь видит **только свои** данные
- пользователь **не может** менять `paid_credits` напрямую
- пользователь **не может** читать чужие `generations`
- payment / credit операции делает **только backend** (service role)

**Проверка:**

- [ ] RLS включён на всех трёх таблицах
- [ ] Клиентский anon key не обходит ограничения для чужих данных
- [ ] Backend service role используется **только на сервере**

---

## 5. Supabase Storage

**Проверить bucket:**

- [ ] `generated-images` создан
- [ ] Решено: **public bucket** или **signed URLs**
- [ ] Если public bucket — убедиться, что это **допустимо** для продукта
- [ ] Если private bucket — реализован **signed URL flow**

**Проверить flow:**

- [ ] generated images сохраняются в Storage
- [ ] URL сохраняется в `generations.image_url`
- [ ] **Галерея** показывает storage URLs
- [ ] исходные пользовательские фото **не хранятся** дольше нужного без необходимости

---

## 6. Secrets and env

**Никогда не коммитить:**

- `backend/.env`
- `SUPABASE_SERVICE_ROLE_KEY`
- `SUPABASE_ANON_KEY` в коде
- `GEMINI_API_KEY`
- RuStore secrets
- любые payment credentials

**Проверить:**

- [ ] `.gitignore` содержит `.env`
- [ ] `.env.example` **не содержит** реальных ключей
- [ ] production secrets хранятся в **безопасном окружении** (CI secrets, hosting env)
- [ ] логи **не печатают** ключи и токены
- [ ] `GET /debug/config` и аналоги **не доступны** в production

---

## 7. CORS

Сейчас development может использовать широкий CORS (`allow_origins=["*"]`).

**Перед production:**

- [ ] убрать `allow_origins=["*"]`
- [ ] указать **реальные домены** приложения / backend
- [ ] проверить **preflight** requests
- [ ] не открывать backend для лишних origins

---

## 8. Gemini generation

**Перед production:**

- [ ] `IMAGE_PROVIDER=gemini` **только после** успешного ручного теста (см. [gemini_test_checklist.md](gemini_test_checklist.md))
- [ ] проверить баланс / квоты
- [ ] проверить, что Gemini **возвращает изображение**
- [ ] проверить, что data URL **загружается** в Supabase Storage
- [ ] проверить, что `/generate` возвращает **`public_url`** или **signed URL**
- [ ] проверить, что **большие base64** не уходят во frontend
- [ ] обработать ошибки Gemini **мягко** (без технических сообщений в UI)

**Безопасный режим до теста:**

- `IMAGE_PROVIDER=mock`
- `ENABLE_CREDIT_CONSUMPTION=false`

---

## 9. Credit / payment logic

**Перед production:**

- [ ] `ENABLE_CREDIT_CONSUMPTION=true` **только после** полной проверки
- [ ] проверить **бесплатный лимит** (`FREE_GENERATIONS_LIMIT`)
- [ ] проверить **paid generation spending**
- [ ] проверить записи в `credit_transactions`
- [ ] пользователь **не может** сам начислять генерации
- [ ] `/debug/add-credits` **отключён** или удалён

---

## 10. RuStore Billing

**Перед production:**

- [ ] подключить **RuStore Billing**
- [ ] создать товары:
  - фотосессия **100 ₽**
  - пакет **199 ₽**
  - пакет **499 ₽**
  - пакет **1199 ₽**
- [ ] backend **проверяет платежи** (не доверять только клиенту)
- [ ] генерация **платной фотосессии** запускается **только после** подтверждения оплаты
- [ ] покупка **пакета** начисляет генерации **только после** подтверждения оплаты

---

## 11. Flutter production config

**Проверить:**

- [ ] Supabase config передаётся **безопасно** (`--dart-define` / build-time env, не в git)
- [ ] ключи **не хардкодятся** в исходниках
- [ ] `ApiService` `baseUrl` настроен на **production backend**
- [ ] Android emulator URL `10.0.2.2` **не используется** в production
- [ ] **Профиль / Auth** работает
- [ ] **Галерея** работает после перезапуска приложения
- [ ] error messages **не показывают** технические детали (HTTP-коды, stack trace, названия провайдеров)

---

## 12. Android build

**Перед релизом:**

- [ ] решить **Gradle / SSL** проблему (сейчас Android-сборка отложена)
- [ ] проверить **Android build**
- [ ] проверить **release signing**
- [ ] проверить **permissions** для `image_picker`
- [ ] проверить работу на **реальном Android-устройстве**
- [ ] проверить **RuStore requirements**

---

## 13. Final manual check

Перед релизом **руками** проверить:

- [ ] регистрация
- [ ] вход
- [ ] выход
- [ ] создание изображения
- [ ] история в **Галерее**
- [ ] фотосессия **бесплатная**
- [ ] фотосессия **платная** (после оплаты)
- [ ] покупка **пакета**
- [ ] **отсутствие доступа** к debug endpoints
- [ ] **отсутствие запрещённых слов** в UI:
  - промпт
  - кредиты
  - токены

---

## 14. Release rule

**Не выпускать production**, пока:

- debug endpoints **доступны публично**
- `TEST_USER_ID` fallback **работает** в production
- CORS **открыт** на `*`
- **реальные ключи** есть в коде или в git
- **платежи не проверяются** backend
- user data **доступна другим** пользователям
- ошибки Gemini / backend **показываются пользователю** техническими сообщениями

---

## Связанные документы

| Документ | Зачем |
|----------|--------|
| [project_status.md](project_status.md) | Текущий технический статус |
| [roadmap.md](roadmap.md) | Этапы до и после MVP |
| [gemini_test_checklist.md](gemini_test_checklist.md) | Безопасный ручной тест Gemini + Storage |
| [api_contract.md](api_contract.md) | Контракт API |
| [app_design_strategy.md](app_design_strategy.md) | UX-правила (без «промпт», «кредиты», «токены») |
| `backend/README.md` | Env, endpoints, CORS |
| `frontend/README.md` | Запуск Flutter |
