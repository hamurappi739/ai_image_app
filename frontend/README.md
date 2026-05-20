# Frontend

Flutter MVP UI for **AI Image Generator** (Android / iOS / Web).

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

## Navigation

Bottom navigation with 5 tabs:

| Tab | Status |
|-----|--------|
| **Create** | Working — image generation via `ApiService` |
| Templates | Placeholder |
| History | Placeholder |
| Credits | Placeholder |
| Settings | Placeholder |

## Create tab

- **Generation status** card
- Describe your image + quick idea chips
- **Generate image** → `POST /generate`
- Square result card, no-generations warning on 402

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
├── main.dart              # Shell + Create tab + placeholders
└── services/
    └── api_service.dart
```
