# RuStore integration plan

Подготовительный план интеграции **RuStore Pay SDK** (не deprecated BillingClient). Реальный SDK **не подключён**; оплата в development идёт через backend mock-verify.

---

## Current state

| Область | Статус |
|---------|--------|
| RuStore Pay SDK (Flutter / Android) | **Не подключён** |
| RuStore BillingClient (deprecated) | **Не использовать** |
| Backend `payment_transactions` + catalog | ✅ Foundation готов |
| `POST /payments/rustore/mock-verify` (dev) | ✅ Готовые пакеты |
| `POST /payments/rustore/mock-verify-custom` (dev) | ✅ Своя сумма |
| Flutter `PaymentService` | ✅ Абстракция demo / future RuStore |
| Flutter `ApiService` mock-verify + retry 503 | ✅ |
| Real RuStore API calls from backend | **Не реализованы** (TODO в `payment_service.py`) |

---

## What is ready

### Android project (audit)

| Параметр | Значение |
|----------|----------|
| **applicationId** | `com.aiimagegenerator.ai_image_generator` |
| **namespace** | `com.aiimagegenerator.ai_image_generator` |
| **MainActivity** | `com.aiimagegenerator.ai_image_generator.MainActivity` (`FlutterActivity`) |
| **minSdk** | Flutter default **24** (`flutter.minSdkVersion`) |
| **targetSdk** | Flutter default **36** (`flutter.targetSdkVersion`) |
| **compileSdk** | Flutter default **36** (`flutter.compileSdkVersion`) |
| **INTERNET** | ✅ В `app/src/main/AndroidManifest.xml` (release + debug) |
| **Deep links / RuStore intent filters** | Нет (добавятся на этапе SDK) |
| **Release signing** | Debug keys (TODO: release keystore перед публикацией) |

### Frontend

- **`PaymentService.purchasePackageDemo`** / **`purchaseCustomAmountDemo`** — development flow без начисления баланса на клиенте.
- Заготовки **`purchasePackageWithRuStore`** / **`purchaseCustomAmountWithRuStore`** — `UnimplementedError`.
- UI **«Пакеты»** не вызывает mock-verify напрямую.

### Backend

- Начисление баланса **только** после server-side verification.
- Package catalog на сервере (`package_199_mix`, …); custom amount — `custom_amount`.
- Идемпотентность по `(provider, provider_payment_id)`.

---

## What is not connected

- RuStore Pay SDK dependency (например `flutter_rustore_pay` или официальный Android Pay SDK wrapper).
- RuStore Console: приложение, продукты, тестовые покупки.
- Backend endpoint real RuStore verification (вместо / в дополнение к mock-verify).
- Android manifest: deeplink / callback activity для Pay SDK.
- Release signing config (`key.properties`, keystore).
- Маппинг RuStore product SKU ↔ backend `package_id`.

---

## Future Pay SDK integration steps

1. **RuStore Console (вне репозитория)**  
   - Зарегистрировать приложение с **финальным** `applicationId`.  
   - Создать in-app продукты для пакетов 199/499/999 ₽ (mixed + images-only).  
   - Custom amount: отдельная стратегия (консоль / backend) — уточнить при интеграции.

2. **Android**  
   - Подтвердить или заменить `applicationId` на production package name.  
   - Добавить RuStore Pay SDK по официальной документации (не BillingClient).  
   - Добавить manifest-настройки SDK (deeplink / activity) **только** по требованиям SDK.  
   - Настроить release signing (keystore вне git).

3. **Flutter**  
   - Подключить Pay SDK wrapper (без изменения UI-контрактов).  
   - Реализовать `purchasePackageWithRuStore` / `purchaseCustomAmountWithRuStore` в `PaymentService`.  
   - Переключить **«Пакеты»** с demo-методов на RuStore-методы в production build.

4. **Backend**  
   - Реализовать server-side verification RuStore purchase token / payment id.  
   - Маппинг SKU → `package_id` из catalog (не доверять суммам с клиента).  
   - Custom amount: отдельный verified flow или ограничение только catalog-пакетами в v1.

5. **End-to-end flow**  
   1. Пользователь нажимает «Пополнить» / «Выбрать пакет».  
   2. RuStore Pay SDK — оплата, возврат purchase / payment id.  
   3. Frontend → backend verification с purchase id.  
   4. Backend проверяет в RuStore API, пишет `payment_transactions`, начисляет баланс.  
   5. Frontend получает `balance` в response → `onBalanceUpdated` / refresh.

---

## Backend verification rule

- **Никогда** не начислять `paid_image_generations` / `paid_photoshoots` на клиенте.
- **Всегда** верифицировать покупку на backend перед `add_paid_balance`.
- Demo `provider_payment_id` (`dev-package-…`, `dev-custom-…`) заменяется на **реальный purchase id** от RuStore.
- Повторная verification с тем же id → `already_processed`, без двойного начисления.

---

## Package IDs mapping (backend catalog)

| Backend `package_id` | ₽ | изображения | фотосессии |
|----------------------|---|-------------|------------|
| `package_199_mix` | 199 | 9 | 1 |
| `package_499_mix` | 499 | 19 | 3 |
| `package_999_mix` | 999 | 19 | 8 |
| `package_199_images` | 199 | 19 | 0 |
| `package_499_images` | 499 | 49 | 0 |
| `package_999_images` | 999 | 99 | 0 |
| `custom_amount` | user | calculated | user |

RuStore Console SKU должны однозначно маппиться на `package_id` на сервере.

---

## Custom amount flow

- **Сейчас (dev):** `PaymentService.purchaseCustomAmountDemo` → `mock-verify-custom`; backend считает изображения/фотосессии.
- **Production:** стратегия уточняется (отдельный RuStore продукт / подписка / только фиксированные пакеты в v1). Не реализовывать без требований RuStore Pay SDK и консоли.

---

## Security checklist

- [ ] Keystore и пароли **не** в git (`.gitignore`: `key.properties`, `*.jks`, `*.keystore`).
- [ ] RuStore API secrets только на backend / secure CI.
- [ ] Не доверять `amount_rub` / количеству изображений с клиента для catalog-пакетов.
- [ ] Уникальный `provider_payment_id` / purchase id на транзакцию.
- [ ] Production: отключить mock-verify endpoints (`ENVIRONMENT` ≠ development).

---

## Release signing notes

- **Сейчас:** `release` build подписан debug-ключом (`app/build.gradle.kts` — TODO Flutter template).
- **Перед RuStore публикацией:** создать release keystore **локально**, хранить вне репозитория.
- Подключить `signingConfigs.release` через `key.properties` (не коммитить).
- В CI: secrets / secure storage для alias, passwords, keystore file.
- RuStore принимает подписанный release/bundle с тем же certificate, что зарегистрирован в консоли.

---

## Test checklist (после подключения SDK)

- [ ] Sandbox / test purchase готового пакета → backend verified → баланс +N изображений.
- [ ] Повтор verification → `already_processed`, баланс не дублируется.
- [ ] Отмена оплаты в RuStore → понятное сообщение, баланс без изменений.
- [ ] Offline / 503 → retry или сообщение пользователю.
- [ ] **Своя сумма** (если поддерживается в production).
- [ ] Профиль / Создать / Фотосессии видят обновлённый баланс.
- [ ] Release APK/AAB подписан production keystore.

---

## TODO before real RuStore integration

1. Подтвердить **финальный `applicationId`** в RuStore Console (сейчас `com.aiimagegenerator.ai_image_generator`).
2. Настроить **release signing** (keystore, `key.properties`, CI secrets).
3. Зарегистрировать приложение и продукты в **RuStore Console**.
4. Выбрать и подключить **RuStore Pay SDK** (не BillingClient).
5. Добавить **manifest / deeplink** по документации Pay SDK.
6. Реализовать backend **real verification** endpoint.
7. Реализовать `PaymentService.purchase*WithRuStore` и переключить production UI.
8. Отключить mock-verify вне development.

---

## Related docs

- [api_contract.md](api_contract.md) — mock-verify, mock-verify-custom
- [project_status.md](project_status.md) — текущий статус оплаты
- [roadmap.md](roadmap.md) — этапы RuStore
