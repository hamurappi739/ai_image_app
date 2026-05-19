# Frontend

Flutter-приложение **AI Image Generator** (Android / iOS).

См. [docs/api_contract.md](../docs/api_contract.md).

## Backend

Перед тестами API запустите backend:

```bash
cd backend
uvicorn app.main:app --reload
```

Backend по умолчанию: **`http://127.0.0.1:8000`**

| Платформа | Base URL в `ApiService` |
|-----------|-------------------------|
| iOS simulator, desktop | `http://127.0.0.1:8000` (уже в коде) |
| Android emulator | позже заменить на `http://10.0.2.2:8000` |

`lib/services/api_service.dart` реализует `POST /generate`. **UI пока не подключён** — подключение на следующем шаге.

## Требования

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable)
- Android Studio / Xcode — для эмуляторов или реальных устройств

```bash
flutter doctor
```

## Запуск приложения

```bash
cd frontend
flutter pub get
flutter run
```

```bash
flutter devices
flutter run -d <device_id>
```

## Структура

```
frontend/
├── lib/
│   ├── main.dart
│   └── services/
│       └── api_service.dart   # POST /generate
├── pubspec.yaml
├── android/
└── ios/
```

## Следующие шаги

- Подключить `ApiService` к экрану генерации
- Supabase Auth, RuStore Billing — позже
