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
- вкладка **Создать** должна работать
- **Галерея** должна грузиться
- UI пока не меняется
- экран входа ещё не добавлен

## Текущий статус

- `supabase_flutter` добавлен
- `AuthService` подготовлен
- `Supabase.initialize` вызывается только если переданы `SUPABASE_URL` и `SUPABASE_ANON_KEY`
- access token пока не передаётся в `ApiService`
- реальный экран входа будет добавлен позже

## Важно

Никогда не коммитить:

- `backend/.env`
- Supabase anon key в коде
- service role key
- Gemini API key
