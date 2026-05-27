# Gemini Test Checklist

## Цель
Проверить реальную генерацию изображения через Gemini provider одним контролируемым запросом, без случайных списаний и без утечки секретов.

## Перед тестом

Проверить:

- Git чистый:  
  `git status`

- `backend/.env` не должен попадать в git

- В `backend/.env` временно поставить:  
  `IMAGE_PROVIDER=gemini`  
  `ENABLE_CREDIT_CONSUMPTION=false`

- Проверить, что `GEMINI_API_KEY` задан

- Проверить модель:  
  `GEMINI_MODEL=gemini-2.5-flash-image`

- Проверить баланс/квоты/доступ к Gemini API

- Проверить debug config:  
  `GET http://127.0.0.1:8000/debug/config`

Ожидаемые безопасные значения:
- `image_provider: gemini`
- `credit_consumption_enabled: false`
- `gemini_api_key_configured: true`
- ключи не должны отображаться

## Запуск

Backend:

```powershell
cd C:\Users\shuly\Desktop\ai_image_app\backend
.\.venv\Scripts\python.exe -m uvicorn app.main:app --reload
```

Frontend:

```powershell
cd C:\Users\shuly\Desktop\ai_image_app\frontend
flutter run -d chrome
```

## Тестовый запрос

Ввести во вкладке "Создать":

Красивая чашка кофе на деревянном столе, реализм, мягкий свет

Нажать "Создать изображение".

## Что считать успехом

- backend не падает
- frontend не показывает техническую ошибку
- появляется реальная картинка или data-url изображение
- результат добавляется в Галерею
- в backend нет утечки ключей в логах

## Если тест не прошёл

Возможные причины:
- нет баланса
- нет доступа к модели
- неверный `GEMINI_API_KEY`
- модель не вернула изображение
- SDK/API вернул ошибку

Что делать:
- не продолжать повторные платные попытки вслепую
- вернуть `IMAGE_PROVIDER=mock`
- перезапустить backend
- проверить, что demo fallback снова работает
- зафиксировать ошибку в заметках/roadmap без секретов

## После теста обязательно

Вернуть в `backend/.env`:

`IMAGE_PROVIDER=mock`  
`ENABLE_CREDIT_CONSUMPTION=false`

Перезапустить backend.

Проверить:

`GET http://127.0.0.1:8000/debug/config`

Ожидаемо:
- `image_provider: mock`
- `credit_consumption_enabled: false`

Проверить Flutter:
- вкладка Создать работает в demo-mode
- fallback-preview отображается

Проверить Git:  
`git status`

`backend/.env` не должен отображаться.

## Важно

Никогда не отправлять:
- `GEMINI_API_KEY`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- содержимое `backend/.env`
- скриншоты с секретами
