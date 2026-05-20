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
| **Photoshoots** | UI stub — 3 free + 5 paid photo sets (no backend / no payment) |
| History | Placeholder |
| **Credits** | UI stub — generation packages (no real payments) |
| Settings | Placeholder |

## Photoshoots tab

Former **Templates** tab. Ready-made **photo sets** (3 images per theme):

- Info card: upload and payments coming later
- **Free:** Studio, Business, Cozy Home → **Try free**
- **Paid (100 ₽):** Luxury, Winter, City, Evening Dress, Travel → **Pay later**

SnackBars only — no API calls, no navigation to Create. Real uploads and RuStore billing later.

## Credits tab

UI placeholder for future in-app purchases:

- Current balance card (Coming soon)
- **Starter** (25 / 199 ₽), **Creator** (100 / 599 ₽, Popular), **Pro** (250 / 1190 ₽)
- **Coming soon** → SnackBar *Payments will be added later*

## Create tab

- **Generation status** card
- Describe your image + quick idea chips
- **Generate image** → `POST /generate`
- Square result card, no-generations warning on 402

Light premium style, English copy. No Supabase / auth yet.

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
├── main.dart              # Shell, Create, Photoshoots, Credits, placeholders
└── services/
    └── api_service.dart
```
