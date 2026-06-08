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

Перед демо: `backend/.env` с Supabase-ключами; `ENVIRONMENT=development` для mock-пополнения в **Пакеты**.

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

```powershell
cd C:\Users\shuly\Desktop\ai_image_app\frontend
flutter clean
flutter pub get
flutter build apk --debug
```

**Путь к APK:**

```
frontend/build/app/outputs/flutter-apk/app-debug.apk
```

| | |
|---|---|
| Тип сборки | **debug** — не для RuStore / Play |
| Подпись | Debug keystore (Flutter template) |
| Проверка | Сборка `app-debug.apk` уже проходила успешно на текущем проекте |

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

| Клиент | URL backend (текущая сборка) |
|--------|------------------------------|
| **Chrome (web)** | `http://127.0.0.1:8000` |
| **Android emulator** | `http://10.0.2.2:8000` (alias хоста ПК) |
| **Физический телефон (APK)** | В коде сейчас тоже `http://10.0.2.2:8000` — это **адрес эмулятора**, на реальном телефоне **не работает** |

**Для демо через APK сейчас надёжнее:**

1. **Android emulator** + backend на ПК (`--host 0.0.0.0`), или  
2. **Chrome** на том же ПК, где крутится backend.

**Для физического телефона в будущем** понадобится IP компьютера в Wi‑Fi (например `http://192.168.1.10:8000`) или туннель (ngrok и т.п.) и настройка base URL в сборке — **пока не реализовано** (см. раздел G).

Убедитесь, что firewall не блокирует порт **8000**, если тестируете по сети.

---

## E. Android emulator

```powershell
cd C:\Users\shuly\Desktop\ai_image_app\frontend
flutter run -d emulator-5554
```

Замените `emulator-5554` на id из `flutter devices`. Backend: `http://10.0.2.2:8000` из приложения.

---

## F. Chrome demo

```powershell
cd C:\Users\shuly\Desktop\ai_image_app\frontend
flutter run -d chrome
```

Backend на том же ПК: `http://127.0.0.1:8000`. Удобнее всего для быстрого MVP-показа без APK.

---

## G. Not production yet

Следующее **ещё не готово** к публичному релизу:

| Область | Статус |
|---------|--------|
| RuStore real payment | Не подключён (`PaymentService` — demo mock-verify) |
| Release signing | Не настроен (debug keys в `app/build.gradle.kts`) |
| Production backend deploy | Не выполнен |
| Debug endpoints (`/debug/*`, mock-verify) | **404** в production (`ENVIRONMENT` ≠ development) — см. [production_safety_checklist.md](production_safety_checklist.md) |
| Real package purchase verification (RuStore API) | Не подключена |
| Supabase RLS / policies | Нужен финальный production review |
| App icon / name / store metadata | Могут потребовать доработки |
| Настраиваемый API URL для APK на физическом телефоне | Не реализован (hardcoded `10.0.2.2` для Android) |

---

## H. Demo scenario (короткий сценарий)

Режим backend: **раздел A** (demo mock + списание баланса).

1. **Профиль** — посмотреть баланс (изображения / фотосессии / бесплатные).
2. **Пакеты** — demo-пополнение: готовый пакет или **Своя сумма** → «Баланс пополнен».
3. **Создать** — генерация **без фото** → результат → **Галерея**.
4. **Создать** — генерация **с фото** → результат в **Галерее**.
5. **Галерея** — история сверху, группировка фотосессий.
6. **Фотосессии** — бесплатный стиль → 3 фото → **Галерея**.
7. Исчерпать баланс → предупреждение → переход в **Пакеты**.

Подробный текст для презентации: [demo_script.md](demo_script.md).

---

## Быстрая шпаргалка

| Задача | Команда / путь |
|--------|----------------|
| Demo backend | `uvicorn` + env из раздела A |
| Debug APK | `flutter build apk --debug` |
| APK файл | `frontend/build/app/outputs/flutter-apk/app-debug.apk` |
| Установка | `adb install -r build/app/outputs/flutter-apk/app-debug.apk` |
| Chrome | `flutter run -d chrome` |
| Emulator | `flutter run -d emulator-5554` |
