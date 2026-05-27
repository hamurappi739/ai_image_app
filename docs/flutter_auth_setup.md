# Flutter Auth Setup

## Цель

Подготовка Flutter-приложения к Supabase Auth без хранения ключей в коде.

## Обычный запуск без Supabase Auth

Команда:

```powershell
cd C:\Users\shuly\Desktop\ai_image_app\frontend
flutter run -d chrome
```

Что происходит:

- приложение запускается без `Supabase.initialize`
- авторизация отключена
- backend работает через development fallback `TEST_USER_ID`
- **Создать** и **Галерея** продолжают работать

## Запуск с Supabase config

Команда-шаблон:

```powershell
cd C:\Users\shuly\Desktop\ai_image_app\frontend
flutter run -d chrome --dart-define=SUPABASE_URL=YOUR_SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

Где взять значения:

- `SUPABASE_URL` и `SUPABASE_ANON_KEY` сейчас можно взять из `backend/.env`
- не отправлять эти значения в чат
- не делать скриншоты с ключами
- не коммитить ключи

## Проверка

После запуска с `dart-define`:

- приложение должно открыться
- вкладка **Профиль** показывает форму входа/регистрации
- после входа или регистрации — SnackBar «Вы вошли в аккаунт» / «Аккаунт создан»

## Проверенный сценарий

1. Запустить backend (`uvicorn` на `127.0.0.1:8000`).
2. Запустить Flutter **с dart-define** (подставить свои значения локально, **не коммитить**):

```powershell
cd C:\Users\shuly\Desktop\ai_image_app\frontend
flutter run -d chrome --dart-define=SUPABASE_URL=YOUR_SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

3. Открыть вкладку **Профиль** → **Войти** или **Зарегистрироваться** (email + пароль).
4. После входа проверить:
   - **Создать** — генерация по описанию работает
   - **Галерея** — история загружается
5. **Выйти** в Профиле → токен сбрасывается; без входа снова работает development fallback на backend.

Не отправлять ключи в чат, не делать скриншоты с секретами, не коммитить `backend/.env` и dart-define в git.

## Текущий статус

- `supabase_flutter` + `AuthService` + форма в **Профиль**
- `Supabase.initialize` только при `SUPABASE_URL` и `SUPABASE_ANON_KEY` (dart-define)
- после входа access token передаётся в `ApiService`
- без dart-define — demo-mode, вход недоступен, **Создать** / **Галерея** через `TEST_USER_ID`

## Важно

Никогда не коммитить:

- `backend/.env`
- Supabase anon key в коде
- service role key
- Gemini API key
