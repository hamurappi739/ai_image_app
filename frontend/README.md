# Frontend

Flutter MVP UI для **AI Image Generator** (Android / iOS / Web).

**Основной язык интерфейса:** русский.

## Backend

Перед генерацией запустите API:

```bash
cd backend
uvicorn app.main:app --reload
```

| Платформа | `ApiService.baseUrl` |
|----------|----------------------|
| Web / Chrome | `http://127.0.0.1:8000` |
| Android emulator | `http://10.0.2.2:8000` |

## Авторизация (Supabase Auth)

- **`supabase_flutter`** + **`AuthService`**: вход и регистрация по email/паролю.
- **`Supabase.initialize`** только при `--dart-define=SUPABASE_URL=...` и `--dart-define=SUPABASE_ANON_KEY=...`.
- **Без dart-define:** вкладка **Профиль** показывает, что вход недоступен; **Создать** и **Галерея** работают через backend development fallback (`TEST_USER_ID`).
- **После входа:** access token передаётся в общий **`ApiService`** (`setAccessToken`); backend использует пользователя из Supabase Auth.
- **Без входа:** запросы без `Authorization` — в development backend по-прежнему использует `TEST_USER_ID`.
- Токен **не логируется** и **не хардкодится** в коде.

## Навигация

Нижнее меню (5 вкладок):

| Вкладка | Статус |
|---------|--------|
| **Создать** | Работает — `POST /generate` через `ApiService` |
| **Фотосессии** | Preview-карточки стилей, responsive layout (1–2 колонки) |
| **Галерея** | `GET /generations` + новые за сессию; empty state + переход на «Создать» |
| **Пакеты** | Пакеты генераций, responsive layout (1–3 колонки), без реальной оплаты |
| **Профиль** | Вход / регистрация / выход (при Supabase config) |

## Создать

- Статус генераций, поле описания, быстрые идеи (на русском)
- Подсказки «Как получить хороший результат» — простое описание без слова «промпт»
- Кнопка **Создать изображение** → `POST /generate`
- После генерации — **Открыть в Галерее** (переход на вкладку «Галерея»)
- Результат и предупреждение при отсутствии генераций

## Фотосессии

- 8 готовых стилей: градиентный preview, badge «Бесплатно» / «100 ₽»
- Кнопки «Попробовать» / «Оплата позже» открывают **демо-экран** (bottom sheet) с локальным выбором фото
- Можно выбрать фото с устройства, увидеть preview и выбрать другое фото в рамках открытого окна
- Для бесплатного сценария после выбора фото Flutter отправляет multipart-запрос в `POST /photoshoots/generate` (`style_id`, `style_title`, `photo`)
- Backend сейчас только валидирует файл и возвращает placeholder `501`; это ожидаемая заглушка
- Платные фотосессии пока не отправляют фото на backend
- Платные фотосессии пока показывают только «Оплата будет добавлена позже»
- Responsive layout: 2 колонки на широком экране (web), 1 колонка на узком
- Реальная загрузка фото, обработка и оплата будут добавлены позже

## Пакеты

- Три пакета генераций (Стартовый / Авторский / Профи) с ценами и количеством изображений
- Responsive layout: до 3 колонок на широком экране, 2 на среднем, 1 на мобильном
- В видимом UI нет слов «кредиты» и «токены» — только генерации и изображения
- Реальные платежи RuStore будут добавлены позже

## Галерея

- При старте: `ApiService.fetchGenerations()` → `GET /generations` (тихо при ошибке backend); служебные debug-записи dev-истории скрываются
- После генерации новый результат сразу добавляется **сверху** (локально)
- Сетка карточек: preview, описание, время; responsive 1–3 колонки
- Пустой список → empty state; кнопка **Создать первое изображение** → вкладка «Создать»
- **Очистить** — сброс списка только на этом устройстве (серверная история в Supabase не удаляется)
- Полная история по аккаунту и фотосессии — позже

## Профиль

- **Без Supabase config:** placeholder + текст «Вход недоступен в этом запуске» и подсказка про `dart-define`
- **С Supabase, без входа:** форма email/пароль, кнопки **Войти** и **Зарегистрироваться**
- **После входа:** карточка «Вы вошли», email, кнопка **Выйти**
- Мягкие SnackBar при ошибках (без технических деталей Supabase)
- Блок **Безопасность** при включённом Supabase

## Запуск

```bash
cd frontend
flutter pub get
```

### Без Supabase (по умолчанию)

Генерация и галерея работают через backend development fallback (`TEST_USER_ID`). Auth во Flutter отключён.

```bash
flutter run -d chrome
```

В debug в консоли может появиться: `Supabase is not configured for Flutter; auth disabled` (без вывода ключей).

### С конфигурацией Supabase Auth (dart-define)

Подставьте значения из Supabase Dashboard. **Не коммитьте** реальные URL и anon key в git.

```bash
flutter run -d chrome ^
  --dart-define=SUPABASE_URL=https://your-project.supabase.co ^
  --dart-define=SUPABASE_ANON_KEY=your_anon_key_here
```

Экран входа и привязка токена к `ApiService` уже работают при запуске с `dart-define`.

```bash
flutter analyze
flutter test
```

## Structure

```
lib/
├── main.dart
├── models/
│   └── generated_image_item.dart
└── services/
    ├── api_service.dart
    └── auth_service.dart
```
