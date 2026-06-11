# Demo / release readiness checklist

Инструкция для **демонстрации приложения** через debug APK, Chrome или Android emulator. Это **не production release**.

Связанные документы: [demo_script.md](demo_script.md), [rustore_integration_plan.md](rustore_integration_plan.md), [project_status.md](project_status.md).

**Режимы env:** см. [env_config_checklist.md](env_config_checklist.md) (safe local, demo mock+balance, Gemini safe test, production).

---

## A. Demo backend mode (рекомендуется для показа логики)

Полный цикл: баланс списывается, фотосессии отдают 3 mock-кадра, Gemini **не** вызывается.

**Windows PowerShell:**

```powershell
cd C:\Users\shuly\Desktop\ai_image_app\backend
$env:ENABLE_CREDIT_CONSUMPTION='true'
$env:IMAGE_PROVIDER='mock'
$env:ENABLE_PHOTOSHOOT_GENERATION='true'
$env:PHOTOSHOOT_OUTPUT_COUNT='3'
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

| Параметр | Значение | Смысл |
|----------|----------|--------|
| `IMAGE_PROVIDER` | `mock` | Placeholder-изображения, **без расхода Gemini API** |
| `ENABLE_CREDIT_CONSUMPTION` | `true` | Списание баланса после успешной генерации |
| `ENABLE_PHOTOSHOOT_GENERATION` | `true` | Фотосессии проходят через backend (mock) |
| `PHOTOSHOOT_OUTPUT_COUNT` | `3` | Три кадра на фотосессию |
| `--host 0.0.0.0` | — | Backend доступен с других устройств в сети (не только localhost) |

Перед демо: `backend/.env` с Supabase-ключами; `ENVIRONMENT=development` для mock-пополнения в **Купить**.

Этот же режим использовался при **ручной проверке redesigned debug APK на физическом Android-телефоне** (см. раздел **D**).

---

## B. Safe Gemini test mode (осторожно)

Реальные генерации Gemini; баланс **не** списывается.

```powershell
cd C:\Users\shuly\Desktop\ai_image_app\backend
$env:ENABLE_CREDIT_CONSUMPTION='false'
$env:IMAGE_PROVIDER='gemini'
$env:ENABLE_PHOTOSHOOT_GENERATION='true'
$env:PHOTOSHOOT_OUTPUT_COUNT='3'
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

| | |
|---|---|
| Плюс | Реальное качество изображений в **Создать** / **Фотосессии** / **Галерея** |
| Минус | Каждая генерация **тратит Gemini API**; для массового демо не подходит |
| Баланс | Не списывается (`ENABLE_CREDIT_CONSUMPTION=false`) |

Использовать для точечной проверки качества, не для ежедневного APK-демо.

---

## C. Build debug APK

**Локальный backend на эмуляторе (проверено):**

```powershell
cd C:\Users\shuly\Desktop\ai_image_app\frontend
flutter pub get
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Без `API_BASE_URL` на Android по умолчанию тоже `http://10.0.2.2:8000`; явный dart-define зафиксирован в ручной проверке.

**Полная пересборка (при необходимости):**

```powershell
flutter clean
flutter pub get
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

**Путь к APK:**

```
frontend/build/app/outputs/flutter-apk/app-debug.apk
```

| | |
|---|---|
| Тип сборки | **debug** — не для RuStore / Play |
| Подпись | Debug keystore (Flutter template) |
| **Ручная проверка (✅)** | Сборка с `API_BASE_URL=http://10.0.2.2:8000` → `app-debug.apk`; установка на **Android emulator** через `adb install -r` |

---

## D. Install APK на Android-телефон

Из папки `frontend`:

```powershell
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

### На телефоне

- Разрешить **установку из неизвестных источников** (или через USB-отладку / файловый менеджер).
- Включить **USB-отладку**, если ставите через `adb`.

### Backend должен быть доступен устройству

| Клиент | URL backend по умолчанию | Переопределение |
|--------|--------------------------|-----------------|
| **Chrome (web)** | `http://127.0.0.1:8000` | `--dart-define=API_BASE_URL=...` |
| **Android emulator** | `http://10.0.2.2:8000` | `--dart-define=API_BASE_URL=...` |
| **Физический телефон (APK)** | `http://10.0.2.2:8000` (не работает на реальном устройстве) | **Обязательно** `--dart-define=API_BASE_URL=https://...` или IP/LAN URL |

**Для демо через APK на эмуляторе (✅ проверено):**

1. Backend на ПК: `python -m uvicorn app.main:app --host 0.0.0.0 --port 8000` (раздел A).
2. Сборка: `flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8000`.
3. Установка: `adb install -r build/app/outputs/flutter-apk/app-debug.apk`.
4. Эмулятор видит хост-машину как **`http://10.0.2.2:8000`**.

**Smoke test на Android emulator (✅):**

| Раздел / действие | Результат |
|-------------------|-----------|
| **Профиль** | Баланс отображается |
| **Свой запрос** | Генерация работает |
| **Купить** | Demo-пополнение (mock-verify) работает |
| **Фотосессии** | Экран открывается |
| **Готовые фото** | Экран открывается |

**Русский ввод на «Свой запрос»:** в **Chrome** кириллица вводится нормально. На **Android emulator** и **физическом телефоне** ввод зависит от раскладки клавиатуры; на уровне приложения **отдельной блокировки кириллицы не обнаружено**.

**Для физического телефона:** `10.0.2.2` **не работает** — LAN IP ПК в Wi‑Fi или HTTPS:

```powershell
flutter build apk --debug --dart-define=API_BASE_URL=http://192.168.31.242:8000
```

Замените IP на адрес вашего ПК в локальной сети (`ipconfig` в PowerShell). Альтернатива для production-like теста: `--dart-define=API_BASE_URL=https://your-backend.example.com`.

Убедитесь, что firewall не блокирует порт **8000**, телефон и ПК в **одной Wi‑Fi-сети**.

### Физический Android-телефон — redesigned APK (✅ проверено)

**Сборка и установка:**

```powershell
cd C:\Users\shuly\Desktop\ai_image_app\frontend
flutter build apk --debug --dart-define=API_BASE_URL=http://192.168.31.242:8000
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

**Backend на ПК (раздел A):**

```powershell
cd C:\Users\shuly\Desktop\ai_image_app\backend
$env:ENABLE_CREDIT_CONSUMPTION='true'
$env:IMAGE_PROVIDER='mock'
$env:ENABLE_PHOTOSHOOT_GENERATION='true'
$env:PHOTOSHOOT_OUTPUT_COUNT='3'
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

| Параметр | Значение при проверке |
|----------|------------------------|
| `API_BASE_URL` в APK | `http://192.168.31.242:8000` |
| Backend | `--host 0.0.0.0 --port 8000` на ПК в LAN |
| Режим | Demo mock + списание баланса (раздел A) |

**Smoke test нового UX на реальном телефоне (✅):**

| Раздел / действие | Результат |
|-------------------|-----------|
| **Главная** | Открывается |
| **«Начать создавать»** | Ведёт в **Фото по шаблону** |
| **Burger / drawer** | Открывается |
| Пункты меню (все разделы) | Открываются |
| **Фото по шаблону** → шаблон | Описание подставляется в **Свой запрос** |
| **Свой запрос** + фото | Добавление фото и генерация работают |
| **Фотосессии** | Экран открывается |
| **Купить** | Экран открывается |
| **Готовые фото** | Экран открывается |
| **Помощь** | Диалоги не выходят за границы экрана |
| **UX-polish (после redesign)** | Шапка без balance chip; подзаголовки целиком; компактные карточки; preview фотосессий без overflow |

**Не проверялось в этом прогоне как цель релиза:** production HTTPS backend, release signing, RuStore, массовая установка на разные модели Android.

---

## E. Android emulator

**`flutter run` (без APK):**

```powershell
cd C:\Users\shuly\Desktop\ai_image_app\frontend
flutter run -d emulator-5554
```

**Debug APK (проверенный сценарий):**

```powershell
# backend (отдельный терминал, раздел A):
# python -m uvicorn app.main:app --host 0.0.0.0 --port 8000

flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8000
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

Замените `emulator-5554` на id из `flutter devices`. Backend для эмулятора: **`http://10.0.2.2:8000`**.

---

## F. Chrome demo

**Локальный backend (по умолчанию):**

```powershell
cd C:\Users\shuly\Desktop\ai_image_app\frontend
flutter run -d chrome
```

**Внешний backend:**

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=https://your-backend.example.com
```

По умолчанию Chrome использует `http://127.0.0.1:8000`.

---

## G. Not production yet

Redesigned debug APK **проверен на одном физическом Android-телефоне** в LAN + demo mock-режиме (раздел **D**). Для **реального распространения** всё ещё нужно:

| Область | Статус |
|---------|--------|
| **Production backend deploy** | Не выполнен |
| **Публичный HTTPS `API_BASE_URL`** | Не настроен (сейчас LAN IP или localhost) |
| **Release signing** | Не настроен (debug keys в `app/build.gradle.kts`) |
| **RuStore real payment** | Не подключён (`PaymentService` — demo mock-verify) |
| **Проверка на нескольких Android-устройствах** | Не выполнена (проверен один телефон) |
| Debug endpoints (`/debug/*`, mock-verify) | **404** в production (`ENVIRONMENT` ≠ development) — см. [production_safety_checklist.md](production_safety_checklist.md) |
| Real package purchase verification (RuStore API) | Не подключена |
| Supabase RLS / policies | Нужен финальный production review |
| App icon / name / store metadata | Могут потребовать доработки |

---

## I. UX redesign checklist (APK / Chrome)

Проверка после сборки debug APK или `flutter run`. Backend: **раздел A** (demo mock + списание), если нужны фотосессии и списание баланса.

| # | Проверка | Ожидание |
|---|----------|----------|
| 1 | **Главная** | Welcome-экран; **«Начать создавать»** → **Фото по шаблону** |
| 2 | **Burger / drawer** | Открывается; виден блок **«Ваш баланс»** и **«Купить»** |
| 3 | **Фото по шаблону** | Категории шаблонов; **«Выбрать»** → **Свой запрос** с описанием |
| 4 | **Свой запрос** | Добавить фото → **«Создать фото»** → переход в **Готовые фото** |
| 5 | **Готовые фото** | Success-блок; результат виден; **«Что сделать дальше?»** ведёт в нужные разделы |
| 6 | **Фотосессии** | Подборки; бесплатный стиль → 3 фото → **Готовые фото** |
| 7 | **Купить** | 1 фото = 10 ₽, 1 фотосессия = 100 ₽; demo-пополнение обновляет баланс |
| 8 | **Профиль** | Личный кабинет; баланс совпадает с drawer |
| 9 | **Помощь** | Hub и диалоги без overflow |
| 10 | **Нулевой баланс** | Info-блок или диалог «Фото / Фотосессии закончились» → **Купить** |
| 11 | **Шапка** | Burger нажимается; **нет balance chip** (число «630» / «Фото: N»); подзаголовки **не обрезаются** |
| 12 | **Терминология** | Нет в UI: Пакеты, Галерея, prompt, credits, tokens, package |
| 13 | **Фото по шаблону** | Категории визуально разделены; карточки **компактные**; preview заметнее |
| 14 | **Свой запрос** | Preview фото после выбора; поле описания как input; блок **«Что получится»**; баланс не пугает при большом остатке |
| 15 | **Фотосессии** | Preview серии **без overflow**; chips-категории сверху; компактные карточки |
| 16 | **Layout / crash** | Нет **RenderBox was not laid out**; нет **yellow/black overflow** на основных экранах |
| 17 | **Баланс** | Виден в **drawer**, **Профиле**, **Купить**; **не** в шапке разделов |

---

## H. Demo scenario (короткий сценарий)

Режим backend: **раздел A** (demo mock + списание баланса). Проверен на **Chrome**, **Android emulator** и **физическом телефоне** (LAN APK).

1. **Главная** → **«Начать создавать»** → **Фото по шаблону**.
2. Выбрать шаблон → **Свой запрос** (описание уже заполнено) → добавить фото → **«Создать фото»**.
3. **Готовые фото** — результат в истории.
4. **Профиль** — баланс (фото / фотосессии / бесплатные).
5. **Купить** — demo-пополнение: готовый набор или **Своя сумма** → «Баланс пополнен».
6. **Фотосессии** — бесплатный стиль → 3 фото → **Готовые фото**.
7. Drawer — переход между разделами; **Помощь** — без overflow.
8. Исчерпать баланс → мягкий диалог / info-блок → **Купить**; баланс в drawer обновился после покупки.
9. Полный UX checklist — **раздел I**.

Подробный текст для презентации: [demo_script.md](demo_script.md).

---

## Быстрая шпаргалка

| Задача | Команда / путь |
|--------|----------------|
| Demo backend | `uvicorn` + env из раздела A |
| Debug APK (emulator) | `flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8000` |
| Debug APK (физ. телефон, LAN) | `flutter build apk --debug --dart-define=API_BASE_URL=http://<LAN-IP-ПК>:8000` (проверено: `192.168.31.242`) |
| Backend для emulator/APK/телефона | `uvicorn … --host 0.0.0.0 --port 8000` |
| APK файл | `frontend/build/app/outputs/flutter-apk/app-debug.apk` |
| Установка | `adb install -r build/app/outputs/flutter-apk/app-debug.apk` |
| Chrome | `flutter run -d chrome` |
| Emulator | `flutter run -d emulator-5554` |
