# Frontend

Flutter MVP UI for **AI Image Generator** (Android / iOS).

## Backend

Start the API before generating:

```bash
cd backend
uvicorn app.main:app --reload
```

| Platform | `ApiService.baseUrl` in `lib/services/api_service.dart` |
|----------|--------------------------------------------------------|
| iOS simulator, desktop | `http://127.0.0.1:8000` |
| Android emulator | `http://10.0.2.2:8000` |

## UI (MVP)

Single screen (`lib/main.dart`):

- Describe your image (multiline field, 3–6 lines)
- Quick idea chips → fill the field
- **Generate image** → `POST /generate` via `ApiService`
- Result: `Image.network` + credits block when `creditConsumed` is true

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
