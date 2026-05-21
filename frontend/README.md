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
| **Photoshoots** | UI stub — free + paid photo sets |
| **Gallery** | Placeholder — your generated images (history later) |
| **Packs** | UI stub — generation packs (no credits/tokens in UI) |
| Settings | Placeholder |

User-facing copy uses **generations** and **packs**, not credits or tokens.

## Packs tab

Former **Credits** tab. **Generation packs** for advanced / custom flow:

- **Available generations** (Coming soon)
- **Starter** (25 / 199 ₽), **Creator** (100 / 499 ₽, Popular), **Pro** (250 / 1199 ₽)
- **Coming soon** → SnackBar *Payments will be added later*

Real RuStore billing not connected.

## Photoshoots tab

Ready-made photo sets (3 images per theme): 3 free + 5 paid (100 ₽) placeholders.

## Gallery tab

Former **History** tab. Placeholder for saved **generated images**:

- Empty state: *No images yet*
- Real gallery / Supabase history will be connected later

## Create tab

- **Generation status** — generations updated, free / paid generations left
- Describe your image + chips → `POST /generate`
- No-generations state → buy a **pack** (no “credits” wording)

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
