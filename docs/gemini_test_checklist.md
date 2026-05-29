# Gemini Test Checklist

## Цель

- Проверить **реальную Gemini-генерацию** одним контролируемым запросом, без случайных списаний и без утечки секретов.
- Проверить, что если Gemini возвращает **`data:image/...;base64,...`**, backend **загружает изображение в Supabase Storage** (bucket `generated-images`).
- Проверить, что frontend получает **`image_url` как `public_url` из Storage**, а **не** огромный data URL в response.

## Перед тестом

Проверить:

- Git чистый:  
  `git status`

- `backend/.env` не должен попадать в git

- **Supabase Storage** bucket **`generated-images`** создан в Supabase Dashboard (для MVP — **public**)

- Storage debug endpoints работают (backend запущен, `ENVIRONMENT=development`):
  - `POST http://127.0.0.1:8000/debug/storage-test` — upload тестового файла, в ответе `public_url`
  - `POST http://127.0.0.1:8000/debug/storage-image-test` — upload тестового PNG data URL через `upload_generated_image_data_url`, в ответе `public_url`

- В `backend/.env` временно поставить:  
  `IMAGE_PROVIDER=gemini`  
  `ENABLE_CREDIT_CONSUMPTION=false`

- Проверить, что `GEMINI_API_KEY` задан (значение **не** логировать и **не** коммитить)

- Проверить модель:  
  `GEMINI_MODEL=gemini-2.5-flash-image`

- Проверить баланс/квоты/доступ к Gemini API

- Проверить debug config:  
  `GET http://127.0.0.1:8000/debug/config`

Ожидаемые безопасные значения:
- `image_provider: gemini`
- `credit_consumption_enabled: false`
- `gemini_api_key_configured: true`
- ключи и секреты **не должны** отображаться в ответе

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

Ввести во вкладке **Создать**:

Красивая чашка кофе на деревянном столе, реализм, мягкий свет

Нажать **Создать изображение**.

Опционально (только backend, без Flutter): короткий `POST /generate` с тем же prompt и проверка поля `image_url` в JSON-ответе.

## Что считать успехом

- backend **не падает**
- Gemini **возвращает изображение** (provider отдаёт data URL или backend успешно обрабатывает результат)
- backend **загружает generated image в Supabase Storage** (при data URL от provider)
- **`POST /generate`** возвращает **`image_url` как `public_url`** (URL вида `/storage/v1/object/public/generated-images/...`), **не** `data:image/...;base64,...`
- **`public_url` открывается в браузере** и показывает сгенерированное изображение
- frontend **не показывает** техническую ошибку
- результат **появляется в Галерее** (локально после генерации; при включённом credit consumption — также в истории Supabase)
- в **response / frontend не остаётся** огромный **`data:image` base64 URL**
- в backend **нет утечки ключей** в логах и ответах

## Если тест не прошёл

Возможные причины:

- Gemini **не вернул изображение** (только текст / пустой ответ)
- **нет баланса / квоты** Gemini API
- **`storage upload failed`** (ошибка Supabase Storage REST)
- bucket **`generated-images` не найден** или неверное имя (`SUPABASE_STORAGE_BUCKET`)
- проблема **public bucket / signed URL** (URL не открывается в браузере)
- **data URL невалидный или слишком большой** (> 10 MB) → backend **`400`**
- неверный `GEMINI_API_KEY`
- нет доступа к модели
- SDK/API вернул ошибку

Что делать:

- не продолжать повторные платные попытки вслепую
- проверить `POST /debug/storage-test` и `POST /debug/storage-image-test` — Storage должен работать отдельно от Gemini
- вернуть `IMAGE_PROVIDER=mock`
- перезапустить backend
- проверить, что demo fallback снова работает
- зафиксировать ошибку в заметках/roadmap **без секретов**

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
- вкладка **Создать** работает в demo-mode (mock fallback)
- fallback-preview отображается при необходимости

Проверить Git:  
`git status`

`backend/.env` **не должен** отображаться в git status.

## Важно

Никогда не отправлять:

- `GEMINI_API_KEY`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- содержимое `backend/.env`
- скриншоты с секретами
