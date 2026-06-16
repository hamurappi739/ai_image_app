# RuStore payments plan

Простой план подключения **реальных** RuStore-платежей.  
Сейчас приложение работает в **demo-режиме**; этот документ описывает текущее состояние и следующие шаги.

Связанные документы: [rustore_integration_plan.md](rustore_integration_plan.md), [production_safety_checklist.md](production_safety_checklist.md), [api_contract.md](api_contract.md).

---

## 1. Что сейчас

| Факт | Детали |
|------|--------|
| Покупка в UI | Экран **«Купить изображения»** → `PaymentService.purchasePackage(packageId)` |
| Режим | **Demo / development** — деньги **не списываются** |
| Backend | `POST /payments/rustore/mock-verify` начисляет изображения после «покупки» |
| Guard | Mock endpoints доступны **только** при `ENVIRONMENT=development` (иначе **404**) |
| Frontend | Не знает URL mock-verify — только `PaymentService` → `ApiService` |
| Транзакции | Запись в `payment_transactions`; повторный `provider_payment_id` → `already_processed` |
| Real RuStore | **Не подключён** — `POST /payments/rustore/verify` возвращает **501** |

---

## 2. Экономика (единая валюта «изображения»)

| Правило | Значение |
|---------|----------|
| 1 фото (обычная генерация) | **1 изображение** |
| 1 фотосессия | **3 изображения** |
| В UI | Без слов «кредиты», «пакеты», отдельного баланса фотосессий |

### Варианты покупки (каталог на backend)

| UI | Цена | Изображений | `package_id` |
|----|------|-------------|--------------|
| 1 фото | 39 ₽ | 1 | `package_39_1_image` |
| 3 фото | 99 ₽ | 3 | `package_99_3_images` |
| 9 фото | 249 ₽ | 9 | `package_249_9_images` |
| 20 фото | 499 ₽ | 20 | `package_499_20_images` |
| 50 фото | 999 ₽ | 50 | `package_999_50_images` |

Суммы и начисления задаются **только** в `backend/app/services/package_catalog.py`.  
Клиент передаёт только `package_id` и id платежа от RuStore.

---

## 3. Архитектура кода (сейчас)

### Backend

```
package_catalog.py      — список пакетов, цены, количество изображений
payment_verification.py — mock verify (dev) + verify_real_rustore_payment (placeholder)
payment_service.py      — оркестрация verify_and_credit_package_purchase(...)
routes/payments.py      — HTTP: mock-verify, mock-verify-custom, verify (501)
```

### Frontend

```
PaymentService.purchasePackage(packageId)   — единая точка для UI
  └─ PaymentChannel.demo → ApiService.mockVerifyRuStorePayment (сейчас)
  └─ PaymentChannel.rustore → RuStore SDK + ApiService.verifyRuStorePayment (будущее)
```

Экран **«Купить»** не вызывает HTTP напрямую.

---

## 4. Как должно быть в production

1. Пользователь нажимает **«Купить»** в приложении.
2. **RuStore Pay SDK** (Android) проводит оплату в магазине.
3. Приложение получает **purchase id / payment token** от RuStore (не секреты).
4. Frontend отправляет результат на backend: `POST /payments/rustore/verify`.
5. Backend **проверяет оплату** через RuStore (server-side verification, credentials только на сервере).
6. Backend сверяет SKU / сумму с `package_catalog` — **не доверяет** сумме с клиента.
7. Только после успешной проверки backend начисляет изображения (`add_paid_balance`).
8. Транзакция пишется в `payment_transactions`.
9. Повторная отправка того же `provider_payment_id` → `already_processed`, баланс **не** начисляется второй раз.
10. Frontend обновляет UI из поля `balance` в ответе.

---

## 5. Что нельзя делать

- Нельзя начислять баланс **только** по словам frontend.
- Нельзя хранить RuStore **секреты** в Flutter / APK.
- Нельзя включать **mock payments** в production (`ENVIRONMENT=production` → mock **404**).
- Нельзя коммитить `.env` с ключами.
- Нельзя принимать оплату **без** server-side verification.
- Нельзя возвращать fake-success из `verify_real_rustore_payment` до реальной интеграции.

---

## 6. Что понадобится позже (вне этого этапа)

- RuStore application / package info в консоли RuStore
- Merchant / project settings
- Документация RuStore по **server-side verification**
- Требования к callback / webhook (если нужны)
- Production backend URL (HTTPS)
- Тестовые платежи RuStore (sandbox), если доступны
- Production env flags (`ENVIRONMENT=production`, отключение demo-notice в UI)

**Секреты и API keys на этом этапе не добавляются.**

---

## 7. TODO (реальная интеграция)

- [ ] Подключить **RuStore Pay SDK** во Flutter (Android)
- [ ] Переключить `PaymentService` на `PaymentChannel.rustore` в production-сборке
- [ ] Реализовать `verify_real_rustore_payment` на backend (RuStore API)
- [ ] Добавить production env flags и проверки в CI
- [ ] Протестировать **duplicate transaction** (`provider_payment_id`)
- [ ] Протестировать **отказ / ошибку** платежа (баланс не меняется)
- [ ] Протестировать **восстановление покупки**, если требуется RuStore
- [ ] Убрать demo-notice на экране «Купить» в production
- [ ] Обновить [api_contract.md](api_contract.md) для `POST /payments/rustore/verify`

---

## 8. Ручная проверка (текущий этап)

**Development:**

```powershell
# Mock verify — ожидание 200 (с Bearer)
curl -X POST http://127.0.0.1:8000/payments/rustore/mock-verify ^
  -H "Authorization: Bearer <token>" ^
  -H "Content-Type: application/json" ^
  -d "{\"package_id\":\"package_99_3_images\",\"provider_payment_id\":\"dev-test-1\"}"
```

**Real verify placeholder:**

```powershell
# Ожидание 501 — баланс не начисляется
curl -X POST http://127.0.0.1:8000/payments/rustore/verify ^
  -H "Authorization: Bearer <token>" ^
  -H "Content-Type: application/json" ^
  -d "{\"package_id\":\"package_99_3_images\",\"provider_payment_id\":\"rustore-test-1\"}"
```

**Production-like:** `ENVIRONMENT=production` → mock-verify **404**; см. [production_safety_checklist.md](production_safety_checklist.md).
