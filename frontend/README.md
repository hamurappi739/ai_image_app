# Frontend

Flutter MVP UI for **AI Image Generator** (Android / iOS).

## Backend

Start the API before generating:

```bash
cd backend
uvicorn app.main:app --reload
```

| Platform | `ApiService.baseUrl` |
|----------|----------------------|
| Web / Chrome | `http://127.0.0.1:8000` |
| Android emulator | `http://10.0.2.2:8000` |

Выбор URL автоматический (`kIsWeb` в `api_service.dart`).

## UI (MVP)

Single screen (`lib/main.dart`):

- **Generation status** card (ready / credits left / demo mode)
- Describe your image (multiline field, 3–6 lines)
- Quick idea chips → fill the field
- **Generate image** → `POST /generate` via `ApiService`
- Square image result card with loading and error states
- **No generations** warning card + SnackBar on HTTP 402

Light premium style, English copy. No Supabase / payments / auth yet.

## Run

```bash
cd frontend
flutter pub get
flutter run
```

```bash
flutter analyze
flutter test
```

## Structure

```
lib/
├── main.dart
└── services/
    └── api_service.dart
```
