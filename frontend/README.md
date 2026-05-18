# Frontend

Flutter-приложение **AI Image Generator** (Android / iOS).

Минимальный стартовый экран; подключение к backend API — на следующем этапе. См. [docs/roadmap.md](../docs/roadmap.md) и [docs/api_contract.md](../docs/api_contract.md).

## Требования

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable)
- Android Studio / Xcode — для эмуляторов или реальных устройств

Проверка:

```bash
flutter doctor
```

## Запуск

```bash
cd frontend
flutter pub get
flutter run
```

Выберите устройство (эмулятор или подключённый телефон), когда CLI спросит.

Полезные команды:

```bash
flutter devices    # список устройств
flutter run -d <device_id>
```

## Структура

```
frontend/
├── lib/main.dart      # Точка входа и главный экран
├── pubspec.yaml       # Зависимости
├── android/           # Android-проект
└── ios/               # iOS-проект
```

## Следующие шаги

- HTTP-клиент к `POST /generate` (см. api contract)
- Supabase Auth, RuStore Billing — позже
